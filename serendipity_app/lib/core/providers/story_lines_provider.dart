import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/story_line.dart';
import '../../models/encounter_record.dart';
import '../services/sync_service.dart';
import '../repositories/story_line_repository.dart';
import 'records_provider.dart';
import 'auth_provider.dart';

/// 故事线仓储 Provider
final storyLineRepositoryProvider = Provider<StoryLineRepository>((ref) {
  return StoryLineRepository(ref.read(storageServiceProvider));
});

/// 故事线列表状态管理
class StoryLinesNotifier extends AsyncNotifier<List<StoryLine>> {
  late StoryLineRepository _repository;
  late SyncService _syncService;

  @override
  Future<List<StoryLine>> build() async {
    _repository = ref.read(storyLineRepositoryProvider);
    _syncService = ref.read(syncServiceProvider);
    // 初始化时加载所有故事线
    return _repository.getStoryLinesSortedByTime();
  }

  /// 刷新故事线列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.getStoryLinesSortedByTime();
    });
  }

  /// 创建故事线
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，保存到本地后自动上传到云端
  /// - 如果用户未登录，只保存到本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> createStoryLine(StoryLine storyLine) async {
    // 1. 保存到本地
    await _repository.saveStoryLine(storyLine);
    
    // 2. 如果用户已登录，上传到云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.uploadStoryLine(currentUser, storyLine);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 但需要向上抛出异常，让 UI 层显示提示
        rethrow;
      }
    }
    
    // 3. 刷新列表
    await refresh();
  }

  /// 更新故事线
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，更新本地后自动上传到云端
  /// - 如果用户未登录，只更新本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> updateStoryLine(StoryLine storyLine) async {
    // 1. 更新本地
    await _repository.updateStoryLine(storyLine);
    
    // 2. 如果用户已登录，上传到云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.uploadStoryLine(currentUser, storyLine);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 但需要向上抛出异常，让 UI 层显示提示
        rethrow;
      }
    }
    
    // 3. 刷新列表
    await refresh();
  }

  /// 删除故事线（自动取消所有记录关联）
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，删除本地后自动删除云端数据
  /// - 如果用户未登录，只删除本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> deleteStoryLine(String id) async {
    // 1. 删除本地
    await _repository.deleteStoryLine(id);
    
    // 2. 如果用户已登录，删除云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.deleteStoryLine(currentUser, id);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 但需要向上抛出异常，让 UI 层显示提示
        rethrow;
      }
    }
    
    // 3. 刷新列表
    await refresh();
  }

  /// 将记录关联到故事线
  Future<void> linkRecord(String recordId, String storyLineId) async {
    await _repository.linkRecord(recordId, storyLineId);
    await refresh();
  }

  /// 从故事线移除记录
  Future<void> unlinkRecord(String recordId, String storyLineId) async {
    await _repository.unlinkRecord(recordId, storyLineId);
    await refresh();
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
}

/// 故事线列表 Provider
final storyLinesProvider = AsyncNotifierProvider<StoryLinesNotifier, List<StoryLine>>(() {
  return StoryLinesNotifier();
});

