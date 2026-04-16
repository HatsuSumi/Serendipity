import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../widgets/account_settings_danger_section.dart';
import '../widgets/account_settings_security_section.dart';
import 'account_settings_actions.dart';

/// 账号管理子页面
///
/// 包含：修改密码、更换邮箱、更换手机号、恢复密钥、退出登录
///
/// 调用者：ProfilePage（仅已登录用户可访问）
class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('账号管理')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, errorStack) => const Center(child: Text('加载失败，请返回重试')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('请先登录'));
          }

          return ListView(
            children: [
              AccountSettingsSecuritySection(
                user: user,
                onUpdatePassword: () =>
                    AccountSettingsActions.showUpdatePasswordDialog(context, ref),
                onUpdateEmail: () =>
                    AccountSettingsActions.showUpdateEmailDialog(context, ref),
                onUpdatePhone: () =>
                    AccountSettingsActions.showUpdatePhoneDialog(context, ref),
                onShowRecoveryKey: () =>
                    AccountSettingsActions.showRecoveryKeyDialog(context, ref),
              ),
              AccountSettingsDangerSection(
                onLogout: () =>
                    AccountSettingsActions.showLogoutDialog(context, ref),
                onDeleteAccount: () =>
                    AccountSettingsActions.showDeleteAccountDialog(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }
}
