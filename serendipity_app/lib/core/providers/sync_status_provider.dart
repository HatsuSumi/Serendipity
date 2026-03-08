import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/i_storage_service.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';

/// 同步状态
enum SyncStatus {
  /// 空闲（未同步或同步完成）
  idle,
  
  /// 同步中
  syncing,
  
  /// 同步成功
  success,
  
  /// 同步失败
  error,
}

/// 同步状态信息
/// 
/// 职责：
/// - 追踪同步状态（空闲、同步中、成功、失败）
/// - 记录上次手动同步时间
/// - 记录同步结果统计
/// - 记录错误信息
class SyncStatusInfo {
  /// 当前状态
  final SyncStatus status;
  
  /// 上次手动同步时间
  final DateTime? lastManualSyncTime;
  
  /// 同步结果统计
  final SyncResult? syncResult;
  
  /// 错误信息（如果有）
  final String? errorMessage;
  
  const SyncStatusInfo({
    required this.status,
    this.lastManualSyncTime,
    this.syncResult,
    this.errorMessage,
  });
  
  SyncStatusInfo copyWith({
    SyncStatus? status,
    DateTime? lastManualSyncTime,
    SyncResult? syncResult,
    String? errorMessage,
  }) {
    return SyncStatusInfo(
      status: status ?? this.status,
      lastManualSyncTime: lastManualSyncTime ?? this.lastManualSyncTime,
      syncResult: syncResult ?? this.syncResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 同步状态管理
/// 
/// 职责：
/// - 追踪同步状态
/// - 记录上次手动同步时间（只记录手动同步，不记录自动同步）
/// - 记录同步结果统计
/// - 记录错误信息
/// 
/// 调用者：
/// - SettingsPage：显示同步状态和手动同步按钮
/// - 手动同步对话框：显示同步进度和结果
/// 
/// 遵循原则：
/// - 单一职责（SRP）：只负责同步状态管理
/// - 依赖倒置（DIP）：依赖 IStorageService 抽象
/// - Fail Fast：参数验证立即抛出异常
class SyncStatusNotifier extends StateNotifier<SyncStatusInfo> {
  final IStorageService _storage;
  
  static const String _lastManualSyncTimeKey = 'last_manual_sync_time';
  
  /// 构造函数
  /// 
  /// 调用者：syncStatusProvider
  /// 
  /// Fail Fast：
  /// - storage 为 null：由 Dart 类型系统保证
  SyncStatusNotifier(this._storage) : super(SyncStatusInfo(
    status: SyncStatus.idle,
    lastManualSyncTime: _loadLastManualSyncTime(_storage),
  ));
  
  /// 加载上次手动同步时间
  /// 
  /// 调用者：构造函数
  static DateTime? _loadLastManualSyncTime(IStorageService storage) {
    final timeStr = storage.get<String>(_lastManualSyncTimeKey);
    if (timeStr == null) return null;
    
    try {
      return DateTime.parse(timeStr);
    } catch (e) {
      // 解析失败，返回 null
      return null;
    }
  }
  
  /// 开始同步
  /// 
  /// 调用者：手动同步对话框
  void startSync() {
    state = state.copyWith(
      status: SyncStatus.syncing,
      syncResult: null,
      errorMessage: null,
    );
  }
  
  /// 同步成功
  /// 
  /// 调用者：手动同步对话框
  /// 
  /// Fail Fast：
  /// - result 为 null：由 Dart 类型系统保证
  void syncSuccess(SyncResult result) {
    final now = DateTime.now();
    _storage.set(_lastManualSyncTimeKey, now.toIso8601String());
    
    state = SyncStatusInfo(
      status: SyncStatus.success,
      lastManualSyncTime: now,
      syncResult: result,
      errorMessage: null,
    );
    
    // 3 秒后自动切换回空闲状态
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && state.status == SyncStatus.success) {
        state = state.copyWith(status: SyncStatus.idle);
      }
    });
  }
  
  /// 同步失败
  /// 
  /// 调用者：手动同步对话框
  /// 
  /// Fail Fast：
  /// - errorMessage 为空：抛出 ArgumentError
  void syncError(String errorMessage) {
    // Fail Fast：参数验证
    if (errorMessage.isEmpty) {
      throw ArgumentError('错误信息不能为空');
    }
    
    state = SyncStatusInfo(
      status: SyncStatus.error,
      lastManualSyncTime: state.lastManualSyncTime,
      syncResult: null,
      errorMessage: errorMessage,
    );
    
    // 5 秒后自动切换回空闲状态
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && state.status == SyncStatus.error) {
        state = state.copyWith(status: SyncStatus.idle);
      }
    });
  }
  
  /// 重置状态
  /// 
  /// 调用者：手动同步对话框关闭时
  void reset() {
    state = SyncStatusInfo(
      status: SyncStatus.idle,
      lastManualSyncTime: state.lastManualSyncTime,
      syncResult: state.syncResult,
      errorMessage: null,
    );
  }
}

/// 同步状态 Provider
/// 
/// 调用者：
/// - SettingsPage：显示同步状态
/// - 手动同步对话框：更新同步状态
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatusInfo>((ref) {
  return SyncStatusNotifier(ref.read(storageServiceProvider));
});

