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
import 'sync_orchestrator.dart';

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
  
  /// 监听器的取消句柄
  ProviderSubscription<AuthCompletedEvent?>? _authCompletedSubscription;
  ProviderSubscription<AsyncValue<User?>>? _authProviderSubscription;
  
  /// 开始监听网络状态
  /// 
  /// 调用者：main.dart 的 MyApp.initState()
  /// 
  /// 功能：
  /// 1. 启动网络状态监听
  /// 2. 监听认证完成信号（登录/注册成功）
  /// 3. 触发 App 启动时的初始同步
  /// 4. 启动轮询（每 10 秒检查一次）
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
    
    // 监听认证完成信号（登录/注册成功）
    // 保存句柄以便后续取消
    _authCompletedSubscription = ref.listen(authCompletedProvider, (prev, next) {
      if (next != null) {
        _onAuthCompleted(ref, next);
      }
    });
    
    // 监听认证状态变化（App 启动时触发初始同步）
    // 保存句柄以便后续取消
    _authProviderSubscription = ref.listen(authProvider, (prev, next) {
      next.whenData((user) {
        if (user != null) {
          _triggerSync(ref, user, SyncSource.appStartup);
        }
      });
    });
    
    // 启动轮询作为备用方案
    _pollingTimer = Timer.periodic(
      Duration(seconds: ServerConfig.networkPollingInterval),
      (_) {
        _pollNetworkStatus(ref);
      },
    );
  }
  
  /// 停止监听
  /// 
  /// 调用者：main.dart 的 MyApp.dispose()
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _authCompletedSubscription?.close();
    _authCompletedSubscription = null;
    _authProviderSubscription?.close();
    _authProviderSubscription = null;
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
  
  /// 认证完成时的处理（登录/注册成功）
  /// 
  /// 调用者：startMonitoring() 的 ref.listen(authCompletedProvider)
  void _onAuthCompleted(WidgetRef ref, AuthCompletedEvent event) {
    _triggerSync(ref, event.user, 
      event.isRegister ? SyncSource.register : SyncSource.login,
      skipDownload: event.isRegister,
    );
  }
  
  /// 触发同步（带重试机制和并发保护）
  /// 
  /// 调用者：
  /// - startMonitoring()：App 启动、认证完成、网络恢复
  /// - _pollNetworkStatus()：定期轮询
  /// 
  /// 设计说明：
  /// - 使用 SyncOrchestrator 统一管理同步
  /// - SyncOrchestrator 处理并发保护和重试
  /// - 这里只负责触发，不负责具体逻辑
  Future<void> _triggerSync(
    WidgetRef ref,
    User user,
    SyncSource source, {
    bool skipDownload = false,
  }) async {
    try {
      final orchestrator = ref.read(syncOrchestratorProvider);
      
      // 获取上次同步时间，失败时使用 null（全量同步）
      DateTime? lastSyncTime;
      if (!skipDownload) {
        try {
          lastSyncTime = await ref.read(syncServiceProvider).getLastSyncTime(user.id);
        } catch (e) {
          // 获取失败，使用 null 进行全量同步
          if (kDebugMode) {
            print('获取上次同步时间失败，使用全量同步: $e');
          }
          lastSyncTime = null;
        }
      }
      
      await orchestrator.sync(
        ref,
        user,
        source: source,
        lastSyncTime: lastSyncTime,
        skipDownload: skipDownload,
      );
    } catch (e) {
      // 同步失败不影响用户体验，但记录日志便于调试
      if (kDebugMode) {
        print('自动同步失败（来源：$source）: $e');
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

