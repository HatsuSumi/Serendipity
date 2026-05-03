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
/// 根据故事线ID获取该故事线的所有记录。
///
/// 设计说明：
/// - 直接依赖故事线仓储，而不是依赖时间轴分页后的 recordsProvider
/// - 避免故事线详情页被时间轴分页状态污染
/// - 通过监听 storyLinesProvider / syncCompletedProvider 自动响应关联变化与同步更新
final storyLineRecordsProvider = Provider.family<List<EncounterRecord>, String>((ref, storyLineId) {
  ref.watch(syncCompletedProvider);
  ref.watch(storyLinesProvider);

  final repository = ref.watch(storyLineRepositoryProvider);
  return repository.getRecordsInStoryLine(storyLineId);
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
  /// - 云端同步失败时：本地数据已保存，UI 刷新展示，不抛异常
  Future<void> createStoryLine(StoryLine storyLine) async {
    // 1. 保存到本地
    await _repository.saveStoryLine(storyLine);
    
    // 2. 如果用户已登录，上传到云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.uploadStoryLine(currentUser, storyLine);
      } catch (e) {
        // 云端同步失败，但本地已保存，继续执行
        // 不抛异常，避免对话框关闭时序不确定
      }
    }
    
    // 3. 检测成就
    try {
      if (currentUser != null) {
        final unlockedAchievements = await _achievementDetector.checkStoryLineAchievements(currentUser.id);
        if (unlockedAchievements.isNotEmpty) {
          ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
          ref.invalidate(achievementsProvider);
          await _uploadAchievementUnlocks(unlockedAchievements);
        }
      }
    } catch (e) {
      // 成就检测失败不影响故事线创建
    }
    
    // 4. 刷新 UI（最后一步，之后不会有异常）
    await refresh();
  }

  /// 更新故事线
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，更新本地后自动上传到云端（使用 PUT API 增量更新）
  /// - 如果用户未登录，只更新本地（离线模式）
  /// - 云端同步失败时：本地数据已更新，UI 刷新展示，不抛异常
  Future<void> updateStoryLine(StoryLine storyLine) async {
    // 1. 更新本地
    await _repository.updateStoryLine(storyLine);
    
    // 2. 如果用户已登录，使用 PUT API 更新云端（增量更新）
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateStoryLine(currentUser, storyLine);
      } catch (e) {
        // 云端同步失败，但本地已更新，继续执行
        // 不抛异常，避免对话框关闭时序不确定
      }
    }
    
    // 3. 刷新 UI（最后一步，之后不会有异常）
    await refresh();
  }

  /// 删除故事线（自动取消所有记录关联）
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，删除本地后自动删除云端数据
  /// - 如果用户未登录，只删除本地（离线模式）
  /// - 云端同步失败时：本地数据已删除，UI 刷新展示，不抛异常
  Future<void> deleteStoryLine(String id) async {
    // 1. 删除本地
    await _repository.deleteStoryLine(id);
    
    // 2. 如果用户已登录，删除云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.deleteStoryLine(currentUser, id);
      } catch (e) {
        // 云端同步失败，但本地已删除，继续执行
        // 不抛异常，避免对话框关闭时序不确定
      }
    }
    
    // 3. 刷新故事线列表
    await refresh();
    
    // 4. 刷新记录列表（重要！确保记录的 storyLineId 更新为 null）
    ref.invalidate(recordsProvider);
  }

  /// 将记录关联到故事线
  Future<void> linkRecord(String recordId, String storyLineId) async {
    await _repository.linkRecord(recordId, storyLineId);
    
    // 检测成就
    try {
      final currentUser = await ref.read(authProvider.notifier).currentUser;
      if (currentUser != null) {
        final unlockedAchievements = await _achievementDetector.checkStoryLineAchievements(currentUser.id);
        if (unlockedAchievements.isNotEmpty) {
          // 通知UI层显示成就解锁通知
          ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
          // 刷新成就列表
          ref.invalidate(achievementsProvider);
          
          // 上传成就解锁记录到云端
          await _uploadAchievementUnlocks(unlockedAchievements);
        }
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

    // 同步到云端（置顶状态需要跨设备一致）
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateStoryLine(currentUser, updatedStoryLine);
      } catch (_) {
        // 云端同步失败不影响本地置顶，用户可稍后手动同步
      }
    }

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

    // 同步到云端（置顶状态需要跨设备一致）
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateStoryLine(currentUser, updatedStoryLine);
      } catch (_) {
        // 云端同步失败不影响本地取消置顶，用户可稍后手动同步
      }
    }

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

/// 故事线统计 Provider
/// 
/// 计算当前用户的故事线总数
/// 
/// 设计说明：
/// - 依赖 storyLinesProvider，自动响应数据变化
/// - 返回异步值，支持 loading/error 状态
/// - 用于 UI 显示统计信息（如标题中的故事线数）
final storyLinesCountProvider = FutureProvider<int>((ref) async {
  final storyLinesAsync = ref.watch(storyLinesProvider);
  return storyLinesAsync.maybeWhen(
    data: (storyLines) => storyLines.length,
    orElse: () => 0,
  );
});

