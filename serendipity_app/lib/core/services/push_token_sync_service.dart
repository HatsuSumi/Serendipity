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
import 'sync_service.dart';

final pushTokenSyncServiceProvider = Provider<PushTokenSyncService>((ref) {
  final repository = ref.read(remoteDataRepositoryProvider);
  return PushTokenSyncService(ref, repository);
});

class PushTokenSyncService {
  PushTokenSyncService(this._ref, this._remoteRepository);

  final Ref _ref;
  final IRemoteDataRepository _remoteRepository;

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _lastSyncedToken;
  bool _initialized = false;

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
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _initialized = false;
  }

  Future<void> syncForAuthenticatedUser() async {
    await _syncForCurrentUser();
  }

  Future<void> unregisterForCurrentUser() async {
    if (kIsWeb || AppConfig.serverType != ServerType.customServer) {
      return;
    }

    final token = _lastSyncedToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      _lastSyncedToken = null;
      return;
    }

    try {
      await _remoteRepository.unregisterPushToken(token);
    } catch (_) {
      // 登出路径静默失败，不阻塞主流程
    } finally {
      _lastSyncedToken = null;
    }
  }

  Future<void> _syncForCurrentUser({String? tokenOverride}) async {
    if (kIsWeb || AppConfig.serverType != ServerType.customServer) {
      return;
    }

    final authState = _ref.read(authProvider);
    final user = authState.value;
    if (!_isAuthenticatedUser(user)) {
      return;
    }

    final permission = await FirebaseMessaging.instance.requestPermission();
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = tokenOverride ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final timezone = await FlutterTimezone.getLocalTimezone();
    final registration = PushTokenRegistration(
      token: token,
      platform: _resolvePlatform(),
      timezone: timezone,
    );

    await _remoteRepository.registerPushToken(registration);
    _lastSyncedToken = token;
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

