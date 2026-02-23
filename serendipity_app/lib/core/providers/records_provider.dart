import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../services/i_storage_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../services/achievement_detector.dart';
import '../repositories/record_repository.dart';
import '../repositories/story_line_repository.dart';
import 'story_lines_provider.dart';
import 'auth_provider.dart';
import 'achievement_provider.dart';

/// 存储服务 Provider
final storageServiceProvider = Provider<IStorageService>((ref) {
  return StorageService();
});

/// 记录仓储 Provider
final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(ref.read(storageServiceProvider));
});

/// 故事线仓储 Provider（用于 RecordsProvider）
final storyLineRepositoryProvider = Provider<StoryLineRepository>((ref) {
  return StoryLineRepository(ref.read(storageServiceProvider));
});

/// 记录列表状态管理
class RecordsNotifier extends AsyncNotifier<List<EncounterRecord>> {
  late RecordRepository _repository;

  @override
  Future<List<EncounterRecord>> build() async {
    _repository = ref.read(recordRepositoryProvider);
    // 初始化时加载所有记录
    return _repository.getRecordsSortedByTime();
  }
  
  /// 获取同步服务（延迟初始化，避免测试模式下创建 Firebase 实例）
  SyncService get _syncService => ref.read(syncServiceProvider);
  
  /// 获取成就检测服务
  AchievementDetector get _achievementDetector => ref.read(achievementDetectorProvider);

  /// 刷新记录列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.getRecordsSortedByTime();
    });
  }

  /// 保存记录（自动处理故事线关联）
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，保存到本地后自动上传到云端
  /// - 如果用户未登录，只保存到本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> saveRecord(EncounterRecord record) async {
    // 1. 保存到本地
    await _repository.saveRecord(record);
    
    // 2. 如果关联了故事线，建立双向关联
    if (record.storyLineId != null) {
      final storyLineRepo = ref.read(storyLineRepositoryProvider);
      await storyLineRepo.linkRecord(record.id, record.storyLineId!);
      
      // 刷新故事线列表（重要！）
      ref.invalidate(storyLinesProvider);
    }
    
    // 3. 检测成就（在云端同步之前，确保成就检测不受网络影响）
    try {
      final unlockedAchievements = await _achievementDetector.checkRecordAchievements(record);
      if (unlockedAchievements.isNotEmpty) {
        // 通知UI层显示成就解锁通知
        ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
        // 刷新成就列表
        ref.invalidate(achievementsProvider);
      }
    } catch (e) {
      // 成就检测失败不影响记录保存
      // 但需要记录错误日志（生产环境）
    }
    
    // 4. 如果用户已登录，上传到云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.uploadRecord(currentUser, record);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 不抛出异常，避免影响后续流程
        // 用户可以稍后手动触发全量同步
      }
    }
    
    // 5. 刷新记录列表
    await refresh();
  }

  /// 更新记录（自动处理故事线关联变化）
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，更新本地后自动上传到云端
  /// - 如果用户未登录，只更新本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> updateRecord(EncounterRecord record) async {
    // 1. 获取旧记录，检查故事线是否变化
    final oldRecord = _repository.getRecord(record.id);
    final oldStoryLineId = oldRecord?.storyLineId;
    final newStoryLineId = record.storyLineId;
    
    // 2. 更新本地
    await _repository.updateRecord(record);
    
    // 3. 如果故事线发生变化，更新双向关联
    if (oldStoryLineId != newStoryLineId) {
      final storyLineRepo = ref.read(storyLineRepositoryProvider);
      
      // 从旧故事线移除
      if (oldStoryLineId != null) {
        await storyLineRepo.unlinkRecord(record.id, oldStoryLineId);
      }
      
      // 关联到新故事线
      if (newStoryLineId != null) {
        await storyLineRepo.linkRecord(record.id, newStoryLineId);
      }
      
      // 刷新故事线列表（重要！）
      ref.invalidate(storyLinesProvider);
    }
    
    // 4. 检测成就（在云端同步之前，确保成就检测不受网络影响）
    try {
      final unlockedAchievements = await _achievementDetector.checkRecordAchievements(record);
      if (unlockedAchievements.isNotEmpty) {
        // 通知UI层显示成就解锁通知
        ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
        // 刷新成就列表
        ref.invalidate(achievementsProvider);
      }
    } catch (e) {
      // 成就检测失败不影响记录更新
      // 但需要记录错误日志（生产环境）
    }
    
    // 5. 如果用户已登录，上传到云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.uploadRecord(currentUser, record);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 不抛出异常，避免影响后续流程
        // 用户可以稍后手动触发全量同步
      }
    }
    
    // 6. 刷新记录列表
    await refresh();
  }

  /// 删除记录（自动从故事线移除）
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，删除本地后自动删除云端数据
  /// - 如果用户未登录，只删除本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> deleteRecord(String id) async {
    // 1. 获取记录，检查是否关联了故事线
    final record = _repository.getRecord(id);
    if (record != null && record.storyLineId != null) {
      // 先从故事线移除
      final storyLineRepo = ref.read(storyLineRepositoryProvider);
      await storyLineRepo.unlinkRecord(id, record.storyLineId!);
      
      // 刷新故事线列表（重要！）
      ref.invalidate(storyLinesProvider);
    }
    
    // 2. 删除本地
    await _repository.deleteRecord(id);
    
    // 3. 如果用户已登录，删除云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.deleteRecord(currentUser, id);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 但需要向上抛出异常，让 UI 层显示提示
        rethrow;
      }
    }
    
    // 4. 刷新记录列表
    await refresh();
  }

  /// 置顶记录
  Future<void> pinRecord(String id) async {
    final record = _repository.getRecord(id);
    if (record == null) {
      throw StateError('Record $id does not exist');
    }
    
    final updatedRecord = record.copyWith(
      isPinned: true,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateRecord(updatedRecord);
    await refresh();
  }

  /// 取消置顶记录
  Future<void> unpinRecord(String id) async {
    final record = _repository.getRecord(id);
    if (record == null) {
      throw StateError('Record $id does not exist');
    }
    
    final updatedRecord = record.copyWith(
      isPinned: false,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateRecord(updatedRecord);
    await refresh();
  }

  /// 切换置顶状态
  Future<void> togglePin(String id) async {
    final record = _repository.getRecord(id);
    if (record == null) {
      throw StateError('Record $id does not exist');
    }
    
    if (record.isPinned) {
      await unpinRecord(id);
    } else {
      await pinRecord(id);
    }
  }
}

/// 记录列表 Provider
final recordsProvider = AsyncNotifierProvider<RecordsNotifier, List<EncounterRecord>>(() {
  return RecordsNotifier();
});

