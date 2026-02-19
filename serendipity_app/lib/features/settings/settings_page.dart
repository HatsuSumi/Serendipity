import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/providers/dialog_animation_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/enums.dart';
import '../auth/welcome_page.dart';

/// 设置页面（演示版）
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTransition = ref.watch(pageTransitionProvider);
    final currentDialogAnimation = ref.watch(dialogAnimationProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          authState.when(
            data: (user) {
              if (user != null) {
                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                user.displayName?.substring(0, 1).toUpperCase() ?? 
                                user.email?.substring(0, 1).toUpperCase() ?? 
                                user.phoneNumber?.substring(user.phoneNumber!.length - 4) ?? 
                                '?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ?? user.email ?? user.phoneNumber ?? '用户',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.authProvider == AuthProvider.email 
                                        ? '邮箱登录' 
                                        : '手机号登录',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          const Divider(),
          
          // 页面跳转动画设置
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '页面跳转动画',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...PageTransitionType.values.map((type) {
            final isSelected = currentTransition == type;
            return ListTile(
              leading: Text(
                type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(type.label),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              selected: isSelected,
              onTap: () {
                ref.read(pageTransitionProvider.notifier).state = type;
                MessageHelper.showSuccess(context, '已切换到：${type.label}');
              },
            );
          }),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '💡 提示：点击记录卡片、编辑按钮等跳转到新页面时生效\n（底部导航栏切换不触发动画）',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '对话框动画',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...DialogAnimationType.values.map((type) {
            final isSelected = currentDialogAnimation == type;
            return ListTile(
              leading: Text(
                type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(type.label),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              selected: isSelected,
              onTap: () {
                ref.read(dialogAnimationProvider.notifier).state = type;
                MessageHelper.showSuccess(context, '已切换到：${type.label}');
              },
            );
          }),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '💡 提示：打开任意对话框查看效果',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          
          const Divider(),
          
          // 账号管理
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '账号管理',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              '退出登录',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutDialog(context, ref),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  /// 显示退出登录确认对话框
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              // 关闭对话框
              Navigator.of(context).pop();
              
              try {
                // 执行登出
                await ref.read(authProvider.notifier).signOut();
                
                // 跳转到欢迎页
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomePage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                // 显示错误信息
                if (context.mounted) {
                  MessageHelper.showError(context, '退出登录失败：$e');
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

