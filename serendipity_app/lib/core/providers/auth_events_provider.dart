import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';

/// 认证完成信号（用于触发同步）
/// 
/// 设计说明：
/// - AuthNotifier 登录/注册成功后发送此信号
/// - NetworkMonitorService 监听此信号，触发实际同步
/// - 这样可以保持分层约束：UI 层不直接调用 SyncService
class AuthCompletedEvent {
  final User user;
  final bool isRegister;

  AuthCompletedEvent({
    required this.user,
    required this.isRegister,
  });
}

/// 认证完成事件通知器
/// 
/// 使用 StateNotifierProvider 而不是 StateProvider，原因：
/// - StateNotifier 提供更好的事件语义
/// - 可以在 build 方法中初始化为 null，避免信号丢失
/// - 支持更复杂的状态转换逻辑
class AuthCompletedNotifier extends StateNotifier<AuthCompletedEvent?> {
  AuthCompletedNotifier() : super(null);

  /// 发送认证完成事件
  void emit(AuthCompletedEvent event) {
    state = event;
  }
}

final authCompletedProvider =
    StateNotifierProvider<AuthCompletedNotifier, AuthCompletedEvent?>((ref) {
  return AuthCompletedNotifier();
});

