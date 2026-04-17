import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/sync_status_provider.dart';
import '../dialogs/sync_history_dialog.dart';
import '../dialogs/sync_info_dialog.dart';
import '../pages/profile_page_actions.dart';

class ProfileMenuSections extends ConsumerWidget {
  final VoidCallback onCheckInTap;
  final VoidCallback onAchievementsTap;
  final VoidCallback onMyPostsTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onStatisticsTap;
  final VoidCallback onNotificationSettingsTap;
  final VoidCallback onThemeSettingsTap;
  final VoidCallback onAboutTap;
  final VoidCallback onAccountSettingsTap;
  final VoidCallback onDevToolsTap;

  const ProfileMenuSections({
    super.key,
    required this.onCheckInTap,
    required this.onAchievementsTap,
    required this.onMyPostsTap,
    required this.onFavoritesTap,
    required this.onStatisticsTap,
    required this.onNotificationSettingsTap,
    required this.onThemeSettingsTap,
    required this.onAboutTap,
    required this.onAccountSettingsTap,
    required this.onDevToolsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Column(
      children: [
        const Divider(),
        const _ProfileSectionHeader('功能'),
        ListTile(
          leading: const _ProfileEmojiLeading('✨'),
          title: const Text('每日签到'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onCheckInTap,
        ),
        ListTile(
          leading: const _ProfileEmojiLeading('🏆'),
          title: const Text('我的成就'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onAchievementsTap,
        ),
        ListTile(
          leading: const _ProfileEmojiLeading('🌍'),
          title: const Text('我的发布'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onMyPostsTap,
        ),
        ListTile(
          leading: const _ProfileEmojiLeading('🔖'),
          title: const Text('我的收藏'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onFavoritesTap,
        ),
        ListTile(
          leading: const _ProfileIconLeading(Icons.bar_chart_outlined),
          title: const Text('统计面板'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onStatisticsTap,
        ),
        Column(
          children: [
            ListTile(
              leading: const _ProfileEmojiLeading('🔄'),
              title: Row(
                children: [
                  const Text('手动同步'),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => SyncInfoDialog.show(context),
                    child: Icon(
                      Icons.help_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              subtitle: ProfilePageActions.buildSyncSubtitle(context, syncStatus),
              trailing: syncStatus.status == SyncStatus.syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: syncStatus.status == SyncStatus.syncing
                  ? null
                  : () => ProfilePageActions.handleManualSync(
                        context,
                        ref,
                        authState,
                      ),
            ),
            ListTile(
              leading: const _ProfileEmojiLeading('📋'),
              title: const Text('同步历史'),
              subtitle: const Text('查看历史同步记录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => SyncHistoryDialog.show(context),
            ),
          ],
        ),
        const Divider(),
        const _ProfileSectionHeader('设置'),
        ListTile(
          leading: const _ProfileEmojiLeading('🔔'),
          title: const Text('提醒设置'),
          subtitle: const Text('签到提醒、纪念日提醒'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onNotificationSettingsTap,
        ),
        ListTile(
          leading: const _ProfileIconLeading(Icons.palette_outlined),
          title: const Text('外观设置'),
          subtitle: const Text('主题、页面动画、对话框动画'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onThemeSettingsTap,
        ),
        const Divider(),
        const _ProfileSectionHeader('关于与说明'),
        ListTile(
          leading: const Icon(Icons.error_outline),
          title: const Text('关于 Serendipity'),
          subtitle: const Text('产品定位、状态说明与记录方式'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onAboutTap,
        ),
        authState.when(
          data: (user) {
            if (user == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const _ProfileSectionHeader('账号管理'),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('账号管理'),
                  subtitle: const Text('密码、邮箱、手机号、退出登录'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onAccountSettingsTap,
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, error) => const SizedBox.shrink(),
        ),
        if (AppConfig.isDeveloperMode) ...[
          const Divider(),
          const _ProfileSectionHeader('开发测试'),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined, color: Colors.orange),
            title: const Text('开发者工具'),
            subtitle: const Text('重置、测试推送、定位等'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onDevToolsTap,
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  final String title;

  const _ProfileSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ProfileEmojiLeading extends StatelessWidget {
  final String emoji;

  const _ProfileEmojiLeading(this.emoji);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22, height: 1),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ProfileIconLeading extends StatelessWidget {
  final IconData icon;

  const _ProfileIconLeading(this.icon);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(child: Icon(icon, size: 22)),
    );
  }
}

