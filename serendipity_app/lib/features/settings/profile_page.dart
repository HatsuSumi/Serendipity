import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/membership_provider.dart';
import '../../core/utils/navigation_helper.dart';
import '../about/about_page.dart';
import '../achievement/achievements_page.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../check_in/check_in_page.dart';
import '../community/my_posts_page.dart';
import '../favorites/favorites_page.dart';
import '../membership/membership_page.dart';
import '../statistics/statistics_page.dart';
import 'pages/account_settings_page.dart';
import 'pages/dev_tools_page.dart';
import 'pages/notification_settings_page.dart';
import 'pages/profile_page_actions.dart';
import 'pages/theme_settings_page.dart';
import 'widgets/profile_menu_sections.dart';
import 'widgets/profile_user_card_section.dart';

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
          authState.when(
            data: (user) => ProfileUserCardSection(
              user: user,
              membershipInfo: membershipInfo,
              onMembershipTap: () => NavigationHelper.pushWithTransition(
                context,
                ref,
                const MembershipPage(),
              ),
              onLoginTap: () => NavigationHelper.pushWithTransition(
                context,
                ref,
                const LoginPage(),
              ),
              onRegisterTap: () => NavigationHelper.pushWithTransition(
                context,
                ref,
                const RegisterPage(),
              ),
              onAvatarTap: () => ProfilePageActions.handleAvatarTap(
                context,
                ref,
              ),
              onEditDisplayNameTap: () => ProfilePageActions.handleEditDisplayName(
                context,
                ref,
                user!,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, error) => const SizedBox.shrink(),
          ),
          ProfileMenuSections(
            onCheckInTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const CheckInPage(),
            ),
            onAchievementsTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const AchievementsPage(),
            ),
            onMyPostsTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const MyPostsPage(),
            ),
            onFavoritesTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const FavoritesPage(),
            ),
            onStatisticsTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const StatisticsPage(),
            ),
            onNotificationSettingsTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const NotificationSettingsPage(),
            ),
            onThemeSettingsTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const ThemeSettingsPage(),
            ),
            onAboutTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const AboutPage(),
            ),
            onAccountSettingsTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const AccountSettingsPage(),
            ),
            onDevToolsTap: () => NavigationHelper.pushWithTransition(
              context,
              ref,
              const DevToolsPage(),
            ),
          ),
        ],
      ),
    );
  }
}
