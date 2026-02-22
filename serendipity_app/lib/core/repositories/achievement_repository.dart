import '../../models/achievement.dart';
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
  Future<void> unlockAchievement(String id) async {
    assert(id.isNotEmpty, 'Achievement ID cannot be empty');
    
    final achievement = await getAchievement(id);
    if (achievement == null) {
      throw StateError('Achievement $id does not exist');
    }
    
    if (achievement.unlocked) {
      // 已经解锁，不需要重复解锁
      return;
    }
    
    final unlockedAchievement = achievement.copyWith(
      unlocked: true,
      unlockedAt: () => DateTime.now(),
    );
    
    await _storageService.updateAchievement(unlockedAchievement);
  }

  /// 更新成就进度
  Future<void> updateProgress(String id, int progress) async {
    assert(id.isNotEmpty, 'Achievement ID cannot be empty');
    assert(progress >= 0, 'Progress cannot be negative');
    
    final achievement = await getAchievement(id);
    if (achievement == null) {
      throw StateError('Achievement $id does not exist');
    }
    
    if (achievement.unlocked) {
      // 已经解锁，不需要更新进度
      return;
    }
    
    if (!achievement.hasProgress) {
      throw StateError('Achievement $id does not have progress tracking');
    }
    
    final updatedAchievement = achievement.copyWith(
      progress: () => progress,
    );
    
    await _storageService.updateAchievement(updatedAchievement);
    
    // 如果达到目标，自动解锁
    if (progress >= achievement.target!) {
      await unlockAchievement(id);
    }
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
}

