/// 节日工具类
/// 
/// 提供节日判断功能
/// 
/// 调用者：
/// - RecordAchievementChecker：检测节日相关成就
/// 
/// 设计原则：
/// - 单一职责：只负责节日判断
/// - 无状态：所有方法都是静态的，不依赖实例状态
class HolidayHelper {
  HolidayHelper._(); // 私有构造函数，防止实例化

  /// 判断是否为节日
  /// 
  /// 支持的节日（仅固定日期）：
  /// - 元旦（1月1日）
  /// - 情人节（2月14日）
  /// - 白色情人节（3月14日）
  /// - 520表白日（5月20日）
  /// - 万圣节（10月31日）
  /// - 双十一（11月11日）
  /// - 平安夜（12月24日）
  /// - 圣诞节（12月25日）
  /// 
  /// 注意：不包含农历节日（春节、七夕、中秋），因为公历日期每年变化
  static bool isHoliday(DateTime date) {
    final month = date.month;
    final day = date.day;

    // 固定日期节日
    if (month == 1 && day == 1) return true; // 元旦
    if (month == 2 && day == 14) return true; // 情人节
    if (month == 3 && day == 14) return true; // 白色情人节
    if (month == 5 && day == 20) return true; // 520表白日
    if (month == 10 && day == 31) return true; // 万圣节
    if (month == 11 && day == 11) return true; // 双十一（光棍节）
    if (month == 12 && day == 24) return true; // 平安夜
    if (month == 12 && day == 25) return true; // 圣诞节

    return false;
  }
}

