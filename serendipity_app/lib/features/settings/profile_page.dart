import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/membership_provider.dart';
import '../../core/providers/sync_status_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../models/enums.dart';
import '../../models/user.dart';
import '../../core/config/app_config.dart';
import '../about/about_page.dart';
import '../achievement/achievements_page.dart';
import '../check_in/check_in_page.dart';
import '../community/my_posts_page.dart';
import '../membership/membership_page.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../statistics/statistics_page.dart';
import 'dialogs/manual_sync_dialog.dart';
import 'dialogs/sync_info_dialog.dart';
import 'dialogs/sync_history_dialog.dart';
import 'favorites_page.dart';
import 'pages/notification_settings_page.dart';
import 'pages/theme_settings_page.dart';
import 'pages/account_settings_page.dart';
import 'pages/dev_tools_page.dart';

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

/// 个人资料页面（我的页面）
///
/// 仅作为入口聚合页，所有设置均跳转对应子页面。
///
/// 调用者：
/// - MainNavigationPage：底部导航栏的「我的」标签
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final membershipAsync = ref.watch(membershipProvider);
    final membershipInfo = membershipAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          // ── 用户信息卡片 ───────────────────────────────────────
          authState.when(
            data: (user) => user != null
                ? _buildLoggedInUserCard(context, ref, user, membershipInfo)
                : _buildLoggedOutUserCard(context, ref, membershipInfo),
            loading: () => const SizedBox.shrink(),
            error: (_, e) => const SizedBox.shrink(),
          ),

          const Divider(),

          // ── 功能入口 ──────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '功能',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const _ProfileEmojiLeading('✨'),
            title: const Text('每日签到'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CheckInPage()),
            ),
          ),
          ListTile(
            leading: const _ProfileEmojiLeading('🏆'),
            title: const Text('我的成就'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementsPage()),
            ),
          ),
          ListTile(
            leading: const _ProfileEmojiLeading('🌍'),
            title: const Text('我的发布'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => NavigationHelper.pushWithTransition(
              context, ref, const MyPostsPage(),
            ),
          ),
          ListTile(
            leading: const _ProfileEmojiLeading('🔖'),
            title: const Text('我的收藏'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => NavigationHelper.pushWithTransition(
              context, ref, const FavoritesPage(),
            ),
          ),
          ListTile(
            leading: const _ProfileIconLeading(Icons.bar_chart_outlined),
            title: const Text('统计面板'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => NavigationHelper.pushWithTransition(
              context, ref, const StatisticsPage(),
            ),
          ),

          // 数据同步
          Consumer(
            builder: (context, ref, child) {
              final auth = ref.watch(authProvider);
              final syncStatus = ref.watch(syncStatusProvider);
              return Column(
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
                    subtitle: _buildSyncSubtitle(context, syncStatus),
                    trailing: syncStatus.status == SyncStatus.syncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: syncStatus.status == SyncStatus.syncing
                        ? null
                        : () => _handleManualSync(context, ref, auth),
                  ),
                  ListTile(
                    leading: const _ProfileEmojiLeading('📋'),
                    title: const Text('同步历史'),
                    subtitle: const Text('查看历史同步记录'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => SyncHistoryDialog.show(context),
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // ── 设置入口 ──────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const _ProfileEmojiLeading('🔔'),
            title: const Text('提醒设置'),
            subtitle: const Text('签到提醒、纪念日提醒'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => NavigationHelper.pushWithTransition(
              context, ref, const NotificationSettingsPage(),
            ),
          ),
          ListTile(
            leading: const _ProfileIconLeading(Icons.palette_outlined),
            title: const Text('外观设置'),
            subtitle: const Text('主题、页面动画、对话框动画'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => NavigationHelper.pushWithTransition(
              context, ref, const ThemeSettingsPage(),
            ),
          ),

          const Divider(),

          // ── 关于 ──────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '关于与说明',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.error_outline),
            title: const Text('关于 Serendipity'),
            subtitle: const Text('产品定位、状态说明与记录方式'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => NavigationHelper.pushWithTransition(
              context, ref, const AboutPage(),
            ),
          ),

          // ── 账号管理（已登录） ─────────────────────────────────
          authState.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '账号管理',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('账号管理'),
                    subtitle: const Text('密码、邮箱、手机号、退出登录'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => NavigationHelper.pushWithTransition(
                      context, ref, const AccountSettingsPage(),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, e) => const SizedBox.shrink(),
          ),

          // ── 开发测试（仅开发者模式） ───────────────────────────
          if (AppConfig.isDeveloperMode) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '开发测试',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined,
                  color: Colors.orange),
              title: const Text('开发者工具'),
              subtitle: const Text('重置、测试推送、定位等'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NavigationHelper.pushWithTransition(
                context, ref, const DevToolsPage(),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── 用户信息卡片 ────────────────────────────────────────────

  Widget _buildLoggedInUserCard(
    BuildContext context,
    WidgetRef ref,
    User user,
    MembershipInfo? membershipInfo,
  ) {
    final membershipLabel =
        membershipInfo?.isPremium == true ? '会员有效中' : '免费版';
    final membershipColor = membershipInfo?.isPremium == true
        ? Colors.amber.shade700
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user.displayName?.substring(0, 1).toUpperCase() ??
                    user.email?.substring(0, 1).toUpperCase() ??
                    user.phoneNumber?.substring(
                          user.phoneNumber!.length - 4,
                        ) ??
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
                    user.displayName ??
                        user.email ??
                        user.phoneNumber ??
                        '用户',
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => NavigationHelper.pushWithTransition(
                      context, ref, const MembershipPage(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            size: 16,
                            color: membershipColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            membershipLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: membershipColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: membershipColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutUserCard(
    BuildContext context,
    WidgetRef ref,
    MembershipInfo? membershipInfo,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person_outline,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '未登录',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '登录后可同步数据到云端，也可随时查看会员权益',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => NavigationHelper.pushWithTransition(
                context, ref, const MembershipPage(),
              ),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(
                membershipInfo?.isPremium == true ? '查看会员' : '查看会员权益',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => NavigationHelper.pushWithTransition(
                    context, ref, const LoginPage(),
                  ),
                  child: const Text('登录'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => NavigationHelper.pushWithTransition(
                    context, ref, const RegisterPage(),
                  ),
                  child: const Text('注册'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 同步辅助 ────────────────────────────────────────────────

  Widget? _buildSyncSubtitle(
      BuildContext context, SyncStatusInfo syncStatus) {
    if (syncStatus.status == SyncStatus.syncing) {
      return const Text('同步中...');
    }
    if (syncStatus.status == SyncStatus.success) {
      return Text(
        '同步成功',
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      );
    }
    if (syncStatus.status == SyncStatus.error) {
      return Text(
        '同步失败：${syncStatus.errorMessage}',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (syncStatus.lastManualSyncTime != null) {
      return Text(
        '上次同步：${DateTimeHelper.formatRelativeTime(syncStatus.lastManualSyncTime!)}',
      );
    }
    return const Text('同步本地数据到云端');
  }

  void _handleManualSync(
    BuildContext context,
    WidgetRef ref,
    AsyncValue authState,
  ) {
    authState.when(
      data: (user) {
        if (user == null) {
          MessageHelper.showError(context, '请先登录后再同步数据');
        } else {
          ManualSyncDialog.show(context, ref);
        }
      },
      loading: () => MessageHelper.showError(context, '正在加载用户信息...'),
      error: (_, e) => MessageHelper.showError(context, '获取用户信息失败'),
    );
  }
}
