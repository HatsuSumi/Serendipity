import '../../models/encounter_record.dart';
import '../../models/enums.dart';

/// 纪念日工具类
///
/// 负责基于"邂逅"记录计算周年纪念日。
///
/// 调用者：
/// - anniversaryReminderProvider：今日纪念日列表
/// - NotificationService：调度本地通知时获取文案
///
/// 设计原则：
/// - 单一职责：只负责纪念日计算，不涉及通知调度和 UI
/// - 无副作用：纯函数，不修改任何状态
/// - Fail Fast：参数非法立即抛出异常
class AnniversaryHelper {
  AnniversaryHelper._(); // 私有构造函数，防止实例化

  /// 从记录列表中筛选出今天是周年纪念日的"邂逅"记录
  ///
  /// 规则：
  /// - 仅取状态为 EncounterStatus.encountered 的记录
  /// - 基于记录的 timestamp（错过时间）计算周年
  /// - 月日相同即视为周年（不包括当年本身）
  ///
  /// [records] 当前用户的全量记录
  /// [today]   当前日期，默认为 DateTime.now()，测试时可注入
  static List<EncounterRecord> getTodayAnniversaries(
    List<EncounterRecord> records, {
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final todayMonth = now.month;
    final todayDay = now.day;
    final todayYear = now.year;

    return records.where((record) {
      // 只取"邂逅"状态的记录
      if (record.status != EncounterStatus.encountered) return false;

      final ts = record.timestamp;

      // 不包括当年本身（必须是过去的年份）
      if (ts.year >= todayYear) return false;

      // 月日相同即为周年
      return ts.month == todayMonth && ts.day == todayDay;
    }).toList();
  }

  /// 计算某条记录距今的周年数
  ///
  /// [record] 必须是"邂逅"状态的记录
  /// [today]  当前日期，默认为 DateTime.now()
  ///
  /// 抛出 [ArgumentError] 如果记录不是"邂逅"状态
  static int getAnniversaryYears(
    EncounterRecord record, {
    DateTime? today,
  }) {
    if (record.status != EncounterStatus.encountered) {
      throw ArgumentError.value(
        record.status,
        'record.status',
        'Only encountered records have anniversaries',
      );
    }
    final now = today ?? DateTime.now();
    return now.year - record.timestamp.year;
  }

  /// 生成单条纪念日的通知文案
  ///
  /// [record] 必须是"邂逅"状态的记录
  /// [today]  当前日期，默认为 DateTime.now()
  static String generateNotificationBody(
    EncounterRecord record, {
    DateTime? today,
  }) {
    final years = getAnniversaryYears(record, today: today);
    final place = record.location.placeName ??
        record.location.address ??
        record.location.placeType?.label ??
        '某个地方';
    return '${years}年前的今天，你在${place}邂逅了TA';
  }

  /// 纪念日通知标题
  static const String notificationTitle = '今天是一个特别的纪念日 🌸';
}

