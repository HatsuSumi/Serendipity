import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/encounter_record.dart';
import '../utils/anniversary_helper.dart';
import 'auth_provider.dart';
import 'membership_provider.dart';
import 'records_provider.dart';
import 'user_settings_provider.dart';

/// 今日需要弹窗提醒的纪念日记录列表
///
/// 返回规则：
/// - 用户已登录
/// - 已开启纪念日提醒
/// - 当前为会员
/// - 今天有"邂逅"周年纪念日
/// - 今天尚未弹过窗（通过 SharedPreferences 记录）
///
/// 空列表表示今天不需要弹窗。
///
/// 调用者：
/// - MainNavigationPage：首次进入时读取，非空则展示纪念日弹窗
final anniversaryReminderProvider =
    FutureProvider<List<EncounterRecord>>((ref) async {
  final settings = ref.watch(userSettingsProvider);
  if (!settings.anniversaryReminder) return const [];

  final membershipInfo = ref.watch(membershipProvider).valueOrNull;
  if (membershipInfo == null || !membershipInfo.canUseAnniversaryReminder) {
    return const [];
  }

  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return const [];

  // 今天是否已经弹过窗
  final alreadyShown = await AnniversaryReminderRecord.hasShownToday();
  if (alreadyShown) return const [];

  final records = ref.watch(recordsProvider).valueOrNull ?? const [];
  return AnniversaryHelper.getTodayAnniversaries(records);
});

/// 纪念日弹窗记录工具
///
/// 负责读写「今天是否已弹过纪念日弹窗」的持久化标记。
///
/// 调用者：
/// - anniversaryReminderProvider：判断今天是否需要弹窗
/// - MainNavigationPage：弹窗展示后调用 markShownToday()
class AnniversaryReminderRecord {
  AnniversaryReminderRecord._();

  static const String _key = 'anniversary_reminder_last_shown_date';

  /// 今天是否已弹过纪念日弹窗
  static Future<bool> hasShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_key);
    if (lastShown == null) return false;
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return lastShown == todayKey;
  }

  /// 标记今天已弹过纪念日弹窗
  ///
  /// 调用者：MainNavigationPage（弹窗展示后立即调用）
  static Future<void> markShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await prefs.setString(_key, todayKey);
  }
}

