import '../../repositories/story_line_repository.dart';
import '../../../models/enums.dart';
import 'base_achievement_checker.dart';

/// 故事线成就检测器
/// 
/// 负责检测与故事线相关的成就：
/// - 第一条故事线
/// - 故事收集者（3条故事线）
/// - 故事大师（10条故事线）
/// - 真爱无价（同一个人的故事线达到10条记录）
/// - 重新开始（从"别离"到"重逢"）
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
  /// 参数：
  /// - userId: 当前用户ID（用于数据隔离）
  /// 
  /// 返回：新解锁的成就ID列表
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  Future<List<String>> check(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    final unlockedAchievements = <String>[];

    // 获取当前用户的故事线（数据隔离）
    final allStoryLines = _storyLineRepository.getStoryLinesByUser(userId);
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
    // 找到记录数最多的故事线
    final maxRecordCount = allStoryLines.isEmpty 
        ? 0 
        : allStoryLines.map((s) => s.recordIds.length).reduce((a, b) => a > b ? a : b);
    
    if (maxRecordCount > 0) {
      final justUnlocked = await achievementRepository.updateProgress(
        'true_love',
        maxRecordCount,
      );
      if (justUnlocked) {
        unlockedAchievements.add('true_love');
      }
    }

    // 检测：重新开始（从"别离"到"重逢"）
    unlockedAchievements.addAll(
      await _checkNewBeginningAchievement(allStoryLines),
    );

    return unlockedAchievements;
  }

  /// 检测"重新开始"成就
  /// 
  /// 检测故事线中是否存在从"别离"到"重逢"的状态转换
  /// 
  /// 遵循原则：
  /// - 单一职责：只检测一个成就
  /// - DRY：复用 Repository 的方法获取记录
  Future<List<String>> _checkNewBeginningAchievement(List storyLines) async {
    final unlockedAchievements = <String>[];

    // 遍历所有故事线
    for (final storyLine in storyLines) {
      // 获取故事线的所有记录（已按时间排序）
      final records = _storyLineRepository.getRecordsInStoryLine(storyLine.id);

      // 检查相邻记录的状态转换
      for (int i = 0; i < records.length - 1; i++) {
        if (records[i].status == EncounterStatus.farewell &&
            records[i + 1].status == EncounterStatus.reunion) {
          final justUnlocked = await achievementRepository.unlockAchievement('new_beginning');
          if (justUnlocked) {
            unlockedAchievements.add('new_beginning');
          }
          return unlockedAchievements; // 只需要解锁一次
        }
      }
    }

    return unlockedAchievements;
  }
}

