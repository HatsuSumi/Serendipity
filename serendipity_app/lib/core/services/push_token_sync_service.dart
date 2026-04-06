import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../models/push_token_registration.dart';
import '../../models/user.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../repositories/i_remote_data_repository.dart';
import 'push_models.dart';
import 'sync_service.dart';

final pushTokenRemoteServiceProvider = Provider<PushTokenRemoteService>((ref) {
  final repository = ref.read(remoteDataRepositoryProvider);
  return PushTokenRemoteService(repository);
});

final pushTokenSignOutInProgressProvider = StateProvider<bool>((ref) => false);

final pushTokenSyncServiceProvider = Provider<PushTokenSyncService>((ref) {
  final remoteService = ref.read(pushTokenRemoteServiceProvider);
  return PushTokenSyncService(ref, remoteService);
});

class PushTokenRemoteService {
  PushTokenRemoteService(this._remoteRepository);

  final IRemoteDataRepository _remoteRepository;

  Future<void> unregisterCurrentToken(String? fallbackToken) async {
    final token = fallbackToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _remoteRepository.unregisterPushToken(token);
    } catch (_) {}
  }

  Future<void> registerToken(PushTokenRegistration registration) async {
    await _remoteRepository.registerPushToken(registration);
  }

  Future<RepositoryPushTokenStatus> fetchRegisteredTokens() async {
    return _remoteRepository.listPushTokens();
  }
}

class PushTokenSyncService {
  PushTokenSyncService(this._ref, this._remoteService);

  final Ref _ref;
  final PushTokenRemoteService _remoteService;

  StreamSubscription<String>? _tokenRefreshSubscription;
  ProviderSubscription<AsyncValue<User?>>? _authSubscription;
  String? _lastSyncedToken;
  String? _lastAuthenticatedUserId;
  bool _initialized = false;
  Future<void>? _activeSync;
  PushTokenSyncStatus _lastSyncStatus = const PushTokenSyncStatus.idle();

  Future<void> initialize() async {
    if (_initialized || kIsWeb || AppConfig.serverType != ServerType.customServer) {
      return;
    }

    _initialized = true;
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) {
        _lastSyncedToken = token;
        unawaited(_syncForCurrentUser(tokenOverride: token));
      },
      onError: (_, __) {},
    );
    _authSubscription = _ref.listen<AsyncValue<User?>>(
      authProvider,
      (previous, next) {
        _handleAuthStateChanged(next.valueOrNull);
      },
    );

    final currentUser = _ref.read(authProvider).valueOrNull;
    if (_isAuthenticatedUser(currentUser)) {
      _lastAuthenticatedUserId = currentUser!.id;
      await syncForAuthenticatedUser();
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _authSubscription?.close();
    _authSubscription = null;
    _lastAuthenticatedUserId = null;
    _initialized = false;
  }

  Future<void> syncForAuthenticatedUser() async {
    await _syncForCurrentUser();
  }

  User? get currentAuthenticatedUser {
    final user = _ref.read(authProvider).value;
    return _isAuthenticatedUser(user) ? user : null;
  }

  Future<RepositoryPushTokenStatus?> fetchRegisteredTokensForCurrentUser() async {
    if (kIsWeb || AppConfig.serverType != ServerType.customServer) {
      return null;
    }

    if (currentAuthenticatedUser == null) {
      return null;
    }

    return _remoteService.fetchRegisteredTokens();
  }

  PushTokenSyncStatus get lastSyncStatus => _lastSyncStatus;

  Future<void> unregisterBeforeSignOut() async {
    _lastAuthenticatedUserId = null;
    await unregisterForCurrentUser();
  }

  Future<void> unregisterForCurrentUser() async {
    if (kIsWeb || AppConfig.serverType != ServerType.customServer) {
      return;
    }

    await _remoteService.unregisterCurrentToken(_lastSyncedToken);
    _lastSyncedToken = null;
  }

  Future<void> _syncForCurrentUser({String? tokenOverride}) async {
    if (_activeSync != null) {
      await _activeSync;
      return;
    }

    final syncFuture = _performSyncForCurrentUser(tokenOverride: tokenOverride);
    _activeSync = syncFuture;
    try {
      await syncFuture;
    } finally {
      if (identical(_activeSync, syncFuture)) {
        _activeSync = null;
      }
    }
  }

  void _handleAuthStateChanged(User? user) {
    if (_isAuthenticatedUser(user)) {
      final userId = user!.id;
      if (_lastAuthenticatedUserId == userId) {
        return;
      }

      _lastAuthenticatedUserId = userId;
      unawaited(syncForAuthenticatedUser());
      return;
    }

    if (_lastAuthenticatedUserId == null) {
      return;
    }

    final isSigningOut = _ref.read(pushTokenSignOutInProgressProvider);
    _lastAuthenticatedUserId = null;

    if (isSigningOut) {
      _ref.read(pushTokenSignOutInProgressProvider.notifier).state = false;
      _lastSyncedToken = null;
      return;
    }

    unawaited(unregisterForCurrentUser());
  }

  Future<void> _performSyncForCurrentUser({String? tokenOverride}) async {
    if (kIsWeb || AppConfig.serverType != ServerType.customServer) {
      return;
    }

    final user = currentAuthenticatedUser;
    if (user == null) {
      return;
    }

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!permissionGranted) {
      _lastSyncStatus = const PushTokenSyncStatus.failure(errorMessage: '通知权限未授予');
      return;
    }

    String? token;
    try {
      if (tokenOverride != null) {
        token = tokenOverride;
      } else {
        token = await FirebaseMessaging.instance.getToken().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            return null;
          },
        );
      }
    } catch (error) {
      _lastSyncStatus = PushTokenSyncStatus.failure(errorMessage: error.toString());
      rethrow;
    }

    if (token == null || token.isEmpty) {
      _lastSyncStatus = const PushTokenSyncStatus.failure(errorMessage: '未获取到 push token');
      return;
    }

    final timezone = await FlutterTimezone.getLocalTimezone();
    final registration = PushTokenRegistration(
      token: token,
      platform: _resolvePlatform(),
      timezone: timezone,
    );

    try {
      await _remoteService.registerToken(registration);
      _lastSyncedToken = token;
      _lastSyncStatus = PushTokenSyncStatus.success(syncedAt: DateTime.now());
    } catch (error) {
      _lastSyncStatus = PushTokenSyncStatus.failure(errorMessage: error.toString());
      rethrow;
    }
  }

  bool _isAuthenticatedUser(User? user) {
    return user != null && user.id.isNotEmpty && user.id != 'guest';
  }

  String _resolvePlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
      default:
        return 'android';
    }
  }
}
