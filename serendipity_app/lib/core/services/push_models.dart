import 'notification_service.dart' show TestNotificationResult;
import '../repositories/i_remote_data_repository.dart'
    show RepositoryPushTokenStatus, RepositoryServerTestPushSummary;

/// 推送同步结果状态
class PushTokenSyncStatus {
  final bool hasSynced;
  final DateTime? syncedAt;
  final String? errorMessage;

  const PushTokenSyncStatus({
    required this.hasSynced,
    this.syncedAt,
    this.errorMessage,
  });

  const PushTokenSyncStatus.idle()
      : hasSynced = false,
        syncedAt = null,
        errorMessage = null;

  const PushTokenSyncStatus.success({required this.syncedAt})
      : hasSynced = true,
        errorMessage = null;

  const PushTokenSyncStatus.failure({required this.errorMessage})
      : hasSynced = false,
        syncedAt = null;

  String get summaryText {
    if (hasSynced && syncedAt != null) {
      return '最近一次同步成功：${syncedAt!.toLocal()}';
    }
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return '最近一次同步失败：$errorMessage';
    }
    return '最近一次同步：暂无记录';
  }

  String get statusLabel {
    if (hasSynced && syncedAt != null) {
      return '成功';
    }
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return '失败';
    }
    return '暂无记录';
  }

  String get detailText {
    if (hasSynced && syncedAt != null) {
      return '最近一次同步成功：${syncedAt!.toLocal()}';
    }
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }
    return '尚未记录到 token 同步结果';
  }

  DiagnosticsTone get tone {
    if (hasSynced && syncedAt != null) {
      return DiagnosticsTone.success;
    }
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return DiagnosticsTone.warning;
    }
    return DiagnosticsTone.muted;
  }
}

enum DiagnosticsTone {
  success,
  warning,
  muted,
}

/// 服务端测试推送结果详情
class ServerPushTestResult {
  final TestNotificationResult status;
  final String message;
  final String? details;
  final RepositoryServerTestPushSummary? summary;

  const ServerPushTestResult({
    required this.status,
    required this.message,
    this.details,
    this.summary,
  });
}

/// 服务端测试推送结果摘要
class ServerTestPushSummary {
  final String dispatchSource;
  final int scannedCandidates;
  final int sentCount;
  final int failedCount;

  const ServerTestPushSummary({
    required this.dispatchSource,
    required this.scannedCandidates,
    required this.sentCount,
    required this.failedCount,
  });

  String toShortText() {
    return '扫描 $scannedCandidates 台，成功 $sentCount，失败 $failedCount';
  }
}

/// 推送诊断快照
class PushDiagnosticsSnapshot {
  final bool isSupported;
  final bool permissionGranted;
  final String platform;
  final String? token;
  final bool tokenAvailable;
  final bool tokenSynced;
  final int registeredTokenCount;
  final bool currentTokenRegistered;
  final PushTokenSyncStatus lastSyncStatus;

  const PushDiagnosticsSnapshot({
    required this.isSupported,
    required this.permissionGranted,
    required this.platform,
    required this.token,
    required this.tokenAvailable,
    required this.tokenSynced,
    required this.registeredTokenCount,
    required this.currentTokenRegistered,
    required this.lastSyncStatus,
  });

  String get tokenPreview {
    final value = token;
    if (value == null || value.isEmpty) {
      return '未获取到';
    }
    if (value.length <= 16) {
      return value;
    }
    return '${value.substring(0, 8)}...${value.substring(value.length - 8)}';
  }

  String get permissionStatusText {
    return permissionGranted ? '已授予' : '未授予';
  }

  String get registrationStatusText {
    if (!tokenAvailable) {
      return '当前设备未获取到 token';
    }
    if (currentTokenRegistered) {
      return '当前 token 已注册到服务端';
    }
    return '当前 token 尚未注册到服务端';
  }

  factory PushDiagnosticsSnapshot.unsupported({required String platform}) {
    return PushDiagnosticsSnapshot(
      isSupported: false,
      permissionGranted: false,
      platform: platform,
      token: null,
      tokenAvailable: false,
      tokenSynced: false,
      registeredTokenCount: 0,
      currentTokenRegistered: false,
      lastSyncStatus: const PushTokenSyncStatus.idle(),
    );
  }

  factory PushDiagnosticsSnapshot.fromRemoteStatus({
    required String platform,
    required bool permissionGranted,
    required String? token,
    required RepositoryPushTokenStatus remoteStatus,
    required PushTokenSyncStatus lastSyncStatus,
  }) {
    final tokenAvailable = token != null && token.isNotEmpty;
    final currentTokenRegistered = tokenAvailable &&
        remoteStatus.pushTokens.any((pushToken) => pushToken.token == token);
    return PushDiagnosticsSnapshot(
      isSupported: true,
      permissionGranted: permissionGranted,
      platform: platform,
      token: token,
      tokenAvailable: tokenAvailable,
      tokenSynced: currentTokenRegistered,
      registeredTokenCount: remoteStatus.pushTokens.length,
      currentTokenRegistered: currentTokenRegistered,
      lastSyncStatus: lastSyncStatus,
    );
  }
}
