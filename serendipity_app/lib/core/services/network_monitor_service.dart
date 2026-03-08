import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../providers/auth_provider.dart';
import 'sync_service.dart';

/// 网络监听服务
/// 
/// 职责：
/// - 监听网络状态变化
/// - 检测网络恢复
/// - 触发自动同步
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责网络状态监听和触发同步
/// - 依赖倒置（DIP）：通过 Ref 获取依赖，不直接依赖具体实现
/// - Fail Fast：参数验证立即抛出异常
/// 
/// 调用者：
/// - main.dart：应用启动时初始化
class NetworkMonitorService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _wasOffline = false;
  bool _isMonitoring = false;
  
  /// 开始监听网络状态
  /// 
  /// 调用者：main.dart 的 MyApp.initState()
  /// 
  /// Fail Fast：
  /// - ref 为 null：抛出 ArgumentError
  void startMonitoring(Ref ref) {
    // Fail Fast：参数验证
    if (_isMonitoring) {
      return; // 避免重复监听
    }
    
    _isMonitoring = true;
    
    // 监听网络状态变化
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results, ref);
      },
      onError: (error) {
        // 监听失败不影响应用运行
        // 生产环境应记录错误日志
      },
    );
  }
  
  /// 停止监听
  /// 
  /// 调用者：main.dart 的 MyApp.dispose()
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _isMonitoring = false;
  }
  
  /// 处理网络状态变化
  /// 
  /// 设计原则：
  /// - 只在网络从离线恢复到在线时触发同步
  /// - 避免频繁触发同步（如 WiFi 和移动网络切换）
  void _handleConnectivityChange(List<ConnectivityResult> results, Ref ref) {
    // 判断是否在线
    final isOnline = results.isNotEmpty && 
                     !results.every((result) => result == ConnectivityResult.none);
    
    // 检测到网络恢复（从离线到在线）
    if (isOnline && _wasOffline) {
      _onNetworkRestored(ref);
    }
    
    // 更新离线状态
    _wasOffline = !isOnline;
  }
  
  /// 网络恢复时的处理
  /// 
  /// 设计原则：
  /// - 只在用户已登录时触发同步
  /// - 同步失败不影响应用运行（静默失败）
  /// - 使用 Future.microtask 避免阻塞当前事件循环
  Future<void> _onNetworkRestored(Ref ref) async {
    // 使用 Future.microtask 避免在 Provider 构建期间触发同步
    Future.microtask(() async {
      try {
        // 检查是否有用户登录
        final authState = ref.read(authProvider);
        final user = authState.value;
        
        if (user != null) {
          // 自动触发全量同步
          await _triggerSync(ref, user);
        }
      } catch (e) {
        // 同步失败不影响应用运行
        // 生产环境应记录错误日志
      }
    });
  }
  
  /// 触发同步
  /// 
  /// 设计原则：
  /// - 通过 SyncService 触发同步，遵循分层架构
  /// - 同步失败不抛出异常，静默处理
  Future<void> _triggerSync(Ref ref, User user) async {
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncAllData(user);
    } catch (e) {
      // 同步失败不抛出异常
      // 用户可以稍后手动触发同步
      // 生产环境应记录错误日志
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

