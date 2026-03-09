import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import 'story_line_detail_page.dart';
import 'package:uuid/uuid.dart';
import '../../models/story_line.dart';

/// 排序方式
enum StoryLineSortType {
  createdDesc('创建时间 ↓'),
  createdAsc('创建时间 ↑'),
  updatedDesc('更新时间 ↓'),
  updatedAsc('更新时间 ↑'),
  nameAsc('名称 A-Z'),
  nameDesc('名称 Z-A');

  final String label;
  const StoryLineSortType(this.label);
}

/// 故事线列表页面
class StoryLinesPage extends ConsumerStatefulWidget {
  const StoryLinesPage({super.key});

  @override
  ConsumerState<StoryLinesPage> createState() => _StoryLinesPageState();
}

class _StoryLinesPageState extends ConsumerState<StoryLinesPage> {
  // 当前排序方式（默认更新时间降序）
  StoryLineSortType _currentSort = StoryLineSortType.updatedDesc;

  @override
  Widget build(BuildContext context) {
    final storyLinesAsync = ref.watch(storyLinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的故事线'),
        actions: [
          PopupMenuButton<StoryLineSortType>(
            icon: const Icon(Icons.sort),
            tooltip: '排序方式',
            onSelected: (StoryLineSortType type) {
              setState(() {
                _currentSort = type;
              });
            },
            itemBuilder: (context) => StoryLineSortType.values.map((type) {
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
      body: storyLinesAsync.when(
        data: (storyLines) {
          if (storyLines.isEmpty) {
            return _buildEmptyState(context);
          }

          // 排序：置顶的在前面
          final sortedStoryLines = _sortStoryLines(storyLines);

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(storyLinesProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedStoryLines.length,
              itemBuilder: (context, index) {
                final storyLine = sortedStoryLines[index];
                return _buildStoryLineCard(context, ref, storyLine);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_story_line_fab',
        onPressed: () => _showCreateStoryLineDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('创建故事线'),
      ),
    );
  }

  /// 根据排序方式排序故事线
  /// 
  /// 置顶故事线始终在最前面，然后按照选择的排序方式排序
  List<StoryLine> _sortStoryLines(List<StoryLine> storyLines) {
    final sorted = List<StoryLine>.from(storyLines);
    
    // 先按照选择的排序方式排序
    switch (_currentSort) {
      case StoryLineSortType.createdDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case StoryLineSortType.createdAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case StoryLineSortType.updatedDesc:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case StoryLineSortType.updatedAsc:
        sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case StoryLineSortType.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case StoryLineSortType.nameDesc:
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
    }
    
    // 置顶的排在最前面（稳定排序）
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
      icon: Icons.auto_stories_outlined,
      title: '还没有故事线',
      description: '点击下方按钮创建第一条故事线',
    );
  }

  /// 故事线卡片
  Widget _buildStoryLineCard(BuildContext context, WidgetRef ref, StoryLine storyLine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          NavigationHelper.pushWithTransition(
            context,
            ref,
            StoryLineDetailPage(storyLineId: storyLine.id),
          ).then((_) {
            // 从详情页返回后刷新列表
            ref.read(storyLinesProvider.notifier).refresh();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 置顶图标（左上角）
            if (storyLine.isPinned)
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
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text(
                        '📖',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storyLine.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${storyLine.recordIds.length} 条记录',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // 更多按钮
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleMenuAction(context, ref, storyLine, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(storyLine.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                            const SizedBox(width: 8),
                            Text(storyLine.isPinned ? '取消置顶' : '置顶'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('重命名'),
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
            ),
          ],
        ),
      ),
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(BuildContext context, WidgetRef ref, StoryLine storyLine, String action) {
    switch (action) {
      case 'pin':
        _togglePinStoryLine(context, ref, storyLine);
        break;
      case 'rename':
        _showRenameDialog(context, ref, storyLine);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, ref, storyLine);
        break;
    }
  }

  /// 切换置顶状态
  void _togglePinStoryLine(BuildContext context, WidgetRef ref, StoryLine storyLine) async {
    try {
      await ref.read(storyLinesProvider.notifier).togglePin(storyLine.id);
      if (context.mounted) {
        MessageHelper.showSuccess(
          context,
          storyLine.isPinned ? '已取消置顶' : '已置顶',
        );
      }
    } catch (e) {
      if (context.mounted) {
        MessageHelper.showError(context, '操作失败：$e');
      }
    }
  }

  /// 显示创建故事线对话框
  void _showCreateStoryLineDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建故事线'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '将同一个人的多次记录关联到一个故事线，形成完整的时间线故事。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 输入框
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: '输入故事线名称...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                MessageHelper.showWarning(context, '请输入故事线名称');
                return;
              }

              // 获取当前用户ID（用于数据归属）
              final authState = ref.read(authProvider);
              final currentUser = authState.value;
              final ownerId = currentUser?.id; // 未登录时为 null（离线数据）

              final now = DateTime.now();
              final newStoryLine = StoryLine(
                id: const Uuid().v4(),
                name: name,
                recordIds: [],
                createdAt: now,
                updatedAt: now,
                ownerId: ownerId,
              );

              try {
                await ref.read(storyLinesProvider.notifier).createStoryLine(newStoryLine);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  MessageHelper.showSuccess(context, '故事线已创建');
                }
              } catch (e) {
                if (context.mounted) {
                  MessageHelper.showError(context, '创建失败：$e');
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  /// 显示重命名对话框
  void _showRenameDialog(BuildContext context, WidgetRef ref, StoryLine storyLine) async {
    final newName = await DialogHelper.showRenameDialog(
      context: context,
      title: '重命名故事线',
      initialValue: storyLine.name,
      hintText: '输入新名称...',
      emptyWarning: '请输入故事线名称',
    );

    if (newName != null && context.mounted) {
      final updatedStoryLine = storyLine.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );

      try {
        await ref.read(storyLinesProvider.notifier).updateStoryLine(updatedStoryLine);
        if (context.mounted) {
          MessageHelper.showSuccess(context, '已重命名');
        }
      } catch (e) {
        if (context.mounted) {
          MessageHelper.showError(context, '重命名失败：$e');
        }
      }
    }
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, StoryLine storyLine) async {
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '删除故事线',
      content: '确定要删除"${storyLine.name}"吗？\n\n记录不会被删除，只是取消关联。',
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(storyLinesProvider.notifier).deleteStoryLine(storyLine.id);
        if (context.mounted) {
          MessageHelper.showSuccess(context, '故事线已删除');
        }
      } catch (e) {
        if (context.mounted) {
          MessageHelper.showError(context, '删除失败：$e');
        }
      }
    }
  }
}

