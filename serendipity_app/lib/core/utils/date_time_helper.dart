/// 日期时间格式化工具类
/// 
/// 提供统一的日期时间格式化方法
class DateTimeHelper {
  DateTimeHelper._(); // 私有构造函数，防止实例化

  /// 格式化为简短日期格式
  /// 
  /// 格式：`2024.01.15`
  /// 
  /// 示例：
  /// ```dart
  /// final date = DateTimeHelper.formatShortDate(DateTime.now());
  /// // 输出: "2024.02.21"
  /// ```
  static String formatShortDate(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// 格式化为完整日期时间格式
  /// 
  /// 格式：`2024-01-15 14:30`
  /// 
  /// 示例：
  /// ```dart
  /// final dateTime = DateTimeHelper.formatDateTime(DateTime.now());
  /// // 输出: "2024-02-21 15:30"
  /// ```
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化为相对时间格式
  /// 
  /// 根据时间差返回不同的格式：
  /// - 今天：`今天 14:30`
  /// - 昨天：`昨天 14:30`
  /// - 2-6天前：`3天前`
  /// - 7天及以上：`01-15`
  /// 
  /// 示例：
  /// ```dart
  /// final now = DateTime.now();
  /// final today = DateTimeHelper.formatRelativeTime(now);
  /// // 输出: "今天 15:30"
  /// 
  /// final yesterday = now.subtract(Duration(days: 1));
  /// final yesterdayText = DateTimeHelper.formatRelativeTime(yesterday);
  /// // 输出: "昨天 15:30"
  /// 
  /// final threeDaysAgo = now.subtract(Duration(days: 3));
  /// final threeDaysText = DateTimeHelper.formatRelativeTime(threeDaysAgo);
  /// // 输出: "3天前"
  /// ```
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    
    // 比较日期（忽略时间部分）
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDifference = today.difference(targetDate).inDays;

    // 今天：显示"今天 HH:mm"
    if (daysDifference == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } 
    // 昨天：显示"昨天 HH:mm"
    else if (daysDifference == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } 
    // 2-6天前：显示"X天前"
    else if (daysDifference < 7) {
      return '$daysDifference天前';
    } 
    // 7天及以上：显示"MM-DD"
    else {
      return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化为中文日期格式
  /// 
  /// 格式：`2024年1月15日`
  /// 
  /// 示例：
  /// ```dart
  /// final date = DateTimeHelper.formatChineseDate(DateTime.now());
  /// // 输出: "2024年2月22日"
  /// ```
  static String formatChineseDate(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
  }

  /// 格式化为发布时间（用于社区帖子）
  /// 
  /// 根据时间差返回不同的格式：
  /// - 1分钟内：`刚刚`
  /// - 1小时内：`X分钟前`
  /// - 今天：`X小时前`
  /// - 昨天：`昨天`
  /// - 2-6天前：`X天前`
  /// - 7天及以上：`MM-DD`
  /// 
  /// 示例：
  /// ```dart
  /// final now = DateTime.now();
  /// 
  /// // 30秒前
  /// final text1 = DateTimeHelper.formatPublishTime(now.subtract(Duration(seconds: 30)));
  /// // 输出: "刚刚"
  /// 
  /// // 5分钟前
  /// final text2 = DateTimeHelper.formatPublishTime(now.subtract(Duration(minutes: 5)));
  /// // 输出: "5分钟前"
  /// 
  /// // 2小时前
  /// final text3 = DateTimeHelper.formatPublishTime(now.subtract(Duration(hours: 2)));
  /// // 输出: "2小时前"
  /// ```
  /// 
  /// 调用者：CommunityPostCard._buildPublishTime()
  static String formatPublishTime(DateTime publishedAt) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    // 1分钟内：刚刚
    if (difference.inMinutes < 1) {
      return '刚刚';
    }

    // 1小时内：X分钟前
    if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    }

    // 今天：X小时前
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(publishedAt.year, publishedAt.month, publishedAt.day);
    if (targetDate == today) {
      return '${difference.inHours}小时前';
    }

    // 昨天：昨天
    final yesterday = today.subtract(const Duration(days: 1));
    if (targetDate == yesterday) {
      return '昨天';
    }

    // 2-6天前：X天前
    if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    }

    // 7天及以上：MM-DD
    return '${publishedAt.month.toString().padLeft(2, '0')}-${publishedAt.day.toString().padLeft(2, '0')}';
  }
}

