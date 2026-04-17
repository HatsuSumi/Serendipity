import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/favorites_provider.dart';

class FavoritesPageTabs extends StatelessWidget {
  final TabController controller;
  final AsyncValue<FavoritesState> favoritesAsync;

  const FavoritesPageTabs({
    super.key,
    required this.controller,
    required this.favoritesAsync,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: favoritesAsync.when(
        data: (favoritesState) {
          final recordCount = favoritesState.favoritedRecords.length +
              favoritesState.deletedFavoritedRecords.length;
          final postCount = favoritesState.favoritedPosts.length +
              favoritesState.deletedFavoritedPosts.length;
          return [
            Tab(icon: const Icon(Icons.notes), text: '收藏的记录（共$recordCount条）'),
            Tab(
              icon: const Icon(Icons.people_outline),
              text: '收藏的帖子（共$postCount条）',
            ),
          ];
        },
        loading: () => const [
          Tab(icon: Icon(Icons.notes), text: '收藏的记录'),
          Tab(icon: Icon(Icons.people_outline), text: '收藏的帖子'),
        ],
        error: (error, stackTrace) => const [
          Tab(icon: Icon(Icons.notes), text: '收藏的记录'),
          Tab(icon: Icon(Icons.people_outline), text: '收藏的帖子'),
        ],
      ),
    );
  }
}

