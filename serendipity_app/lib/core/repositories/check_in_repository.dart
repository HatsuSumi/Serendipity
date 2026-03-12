import '../../models/check_in_record.dart';
import '../services/i_storage_service.dart';

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

  /// 签到（创建今天的签到记录）
  /// 
  /// 参数：
  /// - userId: 用户ID（可选，未登录时为 null）
  /// 
  /// 如果今天已经签到，抛出异常
  /// 
  /// 调用者：CheckInProvider.checkIn()
  Future<CheckInRecord> checkIn({String? userId}) async {
    // 按用户+日期去重，避免不同用户互相覆盖
    if (hasCheckedInToday(userId: userId)) {
      throw StateError('Already checked in today');
    }
    
    // 创建签到记录（传入 userId）
    final checkIn = CheckInRecord.create(userId: userId);
    await _storageService.saveCheckIn(checkIn);
    
    return checkIn;
  }

  /// 检查今天是否已签到
  /// 
  /// 参数：
  /// - userId: 用户ID（可选，未登录时为 null）
  /// 
  /// 修复：按用户过滤，避免用户 A 签到后用户 B 误判为已签到
  bool hasCheckedInToday({String? userId}) {
    final today = _getTodayDate();
    final userCheckIns = _storageService.getCheckInsByUser(userId);
    return userCheckIns.any((c) => c.date == today);
  }

  /// 获取指定用户的所有签到记录
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  List<CheckInRecord> getAllCheckInsByUser(String? userId) {
    return _storageService.getCheckInsByUser(userId);
  }

  /// 获取签到记录列表（按日期倒序）
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  List<CheckInRecord> getCheckInsSortedByDate({String? userId}) {
    return _storageService.getCheckInsByUser(userId);
  }
  
  /// 获取指定用户的签到记录列表（按日期倒序）
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  /// 
  /// 调用者：CheckInProvider
  List<CheckInRecord> getCheckInsByUser(String? userId) {
    return _storageService.getCheckInsByUser(userId);
  }

  /// 计算连续签到天数
  /// 
  /// 从今天往前推，连续有签到的天数
  /// 如果今天没有签到，返回0
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示离线数据
  /// 
  /// 时间复杂度：O(n)，其中 n 是签到记录总数
  int calculateConsecutiveDays({String? userId}) {
    final checkIns = _storageService.getCheckInsByUser(userId);
    if (checkIns.isEmpty) return 0;

    // 使用 Set 提高查找效率（O(1) vs O(n)）
    final checkInDatesSet = checkIns.map((c) => c.date).toSet();

    final today = _getTodayDate();

    // 如果今天没有签到，返回0
    if (!checkInDatesSet.contains(today)) {
      return 0;
    }

    int consecutiveDays = 1;
    DateTime currentDate = today;

    // 从今天往前推，检查每一天是否签到
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

  /// 获取累计签到天数
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示离线数据
  int getTotalCheckInDays({String? userId}) {
    return _storageService.getCheckInsByUser(userId).length;
  }

  /// 获取本月签到天数
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示离线数据
  int getCurrentMonthCheckInDays({String? userId}) {
    final now = DateTime.now();
    final checkIns = _storageService.getCheckInsByUser(userId);
    
    return checkIns.where((c) {
      return c.date.year == now.year && c.date.month == now.month;
    }).length;
  }

  /// 获取指定月份的签到日期列表
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示离线数据
  List<DateTime> getCheckInDatesInMonth(int year, int month, {String? userId}) {
    final checkIns = _storageService.getCheckInsByUser(userId);
    
    return checkIns
        .where((c) => c.date.year == year && c.date.month == month)
        .map((c) => c.date)
        .toList();
  }

  /// 获取今天的日期（只保留年月日）
  DateTime _getTodayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 重置所有签到记录（开发者功能）
  Future<void> resetAllCheckIns({String? userId}) async {
    final allCheckIns = _storageService.getCheckInsByUser(userId);
    for (final checkIn in allCheckIns) {
      await _storageService.deleteCheckIn(checkIn.id);
    }
  }
}
