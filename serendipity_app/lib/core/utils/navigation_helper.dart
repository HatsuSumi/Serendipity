import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/message_provider.dart';
import '../providers/page_transition_provider.dart';
import '../../features/home/main_navigation_page.dart';
import '../../models/enums.dart';
import 'page_transition_builder.dart';

/// 导航工具类
/// 
/// 提供通用的导航方法，避免跨文件重复代码。
/// 
/// 调用者：
/// - RegisterPage: 注册成功后跳转
/// - LoginPage: 登录成功后跳转
/// - StoryLinesPage: 导航到故事线详情
/// - StoryLineDetailPage: 导航到编辑记录
/// - TimelinePage: 导航到记录详情/编辑
/// - RecordDetailPage: 导航到编辑页面
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

  /// 使用自定义过渡动画导航到新页面
  /// 
  /// 参数：
  /// - [context]: BuildContext
  /// - [ref]: WidgetRef（用于访问 pageTransitionProvider）
  /// - [page]: 目标页面 Widget
  /// 
  /// 返回：
  /// - Future<T?>: 页面返回值
  /// 
  /// 调用者：
  /// - StoryLinesPage: 导航到故事线详情
  /// - StoryLineDetailPage: 导航到编辑记录
  /// - TimelinePage: 导航到记录详情/编辑
  /// - RecordDetailPage: 导航到编辑页面
  /// 
  /// 工作流程：
  /// 1. 从 pageTransitionProvider 读取动画类型
  /// 2. 如果是 random，获取具体的随机动画类型
  /// 3. 构建 PageRouteBuilder 并导航
  /// 
  /// 设计原则：
  /// - DRY: 避免重复的动画类型选择和 PageRouteBuilder 构建代码
  /// - 封装变化: 将动画逻辑封装在一个地方
  static Future<T?> pushWithTransition<T>(
    BuildContext context,
    WidgetRef ref,
    Widget page,
  ) {
    // 获取用户设置的页面切换动画类型
    var transitionType = ref.read(pageTransitionProvider);
    
    // 如果是随机动画，获取一个具体的动画类型
    if (transitionType == PageTransitionType.random) {
      transitionType = PageTransitionBuilder.getRandomType();
    }
    
    // 导航到目标页面
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitionBuilder.buildTransition(
            transitionType,
            context,
            animation,
            secondaryAnimation,
            child,
          );
        },
        transitionDuration: transitionType == PageTransitionType.none
            ? Duration.zero
            : const Duration(milliseconds: 300),
      ),
    );
  }
}

