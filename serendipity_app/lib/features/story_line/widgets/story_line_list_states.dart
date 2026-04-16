import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state_widget.dart';

class StoryLineEmptyState extends StatelessWidget {
  const StoryLineEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.auto_stories_outlined,
      title: '还没有故事线',
      description: '点击下方按钮创建第一条故事线',
    );
  }
}

class StoryLineMembershipLimitBanner extends StatelessWidget {
  final int count;
  final int maxCount;

  const StoryLineMembershipLimitBanner({
    super.key,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = maxCount - count;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              remaining > 0
                  ? '免费版最多可创建 $maxCount 条故事线，当前还可创建 $remaining 条。'
                  : '免费版最多可创建 $maxCount 条故事线，已达到上限。',
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class StoryLineErrorView extends StatelessWidget {
  final Object error;

  const StoryLineErrorView({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('加载失败', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

