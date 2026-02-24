import '../../repositories/check_in_repository.dart';
import 'base_achievement_checker.dart';

/// 签到成就检测器
/// 
/// 负责检测与签到相关的成就：
/// - 连续签到成就（7天、30天、100天）
/// - 累计签到成就（100天、365天）
/// 
/// 调用者：
/// - AchievementDetector：协调器
/// 
/// 设计原则：
/// - 单一职责：只负责签到相关成就检测
/// - 依赖注入：通过构造函数注入依赖
/// - DRY：继承基类的通用进度检测逻辑
class CheckInAchievementChecker extends BaseAchievementChecker {
  final CheckInRepository _checkInRepository;

  CheckInAchievementChecker(
    super.achievementRepository,
    this._checkInRepository,
  );

  /// 检测签到相关成就
  /// 
  /// 返回：新解锁的成就ID列表
  Future<List<String>> check() async {
    final unlockedAchievements = <String>[];

    // 获取签到统计
    final consecutiveDays = _checkInRepository.calculateConsecutiveDays();
    final totalDays = _checkInRepository.getTotalCheckInDays();

    // 检测连续签到成就
    unlockedAchievements.addAll(
      await _checkConsecutiveAchievements(consecutiveDays),
    );

    // 检测累计签到成就
    unlockedAchievements.addAll(
      await _checkTotalAchievements(totalDays),
    );

    return unlockedAchievements;
  }

  /// 检测连续签到成就
  /// 
  /// 使用基类的通用方法检测多个连续签到成就，消除重复代码
  Future<List<String>> _checkConsecutiveAchievements(int consecutiveDays) async {
    return await checkProgressAchievements(
      consecutiveDays,
      [
        'streak_7_days',
        'streak_30_days',
        'streak_100_days',
      ],
    );
  }

  /// 检测累计签到成就
  /// 
  /// 使用基类的通用方法检测多个累计签到成就，消除重复代码
  Future<List<String>> _checkTotalAchievements(int totalDays) async {
    return await checkProgressAchievements(
      totalDays,
      [
        'checkin_100_days',
        'checkin_365_days',
      ],
    );
  }
}

