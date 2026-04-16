import 'package:flutter/material.dart';
import '../../../models/user.dart';

class AccountSettingsSecuritySection extends StatelessWidget {
  final User user;
  final VoidCallback onUpdatePassword;
  final VoidCallback onUpdateEmail;
  final VoidCallback onUpdatePhone;
  final VoidCallback onShowRecoveryKey;

  const AccountSettingsSecuritySection({
    super.key,
    required this.user,
    required this.onUpdatePassword,
    required this.onUpdateEmail,
    required this.onUpdatePhone,
    required this.onShowRecoveryKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('修改密码'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onUpdatePassword,
        ),
        if (user.email != null)
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('更换邮箱'),
            subtitle: Text(user.email!),
            trailing: const Icon(Icons.chevron_right),
            onTap: onUpdateEmail,
          ),
        if (user.phoneNumber != null)
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('更换手机号'),
            subtitle: Text(user.phoneNumber!),
            trailing: const Icon(Icons.chevron_right),
            onTap: onUpdatePhone,
          ),
        if (user.email != null)
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('恢复密钥'),
            subtitle: const Text('用于找回密码'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onShowRecoveryKey,
          ),
      ],
    );
  }
}

