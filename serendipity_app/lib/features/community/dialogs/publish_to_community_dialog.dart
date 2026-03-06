import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/encounter_record.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/utils/dialog_helper.dart';
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
  /// Fail Fast：
  /// - 如果未选择记录，按钮已禁用（不会调用此方法）
  /// - 如果用户未登录，publishPost 会抛出 StateError
  Future<void> _handleConfirm() async {
    // Fail Fast：未选择记录
    if (_selectedRecordIds.isEmpty) return;

    // 步骤1：检查发布状态
    final recordInfos = await _checkPublishStatusForSelectedRecords();
    if (recordInfos == null) return; // 检查失败或用户已离开页面
    
    // 步骤2：显示确认对话框
    final confirmed = await _showPublishConfirmDialog(recordInfos);
    if (!confirmed) return;
    
    // 步骤3：保存父页面的 context（在关闭对话框之前）
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // 步骤4：关闭选择对话框
    navigator.pop();
    
    // 步骤5：执行发布（使用 ScaffoldMessenger 显示消息）
    await _executePublish(recordInfos, scaffoldMessenger);
  }

  /// 检查选中记录的发布状态
  /// 
  /// 返回：记录发布信息列表，如果检查失败或用户已离开页面则返回 null
  Future<List<RecordPublishInfo>?> _checkPublishStatusForSelectedRecords() async {
    final communityNotifier = ref.read(communityProvider.notifier);
    final recordsAsync = ref.read(recordsProvider);
    final allRecords = recordsAsync.value ?? [];
    
    // 获取选中的记录
    final selectedRecords = _selectedRecordIds
        .map((id) => allRecords.firstWhere(
              (r) => r.id == id,
              orElse: () => throw StateError('Record $id not found'),
            ))
        .toList();
    
    // 检查发布状态
    Map<String, String> statusMap;
    try {
      statusMap = await communityNotifier.checkPublishStatus(selectedRecords);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('检查发布状态失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
    
    // 按状态分组
    return _groupRecordsByPublishStatus(selectedRecords, statusMap);
  }

  /// 按发布状态分组记录
  /// 
  /// 参数：
  /// - selectedRecords: 选中的记录列表
  /// - statusMap: 记录ID到发布状态的映射
  /// 
  /// 返回：记录发布信息列表
  List<RecordPublishInfo> _groupRecordsByPublishStatus(
    List<EncounterRecord> selectedRecords,
    Map<String, String> statusMap,
  ) {
    return selectedRecords.map((record) {
      final status = statusMap[record.id] ?? 'can_publish';
      PublishStatus publishStatus;
      
      switch (status) {
        case 'can_publish':
          publishStatus = PublishStatus.canPublish;
          break;
        case 'need_confirm':
          publishStatus = PublishStatus.needConfirm;
          break;
        case 'cannot_publish':
          publishStatus = PublishStatus.cannotPublish;
          break;
        default:
          publishStatus = PublishStatus.canPublish;
      }
      
      return RecordPublishInfo(record: record, status: publishStatus);
    }).toList();
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

  /// 执行批量发布
  /// 
  /// 参数：
  /// - recordInfos: 记录发布信息列表
  /// - scaffoldMessenger: ScaffoldMessenger（用于显示成功消息）
  /// 
  /// 优化说明：
  /// - 使用 ScaffoldMessenger 显示成功消息，避免对话框关闭后 context 失效
  Future<void> _executePublish(List<RecordPublishInfo> recordInfos, ScaffoldMessengerState scaffoldMessenger) async {
    try {
      final communityNotifier = ref.read(communityProvider.notifier);
      
      // 准备批量发布的数据
      final publishItems = recordInfos
          .where((info) => info.status != PublishStatus.cannotPublish)
          .map((info) => (
                record: info.record,
                forceReplace: info.status == PublishStatus.needConfirm,
              ))
          .toList();

      // 批量发布（只刷新一次）
      final result = await communityNotifier.publishPosts(publishItems);

      // 显示成功消息
      _showPublishSuccessMessage(result.successCount, result.replacedCount, scaffoldMessenger);
    } catch (e) {
      // 显示错误消息
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('发布失败：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示发布成功消息
  /// 
  /// 参数：
  /// - successCount: 成功发布的数量
  /// - replacedCount: 替换旧帖的数量
  /// - scaffoldMessenger: ScaffoldMessenger
  void _showPublishSuccessMessage(int successCount, int replacedCount, ScaffoldMessengerState scaffoldMessenger) {
    if (successCount > 0) {
      final message = replacedCount > 0
          ? '已发布 $successCount 条记录（其中 $replacedCount 条替换了旧帖）'
          : '已发布 $successCount 条记录';
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

