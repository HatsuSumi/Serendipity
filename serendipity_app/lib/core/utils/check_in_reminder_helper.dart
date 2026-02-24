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

  /// 生成智能提醒内容
  /// 
  /// 根据连续签到天数生成不同的提醒内容：
  /// - 接近解锁成就（优先级最高）
  /// - 有连续签到记录（>= 3天）
  /// - 刚开始签到（1-2天）
  /// - 断签后重新开始（0天）
  /// 
  /// [consecutiveDays] 连续签到天数，必须 >= 0
  /// 
  /// 抛出 [ArgumentError] 如果 consecutiveDays < 0
  static String generateContent(int consecutiveDays) {
    // Fail Fast：参数校验
    if (consecutiveDays < 0) {
      throw ArgumentError.value(
        consecutiveDays,
        'consecutiveDays',
        'Consecutive days cannot be negative',
      );
    }

    // 情况1：接近解锁成就（优先级最高）
    if (consecutiveDays == 6) {
      return '再签到 1 天就能解锁"连续7天签到"成就啦！';
    }
    if (consecutiveDays == 29) {
      return '再签到 1 天就能解锁"连续30天签到"成就啦！';
    }
    if (consecutiveDays >= 90 && consecutiveDays < 100) {
      return '再签到 ${100 - consecutiveDays} 天就能解锁"签到大师"成就啦！';
    }

    // 情况2：有连续签到记录
    if (consecutiveDays >= 3) {
      return '已连续签到 $consecutiveDays 天，继续保持！';
    }

    // 情况3：刚开始签到
    if (consecutiveDays > 0) {
      return '养成每日签到的好习惯吧！';
    }

    // 情况4：断签后重新开始
    return '重新开始签到，加油！';
  }
}

