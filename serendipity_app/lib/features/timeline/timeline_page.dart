import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/community_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/record_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/utils/check_in_animation_helper.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/theme/status_color_extension.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/encounter_record.dart';
import '../record/record_detail_page.dart';
import '../record/create_record_page.dart';
import '../story_line/link_to_story_line_dialog.dart';
import '../check_in/widgets/check_in_card.dart';

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
  
  // 是否打码敏感信息
  bool _isMasked = false;
  
  // 粒子效果控制器
  ConfettiController? _confettiController;
  
  @override
  void initState() {
    super.initState();
    _confettiController = CheckInAnimationHelper.createConfettiController();
  }
  
  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TA'),
        actions: [
          // 排序按钮
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
          // 更多菜单按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多',
            onSelected: (String value) {
              if (value == 'mask') {
                setState(() {
                  _isMasked = !_isMasked;
                });
                MessageHelper.showSuccess(
                  context,
                  _isMasked ? '已打码敏感信息' : '已显示原始信息',
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mask',
                child: Row(
                  children: [
                    Icon(_isMasked ? Icons.visibility : Icons.visibility_off),
                    const SizedBox(width: 8),
                    Text(_isMasked ? '显示原始信息' : '打码记录'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主内容
          recordsAsync.when(
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
          // 粒子效果（覆盖在整个页面最顶层）
          if (_confettiController != null)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: CheckInAnimationHelper.createConfettiWidget(
                  controller: _confettiController!,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 根据排序方式排序记录
  /// 
  /// 置顶记录始终在最前面，然后按照选择的排序方式排序
  List<EncounterRecord> _sortRecords(List<EncounterRecord> records) {
    final sorted = List<EncounterRecord>.from(records);
    
    // 先按照选择的排序方式排序
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
    
    // 置顶记录排在最前面（稳定排序）
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });
    
    return sorted;
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context) {
    return const EmptyStateWidget(
      icon: '💫',
      title: '还没有记录',
      description: '点击下方按钮开始记录',
    );
  }

  /// 记录列表
  Widget _buildRecordList(BuildContext context, List<EncounterRecord> records, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(recordsProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: records.length + 1, // +1 for check-in card
        itemBuilder: (context, index) {
          // 第一项显示签到卡片
          if (index == 0) {
            return CheckInCard(
              confettiController: _confettiController,
            );
          }
          
          // 其他项显示记录卡片
          final record = records[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildRecordCard(context, record, ref),
          );
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
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToRecordDetail(context, ref, record),
        // 自定义悬停动画时长（更柔和）
        hoverDuration: const Duration(milliseconds: 300),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 置顶图标（左上角）
            if (record.isPinned)
              Positioned(
                top: 8,
                left: 8,
                child: Icon(
                  Icons.push_pin,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            // 主要内容
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16), // 增加顶部 padding
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
                        '创建：${DateTimeHelper.formatRelativeTime(record.createdAt)}',
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
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(record.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                            const SizedBox(width: 8),
                            Text(record.isPinned ? '取消置顶' : '置顶'),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _isMasked ? _maskText(RecordHelper.getLocationText(record.location)) : RecordHelper.getLocationText(record.location),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // 描述（如果有）
              if (record.description != null && record.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _isMasked ? _maskText(record.description!) : record.description!,
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
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isMasked ? _maskText(tag.tag) : tag.tag,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  // 底部时间信息和故事线信息
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // 左侧：时间信息
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '发生：${DateTimeHelper.formatRelativeTime(record.timestamp)}',
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
                                '更新：${DateTimeHelper.formatRelativeTime(record.updatedAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 右侧：故事线信息
                      if (record.storyLineId != null)
                        _buildStoryLineInfo(context, ref, record.storyLineId!),
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

  /// 处理菜单操作
  void _handleMenuAction(BuildContext context, WidgetRef ref, EncounterRecord record, String action) {
    switch (action) {
      case 'edit':
        _navigateToEditRecord(context, ref, record);
        break;
      case 'pin':
        _togglePinRecord(context, ref, record);
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

  /// 切换置顶状态
  void _togglePinRecord(BuildContext context, WidgetRef ref, EncounterRecord record) async {
    try {
      await ref.read(recordsProvider.notifier).togglePin(record.id);
      if (context.mounted) {
        MessageHelper.showSuccess(
          context,
          record.isPinned ? '已取消置顶' : '已置顶',
        );
      }
    } catch (e) {
      if (context.mounted) {
        MessageHelper.showError(context, '操作失败：$e');
      }
    }
  }

  /// 导航到编辑记录页面
  void _navigateToEditRecord(BuildContext context, WidgetRef ref, EncounterRecord record) async {
    final result = await NavigationHelper.pushWithTransition(
      context,
      ref,
      CreateRecordPage(recordToEdit: record),
    );

    // 如果编辑成功，刷新列表
    if (result != null && mounted) {
      ref.invalidate(recordsProvider);
    }
  }

  /// 导航到记录详情页面（统一方法）
  void _navigateToRecordDetail(BuildContext context, WidgetRef ref, EncounterRecord record) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      RecordDetailPage(record: record),
    );
  }

  /// 显示关联到故事线对话框
  void _showLinkToStoryLineDialog(BuildContext context, WidgetRef ref, EncounterRecord record) {
    DialogHelper.show(
      context: context,
      builder: (context) => LinkToStoryLineDialog(recordId: record.id),
    );
  }

  /// 发布到社区
  /// 
  /// 调用者：_handleMenuAction()
  void _showPublishToCommunityDialog(BuildContext context, WidgetRef ref, EncounterRecord record) {
    AsyncActionHelper.execute(
      context,
      action: () async {
        final communityNotifier = ref.read(communityProvider.notifier);
        
        // 检查发布状态
        final statusMap = await communityNotifier.checkPublishStatus([record]);
        final status = statusMap[record.id] ?? 'can_publish';
        
        if (status == 'cannot_publish') {
          // 内容未变化，不允许发布
          throw Exception('该记录已发布且内容未变化');
        } else if (status == 'need_confirm') {
          // 需要用户确认
          if (!context.mounted) return;
          
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('发布确认'),
              content: const Text('该记录已发布到社区，重新发布会替换旧帖，是否继续？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('确认'),
                ),
              ],
            ),
          );
          
          if (confirmed != true) return;
          
          // 用户确认，强制替换
          await communityNotifier.publishPost(record, forceReplace: true);
        } else {
          // 可以直接发布
          await communityNotifier.publishPost(record);
        }
      },
      successMessage: '已发布到树洞',
      errorMessagePrefix: '发布失败',
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, EncounterRecord record) async {
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '删除记录',
      content: '确定要删除这条记录吗？此操作无法撤销。',
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(recordsProvider.notifier).deleteRecord(record.id);
        if (context.mounted) {
          MessageHelper.showSuccess(context, '记录已删除');
        }
      } catch (e) {
        if (context.mounted) {
          MessageHelper.showError(context, '删除失败：$e');
        }
      }
    }
  }

  /// 构建故事线信息组件
  Widget _buildStoryLineInfo(BuildContext context, WidgetRef ref, String storyLineId) {
    final storyLinesAsync = ref.watch(storyLinesProvider);
    
    return storyLinesAsync.when(
      data: (storyLines) {
        try {
          final storyLine = storyLines.firstWhere((sl) => sl.id == storyLineId);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                _isMasked ? _maskText(storyLine.name) : storyLine.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        } catch (e) {
          // 故事线不存在或已删除
          return const SizedBox.shrink();
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  /// 打码文本（将文本替换为星号）
  /// 
  /// 规则：
  /// - 保留文本长度，每个字符替换为 *
  /// - 中文字符、英文字符、数字、标点符号都替换为 *
  /// - 保留空格（用于区分单词）
  String _maskText(String text) {
    if (text.isEmpty) return text;
    
    return text.split('').map((char) {
      // 保留空格
      if (char == ' ') return ' ';
      // 其他字符替换为 *
      return '*';
    }).join();
  }
}
