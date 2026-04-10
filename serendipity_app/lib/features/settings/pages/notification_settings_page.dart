import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/membership_provider.dart';
import '../../../core/providers/user_settings_provider.dart';
import '../../../core/utils/message_helper.dart';

/// 提醒设置子页面
///
/// 包含：签到提醒（开关、时间、震动、粒子特效）、纪念日提醒（会员）
///
/// 调用者：ProfilePage
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final authState = ref.watch(authProvider);
    final membershipAsync = ref.watch(membershipProvider);
    final isLoggedIn = authState.valueOrNull != null;
    final canUseCheckInReminder = isLoggedIn;
    final canConfigureCheckInReminder = isLoggedIn && settings.checkInReminderEnabled;

    final canUseAnniversaryReminder = membershipAsync.when(
      data: (info) => isLoggedIn && info.canUseAnniversaryReminder,
      loading: () => false,
      error: (_, e) => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('提醒设置')),
      body: ListView(
        children: [
          // ── 签到提醒 ──────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '签到提醒',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          SwitchListTile(
            title: Row(
              children: [
                const Text('签到提醒'),
                const SizedBox(width: 8),
                if (!canUseCheckInReminder)
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
              ],
            ),
            subtitle: Text(
              canUseCheckInReminder
                  ? '每天提醒你签到'
                  : '登录后可开启签到提醒',
            ),
            value: canUseCheckInReminder && settings.checkInReminderEnabled,
            onChanged: (value) async {
              if (!canUseCheckInReminder) {
                MessageHelper.showWarning(context, '请先登录后再开启签到提醒');
                return;
              }
              await ref
                  .read(userSettingsProvider.notifier)
                  .updateCheckInReminderEnabled(value);
              if (context.mounted) {
                MessageHelper.showSuccess(
                  context,
                  value ? '签到提醒已开启' : '签到提醒已关闭',
                );
              }
            },
          ),

          ListTile(
            title: const Text('提醒时间'),
            subtitle: Text(
              '${settings.checkInReminderTime.hour.toString().padLeft(2, '0')}:${settings.checkInReminderTime.minute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.access_time),
            enabled: canConfigureCheckInReminder,
            onTap: canConfigureCheckInReminder
                ? () => _showTimePickerDialog(
                      context,
                      ref,
                      settings.checkInReminderTime,
                    )
                : null,
          ),

          SwitchListTile(
            title: const Text('签到震动'),
            subtitle: Text(
              isLoggedIn ? '签到时震动反馈' : '登录后可配置签到震动',
            ),
            value: isLoggedIn && settings.checkInVibrationEnabled,
            onChanged: isLoggedIn
                ? (value) async {
                    await ref
                        .read(userSettingsProvider.notifier)
                        .updateCheckInVibrationEnabled(value);
                  }
                : (_) {
                    MessageHelper.showWarning(context, '请先登录后再配置签到提醒');
                  },
          ),

          SwitchListTile(
            title: const Text('签到粒子特效'),
            subtitle: Text(
              isLoggedIn ? '签到时显示彩色粒子' : '登录后可配置签到粒子特效',
            ),
            value: isLoggedIn && settings.checkInConfettiEnabled,
            onChanged: isLoggedIn
                ? (value) async {
                    await ref
                        .read(userSettingsProvider.notifier)
                        .updateCheckInConfettiEnabled(value);
                  }
                : (_) {
                    MessageHelper.showWarning(context, '请先登录后再配置签到提醒');
                  },
          ),

          const Divider(),

          // ── 纪念日提醒 ────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '纪念日提醒',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          SwitchListTile(
            title: Row(
              children: [
                const Text('纪念日提醒'),
                const SizedBox(width: 8),
                if (!canUseAnniversaryReminder)
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
              ],
            ),
            subtitle: Text(
              canUseAnniversaryReminder
                  ? '每次"邂逅"记录的周年纪念日当天提醒'
                  : isLoggedIn
                  ? '会员专属功能，升级后可使用'
                  : '登录后可开启纪念日提醒',
            ),
            value: canUseAnniversaryReminder && settings.anniversaryReminder,
            onChanged: (value) async {
              if (!isLoggedIn) {
                MessageHelper.showWarning(context, '请先登录后再开启纪念日提醒');
                return;
              }
              if (!canUseAnniversaryReminder) {
                MessageHelper.showWarning(context, '纪念日提醒为会员专属功能');
                return;
              }
              await ref
                  .read(userSettingsProvider.notifier)
                  .updateAnniversaryReminder(value);
              if (context.mounted) {
                MessageHelper.showSuccess(
                  context,
                  value ? '纪念日提醒已开启' : '纪念日提醒已关闭',
                );
              }
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showTimePickerDialog(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay currentTime,
  ) {
    showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    ).then((selectedTime) async {
      if (selectedTime != null && selectedTime != currentTime) {
        await ref
            .read(userSettingsProvider.notifier)
            .updateCheckInReminderTime(selectedTime);
        if (context.mounted) {
          MessageHelper.showSuccess(
            context,
            '提醒时间已更新为 ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
          );
        }
      }
    });
  }
}

