import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../repositories/achievement_repository.dart';
import '../services/achievement_detector.dart';
import 'records_provider.dart';
import 'check_in_provider.dart';

/// 成就仓储 Provider
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref.read(storageServiceProvider));
});

/// 成就检测服务 Provider
final achievementDetectorProvider = Provider<AchievementDetector>((ref) {
  return AchievementDetector(
    ref.read(achievementRepositoryProvider),
    ref.read(recordRepositoryProvider),
    ref.read(storyLineRepositoryProvider),
    ref.read(checkInRepositoryProvider),
  );
});

/// 成就列表状态管理
class AchievementsNotifier extends AsyncNotifier<List<Achievement>> {
  late AchievementRepository _repository;

  @override
  Future<List<Achievement>> build() async {
    _repository = ref.read(achievementRepositoryProvider);
    
    // 初始化成就列表
    await _repository.initialize();
    
    // 加载所有成就
    return _repository.getAllAchievements();
  }

  /// 刷新成就列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.getAllAchievements();
    });
  }

  /// 解锁成就
  Future<void> unlockAchievement(String id) async {
    await _repository.unlockAchievement(id);
    await refresh();
  }

  /// 更新成就进度
  Future<void> updateProgress(String id, int progress) async {
    await _repository.updateProgress(id, progress);
    await refresh();
  }

  /// 获取已解锁的成就数量
  Future<int> getUnlockedCount() async {
    return _repository.getUnlockedCount();
  }

  /// 获取总成就数量
  Future<int> getTotalCount() async {
    return _repository.getTotalCount();
  }

  /// 获取完成度百分比
  Future<double> getCompletionPercentage() async {
    return _repository.getCompletionPercentage();
  }

  /// 根据类别获取成就列表
  Future<List<Achievement>> getAchievementsByCategory(AchievementCategory category) async {
    return _repository.getAchievementsByCategory(category);
  }
}

/// 成就列表 Provider
final achievementsProvider = AsyncNotifierProvider<AchievementsNotifier, List<Achievement>>(() {
  return AchievementsNotifier();
});

/// 新解锁的成就通知 Provider
/// 
/// 用于在UI层显示成就解锁通知
/// 
/// 使用方式：
/// ```dart
/// ref.listen(newlyUnlockedAchievementsProvider, (previous, next) {
///   if (next.isNotEmpty) {
///     // 显示成就解锁通知
///     for (final achievementId in next) {
///       showAchievementUnlockedDialog(context, achievementId);
///     }
///     // 清空通知列表
///     ref.read(newlyUnlockedAchievementsProvider.notifier).clear();
///   }
/// });
/// ```
class NewlyUnlockedAchievementsNotifier extends StateNotifier<List<String>> {
  NewlyUnlockedAchievementsNotifier() : super([]);

  /// 添加新解锁的成就
  void add(List<String> achievementIds) {
    if (achievementIds.isEmpty) return;
    state = [...state, ...achievementIds];
  }

  /// 清空通知列表
  void clear() {
    state = [];
  }
}

/// 新解锁的成就通知 Provider
final newlyUnlockedAchievementsProvider = StateNotifierProvider<NewlyUnlockedAchievementsNotifier, List<String>>((ref) {
  return NewlyUnlockedAchievementsNotifier();
});

