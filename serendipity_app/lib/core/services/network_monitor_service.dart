import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../models/user.dart';
import '../../models/sync_history.dart';
import '../providers/auth_provider.dart';
import '../providers/records_provider.dart';
import '../providers/check_in_provider.dart';
import '../config/server_config.dart';
import 'sync_service.dart';

/// 网络监听服务
/// 
/// 职责：
/// - 监听网络状态变化
/// - 检测网络恢复
/// - 触发自动同步
/// - App 启动时触发初始同步
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责网络状态监听和触发同步
/// - 依赖倒置（DIP）：通过 WidgetRef 获取依赖，不直接依赖具体实现
/// - Fail Fast：参数验证立即抛出异常
/// 
/// 调用者：
/// - main.dart：应用启动时初始化
class NetworkMonitorService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pollingTimer;
  
  bool _wasOffline = false;
  bool _isMonitoring = false;
  bool _lastServerHealthy = true;
  
  /// 同步进行中标志，防止并发触发多个 syncAllData
  bool _isSyncing = false;
  
  /// 开始监听网络状态
  /// 
  /// 调用者：main.dart 的 MyApp.initState()
  /// 
  /// 功能：
  /// 1. 启动网络状态监听
  /// 2. 触发 App 启动时的初始同步
  /// 3. 启动轮询（每 10 秒检查一次）
  void startMonitoring(WidgetRef ref) {
    if (_isMonitoring) {
      return; // 避免重复监听
    }
    
    _isMonitoring = true;
    
    // 监听网络状态变化
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results, ref);
      },
    );
    
    // 启动轮询作为备用方案
    _pollingTimer = Timer.periodic(
      Duration(seconds: ServerConfig.networkPollingInterval),
      (_) {
        _pollNetworkStatus(ref);
      },
    );
    
    // App 启动时触发初始同步
    _triggerInitialSync(ref);
  }
  
  /// App 启动时触发初始同步
  Future<void> _triggerInitialSync(WidgetRef ref) async {
    Future.microtask(() async {
      try {
        final isServerHealthy = await _checkServerHealth();
        _lastServerHealthy = isServerHealthy;
        
        if (!isServerHealthy) {
          return;
        }
        
        final user = await ref.read(authProvider.future);
        
        if (user != null) {
          await _triggerSync(ref, user, SyncSource.appStartup);
        }
      } catch (e) {
        _lastServerHealthy = false;
      }
    });
  }
  
  /// 停止监听
  /// 
  /// 调用者：main.dart 的 MyApp.dispose()
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isMonitoring = false;
  }
  
  /// 处理网络状态变化
  void _handleConnectivityChange(List<ConnectivityResult> results, WidgetRef ref) {
    final isOnline = results.isNotEmpty && 
                     !results.every((result) => result == ConnectivityResult.none);
    
    if (isOnline && _wasOffline) {
      _onNetworkRestored(ref);
    }
    
    _wasOffline = !isOnline;
  }
  
  /// 轮询网络状态
  /// 
  /// 调用者：startMonitoring() 的 Timer.periodic
  /// 
  /// 同步策略：
  /// - 只检查服务器健康状态
  /// - 如果从不健康恢复到健康，触发一次同步
  /// - 不在轮询中主动触发同步（避免频繁同步）
  /// 
  /// 注意：完整的数据同步由以下场景触发：
  /// - appStartup：App 启动时
  /// - networkReconnect：网络从离线恢复到在线时
  /// - manual：用户手动同步时
  Future<void> _pollNetworkStatus(WidgetRef ref) async {
    try {
      final isServerHealthy = await _checkServerHealth();
      
      // 只在服务器从不健康恢复到健康时触发同步
      if (isServerHealthy && !_lastServerHealthy) {
        _onNetworkRestored(ref);
      }
      
      _lastServerHealthy = isServerHealthy;
    } catch (e) {
      _lastServerHealthy = false;
    }
  }
  
  /// 网络恢复时的处理
  /// 
  /// 调用者：_handleConnectivityChange() 和 _pollNetworkStatus()
  /// 
  /// 同步策略：使用增量同步，只同步有变化的数据
  Future<void> _onNetworkRestored(WidgetRef ref) async {
    Future.microtask(() async {
      try {
        final isServerHealthy = await _checkServerHealth();
        if (!isServerHealthy) {
          return;
        }
        
        // 使用 whenData 安全处理 AsyncValue，避免在 loading/error 状态时访问 .value
        ref.read(authProvider).whenData((user) {
          if (user != null) {
            _triggerSync(ref, user, SyncSource.networkReconnect);
          }
        });
      } catch (e) {
        // 静默失败
      }
    });
  }
  
  /// 检查服务器健康状态
  Future<bool> _checkServerHealth() async {
    try {
      final url = '${ServerConfig.apiUrl}/health';
      final response = await http.get(
        Uri.parse(url),
      ).timeout(Duration(seconds: ServerConfig.healthCheckTimeout));
      
      return response.statusCode == 200;
    } catch (e) {
      // 捕获所有错误（包括 429 Too Many Requests）
      // 静默失败，避免影响用户体验
      return false;
    }
  }
  
  /// 检查并设置同步标志（原子操作）
  /// 
  /// 设计原则：
  /// - 原子操作：检查和设置在一个方法内完成
  /// - 防止竞态条件：多个并发调用只有一个能成功设置标志
  /// 
  /// 返回：
  /// - true：成功设置标志，调用者应该执行同步
  /// - false：标志已被设置，调用者应该跳过同步
  bool _setSyncingIfNotAlready() {
    if (_isSyncing) return false;
    _isSyncing = true;
    return true;
  }
  
  /// 触发同步（带重试机制和并发保护）
  /// 
  /// 调用者：
  /// - _triggerInitialSync()：App 启动
  /// - _pollNetworkStatus()：定期轮询
  /// - _onNetworkRestored()：网络恢复
  /// 
  /// 同步策略：从 SyncService 读取持久化的上次同步时间
  /// - 首次同步（lastSyncTime == null）：全量同步
  /// - 非首次同步（lastSyncTime != null）：增量同步
  /// 
  /// 重试策略：
  /// - 最多重试 3 次
  /// - 重试延迟：2秒、5秒、10秒
  /// - 只重试网络错误，不重试业务逻辑错误
  /// 
  /// 并发保护：
  /// - 使用原子操作 _setSyncingIfNotAlready() 防止并发
  /// - 多个并发调用只有一个能执行同步
  /// - 其他调用直接返回，不阻塞
  /// 
  /// 注意：
  /// - syncStartTime 由 SyncService.syncAllData 内部持久化
  /// - 自动同步不更新 syncStatusProvider（只给手动同步的 UI 用）
  /// - 同步完成信号通过 syncCompletedProvider 发送，但 Provider 失效时静默忽略
  Future<void> _triggerSync(WidgetRef ref, User user, SyncSource source) async {
    // 并发保护：使用原子操作检查和设置标志
    if (!_setSyncingIfNotAlready()) {
      return; // 已有同步在进行中，直接跳过
    }

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
          final lastSyncTime = await syncService.getLastSyncTime(user.id);

          await syncService.syncAllData(
            user,
            lastSyncTime: lastSyncTime,
            source: source,
          );

          // 同步成功，尝试递增信号通知所有监听 syncCompletedProvider 的 Provider 重建
          // 如果 Provider 已失效，静默忽略（不影响同步结果）
          _notifySyncCompleted(ref);
          return; // 成功，退出重试循环
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
            // 静默失败，不影响用户体验
          }
        }
      }
    } finally {
      // 无论成功/失败/异常，确保标志被重置
      _isSyncing = false;
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

/// 网络监听服务 Provider
/// 
/// 设计原则：
/// - 使用 Provider 而不是 StateNotifier，因为不需要管理状态
/// - 遵循依赖倒置原则（DIP）
final networkMonitorServiceProvider = Provider<NetworkMonitorService>((ref) {
  final service = NetworkMonitorService();
  
  // 当 Provider 被销毁时，停止监听
  ref.onDispose(() {
    service.stopMonitoring();
  });
  
  return service;
});

