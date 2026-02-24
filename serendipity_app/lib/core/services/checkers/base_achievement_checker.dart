import '../../repositories/achievement_repository.dart';

/// 成就检测器基类
/// 
/// 提供通用的进度成就检测方法，供所有具体检测器继承使用
/// 
/// 设计原则：
/// - DRY：消除重复的进度检测逻辑
/// - 单一职责：只负责通用的进度检测
/// - 开闭原则：子类可以扩展，但不需要修改基类
/// 
/// 子类：
/// - RecordAchievementChecker：记录相关成就检测
/// - CheckInAchievementChecker：签到相关成就检测
/// - StoryLineAchievementChecker：故事线相关成就检测
abstract class BaseAchievementChecker {
  final AchievementRepository achievementRepository;

  BaseAchievementChecker(this.achievementRepository);

  /// 通用的进度成就检测方法
  /// 
  /// 批量检测多个进度型成就，减少重复代码
  /// 
  /// 参数：
  /// - [currentValue] 当前进度值
  /// - [achievementIds] 要检测的成就ID列表
  /// 
  /// 返回：新解锁的成就ID列表
  /// 
  /// 设计原则：
  /// - DRY：消除重复的检测逻辑
  /// - 性能优化：updateProgress 内部已处理已解锁判断，无需额外查询
  /// - Fail Fast：依赖 updateProgress 的参数校验
  /// 
  /// 使用示例：
  /// ```dart
  /// final unlockedAchievements = await checkProgressAchievements(
  ///   recordCount,
  ///   ['record_10', 'record_50', 'record_100'],
  /// );
  /// ```
  Future<List<String>> checkProgressAchievements(
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
        final justUnlocked = await achievementRepository.updateProgress(
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

