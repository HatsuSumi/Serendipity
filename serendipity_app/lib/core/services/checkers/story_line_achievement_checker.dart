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
/// - DRY：提取通用的进度检测逻辑
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

    // 检测：第一条故事线（无进度条的成就）
    if (storyLineCount >= 1) {
      final justUnlocked = await _achievementRepository.unlockAchievement('first_story_line');
      if (justUnlocked) {
        unlockedAchievements.add('first_story_line');
      }
    }

    // 检测：故事线数量进度成就（有进度条的成就）
    unlockedAchievements.addAll(
      await _checkProgressAchievements(
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
        final justUnlocked = await _achievementRepository.unlockAchievement('true_love');
        if (justUnlocked) {
          unlockedAchievements.add('true_love');
          break; // 只需要解锁一次
        }
      }
    }

    return unlockedAchievements;
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

