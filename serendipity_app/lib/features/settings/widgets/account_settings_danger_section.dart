import 'package:flutter/material.dart';

class AccountSettingsDangerSection extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const AccountSettingsDangerSection({
    super.key,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            '退出登录',
            style: TextStyle(color: Colors.red),
          ),
          onTap: onLogout,
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text(
            '注销账号',
            style: TextStyle(color: Colors.red),
          ),
          subtitle: const Text('删除账号及所有数据，不可恢复'),
          onTap: onDeleteAccount,
        ),
      ],
    );
  }
}

