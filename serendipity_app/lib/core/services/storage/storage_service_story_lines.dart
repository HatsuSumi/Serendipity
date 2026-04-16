part of '../storage_service.dart';

mixin _StorageServiceStoryLines on _StorageServiceCore {
  @override
  Future<void> saveStoryLine(StoryLine storyLine) async {
    assert(storyLine.id.isNotEmpty, 'Story line ID cannot be empty');
    await storyLinesBoxOrThrow.put(storyLine.id, storyLine);
  }

  @override
  StoryLine? getStoryLine(String id) {
    assert(id.isNotEmpty, 'Story line ID cannot be empty');
    return storyLinesBoxOrThrow.get(id);
  }

  @override
  List<StoryLine> getAllStoryLines() {
    return storyLinesBoxOrThrow.values.toList();
  }

  @override
  List<StoryLine> getStoryLinesSortedByTime() {
    final storyLines = getAllStoryLines();
    storyLines.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return storyLines;
  }

  @override
  Future<void> deleteStoryLine(String id) async {
    assert(id.isNotEmpty, 'Story line ID cannot be empty');
    await storyLinesBoxOrThrow.delete(id);
  }

  @override
  Future<void> updateStoryLine(StoryLine storyLine) async {
    assert(storyLine.id.isNotEmpty, 'Story line ID cannot be empty');
    await storyLinesBoxOrThrow.put(storyLine.id, storyLine);
  }

  @override
  List<StoryLine> getStoryLinesByUser(String? userId) {
    final storyLines = getAllStoryLines()
        .where((storyLine) => storyLine.userId == userId)
        .toList();
    storyLines.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return storyLines;
  }
}
