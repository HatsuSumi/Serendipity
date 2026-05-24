import '../../models/check_in_record.dart';
import '../../models/remote_check_in_status.dart';
import '../services/i_storage_service.dart';

class CheckInDateRange {
  final DateTime? startDate;
  final DateTime? endDate;

  const CheckInDateRange({
    required this.startDate,
    required this.endDate,
  });
}

class CheckInStreakSummary {
  final int days;
  final DateTime? startDate;
  final DateTime? endDate;

  const CheckInStreakSummary({
    required this.days,
    required this.startDate,
    required this.endDate,
  });
}

/// 签到仓储
/// 
/// 负责签到数据的持久化和查询
/// 
/// 调用者：
/// - CheckInProvider：状态管理层
/// 
/// 设计原则：
/// - 单一职责：只负责签到数据的存取
/// - Fail Fast：参数校验，立即抛出异常
class CheckInRepository {
  final IStorageService _storageService;

  CheckInRepository(this._storageService);

  /// 保存服务端返回的签到记录到本地缓存
  /// 
  /// 调用者：CheckInProvider.checkIn()
  Future<void> saveRemoteCheckIn(CheckInRecord checkIn) async {
    await _storageService.saveCheckIn(checkIn);
  }

  Future<void> saveRemoteStatusCache({
    required String userId,
    required DateTime month,
    required RemoteCheckInStatus status,
  }) async {
    await _storageService.set(_remoteStatusCacheKey(userId, month), status.toJson());
  }

  RemoteCheckInStatus? getRemoteStatusCache({
    required String userId,
    required DateTime month,
  }) {
    final cached = _storageService.get<Map>(_remoteStatusCacheKey(userId, month));
    if (cached == null) {
      return null;
    }

    return RemoteCheckInStatus.fromJson(Map<String, dynamic>.from(cached));
  }

  /// 签到（创建今天的签到记录）
  /// 
  /// 参数：
  /// - userId: 用户ID（可选，未登录时为 null）
  /// 
  /// 如果今天已经签到，抛出异常
  /// 
  /// 调用者：CheckInProvider.checkIn()
  Future<CheckInRecord> checkIn({String? userId}) async {
    if (hasCheckedInToday(userId: userId)) {
      throw StateError('Already checked in today');
    }

    final checkIn = CheckInRecord.create(userId: userId);
    await _storageService.saveCheckIn(checkIn);

    return checkIn;
  }

  /// 检查今天是否已签到
  bool hasCheckedInToday({String? userId}) {
    final today = _getTodayDate();
    final userCheckIns = _storageService.getCheckInsByUser(userId);
    return userCheckIns.any((c) => _normalizeDate(c.date) == today);
  }

  /// 获取签到记录列表（按日期倒序）
  List<CheckInRecord> getCheckInsSortedByDate({String? userId}) {
    return _storageService.getCheckInsByUser(userId);
  }

  /// 计算连续签到天数
  int calculateConsecutiveDays({String? userId}) {
    final checkIns = _storageService.getCheckInsByUser(userId);
    if (checkIns.isEmpty) return 0;

    final checkInDatesSet = checkIns.map((c) => _normalizeDate(c.date)).toSet();
    final today = _getTodayDate();

    if (!checkInDatesSet.contains(today)) {
      return 0;
    }

    int consecutiveDays = 1;
    DateTime currentDate = today;

    while (true) {
      final previousDate = currentDate.subtract(const Duration(days: 1));
      if (checkInDatesSet.contains(previousDate)) {
        consecutiveDays++;
        currentDate = previousDate;
      } else {
        break;
      }
    }

    return consecutiveDays;
  }

  /// 计算用于提醒文案的连续签到天数
  int calculateReminderStreakDays({String? userId}) {
    final checkIns = _storageService.getCheckInsByUser(userId);
    if (checkIns.isEmpty) return 0;

    final checkInDatesSet = checkIns.map((c) => _normalizeDate(c.date)).toSet();
    final today = _getTodayDate();
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime? streakEndDate;
    if (checkInDatesSet.contains(today)) {
      streakEndDate = today;
    } else if (checkInDatesSet.contains(yesterday)) {
      streakEndDate = yesterday;
    } else {
      return 0;
    }

    int streakDays = 1;
    DateTime currentDate = streakEndDate;
    while (true) {
      final previousDate = currentDate.subtract(const Duration(days: 1));
      if (!checkInDatesSet.contains(previousDate)) {
        break;
      }
      streakDays++;
      currentDate = previousDate;
    }

    return streakDays;
  }

  /// 计算用于提醒文案的最长连续签到天数
  ///
  /// 用于区分“真的断签过”和“尚未形成签到习惯”：
  /// - 返回历史最长连续签到天数
  /// - 无签到记录时返回 0
  int calculateMaxConsecutiveDays({String? userId}) {
    return calculateLongestConsecutiveStreak(userId: userId).days;
  }

  /// 获取累计签到天数
  int getTotalCheckInDays({String? userId}) {
    return _storageService.getCheckInsByUser(userId).length;
  }

  /// 获取本月签到天数
  int getCurrentMonthCheckInDays({String? userId}) {
    final now = DateTime.now();
    final checkIns = _storageService.getCheckInsByUser(userId);

    return checkIns.where((c) {
      final normalizedDate = _normalizeDate(c.date);
      return normalizedDate.year == now.year && normalizedDate.month == now.month;
    }).length;
  }

  /// 获取指定月份的签到日期列表
  List<DateTime> getCheckInDatesInMonth(int year, int month, {String? userId}) {
    final checkIns = _storageService.getCheckInsByUser(userId);

    return checkIns
        .map((c) => _normalizeDate(c.date))
        .where((date) => date.year == year && date.month == month)
        .toList();
  }

  /// 获取累计签到日期范围
  CheckInDateRange getCheckInDateRange({String? userId}) {
    final checkIns = _storageService.getCheckInsByUser(userId);
    if (checkIns.isEmpty) {
      return const CheckInDateRange(startDate: null, endDate: null);
    }

    final sortedDates = checkIns
        .map((record) => _normalizeDate(record.date))
        .toSet()
        .toList()
      ..sort();

    return CheckInDateRange(
      startDate: sortedDates.first,
      endDate: sortedDates.last,
    );
  }

  /// 计算最长连续签到摘要
  CheckInStreakSummary calculateLongestConsecutiveStreak({String? userId}) {
    final checkIns = _storageService.getCheckInsByUser(userId);
    if (checkIns.isEmpty) {
      return const CheckInStreakSummary(
        days: 0,
        startDate: null,
        endDate: null,
      );
    }

    final sortedDates = checkIns
        .map((record) => _normalizeDate(record.date))
        .toSet()
        .toList()
      ..sort();

    var bestStart = sortedDates.first;
    var bestEnd = sortedDates.first;
    var bestDays = 1;

    var currentStart = sortedDates.first;
    var currentEnd = sortedDates.first;
    var currentDays = 1;

    for (var i = 1; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final previousDate = sortedDates[i - 1];
      final isConsecutive = date.difference(previousDate).inDays == 1;

      if (isConsecutive) {
        currentEnd = date;
        currentDays++;
      } else {
        if (currentDays > bestDays) {
          bestStart = currentStart;
          bestEnd = currentEnd;
          bestDays = currentDays;
        }
        currentStart = date;
        currentEnd = date;
        currentDays = 1;
      }
    }

    if (currentDays > bestDays) {
      bestStart = currentStart;
      bestEnd = currentEnd;
      bestDays = currentDays;
    }

    return CheckInStreakSummary(
      days: bestDays,
      startDate: bestStart,
      endDate: bestEnd,
    );
  }

  DateTime _getTodayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _remoteStatusCacheKey(String userId, DateTime month) {
    final normalizedMonth = DateTime(month.year, month.month);
    final monthKey = '${normalizedMonth.year.toString().padLeft(4, '0')}-${normalizedMonth.month.toString().padLeft(2, '0')}';
    return 'remote_check_in_status_${userId}_$monthKey';
  }

  /// 重置所有签到记录（开发者功能）
  Future<void> resetAllCheckIns({String? userId}) async {
    final allCheckIns = _storageService.getCheckInsByUser(userId);
    for (final checkIn in allCheckIns) {
      await _storageService.deleteCheckIn(checkIn.id);
    }
  }
}
