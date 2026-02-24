import '../../repositories/story_line_repository.dart';
import 'base_achievement_checker.dart';

/// 故事线成就检测器
/// 
/// 负责检测与故事线相关的成就：
/// - 第一条故事线
/// - 故事收集者（3条故事线）
/// - 故事大师（10条故事线）
/// - 真爱无价（同一个人的故事线达到10条记录）
/// 
/// 调用者：
/// - AchievementDetector：协调器
/// 
/// 设计原则：
/// - 单一职责：只负责故事线相关成就检测
/// - 依赖注入：通过构造函数注入依赖
/// - DRY：继承基类的通用进度检测逻辑
class StoryLineAchievementChecker extends BaseAchievementChecker {
  final StoryLineRepository _storyLineRepository;

  StoryLineAchievementChecker(
    super.achievementRepository,
    this._storyLineRepository,
  );

  /// 检测故事线相关成就
  /// 
  /// 返回：新解锁的成就ID列表
  Future<List<String>> check() async {
    final unlockedAchievements = <String>[];

    // 获取所有故事线
    final allStoryLines = _storyLineRepository.getAllStoryLines();
    final storyLineCount = allStoryLines.length;

    // 检测：第一条故事线（无进度条的成就）
    if (storyLineCount >= 1) {
      final justUnlocked = await achievementRepository.unlockAchievement('first_story_line');
      if (justUnlocked) {
        unlockedAchievements.add('first_story_line');
      }
    }

    // 检测：故事线数量进度成就（有进度条的成就）
    unlockedAchievements.addAll(
      await checkProgressAchievements(
        storyLineCount,
        [
          'story_collector',
          'story_master',
        ],
      ),
    );

    // 检测：真爱无价（同一个人的故事线达到10条记录）
    for (final storyLine in allStoryLines) {
      if (storyLine.recordIds.length >= 10) {
        final justUnlocked = await achievementRepository.unlockAchievement('true_love');
        if (justUnlocked) {
          unlockedAchievements.add('true_love');
          break; // 只需要解锁一次
        }
      }
    }

    return unlockedAchievements;
  }
}

