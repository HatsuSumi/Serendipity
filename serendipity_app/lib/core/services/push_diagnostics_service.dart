import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'push_models.dart';
import 'push_token_sync_service.dart';

final pushDiagnosticsServiceProvider = Provider<PushDiagnosticsService>((ref) {
  return PushDiagnosticsService(
    ref.read(pushTokenSyncServiceProvider),
  );
});

class PushDiagnosticsService {
  PushDiagnosticsService(this._pushTokenSyncService);

  final PushTokenSyncService _pushTokenSyncService;

  Future<PushDiagnosticsSnapshot> collectDiagnostics() async {
    if (kIsWeb) {
      return PushDiagnosticsSnapshot.unsupported(platform: 'web');
    }

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );
    } catch (_) {
      token = null;
    }

    if (AppConfig.serverType != ServerType.customServer) {
      return PushDiagnosticsSnapshot(
        isSupported: true,
        permissionGranted: permissionGranted,
        platform: defaultTargetPlatform.name,
        token: token,
        tokenAvailable: token != null && token.isNotEmpty,
        tokenSynced: false,
        registeredTokenCount: 0,
        currentTokenRegistered: false,
        lastSyncStatus: const PushTokenSyncStatus.idle(),
      );
    }

    if (_pushTokenSyncService.currentAuthenticatedUser == null) {
      return PushDiagnosticsSnapshot(
        isSupported: true,
        permissionGranted: permissionGranted,
        platform: defaultTargetPlatform.name,
        token: token,
        tokenAvailable: token != null && token.isNotEmpty,
        tokenSynced: false,
        registeredTokenCount: 0,
        currentTokenRegistered: false,
        lastSyncStatus: _pushTokenSyncService.lastSyncStatus,
      );
    }

    try {
      final remoteStatus =
          await _pushTokenSyncService.fetchRegisteredTokensForCurrentUser();
      if (remoteStatus == null) {
        return PushDiagnosticsSnapshot(
          isSupported: true,
          permissionGranted: permissionGranted,
          platform: defaultTargetPlatform.name,
          token: token,
          tokenAvailable: token != null && token.isNotEmpty,
          tokenSynced: false,
          registeredTokenCount: 0,
          currentTokenRegistered: false,
          lastSyncStatus: _pushTokenSyncService.lastSyncStatus,
        );
      }

      return PushDiagnosticsSnapshot.fromRemoteStatus(
        platform: defaultTargetPlatform.name,
        permissionGranted: permissionGranted,
        token: token,
        remoteStatus: remoteStatus,
        lastSyncStatus: _pushTokenSyncService.lastSyncStatus,
      );
    } catch (error) {
      return PushDiagnosticsSnapshot(
        isSupported: true,
        permissionGranted: permissionGranted,
        platform: defaultTargetPlatform.name,
        token: token,
        tokenAvailable: token != null && token.isNotEmpty,
        tokenSynced: false,
        registeredTokenCount: 0,
        currentTokenRegistered: false,
        lastSyncStatus: PushTokenSyncStatus.failure(errorMessage: error.toString()),
      );
    }
  }
}

