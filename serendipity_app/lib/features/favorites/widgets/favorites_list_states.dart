import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state_widget.dart';

class FavoriteRecordsEmptyState extends StatelessWidget {
  const FavoriteRecordsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.bookmark_border,
      title: '还没有收藏的记录',
      description: '在记录列表长按记录卡片可以收藏',
    );
  }
}

class FavoritePostsEmptyState extends StatelessWidget {
  const FavoritePostsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.bookmark_border,
      title: '你还没有收藏过任何人的故事',
      description: '也许是因为\n没有哪个故事\n让你觉得——\n\n这说的是我。',
    );
  }
}

