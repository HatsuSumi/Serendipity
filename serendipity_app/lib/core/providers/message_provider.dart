import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 消息类型
enum MessageType {
  success,
  error,
  info,
}

/// 消息数据
class AppMessage {
  final String message;
  final MessageType type;
  final DateTime timestamp;
  
  AppMessage({
    required this.message,
    required this.type,
  }) : timestamp = DateTime.now();
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppMessage &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          type == other.type &&
          timestamp == other.timestamp;
  
  @override
  int get hashCode => message.hashCode ^ type.hashCode ^ timestamp.hashCode;
}

/// 消息状态管理
/// 
/// 使用 Riverpod 管理全局消息状态，实现页面间解耦通信。
/// 
/// 调用者：
/// - RegisterPage: 发送注册成功消息
/// - LoginPage: 发送登录成功消息
/// - MainNavigationPage: 监听并显示消息
/// 
/// 设计原则：
/// - 单一职责：只负责消息的发送和接收
/// - 依赖倒置：发送者和接收者通过抽象层（Provider）解耦
/// - 开闭原则：添加新的消息类型无需修改现有代码
class MessageNotifier extends StateNotifier<AppMessage?> {
  MessageNotifier() : super(null);
  
  /// 发送成功消息
  /// 
  /// 调用者：
  /// - RegisterPage._handleEmailRegister()
  /// - RegisterPage._handlePhoneRegister()
  /// - LoginPage._handleEmailLogin()
  /// - LoginPage._handlePhoneLogin()
  /// - NavigationHelper.navigateToMainPageWithMessage()
  /// 
  /// Fail Fast：
  /// - message 为空时抛出 ArgumentError
  void showSuccess(String message) {
    // Fail Fast：参数验证
    if (message.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }
    
    state = AppMessage(message: message, type: MessageType.success);
  }
  
  /// 发送错误消息
  /// 
  /// 调用者：
  /// - 各个页面的错误处理逻辑（未来可能使用）
  /// 
  /// Fail Fast：
  /// - message 为空时抛出 ArgumentError
  void showError(String message) {
    // Fail Fast：参数验证
    if (message.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }
    
    state = AppMessage(message: message, type: MessageType.error);
  }
  
  /// 发送信息消息
  /// 
  /// 调用者：
  /// - 各个页面的提示逻辑（未来可能使用）
  /// 
  /// Fail Fast：
  /// - message 为空时抛出 ArgumentError
  void showInfo(String message) {
    // Fail Fast：参数验证
    if (message.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }
    
    state = AppMessage(message: message, type: MessageType.info);
  }
  
  /// 清除消息
  /// 
  /// 调用者：
  /// - MainNavigationPage: 显示消息后清除，避免重复显示
  void clear() {
    state = null;
  }
}

/// 全局消息 Provider
/// 
/// 提供全局消息状态管理，任何页面都可以发送或监听消息。
/// 
/// 使用示例：
/// 
/// 发送消息：
/// ```dart
/// ref.read(messageProvider.notifier).showSuccess('注册成功！');
/// ref.read(messageProvider.notifier).showError('登录失败！');
/// ref.read(messageProvider.notifier).showInfo('提示信息');
/// ```
/// 
/// 监听消息：
/// ```dart
/// ref.listen<AppMessage?>(messageProvider, (previous, next) {
///   if (next != null) {
///     switch (next.type) {
///       case MessageType.success:
///         MessageHelper.showSuccess(context, next.message);
///         break;
///       case MessageType.error:
///         MessageHelper.showError(context, next.message);
///         break;
///       case MessageType.info:
///         MessageHelper.showInfo(context, next.message);
///         break;
///     }
///     Future.microtask(() => ref.read(messageProvider.notifier).clear());
///   }
/// });
/// ```
final messageProvider = StateNotifierProvider<MessageNotifier, AppMessage?>((ref) {
  return MessageNotifier();
});

