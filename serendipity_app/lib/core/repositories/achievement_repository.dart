import '../../models/achievement.dart';
import '../../models/achievement_unlock.dart';
import '../services/i_storage_service.dart';
import '../constants/achievement_definitions.dart';

/// 成就仓储
/// 
/// 负责成就数据的持久化和查询
/// 
/// 调用者：
/// - AchievementProvider：状态管理层
/// 
/// 设计原则：
/// - 单一职责：只负责成就数据的存取
/// - Fail Fast：参数校验，立即抛出异常
class AchievementRepository {
  final IStorageService _storageService;

  AchievementRepository(this._storageService);

  /// 初始化成就列表
  /// 
  /// 如果本地没有成就数据，使用默认定义初始化
  /// 如果本地有数据，合并新增的成就定义
  Future<void> initialize() async {
    final existingAchievements = await getAllAchievements();
    
    // 如果本地没有数据，初始化所有成就
    if (existingAchievements.isEmpty) {
      for (final achievement in AchievementDefinitions.all) {
        await _storageService.saveAchievement(achievement);
      }
      return;
    }
    
    // 如果本地有数据，检查是否有新增的成就定义
    final existingIds = existingAchievements.map((a) => a.id).toSet();
    for (final achievement in AchievementDefinitions.all) {
      if (!existingIds.contains(achievement.id)) {
        // 新增的成就，保存到本地
        await _storageService.saveAchievement(achievement);
      }
    }
  }

  /// 获取所有成就
  Future<List<Achievement>> getAllAchievements() async {
    return _storageService.getAllAchievements();
  }

  /// 获取单个成就
  Future<Achievement?> getAchievement(String id) async {
    assert(id.isNotEmpty, 'Achievement ID cannot be empty');
    return _storageService.getAchievement(id);
  }

  /// 解锁成就
  /// 
  /// 返回值：
  /// - true：刚刚解锁成就
  /// - false：成就已经解锁，无需重复解锁
  Future<bool> unlockAchievement(String id) async {
    assert(id.isNotEmpty, 'Achievement ID cannot be empty');
    
    final achievement = await getAchievement(id);
    if (achievement == null) {
      throw StateError('Achievement $id does not exist');
    }
    
    if (achievement.unlocked) {
      // 已经解锁，不需要重复解锁
      return false;
    }
    
    print('!!! 解锁成就: $id (${achievement.name})');
    print('调用栈: ${StackTrace.current}');
    
    final unlockedAchievement = achievement.copyWith(
      unlocked: true,
      unlockedAt: () => DateTime.now(),
    );
    
    await _storageService.updateAchievement(unlockedAchievement);
    return true;
  }

  /// 更新成就进度
  /// 
  /// 自动限制进度不超过目标值，确保数据一致性
  /// 如果达到目标，自动解锁成就
  /// 
  /// 设计原则：
  /// - 减少操作步骤，避免中间状态
  /// - 如果达到目标，直接解锁（包含进度更新）
  /// - 否则只更新进度
  /// 
  /// 返回值：
  /// - true：刚刚解锁成就（进度达到目标）
  /// - false：未解锁（进度未达到目标或已经解锁）
  Future<bool> updateProgress(String id, int progress) async {
    assert(id.isNotEmpty, 'Achievement ID cannot be empty');
    assert(progress >= 0, 'Progress cannot be negative');
    
    final achievement = await getAchievement(id);
    if (achievement == null) {
      throw StateError('Achievement $id does not exist');
    }
    
    if (achievement.unlocked) {
      // 已经解锁，不需要更新进度
      return false;
    }
    
    if (!achievement.hasProgress) {
      throw StateError('Achievement $id does not have progress tracking');
    }
    
    // 限制进度不超过目标值（防止历史数据导致的进度超标）
    final clampedProgress = progress.clamp(0, achievement.target!);
    
    // 如果达到目标，直接解锁（包含进度更新）
    if (clampedProgress >= achievement.target!) {
      final justUnlocked = await unlockAchievement(id);
      return justUnlocked;
    }
    
    // 否则只更新进度
    final updatedAchievement = achievement.copyWith(
      progress: () => clampedProgress,
    );
    
    await _storageService.updateAchievement(updatedAchievement);
    return false;
  }

  /// 获取已解锁的成就数量
  Future<int> getUnlockedCount() async {
    final achievements = await getAllAchievements();
    return achievements.where((a) => a.unlocked).length;
  }

  /// 获取总成就数量
  Future<int> getTotalCount() async {
    return AchievementDefinitions.all.length;
  }

  /// 获取完成度百分比
  Future<double> getCompletionPercentage() async {
    final unlocked = await getUnlockedCount();
    final total = await getTotalCount();
    if (total == 0) return 0.0;
    return (unlocked / total * 100).clamp(0.0, 100.0);
  }

  /// 根据类别获取成就列表
  Future<List<Achievement>> getAchievementsByCategory(AchievementCategory category) async {
    final achievements = await getAllAchievements();
    return achievements.where((a) => a.category == category).toList();
  }

  /// 静默解锁成就（从云端同步时使用）
  /// 
  /// 与 unlockAchievement() 的区别：
  /// - 不返回 true/false，不触发 UI 通知
  /// - 使用云端的解锁时间，而不是当前时间
  /// - 如果成就已解锁，静默跳过（不抛异常）
  /// 
  /// 调用者：
  /// - SyncService.syncAllData()：同步云端成就解锁状态时调用
  /// 
  /// Fail Fast：
  /// - id 为空：断言失败
  /// - 成就不存在：抛出 StateError
  Future<void> silentUnlockAchievement(String id, DateTime unlockedAt) async {
    assert(id.isNotEmpty, 'Achievement ID cannot be empty');
    
    final achievement = await getAchievement(id);
    if (achievement == null) {
      throw StateError('Achievement $id does not exist');
    }
    
    if (achievement.unlocked) {
      // 已经解锁，静默跳过
      return;
    }
    
    final unlockedAchievement = achievement.copyWith(
      unlocked: true,
      unlockedAt: () => unlockedAt,
    );
    
    await _storageService.updateAchievement(unlockedAchievement);
  }

  /// 批量静默解锁成就（从云端同步时使用）
  /// 
  /// 调用者：
  /// - SyncService.syncAllData()：同步云端成就解锁状态时调用
  /// 
  /// Fail Fast：
  /// - unlocks 为空列表：直接返回，不抛异常（允许空列表）
  /// - 单个成就解锁失败：继续处理其他成就，不中断
  Future<void> syncAchievementUnlocks(List<AchievementUnlock> unlocks) async {
    for (final unlock in unlocks) {
      try {
        await silentUnlockAchievement(unlock.achievementId, unlock.unlockedAt);
      } catch (e) {
        // 单个成就解锁失败不影响其他成就
        // 可能的原因：成就定义已删除、数据损坏等
        // 生产环境应记录错误日志
      }
    }
  }

  /// 重置所有成就（开发者功能）
  /// 
  /// 将所有成就重置为未解锁状态，进度清零
  Future<void> resetAllAchievements() async {
    for (final achievement in AchievementDefinitions.all) {
      final resetAchievement = achievement.copyWith(
        unlocked: false,
        unlockedAt: () => null,
        progress: () => 0,
      );
      await _storageService.updateAchievement(resetAchievement);
    }
  }
}

