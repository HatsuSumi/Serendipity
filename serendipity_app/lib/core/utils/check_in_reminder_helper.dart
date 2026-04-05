/// 签到提醒内容生成工具
/// 
/// 负责根据用户的签到情况生成智能提醒内容
/// 
/// 调用者：
/// - NotificationService：生成通知内容
/// 
/// 设计原则：
/// - 单一职责：只负责生成提醒文本
/// - Fail Fast：参数校验，立即抛出异常
/// - 无副作用：纯函数，不修改任何状态
class CheckInReminderHelper {
  CheckInReminderHelper._(); // 私有构造函数，防止实例化

  /// 固定的通知标题
  static const String title = '别忘了今天的签到哦 🌟';
  static const int _habitFormingStreakDays = 2;

  /// 生成智能提醒内容
  /// 
  /// 根据连续签到与历史最长连续签到天数生成不同的提醒内容：
  /// - 接近解锁成就（优先级最高）
  /// - 有连续签到记录（>= 3天）
  /// - 刚开始签到（1-2天）
  /// - 断签后重新开始（当前 0 天，但历史上形成过习惯）
  /// - 尚未形成签到习惯（当前 0 天，且历史上未形成习惯）
  /// 
  /// [consecutiveDays] 当前用于提醒的连续签到天数，必须 >= 0
  /// [maxConsecutiveDays] 历史最长连续签到天数，必须 >= 0，且必须 >= consecutiveDays
  /// 
  /// 抛出 [ArgumentError] 如果参数不合法
  static String generateContent({
    required int consecutiveDays,
    required int maxConsecutiveDays,
  }) {
    if (consecutiveDays < 0) {
      throw ArgumentError.value(
        consecutiveDays,
        'consecutiveDays',
        'Consecutive days cannot be negative',
      );
    }
    if (maxConsecutiveDays < 0) {
      throw ArgumentError.value(
        maxConsecutiveDays,
        'maxConsecutiveDays',
        'Max consecutive days cannot be negative',
      );
    }
    if (maxConsecutiveDays < consecutiveDays) {
      throw ArgumentError.value(
        maxConsecutiveDays,
        'maxConsecutiveDays',
        'Max consecutive days cannot be less than consecutiveDays',
      );
    }

    if (consecutiveDays == 6) {
      return '再签到 1 天就能解锁"连续7天签到"成就啦！';
    }
    if (consecutiveDays == 29) {
      return '再签到 1 天就能解锁"连续30天签到"成就啦！';
    }
    if (consecutiveDays >= 90 && consecutiveDays < 100) {
      return '再签到 ${100 - consecutiveDays} 天就能解锁"签到大师"成就啦！';
    }

    if (consecutiveDays >= 3) {
      return '已连续签到 $consecutiveDays 天，继续保持！';
    }

    if (consecutiveDays > 0) {
      return '养成每日签到的好习惯吧！';
    }

    if (maxConsecutiveDays >= _habitFormingStreakDays) {
      return '重新开始签到，加油！';
    }

    return '今天也别忘了签到哦～';
  }
}

