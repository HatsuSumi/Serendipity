import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/encounter_record.dart';
import '../../../core/providers/community_publish_provider.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/utils/async_action_helper.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/utils/record_helper.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/theme/status_color_extension.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'publish_confirm_dialog.dart';
import 'publish_warning_dialog.dart';

/// 可发布到树洞的记录列表 Provider
/// 
/// 返回所有记录（按时间倒序）
/// 
/// 调用者：PublishToCommunityDialog
/// 
/// 性能优化：
/// - 避免不必要的列表复制和排序
/// - 如果原列表已排序，直接返回
final publishableRecordsProvider = Provider<List<EncounterRecord>>((ref) {
  final recordsAsync = ref.watch(recordsProvider);
  
  // 如果数据还在加载中，返回空列表
  if (!recordsAsync.hasValue) {
    return [];
  }
  
  final allRecords = recordsAsync.value ?? [];
  
  // 性能优化：避免不必要的复制和排序
  // 如果列表为空或只有一个元素，直接返回
  if (allRecords.length <= 1) {
    return allRecords;
  }
  
  // 检查是否已经按时间倒序排列
  bool isAlreadySorted = true;
  for (int i = 0; i < allRecords.length - 1; i++) {
    if (allRecords[i].timestamp.isBefore(allRecords[i + 1].timestamp)) {
      isAlreadySorted = false;
      break;
    }
  }
  
  // 如果已排序，直接返回原列表（避免复制）
  if (isAlreadySorted) {
    return allRecords;
  }
  
  // 否则，复制并排序
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
                    onPressed: _selectedRecordIds.isEmpty ? null : _showWarningBeforePublish,
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
  /// 
  /// 性能优化：
  /// - 添加 itemExtent 固定高度，提升滚动性能
  /// - 减少布局计算开销
  Widget _buildRecordList(BuildContext context, List<EncounterRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: records.length,
      itemExtent: 80.0, // 性能优化：固定记录项高度（Checkbox + 2行文本）
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

  /// 显示警告对话框
  /// 
  /// 调用者：发布按钮的 onPressed
  Future<void> _showWarningBeforePublish() async {
    final shouldPublish = await PublishWarningDialog.show(context, ref);
    
    if (shouldPublish) {
      await _handleConfirm();
    }
  }

  /// 处理确认
  /// 
  /// 调用者：PublishWarningDialog.onConfirm
  /// 
  /// 优化说明：
  /// - 业务逻辑封装在 Provider 层
  /// - UI 层只负责展示和交互
  /// - 符合分层架构原则
  /// 
  /// Fail Fast：
  /// - 如果未选择记录，按钮已禁用（不会调用此方法）
  /// - 如果用户未登录，Provider 会抛出 Exception
  Future<void> _handleConfirm() async {
    // Fail Fast：未选择记录
    if (_selectedRecordIds.isEmpty) return;

    // 获取选中的记录
    final selectedRecords = _getSelectedRecords();
    if (selectedRecords.isEmpty) return;

    await AsyncActionHelper.execute(
      context,
      action: () async {
        final publishNotifier = ref.read(communityPublishProvider.notifier);

        // 步骤1：准备发布（Provider 层封装）
        final recordInfos = await publishNotifier.preparePublish(selectedRecords);

        // 步骤2：显示确认对话框（UI 层）
        if (!mounted) return;
        final confirmed = await _showPublishConfirmDialog(recordInfos);
        if (!confirmed) return;

        // 步骤3：执行发布（Provider 层封装）
        final result = await publishNotifier.executePublish(recordInfos);

        // 步骤4：显示成功消息（UI 层）
        if (mounted) {
          _showPublishSuccessMessage(result.successCount, result.replacedCount);
          Navigator.of(context).pop();
        }
      },
      errorMessagePrefix: '发布失败',
    );
  }

  /// 获取选中的记录
  /// 
  /// 返回：选中的记录列表
  List<EncounterRecord> _getSelectedRecords() {
    final recordsAsync = ref.read(recordsProvider);
    final allRecords = recordsAsync.value ?? [];

    return _selectedRecordIds
        .map((id) => allRecords.firstWhere(
              (r) => r.id == id,
              orElse: () => throw StateError('Record $id not found'),
            ))
        .toList();
  }

  /// 显示发布确认对话框
  /// 
  /// 返回：用户是否确认发布
  Future<bool> _showPublishConfirmDialog(List<RecordPublishInfo> recordInfos) async {
    if (!mounted) return false;

    final confirmed = await DialogHelper.show<bool>(
      context: context,
      builder: (context) => PublishConfirmDialog(records: recordInfos),
    );

    return confirmed ?? false;
  }

  /// 显示发布成功消息
  /// 
  /// 参数：
  /// - successCount: 成功发布的数量
  /// - replacedCount: 替换旧帖的数量
  void _showPublishSuccessMessage(int successCount, int replacedCount) {
    if (successCount > 0) {
      if (replacedCount > 0) {
        MessageHelper.showSuccess(
          context,
          '已发布 $successCount 条记录（其中 $replacedCount 条替换了旧帖）',
        );
      } else {
        MessageHelper.showSuccess(
          context,
          '已发布 $successCount 条记录',
        );
      }
    }
  }
}

