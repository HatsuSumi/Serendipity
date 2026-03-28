import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/async_action_helper.dart';
import '../../../core/utils/auth_error_helper.dart';
import '../../../core/utils/phone_helper.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../../core/providers/theme_provider.dart' show appColorSchemeProvider, appTextThemeProvider;

/// 账号管理子页面
///
/// 包含：修改密码、更换邮箱、更换手机号、恢复密钥、退出登录
///
/// 调用者：ProfilePage（仅已登录用户可访问）
class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appColorSchemeProvider);
    ref.watch(appTextThemeProvider);
    final authAsync = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('账号管理')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, e) => const Center(child: Text('加载失败，请返回重试')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('请先登录'));
          }
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('修改密码'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showUpdatePasswordDialog(context, ref),
              ),
              if (user.email != null)
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('更换邮箱'),
                  subtitle: Text(user.email!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showUpdateEmailDialog(context, ref),
                ),
              if (user.phoneNumber != null)
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('更换手机号'),
                  subtitle: Text(user.phoneNumber!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showUpdatePhoneDialog(context, ref),
                ),
              if (user.email != null)
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: const Text('恢复密钥'),
                  subtitle: const Text('用于找回密码'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRecoveryKeyDialog(context, ref),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  '退出登录',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 退出登录 ──────────────────────────────────────────────────

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
              Navigator.of(context).pop();
              try {
                await ref.read(authProvider.notifier).signOut();
              } catch (e) {
                if (context.mounted) {
                  MessageHelper.showError(context, '退出登录失败：$e');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  // ── 修改密码 ──────────────────────────────────────────────────

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
                      icon: Icon(currentPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(() =>
                          currentPasswordVisible = !currentPasswordVisible),
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
                      icon: Icon(newPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                          () => newPasswordVisible = !newPasswordVisible),
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
                      icon: Icon(confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(() =>
                          confirmPasswordVisible = !confirmPasswordVisible),
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
                  final currentPassword =
                      currentPasswordController.text.trim();
                  final newPassword = newPasswordController.text.trim();
                  final confirmPassword =
                      confirmPasswordController.text.trim();

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

                  final success = await AsyncActionHelper.execute(
                    context,
                    action: () => ref
                        .read(authProvider.notifier)
                        .updatePassword(currentPassword, newPassword),
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

  // ── 更换邮箱 ──────────────────────────────────────────────────

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
                    hintText: '请输入新邮箱',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: '当前密码',
                    hintText: '请输入当前密码',
                    border: const OutlineInputBorder(),
                    helperText: '需要验证身份',
                    suffixIcon: IconButton(
                      icon: Icon(passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => passwordVisible = !passwordVisible),
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

                  if (newEmail.isEmpty) {
                    MessageHelper.showError(context, '请输入新邮箱');
                    return;
                  }
                  if (password.isEmpty) {
                    MessageHelper.showError(context, '请输入当前密码');
                    return;
                  }

                  final success = await AsyncActionHelper.execute(
                    context,
                    action: () => ref
                        .read(authProvider.notifier)
                        .updateEmail(newEmail, password),
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

  // ── 更换手机号 ────────────────────────────────────────────────

  void _showUpdatePhoneDialog(BuildContext context, WidgetRef ref) {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String countryCode = '+86';
    bool passwordVisible = false;

    DialogHelper.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('更换手机号'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthTextField(
                  type: AuthTextFieldType.phone,
                  controller: phoneController,
                  label: '新手机号',
                  hint: '请输入新手机号',
                  countryCode: countryCode,
                  onCountryCodeChanged: (code) {
                    setState(() => countryCode = code);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: '当前密码',
                    hintText: '请输入当前密码',
                    border: const OutlineInputBorder(),
                    helperText: '需要验证身份',
                    suffixIcon: IconButton(
                      icon: Icon(passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => passwordVisible = !passwordVisible),
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
                  final phone = phoneController.text.trim();
                  final password = passwordController.text.trim();

                  if (phone.isEmpty) {
                    MessageHelper.showError(context, '请输入新手机号');
                    return;
                  }
                  if (password.isEmpty) {
                    MessageHelper.showError(context, '请输入当前密码');
                    return;
                  }

                  final fullPhone =
                      PhoneHelper.formatWithCountryCode(countryCode, phone);

                  final success = await AsyncActionHelper.execute(
                    context,
                    action: () => ref
                        .read(authProvider.notifier)
                        .updatePhoneNumber(fullPhone, password),
                    successMessage: '手机号更换成功',
                    errorMessagePrefix: '更换手机号失败',
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

  // ── 恢复密钥 ──────────────────────────────────────────────────

  void _showRecoveryKeyDialog(BuildContext context, WidgetRef ref) async {
    String? recoveryKey;
    bool isLoading = true;
    bool isInitialLoad = true;

    try {
      recoveryKey = await ref.read(authProvider.notifier).getRecoveryKey();
      isLoading = false;
      isInitialLoad = false;
    } catch (e) {
      isLoading = false;
      isInitialLoad = false;
      if (context.mounted) {
        MessageHelper.showError(
          context,
          '获取恢复密钥失败：${AuthErrorHelper.extractErrorMessage(e)}',
        );
      }
    }

    if (!context.mounted) return;

    DialogHelper.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('恢复密钥'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('恢复密钥用于在忘记密码时重置密码。',
                    style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                const Text(
                  '⚠️ 请妥善保管，丢失后无法找回！',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading && isInitialLoad) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else if (recoveryKey != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: SelectableText(
                      recoveryKey!,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: recoveryKey!));
                          if (context.mounted) {
                            MessageHelper.showSuccess(context, '已复制到剪贴板');
                          }
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('复制'),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text('尚未设置恢复密钥。',
                      style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text(
                    '点击"生成恢复密钥"按钮生成新的恢复密钥。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
              if (isLoading && !isInitialLoad)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    try {
                      final key = await ref
                          .read(authProvider.notifier)
                          .generateRecoveryKey();
                      setState(() {
                        recoveryKey = key;
                        isLoading = false;
                      });
                      if (context.mounted) {
                        MessageHelper.showSuccess(context, '恢复密钥已生成');
                      }
                    } catch (e) {
                      setState(() => isLoading = false);
                      if (context.mounted) {
                        MessageHelper.showError(
                          context,
                          '生成失败：${AuthErrorHelper.extractErrorMessage(e)}',
                        );
                      }
                    }
                  },
                  child: Text(recoveryKey == null ? '生成恢复密钥' : '重新生成'),
                ),
            ],
          );
        },
      ),
    );
  }
}
