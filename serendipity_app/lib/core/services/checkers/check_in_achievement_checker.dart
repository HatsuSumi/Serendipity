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
/// - DRY：提取通用的进度检测逻辑
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
  /// 
  /// 使用通用方法检测多个连续签到成就，消除重复代码
  Future<List<String>> _checkConsecutiveAchievements(int consecutiveDays) async {
    return await _checkProgressAchievements(
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
  /// 使用通用方法检测多个累计签到成就，消除重复代码
  Future<List<String>> _checkTotalAchievements(int totalDays) async {
    return await _checkProgressAchievements(
      totalDays,
      [
        'checkin_100_days',
        'checkin_365_days',
      ],
    );
  }

  /// 通用的进度成就检测方法
  /// 
  /// 批量检测多个进度型成就，减少重复代码
  /// 
  /// 参数：
  /// - currentValue: 当前进度值
  /// - achievementIds: 要检测的成就ID列表
  /// 
  /// 返回：新解锁的成就ID列表
  /// 
  /// 设计原则：
  /// - DRY：消除重复的检测逻辑
  /// - 性能优化：updateProgress 内部已处理已解锁判断，无需额外查询
  /// - Fail Fast：依赖 updateProgress 的参数校验
  Future<List<String>> _checkProgressAchievements(
    int currentValue,
    List<String> achievementIds,
  ) async {
    final unlockedAchievements = <String>[];

    for (final achievementId in achievementIds) {
      try {
        // updateProgress 会：
        // 1. 检查成就是否已解锁（已解锁返回 false）
        // 2. 更新进度
        // 3. 如果达到目标，自动解锁并返回 true
        final justUnlocked = await _achievementRepository.updateProgress(
          achievementId,
          currentValue,
        );

        if (justUnlocked) {
          unlockedAchievements.add(achievementId);
        }
      } catch (e) {
        // 成就不存在或其他错误，跳过
        // 生产环境应该记录日志
        continue;
      }
    }

    return unlockedAchievements;
  }
}

