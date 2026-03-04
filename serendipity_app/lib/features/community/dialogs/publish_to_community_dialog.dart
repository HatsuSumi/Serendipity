import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/encounter_record.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/utils/async_action_helper.dart';
import '../../../core/utils/record_helper.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/theme/status_color_extension.dart';
import '../../../core/widgets/empty_state_widget.dart';

/// 可发布到树洞的记录列表 Provider
/// 
/// 返回所有记录（按时间倒序）
/// 
/// 调用者：PublishToCommunityDialog
final publishableRecordsProvider = Provider<List<EncounterRecord>>((ref) {
  final recordsAsync = ref.watch(recordsProvider);
  
  // 如果数据还在加载中，返回空列表
  if (!recordsAsync.hasValue) {
    return [];
  }
  
  final allRecords = recordsAsync.value ?? [];
  
  // 按时间倒序排列
  final sorted = List<EncounterRecord>.from(allRecords);
  sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  
  return sorted;
});

/// 发布到树洞对话框
/// 
/// 职责：
/// - 显示可发布的记录列表
/// - 支持多选记录
/// - 批量发布到树洞
/// 
/// 调用者：CommunityPage（FloatingActionButton）
class PublishToCommunityDialog extends ConsumerStatefulWidget {
  const PublishToCommunityDialog({super.key});

  @override
  ConsumerState<PublishToCommunityDialog> createState() => _PublishToCommunityDialogState();
}

class _PublishToCommunityDialogState extends ConsumerState<PublishToCommunityDialog> {
  final Set<String> _selectedRecordIds = {};

  @override
  Widget build(BuildContext context) {
    // 使用 ref.watch() 自动响应数据变化
    final publishableRecords = ref.watch(publishableRecordsProvider);
    
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
                      '发布到树洞',
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
              child: publishableRecords.isEmpty
                  ? _buildEmptyState(context)
                  : _buildRecordList(context, publishableRecords),
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
                    child: Text('发布 (${_selectedRecordIds.length})'),
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
      icon: Icons.note_add,
      iconSize: 64,
      title: '还没有记录',
      description: '先创建一些记录吧',
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
  /// 
  /// 调用者：发布按钮的 onPressed
  /// 
  /// Fail Fast：
  /// - 如果未选择记录，按钮已禁用（不会调用此方法）
  /// - 如果用户未登录，publishPost 会抛出 StateError
  Future<void> _handleConfirm() async {
    // Fail Fast：未选择记录
    if (_selectedRecordIds.isEmpty) return;

    // 保存 context 引用
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    navigator.pop();
    
    await AsyncActionHelper.execute(
      context,
      action: () async {
        final communityNotifier = ref.read(communityProvider.notifier);
        final recordsAsync = ref.read(recordsProvider);
        final allRecords = recordsAsync.value ?? [];
        
        int replacedCount = 0;
        
        // 批量发布记录
        for (final recordId in _selectedRecordIds) {
          final record = allRecords.firstWhere(
            (r) => r.id == recordId,
            orElse: () => throw StateError('Record $recordId not found'),
          );
          
          final replaced = await communityNotifier.publishPost(record);
          if (replaced) {
            replacedCount++;
          }
        }
        
        // 根据是否有替换显示不同的成功消息
        if (replacedCount > 0) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('已发布 ${_selectedRecordIds.length} 条记录（其中 $replacedCount 条替换了旧帖）'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('已发布 ${_selectedRecordIds.length} 条记录'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      errorMessagePrefix: '发布失败',
    );
  }
}

