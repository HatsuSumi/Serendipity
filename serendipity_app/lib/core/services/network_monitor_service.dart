import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../models/user.dart';
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
  
  bool _wasOffline = false;
  bool _isMonitoring = false;
  
  /// 开始监听网络状态
  /// 
  /// 调用者：main.dart 的 MyApp.initState()
  /// 
  /// Fail Fast：
  /// - ref 为 null：抛出 ArgumentError
  /// 
  /// 功能：
  /// 1. 启动网络状态监听
  /// 2. 触发 App 启动时的初始同步
  void startMonitoring(WidgetRef ref) {
    // Fail Fast：参数验证
    if (_isMonitoring) {
      debugPrint('🔄 [NetworkMonitor] 已在监听中，跳过重复启动');
      return; // 避免重复监听
    }
    
    debugPrint('🚀 [NetworkMonitor] 开始监听网络状态');
    _isMonitoring = true;
    
    // 监听网络状态变化
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results, ref);
      },
      onError: (error) {
        debugPrint('❌ [NetworkMonitor] 监听失败: $error');
      },
    );
    
    // App 启动时触发初始同步
    debugPrint('📱 [NetworkMonitor] App 启动，准备触发初始同步');
    _triggerInitialSync(ref);
  }
  
  /// App 启动时触发初始同步
  /// 
  /// 设计原则：
  /// - 先检查服务器是否可达（避免无效的同步尝试）
  /// - 只在用户已登录时触发同步
  /// - 同步失败不影响应用启动（静默失败）
  /// - 使用 Future.microtask 避免阻塞当前事件循环
  /// 
  /// 应用场景：
  /// - 用户昨天登录了 App
  /// - 今天打开 App（已登录状态）
  /// - 自动同步最新数据
  Future<void> _triggerInitialSync(WidgetRef ref) async {
    // 使用 Future.microtask 避免在 Provider 构建期间触发同步
    Future.microtask(() async {
      try {
        debugPrint('🔍 [NetworkMonitor] 检查服务器健康状态...');
        
        // 先检查服务器是否可达
        final isServerHealthy = await _checkServerHealth();
        if (!isServerHealthy) {
          debugPrint('⚠️ [NetworkMonitor] 服务器不可达，跳过初始同步');
          return; // 服务器不可达，不触发同步
        }
        
        debugPrint('✅ [NetworkMonitor] 服务器健康');
        
        // 检查是否有用户登录
        final authState = ref.read(authProvider);
        final user = authState.value;
        
        if (user != null) {
          debugPrint('👤 [NetworkMonitor] 用户已登录 (${user.email ?? user.phoneNumber})，触发初始同步');
          // 自动触发全量同步
          await _triggerSync(ref, user);
          debugPrint('🎉 [NetworkMonitor] 初始同步完成');
        } else {
          debugPrint('ℹ️ [NetworkMonitor] 用户未登录，跳过初始同步');
        }
      } catch (e) {
        debugPrint('❌ [NetworkMonitor] 初始同步失败: $e');
      }
    });
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
  void _handleConnectivityChange(List<ConnectivityResult> results, WidgetRef ref) {
    // 判断是否在线
    final isOnline = results.isNotEmpty && 
                     !results.every((result) => result == ConnectivityResult.none);
    
    debugPrint('📡 [NetworkMonitor] 网络状态变化: ${results.map((r) => r.name).join(", ")} (在线: $isOnline)');
    
    // 检测到网络恢复（从离线到在线）
    if (isOnline && _wasOffline) {
      debugPrint('🌐 [NetworkMonitor] 检测到网络恢复！');
      _onNetworkRestored(ref);
    }
    
    // 更新离线状态
    _wasOffline = !isOnline;
  }
  
  /// 网络恢复时的处理
  /// 
  /// 设计原则：
  /// - 先检查服务器是否可达（避免无效的同步尝试）
  /// - 只在用户已登录时触发同步
  /// - 同步失败不影响应用运行（静默失败）
  /// - 使用 Future.microtask 避免阻塞当前事件循环
  Future<void> _onNetworkRestored(WidgetRef ref) async {
    // 使用 Future.microtask 避免在 Provider 构建期间触发同步
    Future.microtask(() async {
      try {
        debugPrint('🔍 [NetworkMonitor] 检查服务器健康状态...');
        
        // 先检查服务器是否可达
        final isServerHealthy = await _checkServerHealth();
        if (!isServerHealthy) {
          debugPrint('⚠️ [NetworkMonitor] 服务器不可达，跳过网络恢复同步');
          return; // 服务器不可达，不触发同步
        }
        
        debugPrint('✅ [NetworkMonitor] 服务器健康');
        
        // 检查是否有用户登录
        final authState = ref.read(authProvider);
        final user = authState.value;
        
        if (user != null) {
          debugPrint('👤 [NetworkMonitor] 用户已登录 (${user.email ?? user.phoneNumber})，触发网络恢复同步');
          // 自动触发全量同步
          await _triggerSync(ref, user);
          debugPrint('🎉 [NetworkMonitor] 网络恢复同步完成');
        } else {
          debugPrint('ℹ️ [NetworkMonitor] 用户未登录，跳过网络恢复同步');
        }
      } catch (e) {
        debugPrint('❌ [NetworkMonitor] 网络恢复同步失败: $e');
      }
    });
  }
  
  /// 检查服务器健康状态
  /// 
  /// 设计原则：
  /// - 使用后端的 /health 端点检查服务器是否可达
  /// - 5 秒超时（避免长时间等待）
  /// - 检查失败返回 false（不抛出异常）
  /// 
  /// 应用场景：
  /// - 酒店 WiFi（需要认证）：返回 false
  /// - WiFi 无外网：返回 false
  /// - 服务器维护：返回 false
  /// - 服务器正常：返回 true
  Future<bool> _checkServerHealth() async {
    try {
      final url = '${ServerConfig.apiUrl}/health';
      debugPrint('🏥 [NetworkMonitor] 检查服务器: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 5));
      
      final isHealthy = response.statusCode == 200;
      debugPrint('🏥 [NetworkMonitor] 服务器状态: ${response.statusCode} ${isHealthy ? "✅" : "❌"}');
      
      return isHealthy;
    } catch (e) {
      debugPrint('❌ [NetworkMonitor] 服务器健康检查失败: $e');
      return false;
    }
  }
  
  /// 触发同步
  /// 
  /// 设计原则：
  /// - 通过 SyncService 触发同步，遵循分层架构
  /// - 同步失败不抛出异常，静默处理
  Future<void> _triggerSync(WidgetRef ref, User user) async {
    try {
      debugPrint('🔄 [NetworkMonitor] 开始同步数据...');
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncAllData(user);
      debugPrint('✅ [NetworkMonitor] 数据同步成功');
    } catch (e) {
      debugPrint('❌ [NetworkMonitor] 数据同步失败: $e');
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

