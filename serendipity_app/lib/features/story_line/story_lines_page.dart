import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/membership_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/utils/navigation_helper.dart';
import '../../features/membership/membership_page.dart';
import 'story_line_detail_page.dart';
import 'story_line_page_actions.dart';
import 'story_line_sort.dart';
import 'widgets/story_line_card.dart';
import 'widgets/story_line_list_states.dart';

/// 故事线列表页面
class StoryLinesPage extends ConsumerStatefulWidget {
  const StoryLinesPage({super.key});

  @override
  ConsumerState<StoryLinesPage> createState() => _StoryLinesPageState();
}

class _StoryLinesPageState extends ConsumerState<StoryLinesPage> {
  StoryLineSortType _currentSort = StoryLineSortType.updatedDesc;

  @override
  Widget build(BuildContext context) {
    final storyLinesAsync = ref.watch(storyLinesProvider);
    final countAsync = ref.watch(storyLinesCountProvider);
    final membershipInfo = ref.watch(membershipProvider).valueOrNull;
    final maxStoryLines = membershipInfo?.maxStoryLines;

    return Scaffold(
      appBar: AppBar(
        title: countAsync.when(
          data: (count) => Text('我的故事线 (共$count条)'),
          loading: () => const Text('我的故事线'),
          error: (_, errorStack) => const Text('我的故事线'),
        ),
        actions: [
          if (maxStoryLines != null)
            IconButton(
              tooltip: '升级会员',
              onPressed: () {
                NavigationHelper.pushWithTransition(
                  context,
                  ref,
                  const MembershipPage(),
                );
              },
              icon: const Icon(Icons.workspace_premium_outlined),
            ),
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
            return const StoryLineEmptyState();
          }

          final sortedStoryLines = sortStoryLines(storyLines, _currentSort);

          return Column(
            children: [
              if (maxStoryLines != null)
                StoryLineMembershipLimitBanner(
                  count: storyLines.length,
                  maxCount: maxStoryLines,
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(storyLinesProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedStoryLines.length,
                    itemBuilder: (context, index) {
                      final storyLine = sortedStoryLines[index];
                      return StoryLineCard(
                        storyLine: storyLine,
                        onTap: () {
                          NavigationHelper.pushWithTransition(
                            context,
                            ref,
                            StoryLineDetailPage(storyLineId: storyLine.id),
                          ).then((_) {
                            ref.read(storyLinesProvider.notifier).refresh();
                          });
                        },
                        onMenuSelected: (value) {
                          StoryLinePageActions.handleMenuAction(
                            context,
                            ref,
                            storyLine,
                            value,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => StoryLineErrorView(error: error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_story_line_fab',
        onPressed: () => StoryLinePageActions.showCreateStoryLineDialog(
          context,
          ref,
        ),
        icon: const Icon(Icons.add),
        label: const Text('创建故事线'),
      ),
    );
  }
}
