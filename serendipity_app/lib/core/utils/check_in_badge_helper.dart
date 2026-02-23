/// 签到徽章等级枚举
/// 
/// 根据连续签到天数划分为5个等级
enum CheckInBadgeLevel {
  /// 萌芽（1-6天）
  sprout(1, '🌱', '萌芽', 1, 6),
  
  /// 成长（7-13天）
  growing(2, '🌿', '成长', 7, 13),
  
  /// 茁壮（14-29天）
  strong(3, '🌳', '茁壮', 14, 29),
  
  /// 火热（30-99天）
  fire(4, '🔥', '火热', 30, 99),
  
  /// 钻石（100天+）
  diamond(5, '💎', '钻石', 100, 999999);

  final int level;
  final String icon;
  final String name;
  final int minDays;
  final int maxDays;
  
  const CheckInBadgeLevel(
    this.level,
    this.icon,
    this.name,
    this.minDays,
    this.maxDays,
  );
}

/// 签到徽章工具类
/// 
/// 根据连续签到天数返回对应的徽章
/// 
/// 调用者：
/// - CheckInCard：显示徽章
/// - CheckInPage：显示徽章
class CheckInBadgeHelper {
  CheckInBadgeHelper._(); // 私有构造函数，防止实例化

  /// 获取签到徽章
  /// 
  /// 根据连续签到天数返回对应的徽章等级
  /// 
  /// 规则：
  /// - 1-6天：🌱 萌芽
  /// - 7-13天：🌿 成长
  /// - 14-29天：🌳 茁壮
  /// - 30-99天：🔥 火热
  /// - 100天+：💎 钻石
  static CheckInBadgeLevel getBadge(int consecutiveDays) {
    // 从高到低检查，确保返回最高等级
    if (consecutiveDays >= CheckInBadgeLevel.diamond.minDays) {
      return CheckInBadgeLevel.diamond;
    } else if (consecutiveDays >= CheckInBadgeLevel.fire.minDays) {
      return CheckInBadgeLevel.fire;
    } else if (consecutiveDays >= CheckInBadgeLevel.strong.minDays) {
      return CheckInBadgeLevel.strong;
    } else if (consecutiveDays >= CheckInBadgeLevel.growing.minDays) {
      return CheckInBadgeLevel.growing;
    } else {
      return CheckInBadgeLevel.sprout;
    }
  }
}

