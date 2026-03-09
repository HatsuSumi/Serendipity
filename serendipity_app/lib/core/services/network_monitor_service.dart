import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../models/user.dart';
import '../../models/sync_history.dart';
import '../providers/auth_provider.dart';
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
    } else if (isOnline && !_wasOffline) {
      _verifyNetworkConnection(ref);
    }
    
    _wasOffline = !isOnline;
  }
  
  /// 验证网络连接
  Future<void> _verifyNetworkConnection(WidgetRef ref) async {
    Future.microtask(() async {
      try {
        final isServerHealthy = await _checkServerHealth();
        if (isServerHealthy) {
          if (_wasOffline) {
            _onNetworkRestored(ref);
          }
        } else {
          _wasOffline = true;
        }
      } catch (e) {
        // 静默失败
      }
    });
  }
  
  /// 轮询网络状态
  Future<void> _pollNetworkStatus(WidgetRef ref) async {
    try {
      final isServerHealthy = await _checkServerHealth();
      
      if (isServerHealthy && !_lastServerHealthy) {
        _onNetworkRestored(ref);
      } else if (isServerHealthy) {
        // 服务器健康，执行定期同步
        final authState = ref.read(authProvider);
        final user = authState.value;
        
        if (user != null) {
          await _triggerSync(ref, user, SyncSource.polling);
        }
      }
      
      _lastServerHealthy = isServerHealthy;
    } catch (e) {
      _lastServerHealthy = false;
    }
  }
  
  /// 网络恢复时的处理
  Future<void> _onNetworkRestored(WidgetRef ref) async {
    Future.microtask(() async {
      try {
        final isServerHealthy = await _checkServerHealth();
        if (!isServerHealthy) {
          return;
        }
        
        final authState = ref.read(authProvider);
        final user = authState.value;
        
        if (user != null) {
          await _triggerSync(ref, user, SyncSource.networkReconnect);
        }
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
  
  /// 触发同步
  Future<void> _triggerSync(WidgetRef ref, User user, SyncSource source) async {
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncAllData(user, source: source);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('数据同步失败: $e');
        print('错误堆栈: $stackTrace');
      }
      rethrow;
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

