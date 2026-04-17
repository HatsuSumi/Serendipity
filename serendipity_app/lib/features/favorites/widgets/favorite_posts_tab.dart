import 'package:flutter/material.dart';

import '../../../core/providers/favorites_provider.dart';
import '../../community/widgets/community_post_card.dart';
import 'favorites_list_states.dart';

class FavoritePostsTab extends StatelessWidget {
  final FavoritesState favoritesState;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String postId) onUnfavoritePost;
  final Future<void> Function(String postId) onUnfavoriteDeletedPost;

  const FavoritePostsTab({
    super.key,
    required this.favoritesState,
    required this.onRefresh,
    required this.onUnfavoritePost,
    required this.onUnfavoriteDeletedPost,
  });

  @override
  Widget build(BuildContext context) {
    final posts = favoritesState.favoritedPosts;
    final deletedPosts = favoritesState.deletedFavoritedPosts;
    final totalCount = posts.length + deletedPosts.length;

    if (totalCount == 0) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            FavoritePostsEmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < posts.length) {
            final post = posts[index];
            return CommunityPostCard(
              post: post,
              isFavorited: true,
              onFavorite: () => onUnfavoritePost(post.id),
            );
          }

          final deletedPost = deletedPosts[index - posts.length];
          return CommunityPostCard(
            post: deletedPost,
            isFavorited: true,
            isDeleted: true,
            onFavorite: () => onUnfavoriteDeletedPost(deletedPost.id),
          );
        },
      ),
    );
  }
}

