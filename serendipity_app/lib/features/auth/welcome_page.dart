import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/navigation_helper.dart';
import 'widgets/auth_button.dart';
import 'login_page.dart';
import 'register_page.dart';

/// 欢迎页
/// 
/// 应用首次启动时显示的页面，提供三个选项：
/// 1. 先离线使用（主按钮）- 直接进入应用，数据仅保存在本地
/// 2. 登录（次要按钮）- 已有账号的用户登录
/// 3. 注册（文字按钮）- 新用户注册
/// 
/// 遵循原则：
/// - 单一职责（SRP）：只负责展示欢迎界面和导航
/// - 用户体验优先：降低注册门槛，允许先试用
/// - 分层约束：UI层不包含业务逻辑
/// 
/// 调用者：
/// - main.dart：应用首次启动时显示此页面
/// - settings_page.dart：用户退出登录后可能跳转到此页面
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              
              // 按钮组
              _buildActionButtons(context, ref, theme),
              
              const SizedBox(height: 16),
              
              // 提示文字
              _buildHintText(theme),
              
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
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责展示 Logo 和标题
  /// - 性能优化：使用 const 构造
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
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
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责展示 Slogan
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
  
  /// 构建操作按钮组
  /// 
  /// 调用者：build()
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责展示按钮组
  /// - 用户体验优先：按钮优先级清晰（主按钮 > 次要按钮 > 文字按钮）
  /// 
  /// 按钮优先级：
  /// 1. 主按钮（FilledButton）：先离线使用 - 鼓励用户先体验
  /// 2. 次要按钮（OutlinedButton）：登录 - 已有账号的用户
  /// 3. 文字按钮（TextButton）：注册 - 新用户
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Column(
      children: [
        // 主按钮：先离线使用
        SizedBox(
          width: double.infinity,
          child: AuthButton.primary(
            text: '先离线使用',
            prefixIcon: Icons.explore,
            onPressed: () async => _navigateToMainPage(context, ref),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 次要按钮：登录
        SizedBox(
          width: double.infinity,
          child: AuthButton.secondary(
            text: '登录',
            prefixIcon: Icons.login,
            onPressed: () => _navigateToLogin(context, ref),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 文字按钮：注册
        TextButton(
          onPressed: () => _navigateToRegister(context, ref),
          child: Text(
            '还没有账号？立即注册',
            style: TextStyle(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
  
  /// 构建提示文字
  /// 
  /// 调用者：build()
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责展示提示文字
  /// - 用户体验优先：清晰说明离线使用和登录的区别
  Widget _buildHintText(ThemeData theme) {
    return Text(
      '离线使用时数据仅保存在本地\n登录后可同步账号数据并支持多设备访问',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }
  
  /// 导航到主页（离线模式）
  /// 
  /// 调用者："先离线使用"按钮的 onPressed
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责导航
  /// - 架构一致性：使用 NavigationHelper 统一导航逻辑
  /// - 用户体验优先：显示友好的欢迎消息
  /// 
  /// 注意：若当前已登录，先执行登出，保证以匿名状态进入主页
  Future<void> _navigateToMainPage(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authProvider).valueOrNull;
    if (user != null) {
      await ref.read(authProvider.notifier).signOut();
    }
    if (!context.mounted) return;
    NavigationHelper.navigateToMainPageWithMessage(
      context,
      ref,
      '欢迎使用 Serendipity！',
    );
  }
  
  /// 导航到登录页
  /// 
  /// 调用者："登录"按钮的 onPressed
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责导航
  /// - 使用 NavigationHelper 保持导航一致性
  void _navigateToLogin(BuildContext context, WidgetRef ref) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      const LoginPage(),
    );
  }
  
  /// 导航到注册页
  /// 
  /// 调用者："注册"按钮的 onPressed
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责导航
  /// - 使用 NavigationHelper 保持导航一致性
  void _navigateToRegister(BuildContext context, WidgetRef ref) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      const RegisterPage(),
    );
  }
}

