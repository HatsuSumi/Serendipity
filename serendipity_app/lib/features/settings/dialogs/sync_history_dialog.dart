import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../models/sync_history.dart';

/// 同步历史对话框
/// 
/// 职责：
/// - 显示历史同步记录列表
/// - 按时间倒序展示
/// - 区分手动同步和自动同步
/// - 显示同步结果统计和耗时
/// 
/// 调用者：
/// - SettingsPage：点击"同步历史"按钮
/// 
/// 遵循原则：
/// - 单一职责（SRP）：只负责展示同步历史
/// - 依赖倒置（DIP）：通过 Provider 获取依赖
/// - 用户体验优先：空状态、加载状态都有友好提示
class SyncHistoryDialog extends ConsumerWidget {
  const SyncHistoryDialog({super.key});

  /// 显示同步历史对话框
  /// 
  /// 调用者：SettingsPage
  /// 
  /// Fail Fast：
  /// - context 为 null：由 Dart 类型系统保证
  static Future<void> show(BuildContext context) async {
    return DialogHelper.show<void>(
      context: context,
      builder: (context) => const SyncHistoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取存储服务
    final storage = ref.read(storageServiceProvider);
    
    // 监听同步完成信号，自动刷新
    ref.watch(syncCompletedProvider);
    
    // 获取所有同步历史记录
    final histories = storage.getAllSyncHistories();
    
    return AlertDialog(
      title: const Text('同步历史'),
      content: SizedBox(
        width: double.maxFinite,
        child: histories.isEmpty
            ? _buildEmptyState(context)
            : _buildHistoryList(context, histories),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  /// 构建空状态
  /// 
  /// 调用者：build()
  /// 
  /// 遵循原则：
  /// - 用户体验优先：友好的空状态提示
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无同步记录',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '执行同步后将显示历史记录',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建历史记录列表
  /// 
  /// 调用者：build()
  /// 
  /// 遵循原则：
  /// - 性能优化：使用 ListView.builder
  /// - 用户体验：按时间分组（今天、昨天、更早）
  Widget _buildHistoryList(BuildContext context, List<SyncHistory> histories) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: histories.length,
      itemBuilder: (context, index) {
        final history = histories[index];
        final showDateHeader = _shouldShowDateHeader(histories, index);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期分组头部
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  _getDateHeaderText(history.syncTime),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            
            // 同步记录项
            _buildHistoryItem(context, history),
          ],
        );
      },
    );
  }

  /// 判断是否显示日期分组头部
  /// 
  /// 调用者：_buildHistoryList()
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责判断逻辑
  /// - DRY：复用 DateTimeHelper
  bool _shouldShowDateHeader(List<SyncHistory> histories, int index) {
    if (index == 0) return true;
    
    final current = histories[index].syncTime;
    final previous = histories[index - 1].syncTime;
    
    final currentDate = DateTime(current.year, current.month, current.day);
    final previousDate = DateTime(previous.year, previous.month, previous.day);
    
    return currentDate != previousDate;
  }

  /// 获取日期分组头部文本
  /// 
  /// 调用者：_buildHistoryList()
  /// 
  /// 遵循原则：
  /// - DRY：复用现有逻辑
  String _getDateHeaderText(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDifference = today.difference(targetDate).inDays;

    if (daysDifference == 0) {
      return '今天';
    } else if (daysDifference == 1) {
      return '昨天';
    } else if (daysDifference < 7) {
      return '$daysDifference天前';
    } else {
      return DateTimeHelper.formatShortDate(dateTime);
    }
  }

  /// 构建单条历史记录
  /// 
  /// 调用者：_buildHistoryList()
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责构建单条记录的 UI
  /// - 用户体验：成功/失败用不同颜色区分
  Widget _buildHistoryItem(BuildContext context, SyncHistory history) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：时间 + 类型 + 状态
            Row(
              children: [
                // 时间
                Text(
                  '${history.syncTime.hour.toString().padLeft(2, '0')}:${history.syncTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                
                // 类型标签（显示来源）
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: history.isManual
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    history.sourceDescription,
                    style: TextStyle(
                      fontSize: 10,
                      color: history.isManual
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                
                // 状态图标 + 耗时
                Row(
                  children: [
                    Icon(
                      history.success ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: history.success
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      history.formattedDuration,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 内容：成功显示统计，失败显示错误信息
            if (history.success) ...[
              if (history.hasChanges) ...[
                // 上传统计
                if (history.uploadedRecords > 0 ||
                    history.uploadedStoryLines > 0 ||
                    history.uploadedCheckIns > 0)
                  _buildStatRow(
                    context,
                    icon: Icons.cloud_upload_outlined,
                    label: '上传',
                    records: history.uploadedRecords,
                    storyLines: history.uploadedStoryLines,
                    checkIns: history.uploadedCheckIns,
                  ),
                
                // 下载统计
                if (history.downloadedRecords > 0 ||
                    history.downloadedStoryLines > 0 ||
                    history.downloadedCheckIns > 0)
                  _buildStatRow(
                    context,
                    icon: Icons.cloud_download_outlined,
                    label: '下载',
                    records: history.downloadedRecords,
                    storyLines: history.downloadedStoryLines,
                    checkIns: history.downloadedCheckIns,
                  ),
                
                // 冲突合并统计
                if (history.mergedRecords > 0 ||
                    history.mergedStoryLines > 0 ||
                    history.mergedCheckIns > 0)
                  _buildStatRow(
                    context,
                    icon: Icons.merge_outlined,
                    label: '合并',
                    records: history.mergedRecords,
                    storyLines: history.mergedStoryLines,
                    checkIns: history.mergedCheckIns,
                    isWarning: true,
                  ),
              ] else ...[
                Text(
                  '无数据变化',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ] else ...[
              // 失败：显示错误信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      history.errorMessage ?? '未知错误',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建统计行
  /// 
  /// 调用者：_buildHistoryItem()
  /// 
  /// 遵循原则：
  /// - DRY：复用 manual_sync_dialog.dart 的逻辑
  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int records,
    required int storyLines,
    required int checkIns,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isWarning
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$label：',
            style: const TextStyle(fontSize: 12),
          ),
          Expanded(
            child: Text(
              '$records条记录、$storyLines条故事线、$checkIns条签到',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

