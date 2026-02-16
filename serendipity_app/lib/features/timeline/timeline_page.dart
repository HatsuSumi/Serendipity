import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/utils/page_transition_builder.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/theme/status_color_extension.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../record/record_detail_page.dart';
import '../story_line/link_to_story_line_dialog.dart';

// 用于传递记录对象的 Provider
final selectedRecordProvider = StateProvider<EncounterRecord?>((ref) => null);

/// 排序方式
enum RecordSortType {
  createdDesc('创建时间 ↓'),
  createdAsc('创建时间 ↑'),
  updatedDesc('更新时间 ↓'),
  updatedAsc('更新时间 ↑');

  final String label;
  const RecordSortType(this.label);
}

/// 时间轴页面（记录列表）
class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  // 当前排序方式（默认创建时间降序）
  RecordSortType _currentSort = RecordSortType.createdDesc;

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TA'),
        actions: [
          PopupMenuButton<RecordSortType>(
            icon: const Icon(Icons.sort),
            tooltip: '排序方式',
            onSelected: (RecordSortType type) {
              setState(() {
                _currentSort = type;
              });
            },
            itemBuilder: (context) => RecordSortType.values.map((type) {
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
      body: recordsAsync.when(
        data: (records) {
          // 根据当前排序方式排序
          final sortedRecords = _sortRecords(records);
          
          return sortedRecords.isEmpty
              ? _buildEmptyState(context)
              : _buildRecordList(context, sortedRecords, ref);
        },
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
              Text(
                '加载失败：$error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
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

  /// 根据排序方式排序记录
  List<EncounterRecord> _sortRecords(List<EncounterRecord> records) {
    final sorted = List<EncounterRecord>.from(records);
    
    switch (_currentSort) {
      case RecordSortType.createdDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case RecordSortType.createdAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case RecordSortType.updatedDesc:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case RecordSortType.updatedAsc:
        sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
    }
    
    return sorted;
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
          var transitionType = ref.read(pageTransitionProvider);
          
          // 如果是随机动画，在这里就决定使用哪个具体动画
          if (transitionType == PageTransitionType.random) {
            transitionType = PageTransitionBuilder.getRandomType();
          }
          
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
              // 状态和创建时间
              Row(
                children: [
                  Text(
                    record.status.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.status.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    '创建：${_formatTime(record.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  // 更多菜单
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleMenuAction(context, ref, record, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'link',
                        child: Row(
                          children: [
                            Icon(Icons.auto_stories_outlined),
                            SizedBox(width: 8),
                            Text('关联到故事线'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'publish',
                        child: Row(
                          children: [
                            Icon(Icons.cloud_outlined),
                            SizedBox(width: 8),
                            Text('发布到社区'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
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
              
              // 底部时间信息
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '发生：${_formatTime(record.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (record.createdAt != record.updatedAt) ...[
                    Text(
                      ' | ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      '更新：${_formatTime(record.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(BuildContext context, WidgetRef ref, EncounterRecord record, String action) {
    switch (action) {
      case 'edit':
        _navigateToEditRecord(context, ref, record);
        break;
      case 'link':
        _showLinkToStoryLineDialog(context, ref, record);
        break;
      case 'publish':
        _showPublishToCommunityDialog(context, ref, record);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, ref, record);
        break;
    }
  }

  /// 导航到编辑记录页面
  void _navigateToEditRecord(BuildContext context, WidgetRef ref, EncounterRecord record) {
    var transitionType = ref.read(pageTransitionProvider);
    if (transitionType == PageTransitionType.random) {
      transitionType = PageTransitionBuilder.getRandomType();
    }

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
  }

  /// 显示关联到故事线对话框
  void _showLinkToStoryLineDialog(BuildContext context, WidgetRef ref, EncounterRecord record) {
    DialogHelper.show(
      context: context,
      builder: (context) => LinkToStoryLineDialog(recordId: record.id),
    );
  }

  /// 显示发布到社区对话框
  void _showPublishToCommunityDialog(BuildContext context, WidgetRef ref, EncounterRecord record) {
    // TODO: 实现发布到社区功能
    MessageHelper.showWarning(context, '社区功能开发中，敬请期待');
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, EncounterRecord record) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(recordsProvider.notifier).deleteRecord(record.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  MessageHelper.showSuccess(context, '记录已删除');
                }
              } catch (e) {
                if (context.mounted) {
                  MessageHelper.showError(context, '删除失败：$e');
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    
    // 比较日期（忽略时间）
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDifference = today.difference(recordDate).inDays;

    if (daysDifference == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (daysDifference == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (daysDifference < 7) {
      return '$daysDifference天前';
    } else {
      return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}
