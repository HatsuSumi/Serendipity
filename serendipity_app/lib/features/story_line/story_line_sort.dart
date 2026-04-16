import '../../models/story_line.dart';

/// 排序方式
enum StoryLineSortType {
  createdDesc('创建时间 ↓'),
  createdAsc('创建时间 ↑'),
  updatedDesc('更新时间 ↓'),
  updatedAsc('更新时间 ↑'),
  nameAsc('名称 A-Z'),
  nameDesc('名称 Z-A');

  final String label;
  const StoryLineSortType(this.label);
}

/// 根据排序方式排序故事线
///
/// 置顶故事线始终在最前面，然后按照选择的排序方式排序。
List<StoryLine> sortStoryLines(
  List<StoryLine> storyLines,
  StoryLineSortType sortType,
) {
  final sorted = List<StoryLine>.from(storyLines);

  switch (sortType) {
    case StoryLineSortType.createdDesc:
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case StoryLineSortType.createdAsc:
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case StoryLineSortType.updatedDesc:
      sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      break;
    case StoryLineSortType.updatedAsc:
      sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      break;
    case StoryLineSortType.nameAsc:
      sorted.sort((a, b) => a.name.compareTo(b.name));
      break;
    case StoryLineSortType.nameDesc:
      sorted.sort((a, b) => b.name.compareTo(a.name));
      break;
  }

  sorted.sort((a, b) {
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    return 0;
  });

  return sorted;
}
