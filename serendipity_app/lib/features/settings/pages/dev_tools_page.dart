import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/achievement_provider.dart';
import '../../../core/providers/auth_provider.dart'
    show authProvider, storageServiceProvider;
import '../../../core/providers/check_in_provider.dart';
import '../../../core/providers/first_launch_provider.dart';
import '../../../core/providers/membership_provider.dart';
import '../../../core/providers/user_settings_provider.dart'
    show userSettingsProvider, notificationServiceProvider;
import '../../../core/providers/records_provider.dart'
    show syncCompletedProvider, recordsProvider;
import '../../../core/utils/message_helper.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/async_action_helper.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/enums.dart';
import '../../home/anniversary_reminder_dialog.dart';
import '../../test/location_test_page.dart';
import '../../auth/welcome_page.dart';

/// 开发者工具页面（仅 AppConfig.isDeveloperMode 下可访问）
///
/// 调用者：ProfilePage
class DevToolsPage extends ConsumerWidget {
  const DevToolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('开发测试')),
      body: ListView(
        children: [
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
          ListTile(
            leading: const Icon(
              Icons.notifications_off_outlined,
              color: Colors.blue,
            ),
            title: const Text('重置发布警告对话框'),
            subtitle: const Text('重新显示"发布到社区"警告对话框'),
            onTap: () => _showResetPublishWarningDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text('重置社区介绍对话框'),
            subtitle: const Text('重新显示"欢迎来到树洞"介绍对话框'),
            onTap: () => _showResetCommunityIntroDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_outline, color: Colors.blue),
            title: const Text('重置收藏页介绍对话框'),
            subtitle: const Text('重新显示"关于收藏"介绍对话框'),
            onTap: () => _showResetFavoritesIntroDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('重置所有成就'),
            subtitle: const Text('清空所有已解锁的成就和进度'),
            onTap: () => _showResetAchievementsDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('重置所有签到记录'),
            subtitle: const Text('清空所有签到数据'),
            onTap: () => _showResetCheckInsDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.orange),
            title: const Text('清空同步历史记录'),
            subtitle: const Text('清空所有同步历史数据'),
            onTap: () => _showClearSyncHistoryDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.blue),
            title: const Text('重置首次启动标记'),
            subtitle: const Text('下次启动将显示欢迎页面'),
            onTap: () => _showResetFirstLaunchDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined,
                color: Colors.purple),
            title: const Text('重置会员状态'),
            subtitle: const Text('清除当前会员数据，恢复为免费版'),
            onTap: () => _showResetMembershipDialog(context, ref),
          ),
          ListTile(
            leading:
                const Icon(Icons.celebration_outlined, color: Colors.pink),
            title: const Text('强制触发纪念日弹窗'),
            subtitle: const Text('使用当前所有"邂逅"记录，绕过年份检查直接展示'),
            onTap: () => _showForceAnniversaryDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined,
                color: Colors.pink),
            title: const Text('发送本地纪念日测试通知'),
            subtitle: const Text('5 秒后触发一条本地纪念日通知，验证本地通知是否正常'),
            onTap: () async {
              final result = await ref
                  .read(notificationServiceProvider)
                  .sendTestAnniversaryNotification();
              if (!context.mounted) return;

              switch (result) {
                case TestNotificationResult.scheduled:
                  MessageHelper.showSuccess(context, '本地测试通知已安排，5 秒后将收到通知');
                  break;
                case TestNotificationResult.permissionDenied:
                  MessageHelper.showError(context, '通知权限未授予，无法发送本地测试通知');
                  break;
                case TestNotificationResult.unsupportedPlatform:
                  MessageHelper.showWarning(context, '当前平台不支持本地测试通知');
                  break;
                case TestNotificationResult.schedulingFailed:
                  MessageHelper.showError(context, '本地测试通知调度失败，请检查系统通知权限');
                  break;
              }
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.alarm_outlined, color: Colors.teal),
            title: const Text('发送本地签到提醒测试通知'),
            subtitle: const Text('5 秒后触发一条本地签到提醒通知，验证本地通知是否正常'),
            onTap: () async {
              final userId = ref.read(authProvider).value?.id;
              final result = await ref
                  .read(notificationServiceProvider)
                  .sendTestCheckInNotification(userId: userId);
              if (!context.mounted) return;

              switch (result) {
                case TestNotificationResult.scheduled:
                  MessageHelper.showSuccess(context, '本地测试通知已安排，5 秒后将收到通知');
                  break;
                case TestNotificationResult.permissionDenied:
                  MessageHelper.showError(context, '通知权限未授予，无法发送本地测试通知');
                  break;
                case TestNotificationResult.unsupportedPlatform:
                  MessageHelper.showWarning(context, '当前平台不支持本地测试通知');
                  break;
                case TestNotificationResult.schedulingFailed:
                  MessageHelper.showError(context, '本地测试通知调度失败，请检查系统通知权限');
                  break;
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined, color: Colors.pink),
            title: const Text('发送服务端纪念日测试推送'),
            subtitle: const Text('调用服务端推送链路，立即向当前账号已注册设备发送纪念日测试推送'),
            onTap: () async {
              final userId = ref.read(authProvider).value?.id;
              if (userId == null || userId.isEmpty) {
                MessageHelper.showWarning(context, '请先登录后再测试服务端推送');
                return;
              }

              final result = await ref
                  .read(notificationServiceProvider)
                  .sendServerTestAnniversaryNotification();
              if (!context.mounted) return;

              switch (result) {
                case TestNotificationResult.scheduled:
                  MessageHelper.showSuccess(context, '服务端纪念日测试推送已发送，请检查设备通知');
                  break;
                case TestNotificationResult.permissionDenied:
                  MessageHelper.showError(context, '通知权限未授予，无法发送测试推送');
                  break;
                case TestNotificationResult.unsupportedPlatform:
                  MessageHelper.showWarning(context, '当前环境未配置服务端推送测试能力');
                  break;
                case TestNotificationResult.schedulingFailed:
                  MessageHelper.showError(context, '纪念日测试推送发送失败，请检查 push token 与服务端配置');
                  break;
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined, color: Colors.teal),
            title: const Text('发送服务端签到提醒测试推送'),
            subtitle: const Text('调用服务端推送链路，立即向当前账号已注册设备发送签到提醒测试推送'),
            onTap: () async {
              final userId = ref.read(authProvider).value?.id;
              if (userId == null || userId.isEmpty) {
                MessageHelper.showWarning(context, '请先登录后再测试服务端推送');
                return;
              }

              final result = await ref
                  .read(notificationServiceProvider)
                  .sendServerTestCheckInNotification();
              if (!context.mounted) return;

              switch (result) {
                case TestNotificationResult.scheduled:
                  MessageHelper.showSuccess(context, '服务端签到提醒测试推送已发送，请检查设备通知');
                  break;
                case TestNotificationResult.permissionDenied:
                  MessageHelper.showError(context, '通知权限未授予，无法发送测试推送');
                  break;
                case TestNotificationResult.unsupportedPlatform:
                  MessageHelper.showWarning(context, '当前环境未配置服务端推送测试能力');
                  break;
                case TestNotificationResult.schedulingFailed:
                  MessageHelper.showError(context, '签到提醒测试推送发送失败，请检查 push token 与服务端配置');
                  break;
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showResetPublishWarningDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置发布警告对话框'),
        content: const Text(
          '确定要重置"发布到社区"警告对话框的"不再提示"设置吗？\n\n重置后，下次发布时将重新显示警告对话框和倒计时。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AsyncActionHelper.execute(
                context,
                action: () async {
                  await ref
                      .read(userSettingsProvider.notifier)
                      .resetPublishWarning();
                },
                successMessage: '发布警告对话框已重置',
                errorMessagePrefix: '重置失败',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  void _showResetCommunityIntroDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置社区介绍对话框'),
        content: const Text(
          '确定要重置社区介绍对话框吗？\n\n重置后，下次进入树洞页面时将重新显示"欢迎来到树洞"介绍对话框。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AsyncActionHelper.execute(
                context,
                action: () async {
                  await ref
                      .read(userSettingsProvider.notifier)
                      .markCommunityIntroSeen(false);
                },
                successMessage: '社区介绍对话框已重置',
                errorMessagePrefix: '重置失败',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  void _showResetFavoritesIntroDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置收藏页介绍对话框'),
        content: const Text(
          '确定要重置收藏页介绍对话框吗？\n\n重置后，下次进入收藏页面时将重新显示"关于收藏"介绍对话框。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AsyncActionHelper.execute(
                context,
                action: () async {
                  await ref
                      .read(userSettingsProvider.notifier)
                      .markFavoritesIntroSeen(false);
                },
                successMessage: '收藏页介绍对话框已重置',
                errorMessagePrefix: '重置失败',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  void _showResetAchievementsDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置所有成就'),
        content: const Text(
            '确定要重置所有成就吗？\n\n这将清空所有已解锁的成就和进度，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await AsyncActionHelper.execute(
                context,
                action: () async {
                  await ref
                      .read(achievementsProvider.notifier)
                      .resetAllAchievements();
                },
                successMessage: '所有成就已重置',
                errorMessagePrefix: '重置失败',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  void _showResetCheckInsDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置所有签到记录'),
        content: const Text(
            '确定要重置所有签到记录吗？\n\n这将清空所有签到数据，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await AsyncActionHelper.execute(
                context,
                action: () =>
                    ref.read(checkInProvider.notifier).resetAllCheckIns(),
                successMessage: '所有签到记录已重置',
                errorMessagePrefix: '重置失败',
              );
              if (success) {
                ref.invalidate(checkInProvider);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  void _showClearSyncHistoryDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空同步历史记录'),
        content: const Text('确定要清空所有同步历史记录吗？\n\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await AsyncActionHelper.execute(
                context,
                action: () async {
                  await ref
                      .read(storageServiceProvider)
                      .clearAllSyncHistories();
                },
                successMessage: '同步历史记录已清空',
                errorMessagePrefix: '清空失败',
              );
              if (success) {
                ref.read(syncCompletedProvider.notifier).state++;
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('确定清空'),
          ),
        ],
      ),
    );
  }

  void _showResetFirstLaunchDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置首次启动标记'),
        content: const Text('确定要重置首次启动标记吗？\n\n将立即跳转到欢迎页面。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await AsyncActionHelper.execute(
                context,
                action: () =>
                    ref.read(firstLaunchProvider.notifier).reset(),
                successMessage: '首次启动标记已重置',
                errorMessagePrefix: '重置失败',
              );
              if (success && context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  void _showResetMembershipDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置会员状态'),
        content: const Text(
            '确定要重置会员状态吗？\n\n这将清除当前会员数据，恢复为免费版，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await AsyncActionHelper.execute(
                context,
                action: () =>
                    ref.read(membershipProvider.notifier).resetMembership(),
                successMessage: '会员状态已重置',
                errorMessagePrefix: '重置失败',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  Future<void> _showForceAnniversaryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final records = ref.read(recordsProvider).valueOrNull ?? [];
    final metRecords =
        records.where((r) => r.status == EncounterStatus.met).toList();
    if (metRecords.isEmpty) {
      MessageHelper.showWarning(context, '没有任何"邂逅"记录，请先创建一条邂逅记录');
      return;
    }
    await AnniversaryReminderDialog.show(context, metRecords);
  }
}

