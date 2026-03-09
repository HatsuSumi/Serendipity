import 'package:hive/hive.dart';
import '../core/services/sync_service.dart';

part 'sync_history.g.dart';

/// 自动同步来源
enum SyncSource {
  /// 手动同步
  manual,
  
  /// App 启动时
  appStartup,
  
  /// 登录成功后
  login,
  
  /// 注册成功后
  register,
  
  /// 网络重新连接
  networkReconnect,
  
  /// 60秒轮询
  polling,
}

/// 同步历史记录
/// 
/// 记录每次同步的详细信息，用于用户查看历史同步记录。
/// 
/// 职责：
/// - 存储同步时间、结果、类型（手动/自动）
/// - 存储同步统计信息（上传/下载/合并数量）
/// - 存储同步耗时和错误信息
/// 
/// 调用者：
/// - SyncStatusNotifier：每次同步完成后保存历史记录
/// - SyncHistoryDialog：读取并展示历史记录
/// 
/// 遵循原则：
/// - 单一职责（SRP）：只负责存储同步历史数据
/// - 不可变性：所有字段都是 final
/// - Fail Fast：构造函数验证必填字段
@HiveType(typeId: 33)
class SyncHistory {
  /// 同步记录 ID（使用时间戳生成）
  @HiveField(0)
  final String id;
  
  /// 同步时间
  @HiveField(1)
  final DateTime syncTime;
  
  /// 是否手动同步（true: 手动，false: 自动）
  @HiveField(2)
  final bool isManual;
  
  /// 是否成功
  @HiveField(3)
  final bool success;
  
  /// 同步耗时（毫秒）
  @HiveField(4)
  final int durationMs;
  
  /// 错误信息（如果失败）
  @HiveField(5)
  final String? errorMessage;
  
  /// 上传的记录数量
  @HiveField(6)
  final int uploadedRecords;
  
  /// 上传的故事线数量
  @HiveField(7)
  final int uploadedStoryLines;
  
  /// 上传的签到记录数量
  @HiveField(8)
  final int uploadedCheckIns;
  
  /// 下载的记录数量
  @HiveField(9)
  final int downloadedRecords;
  
  /// 下载的故事线数量
  @HiveField(10)
  final int downloadedStoryLines;
  
  /// 下载的签到记录数量
  @HiveField(11)
  final int downloadedCheckIns;
  
  /// 合并冲突的记录数量
  @HiveField(12)
  final int mergedRecords;
  
  /// 合并冲突的故事线数量
  @HiveField(13)
  final int mergedStoryLines;
  
  /// 合并冲突的签到记录数量
  @HiveField(14)
  final int mergedCheckIns;
  
  /// 同步的成就解锁数量
  @HiveField(15)
  final int syncedAchievements;
  
  /// 同步来源
  @HiveField(16)
  final SyncSource source;
  
  /// 构造函数
  /// 
  /// 调用者：SyncStatusNotifier.syncSuccess()
  /// 
  /// Fail Fast：
  /// - id 为空：抛出 ArgumentError
  /// - durationMs < 0：抛出 ArgumentError
  /// - success 为 false 但 errorMessage 为空：抛出 ArgumentError
  SyncHistory({
    required this.id,
    required this.syncTime,
    required this.isManual,
    required this.success,
    required this.durationMs,
    this.errorMessage,
    required this.uploadedRecords,
    required this.uploadedStoryLines,
    required this.uploadedCheckIns,
    required this.downloadedRecords,
    required this.downloadedStoryLines,
    required this.downloadedCheckIns,
    required this.mergedRecords,
    required this.mergedStoryLines,
    required this.mergedCheckIns,
    required this.syncedAchievements,
    required this.source,
  }) {
    // Fail Fast：参数验证
    if (id.isEmpty) {
      throw ArgumentError('同步记录 ID 不能为空');
    }
    if (durationMs < 0) {
      throw ArgumentError('同步耗时不能为负数');
    }
    if (!success && (errorMessage == null || errorMessage!.isEmpty)) {
      throw ArgumentError('同步失败时必须提供错误信息');
    }
  }
  
  /// 从 SyncResult 创建成功的同步历史记录
  /// 
  /// 调用者：SyncService.syncAllData()
  /// 
  /// Fail Fast：
  /// - result 为 null：由 Dart 类型系统保证
  /// - syncStartTime 为 null：由 Dart 类型系统保证
  /// - syncEndTime 为 null：由 Dart 类型系统保证
  factory SyncHistory.fromSuccess({
    required SyncResult result,
    required DateTime syncStartTime,
    required DateTime syncEndTime,
    required SyncSource source,
  }) {
    final durationMs = syncEndTime.difference(syncStartTime).inMilliseconds;
    
    return SyncHistory(
      id: syncStartTime.millisecondsSinceEpoch.toString(),
      syncTime: syncStartTime,
      isManual: source == SyncSource.manual,
      success: true,
      durationMs: durationMs,
      errorMessage: null,
      uploadedRecords: result.uploadedRecords,
      uploadedStoryLines: result.uploadedStoryLines,
      uploadedCheckIns: result.uploadedCheckIns,
      downloadedRecords: result.downloadedRecords,
      downloadedStoryLines: result.downloadedStoryLines,
      downloadedCheckIns: result.downloadedCheckIns,
      mergedRecords: result.mergedRecords,
      mergedStoryLines: result.mergedStoryLines,
      mergedCheckIns: result.mergedCheckIns,
      syncedAchievements: result.syncedAchievements,
      source: source,
    );
  }
  
  /// 创建失败的同步历史记录
  /// 
  /// 调用者：SyncService.syncAllData()
  /// 
  /// Fail Fast：
  /// - errorMessage 为空：抛出 ArgumentError
  /// - syncStartTime 为 null：由 Dart 类型系统保证
  /// - syncEndTime 为 null：由 Dart 类型系统保证
  factory SyncHistory.fromError({
    required String errorMessage,
    required DateTime syncStartTime,
    required DateTime syncEndTime,
    required SyncSource source,
  }) {
    if (errorMessage.isEmpty) {
      throw ArgumentError('错误信息不能为空');
    }
    
    final durationMs = syncEndTime.difference(syncStartTime).inMilliseconds;
    
    return SyncHistory(
      id: syncStartTime.millisecondsSinceEpoch.toString(),
      syncTime: syncStartTime,
      isManual: source == SyncSource.manual,
      success: false,
      durationMs: durationMs,
      errorMessage: errorMessage,
      uploadedRecords: 0,
      uploadedStoryLines: 0,
      uploadedCheckIns: 0,
      downloadedRecords: 0,
      downloadedStoryLines: 0,
      downloadedCheckIns: 0,
      mergedRecords: 0,
      mergedStoryLines: 0,
      mergedCheckIns: 0,
      syncedAchievements: 0,
      source: source,
    );
  }
  
  /// 是否有数据变化
  /// 
  /// 调用者：SyncHistoryDialog._buildHistoryItem()
  bool get hasChanges {
    return uploadedRecords > 0 ||
           uploadedStoryLines > 0 ||
           uploadedCheckIns > 0 ||
           downloadedRecords > 0 ||
           downloadedStoryLines > 0 ||
           downloadedCheckIns > 0 ||
           mergedRecords > 0 ||
           mergedStoryLines > 0 ||
           mergedCheckIns > 0 ||
           syncedAchievements > 0;
  }
  
  /// 格式化耗时
  /// 
  /// 调用者：SyncHistoryDialog._buildHistoryItem()
  /// 
  /// 返回格式：
  /// - < 1秒：`XXXms`
  /// - >= 1秒：`X.Xs`
  String get formattedDuration {
    if (durationMs < 1000) {
      return '${durationMs}ms';
    } else {
      return '${(durationMs / 1000).toStringAsFixed(1)}s';
    }
  }
  
  /// 获取来源描述
  /// 
  /// 调用者：SyncHistoryDialog._buildHistoryItem()
  String get sourceDescription {
    switch (source) {
      case SyncSource.manual:
        return '手动同步';
      case SyncSource.appStartup:
        return 'App启动';
      case SyncSource.login:
        return '登录后';
      case SyncSource.register:
        return '注册后';
      case SyncSource.networkReconnect:
        return '网络恢复';
      case SyncSource.polling:
        return '60秒轮询';
    }
  }
  
  /// JSON 序列化
  /// 
  /// 调用者：StorageService（Hive 不需要，但保留以备将来使用）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'syncTime': syncTime.toIso8601String(),
      'isManual': isManual,
      'success': success,
      'durationMs': durationMs,
      'errorMessage': errorMessage,
      'uploadedRecords': uploadedRecords,
      'uploadedStoryLines': uploadedStoryLines,
      'uploadedCheckIns': uploadedCheckIns,
      'downloadedRecords': downloadedRecords,
      'downloadedStoryLines': downloadedStoryLines,
      'downloadedCheckIns': downloadedCheckIns,
      'mergedRecords': mergedRecords,
      'mergedStoryLines': mergedStoryLines,
      'mergedCheckIns': mergedCheckIns,
      'syncedAchievements': syncedAchievements,
      'source': source.name,
    };
  }
  
  /// JSON 反序列化
  /// 
  /// 调用者：StorageService（Hive 不需要，但保留以备将来使用）
  factory SyncHistory.fromJson(Map<String, dynamic> json) {
    return SyncHistory(
      id: json['id'] as String,
      syncTime: DateTime.parse(json['syncTime'] as String),
      isManual: json['isManual'] as bool,
      success: json['success'] as bool,
      durationMs: json['durationMs'] as int,
      errorMessage: json['errorMessage'] as String?,
      uploadedRecords: json['uploadedRecords'] as int,
      uploadedStoryLines: json['uploadedStoryLines'] as int,
      uploadedCheckIns: json['uploadedCheckIns'] as int,
      downloadedRecords: json['downloadedRecords'] as int,
      downloadedStoryLines: json['downloadedStoryLines'] as int,
      downloadedCheckIns: json['downloadedCheckIns'] as int,
      mergedRecords: json['mergedRecords'] as int,
      mergedStoryLines: json['mergedStoryLines'] as int,
      mergedCheckIns: json['mergedCheckIns'] as int,
      syncedAchievements: json['syncedAchievements'] as int,
      source: SyncSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => SyncSource.manual,
      ),
    );
  }
}

