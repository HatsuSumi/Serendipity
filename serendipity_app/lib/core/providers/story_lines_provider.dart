import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/story_line.dart';
import '../services/storage_service.dart';

/// 故事线列表状态管理
class StoryLinesNotifier extends AsyncNotifier<List<StoryLine>> {
  @override
  Future<List<StoryLine>> build() async {
    // 初始化时加载所有故事线
    return StorageService().getStoryLinesSortedByTime();
  }

  /// 刷新故事线列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return StorageService().getStoryLinesSortedByTime();
    });
  }

  /// 创建故事线
  Future<void> createStoryLine(StoryLine storyLine) async {
    await StorageService().saveStoryLine(storyLine);
    await refresh();
  }

  /// 更新故事线
  Future<void> updateStoryLine(StoryLine storyLine) async {
    await StorageService().updateStoryLine(storyLine);
    await refresh();
  }

  /// 删除故事线
  Future<void> deleteStoryLine(String id) async {
    await StorageService().deleteStoryLine(id);
    await refresh();
  }

  /// 将记录关联到故事线
  Future<void> linkRecord(String recordId, String storyLineId) async {
    await StorageService().linkRecordToStoryLine(recordId, storyLineId);
    await refresh();
  }

  /// 从故事线移除记录
  Future<void> unlinkRecord(String recordId, String storyLineId) async {
    await StorageService().unlinkRecordFromStoryLine(recordId, storyLineId);
    await refresh();
  }
}

/// 故事线列表 Provider
final storyLinesProvider = AsyncNotifierProvider<StoryLinesNotifier, List<StoryLine>>(() {
  return StoryLinesNotifier();
});

