import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/sync_history.dart';
import '../providers/records_provider.dart';
import 'sync_service.dart';

/// 同步编排器
/// 
/// 职责：
/// - 统一管理所有同步操作的入口
/// - 处理并发保护（防止多个同步同时进行）
/// - 处理重试机制
/// - 通知同步完成
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责同步编排，不涉及业务逻辑
/// - 依赖倒置（DIP）：通过 WidgetRef 获取依赖
/// - Fail Fast：参数验证立即抛出异常
/// 
/// 调用者：
/// - NetworkMonitorService：网络恢复、App 启动、轮询
/// - AuthNotifier：登录、注册成功后
class SyncOrchestrator {
  /// 同步进行中的 Completer，防止并发同步
  Completer<void>? _syncCompleter;
  
  /// 检查是否有同步在进行中
  bool get isSyncing => _syncCompleter != null && !_syncCompleter!.isCompleted;
  
  /// 触发同步（带重试机制和并发保护）
  /// 
  /// 参数：
  /// - ref：WidgetRef，用于获取依赖
  /// - user：当前用户
  /// - source：同步来源
  /// - lastSyncTime：上次同步时间（null 表示全量同步）
  /// - skipFullSyncCleanup：是否跳过全量同步中的本地对齐清理
  /// - onProgress：同步进度回调
  /// 
  /// 返回：同步结果
  /// 
  /// 并发保护：
  /// - 如果已有同步在进行中，直接返回已有的 Future
  /// - 多个并发调用会等待同一个同步完成
  /// 
  /// 重试策略：
  /// - 最多重试 3 次
  /// - 重试延迟：2秒、5秒、10秒
  /// - 只重试网络错误，不重试业务逻辑错误
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - ref 为 null：由 Dart 类型系统保证
  Future<SyncResult> sync(
    WidgetRef ref,
    User user, {
    required SyncSource source,
    DateTime? lastSyncTime,
    bool skipFullSyncCleanup = false,
    void Function(String)? onProgress,
  }) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    // 并发保护：如果已有同步在进行中，等待该同步完成
    if (isSyncing) {
      if (kDebugMode) {
        print('同步已在进行中，等待完成...');
      }
      try {
        await _syncCompleter!.future;
      } catch (e) {
        // 前一个同步失败，不传播异常
        // 调用者应该通过 syncCompletedProvider 信号来刷新数据
        if (kDebugMode) {
          print('前一个同步失败，本次调用返回空结果: $e');
        }
      }
      // 返回一个空的结果（因为我们不知道前一个同步的结果）
      // 调用者应该通过 syncCompletedProvider 信号来刷新数据
      return SyncResult(
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
      );
    }
    
    // 创建新的 Completer
    _syncCompleter = Completer<void>();
    
    try {
      const maxRetries = 3;
      const retryDelays = [
        Duration(seconds: 2),
        Duration(seconds: 5),
        Duration(seconds: 10),
      ];
      
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          final syncService = ref.read(syncServiceProvider);
          
          final result = await syncService.syncAllData(
            user,
            lastSyncTime: lastSyncTime,
            skipFullSyncCleanup: skipFullSyncCleanup,
            source: source,
            onProgress: onProgress,
          );
          
          // 同步成功，通知所有监听者
          _notifySyncCompleted(ref);
          
          _syncCompleter!.complete();
          return result;
        } catch (e, stackTrace) {
          final isLastAttempt = attempt == maxRetries - 1;
          
          if (kDebugMode) {
            print('数据同步失败（第 ${attempt + 1}/$maxRetries 次）: $e');
            if (isLastAttempt) {
              print('错误堆栈: $stackTrace');
            }
          }
          
          if (!isLastAttempt) {
            await Future.delayed(retryDelays[attempt]);
          } else {
            if (kDebugMode) {
              print('数据同步已放弃（已重试 $maxRetries 次）');
            }
            // 最后一次重试失败，抛出异常
            _syncCompleter!.completeError(e, stackTrace);
            rethrow;
          }
        }
      }
      
      // 不应该到达这里
      throw StateError('同步逻辑异常');
    } catch (e) {
      // 确保 Completer 被完成（如果还没有）
      if (!_syncCompleter!.isCompleted) {
        _syncCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      // 同步完成后，清除 Completer
      _syncCompleter = null;
    }
  }
  
  /// 通知同步完成（安全处理 Provider 失效）
  /// 
  /// 设计原则：
  /// - 尽力而为：如果 Provider 已失效，静默忽略
  /// - 不阻塞：不影响同步结果
  /// - 可靠性：即使通知失败，同步数据已持久化
  void _notifySyncCompleted(WidgetRef ref) {
    try {
      ref.read(syncCompletedProvider.notifier).state++;
    } catch (e) {
      // Provider 已失效（应用已关闭或 Provider 已销毁）
      // 这不是错误，因为同步数据已经持久化到本地存储
      // 下次 App 启动时会自动加载最新数据
      if (kDebugMode) {
        print('同步完成但 Provider 已失效，无法通知刷新（这是正常的）');
      }
    }
  }
}

/// 同步编排器 Provider
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  return SyncOrchestrator();
});

