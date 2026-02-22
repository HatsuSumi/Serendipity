import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/record_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/theme/status_color_extension.dart';
import '../../core/widgets/empty_state_widget.dart';

/// 可用记录列表 Provider
/// 
/// 根据故事线ID获取未关联到该故事线的记录
final availableRecordsProvider = Provider.family<List<EncounterRecord>, String>((ref, storyLineId) {
  final recordsAsync = ref.watch(recordsProvider);
  final storyLinesAsync = ref.watch(storyLinesProvider);
  
  // 如果数据还在加载中，返回空列表
  if (!recordsAsync.hasValue || !storyLinesAsync.hasValue) {
    return [];
  }
  
  final allRecords = recordsAsync.value ?? [];
  final storyLine = storyLinesAsync.value?.firstWhere(
    (sl) => sl.id == storyLineId,
    orElse: () => throw StateError('Story line $storyLineId not found'),
  );
  
  if (storyLine == null) {
    return [];
  }
  
  // 筛选出未关联到该故事线的记录
  final available = allRecords.where((record) {
    return !storyLine.recordIds.contains(record.id);
  }).toList();
  
  // 按时间倒序排列
  available.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  
  return available;
});

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

  @override
  Widget build(BuildContext context) {
    // 使用 ref.watch() 自动响应数据变化
    final availableRecords = ref.watch(availableRecordsProvider(widget.storyLine.id));
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
              child: availableRecords.isEmpty
                  ? _buildEmptyState(context)
                  : _buildRecordList(context, availableRecords),
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
    return const EmptyStateWidget(
      icon: Icons.check_circle_outline,
      iconSize: 64,
      title: '所有记录都已添加',
      description: '没有可添加的记录了',
    );
  }

  /// 记录列表
  Widget _buildRecordList(BuildContext context, List<EncounterRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
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
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
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
                        DateTimeHelper.formatShortDate(record.timestamp),
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
                          RecordHelper.getLocationText(record.location),
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

    Navigator.of(context).pop();
    
    await AsyncActionHelper.execute(
      context,
      action: () async {
        final storyLinesNotifier = ref.read(storyLinesProvider.notifier);
        
        // 批量关联记录
        for (final recordId in _selectedRecordIds) {
          await storyLinesNotifier.linkRecord(recordId, widget.storyLine.id);
        }
      },
      successMessage: '已添加 ${_selectedRecordIds.length} 条记录',
      errorMessagePrefix: '添加失败',
    );
  }
}

