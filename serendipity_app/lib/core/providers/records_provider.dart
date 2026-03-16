import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/achievement_unlock.dart';
import '../../models/enums.dart';
import '../services/sync_service.dart';
import '../services/achievement_detector.dart';
import '../repositories/record_repository.dart';
import '../repositories/story_line_repository.dart';
import 'community_provider.dart';
import 'story_lines_provider.dart';
import 'auth_provider.dart';
import 'achievement_provider.dart';
import 'records_filter_provider.dart';

/// 自动同步完成信号
/// 
/// 每次自动同步（App启动/网络恢复/轮询）完成后递增，
/// 让 recordsProvider / storyLinesProvider / checkInProvider 自动刷新。
final syncCompletedProvider = StateProvider<int>((ref) => 0);

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
    
    // 监听自动同步完成信号，信号变化时自动重建
    ref.watch(syncCompletedProvider);
    
    // 获取当前登录用户
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    
    // 根据用户加载数据
    if (currentUser != null) {
      final records = _repository.getRecordsByUser(currentUser.id);
      return records;
    } else {
      // 未登录：加载离线数据
      return _repository.getRecordsByUser(null);
    }
  }
  
  /// 获取同步服务（延迟初始化）
  SyncService get _syncService => ref.read(syncServiceProvider);
  
  /// 获取成就检测服务
  AchievementDetector get _achievementDetector => ref.read(achievementDetectorProvider);

  /// 刷新记录列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 获取当前登录用户
      final currentUser = await ref.read(authProvider.notifier).currentUser;
      
      // 根据用户加载数据
      if (currentUser != null) {
        return _repository.getRecordsByUser(currentUser.id);
      } else {
        return _repository.getRecordsByUser(null);
      }
    });
  }

  /// 保存记录（自动处理故事线关联）
  /// 
  /// 架构优化：
  /// - 不在此方法中检测成就，避免导航栈混乱
  /// - 成就检测由调用者在页面关闭后手动触发 checkAchievementsForRecord()
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
    
    // 3. 如果用户已登录，上传到云端
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
    
    // 4. 刷新记录列表
    await refresh();
  }
  
  /// 检测记录的成就解锁（由调用者在页面关闭后手动触发）
  /// 
  /// 架构设计：
  /// - 单一职责：只负责成就检测和通知
  /// - 时序控制：由调用者决定何时触发，避免导航栈混乱
  /// - 容错处理：检测失败不影响记录保存
  /// - 数据隔离：传入 userId 确保只检测当前用户的数据
  /// 
  /// 调用者：
  /// - MainNavigationPage：在 CreateRecordPage 关闭后调用
  /// 
  /// 示例：
  /// ```dart
  /// // 保存记录
  /// await ref.read(recordsProvider.notifier).saveRecord(record);
  /// 
  /// // 关闭页面
  /// Navigator.of(context).pop(true);
  /// 
  /// // 页面关闭后检测成就
  /// await ref.read(recordsProvider.notifier).checkAchievementsForRecord(record);
  /// ```
  Future<void> checkAchievementsForRecord(EncounterRecord record) async {
    try {
      // 获取当前用户
      final currentUser = await ref.read(authProvider.notifier).currentUser;
      if (currentUser == null) {
        // 未登录，跳过成就检测
        return;
      }
      
      final detector = ref.read(achievementDetectorProvider);
      // 传入 userId 确保数据隔离
      final unlockedAchievements = await detector.checkRecordAchievements(record, currentUser.id);
      
      // 如果记录关联了故事线，也检测故事线成就（例如"重新开始"成就）
      if (record.storyLineId != null) {
        final storyLineAchievements = await detector.checkStoryLineAchievements(currentUser.id);
        unlockedAchievements.addAll(storyLineAchievements);
      }
      
      if (unlockedAchievements.isNotEmpty) {
        // 通知UI层显示成就解锁通知
        ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
        // 刷新成就列表
        ref.invalidate(achievementsProvider);
        
        // 上传成就解锁记录到云端
        await _uploadAchievementUnlocks(unlockedAchievements);
      }
    } catch (e) {
      // 成就检测失败不影响流程
      // 生产环境应记录错误日志
    }
  }

  /// 更新记录（自动处理故事线关联变化）
  /// 
  /// 架构优化：
  /// - 不在此方法中检测成就，避免导航栈混乱
  /// - 成就检测由调用者在页面关闭后手动触发 checkAchievementsForRecord()
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，更新本地后自动上传到云端（使用 PUT API 增量更新）
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
    
    // 4. 如果用户已登录，使用 PUT API 更新云端（增量更新）
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateRecord(currentUser, record);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 不抛出异常，避免影响后续流程
        // 用户可以稍后手动触发全量同步
      }
    }
    
    // 5. 刷新记录列表
    await refresh();
  }

  /// 删除记录（自动从故事线移除，并联动删除对应社区帖子）
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，删除本地后自动删除云端数据
  /// - 如果用户未登录，只删除本地（离线模式）
  /// - 云端同步失败不影响本地操作
  /// - 社区帖子联动删除失败不影响记录删除（静默处理）
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
    
    // 3. 如果用户已登录，删除云端记录并联动删除社区帖子
    Exception? syncException;
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.deleteRecord(currentUser, id);
      } catch (e) {
        // 先保存异常，确保后续步骤（社区联动、刷新）不被中断
        syncException = e is Exception ? e : Exception(e.toString());
      }
      
      // 联动删除对应的社区帖子（幂等，帖子不存在时静默成功）
      // 无论云端删除是否成功都要执行，保持本地一致性
      try {
        final communityRepo = ref.read(communityRepositoryProvider);
        await communityRepo.deletePostByRecordId(id);
        // 刷新社区相关 Provider
        ref.invalidate(communityProvider);
        ref.invalidate(myPostsProvider);
      } catch (e) {
        // 社区帖子删除失败不影响记录删除（静默处理）
      }
    }
    
    // 4. 无论云端是否成功，UI 都刷新
    await refresh();
    
    // 5. 云端失败时再向上抛出，让 UI 层显示提示
    if (syncException != null) throw syncException;
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

    // 同步到云端（置顶状态需要跨设备一致）
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateRecord(currentUser, updatedRecord);
      } catch (_) {
        // 云端同步失败不影响本地置顶，用户可稍后手动同步
      }
    }

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

    // 同步到云端（置顶状态需要跨设备一致）
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateRecord(currentUser, updatedRecord);
      } catch (_) {
        // 云端同步失败不影响本地取消置顶，用户可稍后手动同步
      }
    }

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
  
  /// 上传成就解锁记录到云端
  /// 
  /// 调用者：saveRecord()、updateRecord()
  /// 
  /// 设计原则：
  /// - 单一职责：只负责上传成就解锁记录
  /// - Fail Fast：用户未登录时直接返回，不抛异常
  /// - 容错处理：上传失败不影响成就解锁（已保存到本地）
  /// - 参数验证：achievementIds 不能为空
  Future<void> _uploadAchievementUnlocks(List<String> achievementIds) async {
    // Fail Fast：参数验证
    if (achievementIds.isEmpty) {
      return; // 允许空列表
    }
    
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
      // Fail Fast：成就ID不能为空
      if (achievementId.isEmpty) {
        continue;
      }
      
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

  /// 应用筛选条件
  /// 
  /// 调用者：RecordFilterDialog._applyFilter()
  /// 
  /// 设计说明：
  /// - 保存筛选条件到 Provider
  /// - 如果有筛选条件，立即调用后端筛选
  /// - 如果没有筛选条件，刷新本地列表
  Future<void> filterRecords({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdStartDate,
    DateTime? createdEndDate,
    String? province,
    String? city,
    String? area,
    List<PlaceType>? placeTypes,
    List<EncounterStatus>? statuses,
    List<EmotionIntensity>? emotionIntensities,
    List<Weather>? weathers,
    List<String>? tags,
    TagMatchMode tagMatchMode = TagMatchMode.contains,
    String? descriptionKeyword,
    String? ifReencounterKeyword,
    String? conversationStarterKeyword,
    String? backgroundMusicKeyword,
  }) async {
    // 保存筛选条件到 Provider
    ref.read(recordsFilterProvider.notifier).state = RecordsFilterCriteria(
      startDate: startDate,
      endDate: endDate,
      createdStartDate: createdStartDate,
      createdEndDate: createdEndDate,
      province: province,
      city: city,
      area: area,
      placeTypes: placeTypes,
      statuses: statuses,
      emotionIntensities: emotionIntensities,
      weathers: weathers,
      tags: tags,
      tagMatchMode: tagMatchMode,
      descriptionKeyword: descriptionKeyword,
      ifReencounterKeyword: ifReencounterKeyword,
      conversationStarterKeyword: conversationStarterKeyword,
      backgroundMusicKeyword: backgroundMusicKeyword,
    );
  }

  /// 清除筛选条件
  /// 
  /// 调用者：RecordFilterDialog._clearFilter()
  Future<void> clearRecordsFilter() async {
    ref.read(recordsFilterProvider.notifier).state = const RecordsFilterCriteria();
  }

  /// 从后端筛选记录（支持多条件组合）
  /// 
  /// 设计原则：
  /// - 后端筛选：支持大数据量和复杂筛选
  /// - 分页支持：limit + offset
  /// - 排序支持：createdAt/updatedAt，升序/降序
  /// - 标签筛选：全词匹配或包含匹配
  /// 
  /// 调用者：
  /// - TimelinePage：时间轴页面筛选
  /// - MyPostsPage：我的发布页面筛选
  /// 
  /// 返回：筛选结果列表
  Future<List<EncounterRecord>> filterRecordsFromServer({
    DateTime? startDate,
    DateTime? endDate,
    String? province,
    String? city,
    String? area,
    List<String>? placeTypes,
    List<String>? tags,
    List<String>? statuses,
    List<String>? emotionIntensities,
    List<String>? weathers,
    String tagMatchMode = 'contains',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int limit = 20,
    int offset = 0,
  }) async {
    // 获取当前用户
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser == null) {
      throw Exception('必须登录后才可筛选');
    }

    try {
      // 直接调用远程数据仓库的筛选方法
      final remoteData = ref.read(remoteDataRepositoryProvider);
      final records = await remoteData.filterRecords(
        userId: currentUser.id,
        startDate: startDate,
        endDate: endDate,
        province: province,
        city: city,
        area: area,
        placeTypes: placeTypes,
        tags: tags,
        statuses: statuses,
        emotionIntensities: emotionIntensities,
        weathers: weathers,
        tagMatchMode: tagMatchMode,
        sortBy: sortBy,
        sortOrder: sortOrder,
        limit: limit,
        offset: offset,
      );
      
      return records;
    } catch (e) {
      throw Exception('筛选记录失败：${e.toString()}');
    }
  }
}

/// 记录列表 Provider
final recordsProvider = AsyncNotifierProvider<RecordsNotifier, List<EncounterRecord>>(() {
  return RecordsNotifier();
});

/// 记录统计 Provider
/// 
/// 计算当前用户的记录总数
/// 
/// 设计说明：
/// - 依赖 recordsProvider，自动响应数据变化
/// - 返回异步值，支持 loading/error 状态
/// - 用于 UI 显示统计信息（如标题中的记录数）
final recordsCountProvider = FutureProvider<int>((ref) async {
  final recordsAsync = ref.watch(recordsProvider);
  return recordsAsync.maybeWhen(
    data: (records) => records.length,
    orElse: () => 0,
  );
});

