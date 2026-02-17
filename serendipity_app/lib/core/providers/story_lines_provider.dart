import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/story_line.dart';
import '../../models/encounter_record.dart';
import '../repositories/story_line_repository.dart';
import 'records_provider.dart';

/// 故事线仓储 Provider
final storyLineRepositoryProvider = Provider<StoryLineRepository>((ref) {
  return StoryLineRepository(ref.read(storageServiceProvider));
});

/// 故事线列表状态管理
class StoryLinesNotifier extends AsyncNotifier<List<StoryLine>> {
  late StoryLineRepository _repository;

  @override
  Future<List<StoryLine>> build() async {
    _repository = ref.read(storyLineRepositoryProvider);
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
  Future<void> createStoryLine(StoryLine storyLine) async {
    await _repository.saveStoryLine(storyLine);
    await refresh();
  }

  /// 更新故事线
  Future<void> updateStoryLine(StoryLine storyLine) async {
    await _repository.updateStoryLine(storyLine);
    await refresh();
  }

  /// 删除故事线（自动取消所有记录关联）
  Future<void> deleteStoryLine(String id) async {
    await _repository.deleteStoryLine(id);
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

