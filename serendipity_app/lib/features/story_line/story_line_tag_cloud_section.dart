import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/story_line_statistics_provider.dart';
import '../statistics/widgets/tag_cloud_card.dart';

class StoryLineTagCloudSection extends ConsumerWidget {
  final String storyLineId;

  const StoryLineTagCloudSection({
    super.key,
    required this.storyLineId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(storyLineTagCloudProvider(storyLineId));

    if (!result.isVisible) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        TagCloudPanel(
          title: '故事线标签词云',
          emptyText: '这条故事线还没有可生成词云的标签',
          tagCloud: result.items,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

