import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/achievement_provider.dart';
import '../../../core/providers/auth_provider.dart' show authProvider;
import '../../../core/providers/check_in_provider.dart';
import '../../../core/providers/first_launch_provider.dart';
import '../../../core/providers/membership_provider.dart';
import '../../../core/providers/records_provider.dart' show recordsProvider;
import '../../../core/providers/user_settings_provider.dart'
    show notificationServiceProvider, userSettingsProvider;
import '../../../core/services/notification_service.dart';
import '../../../core/services/push_models.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/services/push_diagnostics_service.dart';
import '../../../core/utils/async_action_helper.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../models/enums.dart';
import '../../home/anniversary_reminder_dialog.dart';
import '../../test/location_test_page.dart';
import '../widgets/push_diagnostics_dialog.dart';
import '../widgets/push_test_result_dialog.dart';

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
            leading: const Icon(Icons.celebration_outlined, color: Colors.pink),
            title: const Text('强制触发纪念日弹窗'),
            subtitle: const Text('使用当前所有"邂逅"记录，绕过年份检查直接展示'),
            onTap: () => _showForceAnniversaryDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.pink,
            ),
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
            leading: const Icon(Icons.alarm_outlined, color: Colors.teal),
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

              _showServerPushTestFeedback(context, result);
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

              _showServerPushTestFeedback(context, result);
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.medical_information_outlined, color: Colors.indigo),
            title: const Text('查看推送诊断'),
            subtitle: const Text('检查权限、平台与当前设备 token 获取状态'),
            onTap: () async {
              final snapshot =
                  await ref.read(pushDiagnosticsServiceProvider).collectDiagnostics();
              if (!context.mounted) return;
              DialogHelper.show<void>(
                context: context,
                builder: (_) => PushDiagnosticsDialog(snapshot: snapshot),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showServerPushTestFeedback(
    BuildContext context,
    ServerPushTestResult result,
  ) {
    switch (result.status) {
      case TestNotificationResult.scheduled:
        MessageHelper.showSuccess(context, result.message);
        break;
      case TestNotificationResult.permissionDenied:
      case TestNotificationResult.schedulingFailed:
        MessageHelper.showError(context, result.message);
        break;
      case TestNotificationResult.unsupportedPlatform:
        MessageHelper.showWarning(context, result.message);
        break;
    }

    DialogHelper.show<void>(
      context: context,
      builder: (_) => PushTestResultDialog(result: result),
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
          '确定要重置所有成就吗？\n\n这将清空所有已解锁的成就和进度，此操作不可恢复。',
        ),
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
          '确定要重置所有签到记录吗？\n\n这将清空所有签到数据，此操作不可恢复。',
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
                  await ref.read(checkInProvider.notifier).resetAllCheckIns();
                },
                successMessage: '所有签到记录已重置',
                errorMessagePrefix: '重置失败',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定重置'),
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
        content: const Text(
          '确定要重置首次启动标记吗？\n\n重置后，下次启动应用将显示欢迎页面。',
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
                  await ref.read(firstLaunchProvider.notifier).reset();
                },
                successMessage: '首次启动标记已重置',
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

  void _showResetMembershipDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置会员状态'),
        content: const Text(
          '确定要重置会员状态吗？\n\n这将清除当前会员数据，恢复为免费版。',
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
                  await ref.read(membershipProvider.notifier).resetMembership();
                },
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

  void _showForceAnniversaryDialog(BuildContext context, WidgetRef ref) {
    final recordsState = ref.read(recordsProvider);
    final metRecords = recordsState.valueOrNull
            ?.where((record) => record.status == EncounterStatus.met)
            .toList() ??
        const [];

    if (metRecords.isEmpty) {
      MessageHelper.showWarning(context, '当前没有可用于触发纪念日弹窗的"邂逅"记录');
      return;
    }

    DialogHelper.show<void>(
      context: context,
      builder: (dialogContext) => AnniversaryReminderDialog(records: metRecords),
    );
  }
}
