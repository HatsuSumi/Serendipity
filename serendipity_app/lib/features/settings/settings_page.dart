import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/providers/dialog_animation_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/phone_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/widgets/countdown_button.dart';
import '../../models/enums.dart';
import '../auth/welcome_page.dart';
import '../auth/widgets/auth_text_field.dart';
import '../test/location_test_page.dart';

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
          // 修改密码（仅邮箱登录用户）
          authState.when(
            data: (user) {
              if (user?.email != null) {
                return ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('修改密码'),
                  onTap: () => _showUpdatePasswordDialog(context, ref),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // 更换邮箱（仅邮箱登录用户）
          authState.when(
            data: (user) {
              if (user?.email != null) {
                return ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('更换邮箱'),
                  subtitle: Text(user!.email!),
                  onTap: () => _showUpdateEmailDialog(context, ref),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // 更换/绑定手机号（所有用户）
          authState.when(
            data: (user) {
              if (user != null) {
                final hasPhone = user.phoneNumber != null;
                return ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(hasPhone ? '更换手机号' : '绑定手机号'),
                  subtitle: hasPhone 
                      ? Text(user.phoneNumber!) 
                      : const Text('未绑定'),
                  onTap: () => _showUpdatePhoneDialog(context, ref, hasPhone),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              '退出登录',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutDialog(context, ref),
          ),
          
          const Divider(),
          
          // 开发测试
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '开发测试',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('GPS 定位测试'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              NavigationHelper.pushWithTransition(
                context,
                ref,
                const LocationTestPage(),
              );
            },
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
              print('🔍 [SettingsPage] 退出按钮被点击');
              
              // 关闭对话框
              print('🔍 [SettingsPage] 关闭对话框');
              Navigator.of(context).pop();
              
              try {
                print('🔍 [SettingsPage] 开始执行 signOut');
                // 执行登出
                await ref.read(authProvider.notifier).signOut();
                
                print('✅ [SettingsPage] signOut 完成，等待 authProvider 自动跳转到欢迎页');
                // 注意：不需要手动跳转，main.dart 的 authProvider 监听器会自动处理
              } catch (e) {
                print('❌ [SettingsPage] signOut 失败: $e');
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
  
  /// 显示修改密码对话框
  void _showUpdatePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool currentPasswordVisible = false;
    bool newPasswordVisible = false;
    bool confirmPasswordVisible = false;
    
    DialogHelper.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('修改密码'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: !currentPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '当前密码',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        currentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          currentPasswordVisible = !currentPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: !newPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '新密码',
                    border: const OutlineInputBorder(),
                    helperText: '至少6位',
                    suffixIcon: IconButton(
                      icon: Icon(
                        newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          newPasswordVisible = !newPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '确认新密码',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          confirmPasswordVisible = !confirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final currentPassword = currentPasswordController.text.trim();
                  final newPassword = newPasswordController.text.trim();
                  final confirmPassword = confirmPasswordController.text.trim();
                  
                  // Fail Fast：验证输入
                  if (currentPassword.isEmpty) {
                    MessageHelper.showError(context, '请输入当前密码');
                    return;
                  }
                  if (newPassword.isEmpty) {
                    MessageHelper.showError(context, '请输入新密码');
                    return;
                  }
                  if (newPassword.length < 6) {
                    MessageHelper.showError(context, '新密码至少需要6位');
                    return;
                  }
                  if (newPassword != confirmPassword) {
                    MessageHelper.showError(context, '两次输入的新密码不一致');
                    return;
                  }
                  if (currentPassword == newPassword) {
                    MessageHelper.showError(context, '新密码不能与当前密码相同');
                    return;
                  }
                  
                  // 先执行操作，成功后再关闭对话框
                  final success = await AsyncActionHelper.execute(
                    context,
                    action: () => ref.read(authProvider.notifier).updatePassword(
                      currentPassword,
                      newPassword,
                    ),
                    successMessage: '密码修改成功',
                    errorMessagePrefix: '修改密码失败',
                  );
                  
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// 显示更换邮箱对话框
  void _showUpdateEmailDialog(BuildContext context, WidgetRef ref) {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    bool passwordVisible = false;
    
    DialogHelper.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('更换邮箱'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '新邮箱',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: '当前密码',
                    border: const OutlineInputBorder(),
                    helperText: '需要验证身份',
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final newEmail = newEmailController.text.trim();
                  final password = passwordController.text.trim();
                  
                  // Fail Fast：验证输入
                  if (newEmail.isEmpty) {
                    MessageHelper.showError(context, '请输入新邮箱');
                    return;
                  }
                  if (password.isEmpty) {
                    MessageHelper.showError(context, '请输入当前密码');
                    return;
                  }
                  
                  // 先执行操作，成功后再关闭对话框
                  final success = await AsyncActionHelper.execute(
                    context,
                    action: () => ref.read(authProvider.notifier).updateEmail(
                      newEmail,
                      password,
                    ),
                    successMessage: '邮箱更换成功',
                    errorMessagePrefix: '更换邮箱失败',
                  );
                  
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// 显示更换/绑定手机号对话框
  void _showUpdatePhoneDialog(BuildContext context, WidgetRef ref, bool hasPhone) {
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    String countryCode = '+86';
    String? verificationId;
    
    DialogHelper.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(hasPhone ? '更换手机号' : '绑定手机号'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthTextField(
                  type: AuthTextFieldType.phone,
                  controller: phoneController,
                  label: hasPhone ? '新手机号' : '手机号',
                  hint: '请输入手机号',
                  countryCode: countryCode,
                  onCountryCodeChanged: (code) {
                    setState(() {
                      countryCode = code;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        type: AuthTextFieldType.verificationCode,
                        controller: codeController,
                        label: '验证码',
                        hint: '请输入6位验证码',
                        maxLength: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CountdownButton(
                      text: '发送验证码',
                      onPressed: () async {
                        final phone = phoneController.text.trim();
                        
                        // Fail Fast：验证输入
                        if (phone.isEmpty) {
                          MessageHelper.showError(context, '请输入手机号');
                          return false;
                        }
                        
                        final fullPhone = PhoneHelper.formatWithCountryCode(countryCode, phone);
                        
                        final result = await AsyncActionHelper.executeWithResult<String>(
                          context,
                          action: () => ref.read(authProvider.notifier).sendPhoneVerificationCode(fullPhone),
                          errorMessagePrefix: '发送验证码失败',
                        );
                        
                        if (result != null) {
                          setState(() {
                            verificationId = result;
                          });
                          if (context.mounted) {
                            MessageHelper.showSuccess(context, '验证码已发送');
                          }
                          return true;
                        }
                        return false;
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final phone = phoneController.text.trim();
                  final code = codeController.text.trim();
                  
                  // Fail Fast：验证输入
                  if (phone.isEmpty) {
                    MessageHelper.showError(context, '请输入手机号');
                    return;
                  }
                  if (code.isEmpty) {
                    MessageHelper.showError(context, '请输入验证码');
                    return;
                  }
                  if (verificationId == null) {
                    MessageHelper.showError(context, '请先发送验证码');
                    return;
                  }
                  
                  final fullPhone = PhoneHelper.formatWithCountryCode(countryCode, phone);
                  
                  // 先执行操作，成功后再关闭对话框
                  final success = await AsyncActionHelper.execute(
                    context,
                    action: () => ref.read(authProvider.notifier).updatePhoneNumber(
                      fullPhone,
                      code,
                      verificationId!,
                    ),
                    successMessage: hasPhone ? '手机号更换成功' : '手机号绑定成功',
                    errorMessagePrefix: hasPhone ? '更换手机号失败' : '绑定手机号失败',
                  );
                  
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }
}

