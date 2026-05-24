import '../../models/user.dart';
import 'achievement_detector.dart';

/// 成就重算服务
///
/// 职责：
/// - 基于当前本地数据，重新计算所有成就状态
/// - 用于跨设备同步后修正进度型成就
///
/// 设计原则：
/// - 单一职责：只负责重算，不负责 UI、不负责网络
/// - 依赖倒置：只依赖检测器
class AchievementRecalculationService {
  final AchievementDetector _achievementDetector;

  AchievementRecalculationService({
    required AchievementDetector achievementDetector,
  }) : _achievementDetector = achievementDetector;

  /// 基于当前本地数据静默重算成就。
  ///
  /// 返回本次重算中新解锁的成就 ID 列表；
  /// 纯进度更新不会出现在返回值中。
  Future<List<String>> recalculateForUser(User user) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final unlocked = <String>[];

    unlocked.addAll(await _achievementDetector.checkRecordAchievementsForUser(user.id));
    unlocked.addAll(await _achievementDetector.checkCheckInAchievements(user.id));
    unlocked.addAll(await _achievementDetector.checkStoryLineAchievements(user.id));
    unlocked.addAll(await _achievementDetector.checkCommunityAchievements(user.id));

    return unlocked.toSet().toList();
  }
}
