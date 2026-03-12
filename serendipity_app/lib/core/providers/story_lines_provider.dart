import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/story_line.dart';
import '../../models/encounter_record.dart';
import '../../models/achievement_unlock.dart';
import '../services/sync_service.dart';
import '../services/achievement_detector.dart';
import '../repositories/story_line_repository.dart';
import 'records_provider.dart';
import 'auth_provider.dart';
import 'achievement_provider.dart';

/// 故事线记录列表 Provider
/// 
/// 根据故事线ID获取该故事线的所有记录
final storyLineRecordsProvider = Provider.family<List<EncounterRecord>, String>((ref, storyLineId) {
  final recordsAsync = ref.watch(recordsProvider);
  final storyLinesAsync = ref.watch(storyLinesProvider);
  
  // 如果数据还在加载中，返回空列表
  if (!recordsAsync.hasValue || !storyLinesAsync.hasValue) {
    return [];
  }
  
  final allRecords = recordsAsync.value ?? [];
  final storyLine = storyLinesAsync.value?.firstWhere(
    (sl) => sl.id == storyLineId,
    orElse: () => throw StateError('Story line $storyLineId not found'),
  );
  
  if (storyLine == null) {
    return [];
  }
  
  // 筛选出属于该故事线的记录
  final records = allRecords.where((record) {
    return storyLine.recordIds.contains(record.id);
  }).toList();
  
  // 按时间排序
  records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  
  return records;
});

/// 故事线列表状态管理
class StoryLinesNotifier extends AsyncNotifier<List<StoryLine>> {
  late StoryLineRepository _repository;
  late SyncService _syncService;
  
  /// 获取成就检测服务
  AchievementDetector get _achievementDetector => ref.read(achievementDetectorProvider);

  @override
  Future<List<StoryLine>> build() async {
    _repository = ref.read(storyLineRepositoryProvider);
    _syncService = ref.read(syncServiceProvider);
    
    // 监听自动同步完成信号，信号变化时自动重建
    ref.watch(syncCompletedProvider);
    
    // 获取当前登录用户
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    
    // 根据用户加载数据
    if (currentUser != null) {
      // 已登录：加载该用户的数据
      return _repository.getStoryLinesByUser(currentUser.id);
    } else {
      // 未登录：加载离线数据
      return _repository.getStoryLinesByUser(null);
    }
  }

  /// 刷新故事线列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 获取当前登录用户
      final currentUser = await ref.read(authProvider.notifier).currentUser;
      
      // 根据用户加载数据
      if (currentUser != null) {
        return _repository.getStoryLinesByUser(currentUser.id);
      } else {
        return _repository.getStoryLinesByUser(null);
      }
    });
  }

  /// 创建故事线
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，保存到本地后自动上传到云端
  /// - 如果用户未登录，只保存到本地（离线模式）
  /// - 云端同步失败时：UI 仍刷新展示本地数据，再向上抛出异常供 UI 显示提示
  Future<void> createStoryLine(StoryLine storyLine) async {
    // 1. 保存到本地
    await _repository.saveStoryLine(storyLine);
    
    // 2. 如果用户已登录，上传到云端
    // 先保存异常，确保后续步骤（成就检测、刷新）不被中断
    Exception? syncException;
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.uploadStoryLine(currentUser, storyLine);
      } catch (e) {
        syncException = e is Exception ? e : Exception(e.toString());
      }
    }
    
    // 3. 检测成就
    try {
      final unlockedAchievements = await _achievementDetector.checkStoryLineAchievements();
      if (unlockedAchievements.isNotEmpty) {
        ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
        ref.invalidate(achievementsProvider);
        await _uploadAchievementUnlocks(unlockedAchievements);
      }
    } catch (e) {
      // 成就检测失败不影响故事线创建
    }
    
    // 4. 无论云端是否成功，UI 都刷新
    await refresh();
    
    // 5. 云端失败时再向上抛出，让 UI 层显示提示
    if (syncException != null) throw syncException;
  }

  /// 更新故事线
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，更新本地后自动上传到云端（使用 PUT API 增量更新）
  /// - 如果用户未登录，只更新本地（离线模式）
  /// - 云端同步失败时：UI 仍刷新展示本地数据，再向上抛出异常供 UI 显示提示
  Future<void> updateStoryLine(StoryLine storyLine) async {
    // 1. 更新本地
    await _repository.updateStoryLine(storyLine);
    
    // 2. 如果用户已登录，使用 PUT API 更新云端（增量更新）
    // 先保存异常，确保后续 refresh 不被中断
    Exception? syncException;
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateStoryLine(currentUser, storyLine);
      } catch (e) {
        syncException = e is Exception ? e : Exception(e.toString());
      }
    }
    
    // 3. 无论云端是否成功，UI 都刷新
    await refresh();
    
    // 4. 云端失败时再向上抛出，让 UI 层显示提示
    if (syncException != null) throw syncException;
  }

  /// 删除故事线（自动取消所有记录关联）
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，删除本地后自动删除云端数据
  /// - 如果用户未登录，只删除本地（离线模式）
  /// - 云端同步失败时：UI 仍刷新展示本地数据，再向上抛出异常供 UI 显示提示
  Future<void> deleteStoryLine(String id) async {
    // 1. 删除本地
    await _repository.deleteStoryLine(id);
    
    // 2. 如果用户已登录，删除云端
    // 先保存异常，确保后续 refresh 不被中断
    Exception? syncException;
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.deleteStoryLine(currentUser, id);
      } catch (e) {
        syncException = e is Exception ? e : Exception(e.toString());
      }
    }
    
    // 3. 无论云端是否成功，UI 都刷新
    await refresh();
    
    // 4. 刷新记录列表（重要！确保记录的 storyLineId 更新为 null）
    ref.invalidate(recordsProvider);
    
    // 5. 云端失败时再向上抛出，让 UI 层显示提示
    if (syncException != null) throw syncException;
  }

  /// 将记录关联到故事线
  Future<void> linkRecord(String recordId, String storyLineId) async {
    await _repository.linkRecord(recordId, storyLineId);
    
    // 检测成就
    try {
      final unlockedAchievements = await _achievementDetector.checkStoryLineAchievements();
      if (unlockedAchievements.isNotEmpty) {
        // 通知UI层显示成就解锁通知
        ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
        // 刷新成就列表
        ref.invalidate(achievementsProvider);
        
        // 上传成就解锁记录到云端
        await _uploadAchievementUnlocks(unlockedAchievements);
      }
    } catch (e) {
      // 成就检测失败不影响记录关联
      // 但需要记录错误日志（生产环境）
    }
    
    // 刷新故事线列表
    await refresh();
    
    // 刷新记录列表（重要！确保记录的 storyLineId 更新）
    ref.invalidate(recordsProvider);
  }

  /// 从故事线移除记录
  Future<void> unlinkRecord(String recordId, String storyLineId) async {
    await _repository.unlinkRecord(recordId, storyLineId);
    
    // 刷新故事线列表
    await refresh();
    
    // 刷新记录列表（重要！确保记录的 storyLineId 更新）
    ref.invalidate(recordsProvider);
  }

  /// 获取故事线的所有记录
  List<EncounterRecord> getRecordsInStoryLine(String storyLineId) {
    return _repository.getRecordsInStoryLine(storyLineId);
  }

  /// 置顶故事线
  Future<void> pinStoryLine(String id) async {
    final storyLine = _repository.getStoryLine(id);
    if (storyLine == null) {
      throw StateError('StoryLine $id does not exist');
    }
    
    final updatedStoryLine = storyLine.copyWith(
      isPinned: true,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateStoryLine(updatedStoryLine);
    await refresh();
  }

  /// 取消置顶故事线
  Future<void> unpinStoryLine(String id) async {
    final storyLine = _repository.getStoryLine(id);
    if (storyLine == null) {
      throw StateError('StoryLine $id does not exist');
    }
    
    final updatedStoryLine = storyLine.copyWith(
      isPinned: false,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateStoryLine(updatedStoryLine);
    await refresh();
  }

  /// 切换置顶状态
  Future<void> togglePin(String id) async {
    final storyLine = _repository.getStoryLine(id);
    if (storyLine == null) {
      throw StateError('StoryLine $id does not exist');
    }
    
    if (storyLine.isPinned) {
      await unpinStoryLine(id);
    } else {
      await pinStoryLine(id);
    }
  }
  
  /// 上传成就解锁记录到云端
  /// 
  /// 调用者：createStoryLine()、linkRecord()
  /// 
  /// 设计原则：
  /// - 单一职责：只负责上传成就解锁记录
  /// - Fail Fast：用户未登录时直接返回，不抛异常
  /// - 容错处理：上传失败不影响成就解锁（已保存到本地）
  Future<void> _uploadAchievementUnlocks(List<String> achievementIds) async {
    // 获取当前用户
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser == null) {
      // 用户未登录，跳过上传
      return;
    }
    
    // 获取成就仓储
    final achievementRepo = ref.read(achievementRepositoryProvider);
    
    // 遍历每个成就ID，上传解锁记录
    for (final achievementId in achievementIds) {
      try {
        // 获取成就详情（包含解锁时间）
        final achievement = await achievementRepo.getAchievement(achievementId);
        if (achievement == null || !achievement.unlocked || achievement.unlockedAt == null) {
          // 成就不存在或未解锁，跳过
          continue;
        }
        
        // 创建成就解锁记录
        final unlock = AchievementUnlock(
          userId: currentUser.id,
          achievementId: achievementId,
          unlockedAt: achievement.unlockedAt!,
        );
        
        // 上传到云端
        await _syncService.uploadAchievementUnlock(unlock);
      } catch (e) {
        // 单个成就上传失败不影响其他成就
        // 用户可以稍后通过全量同步补齐
        // 生产环境应记录错误日志
      }
    }
  }
}

/// 故事线列表 Provider
final storyLinesProvider = AsyncNotifierProvider<StoryLinesNotifier, List<StoryLine>>(() {
  return StoryLinesNotifier();
});

