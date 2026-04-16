import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/membership_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../models/story_line.dart';
import 'story_line_export_card.dart';

class StoryLinePageActions {
  const StoryLinePageActions._();

  static void handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
    String action,
  ) {
    switch (action) {
      case 'pin':
        togglePinStoryLine(context, ref, storyLine);
        break;
      case 'rename':
        showRenameDialog(context, ref, storyLine);
        break;
      case 'export':
        exportStoryLine(context, ref, storyLine);
        break;
      case 'delete':
        showDeleteConfirmDialog(context, ref, storyLine);
        break;
    }
  }

  static Future<void> exportStoryLine(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
  ) async {
    final membershipInfo = ref.read(membershipProvider).valueOrNull;
    if (membershipInfo == null || !membershipInfo.canExportStoryLineCard) {
      MessageHelper.showWarning(context, '导出故事线图文卡片是会员专属功能');
      return;
    }

    final allRecords = ref.read(recordsProvider).valueOrNull ?? [];
    final records = allRecords.where((r) => storyLine.recordIds.contains(r.id)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (records.isEmpty) {
      MessageHelper.showWarning(context, '故事线暂无记录，无法导出');
      return;
    }

    final success = await StoryLineExportCard.export(context, storyLine, records);
    if (!context.mounted) return;
    if (success) {
      MessageHelper.showSuccess(context, '已保存到相册');
    } else {
      MessageHelper.showError(context, '导出失败，请重试');
    }
  }

  static Future<void> togglePinStoryLine(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
  ) async {
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
        MessageHelper.showError(
          context,
          '操作失败：${AuthErrorHelper.extractErrorMessage(e)}',
        );
      }
    }
  }

  static void showCreateStoryLineDialog(BuildContext context, WidgetRef ref) {
    final membershipInfo = ref.read(membershipProvider).valueOrNull;
    if (membershipInfo == null) {
      MessageHelper.showWarning(context, '会员状态加载中，请稍后再试');
      return;
    }

    final currentCount = ref.read(storyLinesProvider).valueOrNull?.length ?? 0;
    final maxStoryLines = membershipInfo.maxStoryLines;
    if (maxStoryLines != null && currentCount >= maxStoryLines) {
      MessageHelper.showWarning(context, '免费版最多创建 $maxStoryLines 条故事线，请先升级会员');
      return;
    }

    final nameController = TextEditingController();

    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建故事线'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

              final authState = ref.read(authProvider);
              final currentUser = authState.value;
              final userId = currentUser?.id;

              final now = DateTime.now();
              final newStoryLine = StoryLine(
                id: const Uuid().v4(),
                name: name,
                recordIds: [],
                createdAt: now,
                updatedAt: now,
                userId: userId,
              );

              try {
                await ref.read(storyLinesProvider.notifier).createStoryLine(newStoryLine);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  MessageHelper.showSuccess(context, '故事线已创建');
                }
              } catch (e) {
                if (context.mounted) {
                  MessageHelper.showError(
                    context,
                    '创建失败：${AuthErrorHelper.extractErrorMessage(e)}',
                  );
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  static Future<void> showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
  ) async {
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
          MessageHelper.showError(
            context,
            '重命名失败：${AuthErrorHelper.extractErrorMessage(e)}',
          );
        }
      }
    }
  }

  static Future<void> showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
  ) async {
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
          MessageHelper.showError(
            context,
            '删除失败：${AuthErrorHelper.extractErrorMessage(e)}',
          );
        }
      }
    }
  }
}

