/// 地点历史记录项
/// 
/// 用于统计和展示地点的使用频率和最后使用时间
class PlaceHistoryItem {
  final String placeName;
  final int usageCount;
  final DateTime lastUsedTime;

  PlaceHistoryItem({
    required this.placeName,
    required this.usageCount,
    required this.lastUsedTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceHistoryItem &&
          runtimeType == other.runtimeType &&
          placeName == other.placeName &&
          usageCount == other.usageCount &&
          lastUsedTime == other.lastUsedTime;

  @override
  int get hashCode =>
      placeName.hashCode ^ usageCount.hashCode ^ lastUsedTime.hashCode;
}

/// 地点排序方式
enum PlaceSortType {
  usageDesc('使用频率 ↓'),
  usageAsc('使用频率 ↑'),
  timeDesc('最近使用 ↓'),
  timeAsc('最近使用 ↑');

  final String label;
  const PlaceSortType(this.label);
}

