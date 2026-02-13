import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/utils/page_transition_builder.dart';
import '../../core/utils/message_helper.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/status_color_extension.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../record/record_detail_page.dart';

// 用于传递记录对象的 Provider
final selectedRecordProvider = StateProvider<EncounterRecord?>((ref) => null);

/// 时间轴页面（记录列表）
class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TA'),
        actions: [
          // 开发者调试按钮：双击清空所有记录
          GestureDetector(
            onDoubleTap: () => _showClearAllDialog(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Tooltip(
                message: '双击清空所有记录（开发调试）',
                child: Icon(
                  Icons.delete_sweep,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) => records.isEmpty
            ? _buildEmptyState(context)
            : _buildRecordList(context, records, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('加载失败：$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(recordsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
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
          const Text(
            '💫',
            style: TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有记录',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮开始记录',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 记录列表
  Widget _buildRecordList(BuildContext context, List<EncounterRecord> records, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(recordsProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return _buildRecordCard(context, record, ref);
        },
      ),
    );
  }

  /// 记录卡片
  Widget _buildRecordCard(BuildContext context, EncounterRecord record, WidgetRef ref) {
    // 使用主题自适应的状态颜色
    final statusColor = record.status.getColor(context, ref);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          // 读取用户设置的动画类型
          final transitionType = ref.read(pageTransitionProvider);
          
          // 使用 Navigator.push 以便传递动画类型
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return RecordDetailPage(record: record);
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return PageTransitionBuilder.buildTransition(
                  transitionType,
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                );
              },
            ),
          );
        },
        // 自定义悬停动画时长（更柔和）
        hoverDuration: const Duration(milliseconds: 300),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 状态和时间
              Row(
                children: [
                  Text(
                    record.status.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.status.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(record.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 地点
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.location.placeName ?? '未知地点',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // 描述（如果有）
              if (record.description != null && record.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  record.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // 标签（如果有）
              if (record.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: record.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  /// 显示清空所有记录的确认对话框（开发调试用）
  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 开发调试'),
        content: const Text(
          '确定要清空所有记录吗？\n\n'
          '此操作无法撤销！\n'
          '（此功能仅用于开发调试）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // 清空所有记录
                final storage = StorageService();
                await storage.clearAllRecords();
                
                // 刷新列表
                ref.refresh(recordsProvider);
                
                if (context.mounted) {
                  MessageHelper.showSuccess(context, '已清空所有记录');
                }
              } catch (e) {
                if (context.mounted) {
                  MessageHelper.showError(context, '清空失败：$e');
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('确定清空'),
          ),
        ],
      ),
    );
  }
}
