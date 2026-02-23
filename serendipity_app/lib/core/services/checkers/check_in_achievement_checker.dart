import '../../repositories/achievement_repository.dart';
import '../../repositories/check_in_repository.dart';

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
class CheckInAchievementChecker {
  final AchievementRepository _achievementRepository;
  final CheckInRepository _checkInRepository;

  CheckInAchievementChecker(
    this._achievementRepository,
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
  Future<List<String>> _checkConsecutiveAchievements(int consecutiveDays) async {
    final unlockedAchievements = <String>[];

    // 检测：连续7天签到
    if (consecutiveDays >= 7) {
      await _achievementRepository.updateProgress('streak_7_days', consecutiveDays);
      final achievement = await _achievementRepository.getAchievement('streak_7_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('streak_7_days')) {
        unlockedAchievements.add('streak_7_days');
      }
    } else {
      await _achievementRepository.updateProgress('streak_7_days', consecutiveDays);
    }

    // 检测：连续30天签到
    if (consecutiveDays >= 30) {
      await _achievementRepository.updateProgress('streak_30_days', consecutiveDays);
      final achievement = await _achievementRepository.getAchievement('streak_30_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('streak_30_days')) {
        unlockedAchievements.add('streak_30_days');
      }
    } else if (consecutiveDays >= 7) {
      await _achievementRepository.updateProgress('streak_30_days', consecutiveDays);
    }

    // 检测：连续100天签到
    if (consecutiveDays >= 100) {
      await _achievementRepository.updateProgress('streak_100_days', consecutiveDays);
      final achievement = await _achievementRepository.getAchievement('streak_100_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('streak_100_days')) {
        unlockedAchievements.add('streak_100_days');
      }
    } else if (consecutiveDays >= 30) {
      await _achievementRepository.updateProgress('streak_100_days', consecutiveDays);
    }

    return unlockedAchievements;
  }

  /// 检测累计签到成就
  Future<List<String>> _checkTotalAchievements(int totalDays) async {
    final unlockedAchievements = <String>[];

    // 检测：累计签到100天
    if (totalDays >= 100) {
      await _achievementRepository.updateProgress('checkin_100_days', totalDays);
      final achievement = await _achievementRepository.getAchievement('checkin_100_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('checkin_100_days')) {
        unlockedAchievements.add('checkin_100_days');
      }
    } else {
      await _achievementRepository.updateProgress('checkin_100_days', totalDays);
    }

    // 检测：累计签到365天
    if (totalDays >= 365) {
      await _achievementRepository.updateProgress('checkin_365_days', totalDays);
      final achievement = await _achievementRepository.getAchievement('checkin_365_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('checkin_365_days')) {
        unlockedAchievements.add('checkin_365_days');
      }
    } else if (totalDays >= 100) {
      await _achievementRepository.updateProgress('checkin_365_days', totalDays);
    }

    return unlockedAchievements;
  }
}

