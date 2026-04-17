import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/records_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import 'story_line_detail_page_actions.dart';
import 'widgets/story_line_detail_content.dart';

/// 故事线详情页面
class StoryLineDetailPage extends ConsumerWidget {
  final String storyLineId;

  const StoryLineDetailPage({
    super.key,
    required this.storyLineId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 ref.watch() 自动响应数据变化
    final storyLinesAsync = ref.watch(storyLinesProvider);
    final recordsAsync = ref.watch(storyLineRecordsProvider(storyLineId));

    return storyLinesAsync.when(
      data: (storyLines) {
        // 查找当前故事线
        final storyLine = storyLines.firstWhere(
          (sl) => sl.id == storyLineId,
          orElse: () => throw StateError('Story line $storyLineId not found'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(storyLine.name),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => StoryLineDetailPageActions.handleMenuAction(
                  context,
                  ref,
                  storyLine,
                  value,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_existing',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add),
                        SizedBox(width: 8),
                        Text('添加现有记录'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined),
                        SizedBox(width: 8),
                        Text('导出为图文卡片'),
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
          body: StoryLineDetailContent(
            storyLineId: storyLineId,
            storyLine: storyLine,
            records: recordsAsync,
            onRefresh: () async {
              await Future.wait([
                ref.read(storyLinesProvider.notifier).refresh(),
                ref.read(recordsProvider.notifier).refresh(),
              ]);
            },
            onRecordTap: (record) {
              StoryLineDetailPageActions.navigateToRecordDetail(
                context,
                ref,
                record,
              );
            },
            onRecordMenuSelected: (record, action) {
              StoryLineDetailPageActions.handleRecordMenuAction(
                context,
                ref,
                record,
                storyLine,
                action,
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => StoryLineDetailPageActions.navigateToCreateRecord(
              context,
              ref,
              storyLine,
            ),
            icon: const Icon(Icons.add),
            label: const Text('添加新的进展'),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('故事线详情')),
        body: Center(
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
                '加载失败：$error',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
