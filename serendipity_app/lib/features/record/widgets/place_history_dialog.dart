import 'package:flutter/material.dart';
import '../../../core/utils/dialog_helper.dart';
import '../models/place_history_item.dart';

/// 地点历史选择对话框
/// 
/// 用于选择历史地点，支持排序和删除
class PlaceHistoryDialog extends StatefulWidget {
  final List<PlaceHistoryItem> placeHistory;
  final VoidCallback onHistoryChanged;
  
  const PlaceHistoryDialog({
    super.key,
    required this.placeHistory,
    required this.onHistoryChanged,
  });

  @override
  State<PlaceHistoryDialog> createState() => _PlaceHistoryDialogState();
}

class _PlaceHistoryDialogState extends State<PlaceHistoryDialog> {
  PlaceSortType _currentSort = PlaceSortType.timeDesc;
  late List<PlaceHistoryItem> _placeHistory;

  @override
  void initState() {
    super.initState();
    _placeHistory = List.from(widget.placeHistory);
  }

  @override
  Widget build(BuildContext context) {
    // 根据当前排序方式排序
    final sortedPlaces = _getSortedPlaces();
    
    return AlertDialog(
      title: Row(
        children: [
          const Text('选择历史地点'),
          const Spacer(),
          PopupMenuButton<PlaceSortType>(
            icon: const Icon(Icons.sort),
            tooltip: '排序方式',
            onSelected: (PlaceSortType type) {
              setState(() {
                _currentSort = type;
              });
            },
            itemBuilder: (context) => PlaceSortType.values.map((type) {
              return PopupMenuItem(
                value: type,
                child: Row(
                  children: [
                    if (_currentSort == type)
                      const Icon(Icons.check, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(type.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: sortedPlaces.isEmpty
            ? Center(
                child: Text(
                  '暂无历史地点',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: sortedPlaces.length,
                itemBuilder: (context, index) {
                  final item = sortedPlaces[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(item.placeName),
                    subtitle: Text(
                      '使用 ${item.usageCount} 次 · ${_formatDate(item.lastUsedTime)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _confirmDelete(item),
                    ),
                    onTap: () => Navigator.of(context).pop(item.placeName),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  /// 获取排序后的地点列表
  List<PlaceHistoryItem> _getSortedPlaces() {
    final sortedPlaces = List<PlaceHistoryItem>.from(_placeHistory);
    switch (_currentSort) {
      case PlaceSortType.usageDesc:
        sortedPlaces.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case PlaceSortType.usageAsc:
        sortedPlaces.sort((a, b) => a.usageCount.compareTo(b.usageCount));
        break;
      case PlaceSortType.timeDesc:
        sortedPlaces.sort((a, b) => b.lastUsedTime.compareTo(a.lastUsedTime));
        break;
      case PlaceSortType.timeAsc:
        sortedPlaces.sort((a, b) => a.lastUsedTime.compareTo(b.lastUsedTime));
        break;
    }
    return sortedPlaces;
  }

  /// 确认删除地点
  Future<void> _confirmDelete(PlaceHistoryItem item) async {
    final confirm = await DialogHelper.show<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除地点"${item.placeName}"的历史记录吗？\n\n这不会删除相关的记录，只是从历史列表中移除。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _placeHistory.removeWhere((p) => p.placeName == item.placeName);
      });
      widget.onHistoryChanged();
    }
  }

  /// 格式化日期（相对时间）
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} 周前';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} 月前';
    } else {
      return '${(diff.inDays / 365).floor()} 年前';
    }
  }
}

