import '../../repositories/achievement_repository.dart';
import '../../repositories/story_line_repository.dart';

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
class StoryLineAchievementChecker {
  final AchievementRepository _achievementRepository;
  final StoryLineRepository _storyLineRepository;

  StoryLineAchievementChecker(
    this._achievementRepository,
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

    // 检测：第一条故事线
    if (storyLineCount == 1) {
      final achievement = await _achievementRepository.getAchievement('first_story_line');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('first_story_line');
        unlockedAchievements.add('first_story_line');
      }
    }

    // 检测：故事收集者（3条故事线）
    if (storyLineCount >= 3) {
      await _achievementRepository.updateProgress('story_collector', storyLineCount);
      final achievement = await _achievementRepository.getAchievement('story_collector');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('story_collector')) {
        unlockedAchievements.add('story_collector');
      }
    } else {
      await _achievementRepository.updateProgress('story_collector', storyLineCount);
    }

    // 检测：故事大师（10条故事线）
    if (storyLineCount >= 10) {
      await _achievementRepository.updateProgress('story_master', storyLineCount);
      final achievement = await _achievementRepository.getAchievement('story_master');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('story_master')) {
        unlockedAchievements.add('story_master');
      }
    } else if (storyLineCount >= 3) {
      await _achievementRepository.updateProgress('story_master', storyLineCount);
    }

    // 检测：真爱无价（同一个人的故事线达到10条记录）
    for (final storyLine in allStoryLines) {
      if (storyLine.recordIds.length >= 10) {
        final achievement = await _achievementRepository.getAchievement('true_love');
        if (achievement != null && !achievement.unlocked) {
          await _achievementRepository.unlockAchievement('true_love');
          unlockedAchievements.add('true_love');
          break;
        }
      }
    }

    return unlockedAchievements;
  }
}

