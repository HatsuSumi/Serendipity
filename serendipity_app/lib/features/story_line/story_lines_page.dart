import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/page_transition_builder.dart';
import '../../models/enums.dart';
import 'story_line_detail_page.dart';
import 'package:uuid/uuid.dart';
import '../../models/story_line.dart';

/// 故事线列表页面
class StoryLinesPage extends ConsumerWidget {
  const StoryLinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyLinesAsync = ref.watch(storyLinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的故事线'),
      ),
      body: storyLinesAsync.when(
        data: (storyLines) {
          if (storyLines.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(storyLinesProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: storyLines.length,
              itemBuilder: (context, index) {
                final storyLine = storyLines[index];
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
        onPressed: () => _showCreateStoryLineDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('创建故事线'),
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
            Icons.auto_stories_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有故事线',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮创建第一条故事线',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 故事线卡片
  Widget _buildStoryLineCard(BuildContext context, WidgetRef ref, StoryLine storyLine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          var transitionType = ref.read(pageTransitionProvider);
          if (transitionType == PageTransitionType.random) {
            transitionType = PageTransitionBuilder.getRandomType();
          }

          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return StoryLineDetailPage(storyLine: storyLine);
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
              transitionDuration: transitionType == PageTransitionType.none
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
            ),
          ).then((_) {
            // 从详情页返回后刷新列表
            ref.read(storyLinesProvider.notifier).refresh();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(BuildContext context, WidgetRef ref, StoryLine storyLine, String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context, ref, storyLine);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, ref, storyLine);
        break;
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
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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

              final now = DateTime.now();
              final newStoryLine = StoryLine(
                id: const Uuid().v4(),
                name: name,
                recordIds: [],
                createdAt: now,
                updatedAt: now,
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
  void _showRenameDialog(BuildContext context, WidgetRef ref, StoryLine storyLine) {
    final nameController = TextEditingController(text: storyLine.name);

    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名故事线'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '输入新名称...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
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

              final updatedStoryLine = storyLine.copyWith(
                name: name,
                updatedAt: DateTime.now(),
              );

              try {
                await ref.read(storyLinesProvider.notifier).updateStoryLine(updatedStoryLine);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  MessageHelper.showSuccess(context, '已重命名');
                }
              } catch (e) {
                if (context.mounted) {
                  MessageHelper.showError(context, '重命名失败：$e');
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, StoryLine storyLine) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除故事线'),
        content: Text('确定要删除"${storyLine.name}"吗？\n\n记录不会被删除，只是取消关联。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(storyLinesProvider.notifier).deleteStoryLine(storyLine.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  MessageHelper.showSuccess(context, '故事线已删除');
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
}

