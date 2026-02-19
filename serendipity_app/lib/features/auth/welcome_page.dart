import 'package:flutter/material.dart';
import '../../core/utils/page_transition_builder.dart';
import 'widgets/auth_button.dart';
import 'login_page.dart';
import 'register_page.dart';

/// 欢迎页
/// 
/// 应用首次启动或用户未登录时显示的页面。
/// 遵循单一职责原则（SRP）和用户体验优先原则。
/// 
/// 调用者：
/// - main.dart：应用启动时，未登录用户显示此页面
/// - AuthProvider：用户登出后跳转到此页面
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Logo 和标题
              _buildHeader(theme),
              
              const SizedBox(height: 48),
              
              // Slogan
              _buildSlogan(theme),
              
              const Spacer(),
              
              // 登录按钮
              AuthButton.primary(
                text: '登录',
                onPressed: () => _navigateToLogin(context),
              ),
              
              const SizedBox(height: 16),
              
              // 注册按钮
              AuthButton.secondary(
                text: '注册',
                onPressed: () => _navigateToRegister(context),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建头部（Logo 和标题）
  /// 
  /// 调用者：build()
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // Logo - 使用文字 Logo（临时方案，等待设计）
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'S',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -2,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // 应用名称
        Text(
          'Serendipity',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 1,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 中文名称
        Text(
          '错过了么',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
  
  /// 构建 Slogan
  /// 
  /// 调用者：build()
  Widget _buildSlogan(ThemeData theme) {
    return Text(
      '有些错过，只能被记住',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        height: 1.5,
      ),
    );
  }
  
  /// 导航到登录页
  /// 
  /// 调用者：登录按钮的 onPressed
  void _navigateToLogin(BuildContext context) {
    // 获取随机动画类型
    final transitionType = PageTransitionBuilder.getRandomType();
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const LoginPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitionBuilder.buildTransition(
            transitionType,
            context,
            animation,
            secondaryAnimation,
            child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  /// 导航到注册页
  /// 
  /// 调用者：注册按钮的 onPressed
  void _navigateToRegister(BuildContext context) {
    // 获取随机动画类型
    final transitionType = PageTransitionBuilder.getRandomType();
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const RegisterPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitionBuilder.buildTransition(
            transitionType,
            context,
            animation,
            secondaryAnimation,
            child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

