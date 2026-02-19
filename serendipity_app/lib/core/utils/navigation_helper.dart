import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/message_provider.dart';
import '../../features/home/main_navigation_page.dart';

/// 导航工具类
/// 
/// 提供通用的导航方法，避免跨文件重复代码。
/// 
/// 调用者：
/// - RegisterPage: 注册成功后跳转
/// - LoginPage: 登录成功后跳转
/// 
/// 设计原则：
/// - DRY: 避免跨文件重复代码
/// - 单一职责: 只负责导航相关逻辑
/// - YAGNI: 只实现当前需要的功能
class NavigationHelper {
  /// 跳转到主页并显示成功消息
  /// 
  /// 参数：
  /// - [context]: BuildContext
  /// - [ref]: WidgetRef（用于访问 Provider）
  /// - [message]: 要显示的成功消息
  /// 
  /// 调用者：
  /// - RegisterPage._handleEmailRegister()
  /// - RegisterPage._handlePhoneRegister()
  /// - LoginPage._handleEmailLogin()
  /// - LoginPage._handlePhoneLogin()
  /// 
  /// 工作流程：
  /// 1. 先发送消息到 messageProvider
  /// 2. 跳转到主页
  /// 3. MainNavigationPage 监听到消息并显示
  /// 
  /// Fail Fast：
  /// - message 为空时抛出 ArgumentError
  static void navigateToMainPageWithMessage(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
    // Fail Fast：参数验证
    if (message.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }
    
    // 先发送消息（在导航前）
    ref.read(messageProvider.notifier).showSuccess(message);
    
    // 跳转到主页
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationPage()),
      (route) => false,
    );
  }
}

