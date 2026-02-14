import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../core/services/storage_service.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/theme/status_color_extension.dart';

/// 添加现有记录到故事线对话框
class AddExistingRecordsDialog extends ConsumerStatefulWidget {
  final StoryLine storyLine;

  const AddExistingRecordsDialog({
    super.key,
    required this.storyLine,
  });

  @override
  ConsumerState<AddExistingRecordsDialog> createState() => _AddExistingRecordsDialogState();
}

class _AddExistingRecordsDialogState extends ConsumerState<AddExistingRecordsDialog> {
  final Set<String> _selectedRecordIds = {};
  List<EncounterRecord> _availableRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableRecords();
  }

  /// 加载可用的记录（未关联到该故事线的记录）
  Future<void> _loadAvailableRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storage = StorageService();
      final allRecords = storage.getAllRecords();
      
      // 筛选出未关联到该故事线的记录
      final available = allRecords.where((record) {
        return !widget.storyLine.recordIds.contains(record.id);
      }).toList();
      
      // 按时间倒序排列
      available.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _availableRecords = available;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '添加现有记录',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 记录列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _availableRecords.isEmpty
                      ? _buildEmptyState(context)
                      : _buildRecordList(context),
            ),

            const Divider(height: 1),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedRecordIds.isEmpty ? null : _handleConfirm,
                    child: Text('添加 (${_selectedRecordIds.length})'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '所有记录都已添加',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '没有可添加的记录了',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 记录列表
  Widget _buildRecordList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _availableRecords.length,
      itemBuilder: (context, index) {
        final record = _availableRecords[index];
        final isSelected = _selectedRecordIds.contains(record.id);
        
        return _buildRecordItem(context, record, isSelected);
      },
    );
  }

  /// 记录项
  Widget _buildRecordItem(BuildContext context, EncounterRecord record, bool isSelected) {
    final statusColor = record.status.getColor(context, ref);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedRecordIds.remove(record.id);
          } else {
            _selectedRecordIds.add(record.id);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            // 复选框
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedRecordIds.add(record.id);
                  } else {
                    _selectedRecordIds.remove(record.id);
                  }
                });
              },
            ),
            const SizedBox(width: 12),

            // 记录信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期和状态
                  Row(
                    children: [
                      Text(
                        _formatDate(record.timestamp),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record.status.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.status.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 地点
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getLocationText(record),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理确认
  Future<void> _handleConfirm() async {
    if (_selectedRecordIds.isEmpty) return;

    try {
      final storyLinesNotifier = ref.read(storyLinesProvider.notifier);
      
      // 批量关联记录
      for (final recordId in _selectedRecordIds) {
        await storyLinesNotifier.linkRecord(recordId, widget.storyLine.id);
      }

      // 刷新记录列表
      await ref.read(recordsProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop(true);
        MessageHelper.showSuccess(
          context,
          '已添加 ${_selectedRecordIds.length} 条记录',
        );
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, '添加失败：$e');
      }
    }
  }

  /// 格式化日期
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// 获取地点文本
  String _getLocationText(EncounterRecord record) {
    if (record.location.placeName != null) {
      return record.location.placeName!;
    }
    if (record.location.address != null) {
      return record.location.address!;
    }
    if (record.location.placeType != null) {
      return record.location.placeType!.label;
    }
    return '未知地点';
  }
}

