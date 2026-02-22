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
  /// 根据连续签到天数返回对应的徽章图标和名称
  /// 
  /// 规则：
  /// - 1-6天：🌱 萌芽
  /// - 7-13天：🌿 成长
  /// - 14-29天：🌳 茁壮
  /// - 30-99天：🔥 火热
  /// - 100天+：💎 钻石
  static CheckInBadge getBadge(int consecutiveDays) {
    if (consecutiveDays >= 100) {
      return const CheckInBadge(icon: '💎', name: '钻石', level: 5);
    } else if (consecutiveDays >= 30) {
      return const CheckInBadge(icon: '🔥', name: '火热', level: 4);
    } else if (consecutiveDays >= 14) {
      return const CheckInBadge(icon: '🌳', name: '茁壮', level: 3);
    } else if (consecutiveDays >= 7) {
      return const CheckInBadge(icon: '🌿', name: '成长', level: 2);
    } else {
      return const CheckInBadge(icon: '🌱', name: '萌芽', level: 1);
    }
  }
}

/// 签到徽章
class CheckInBadge {
  final String icon;
  final String name;
  final int level;

  const CheckInBadge({
    required this.icon,
    required this.name,
    required this.level,
  });
}

