import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/community_post.dart';
import 'widgets/community_post_card.dart';
import 'dialogs/my_posts_filter_dialog.dart';

/// 我的发布页面
/// 
/// 职责：
/// - 显示当前用户发布的所有帖子
/// - 支持下拉刷新
/// - 支持删除帖子
/// 
/// 调用者：SettingsPage（我的页面）
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责展示我的帖子列表
/// - 分层约束：UI层不包含业务逻辑，通过Provider调用
/// - 状态管理规则：使用 myPostsProvider 管理状态（单一数据源）
/// - DRY：复用 CommunityPostCard 组件
/// - Fail Fast：依赖 Provider 层的参数校验
class MyPostsPage extends ConsumerWidget {
  const MyPostsPage({super.key});

  /// 下拉刷新
  /// 
  /// 调用者：RefreshIndicator
  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(myPostsProvider.notifier).refresh();
  }

  /// 删除帖子
  /// 
  /// 调用者：CommunityPostCard（长按菜单）
  Future<void> _deletePost(BuildContext context, WidgetRef ref, String postId) async {
    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除帖子'),
        content: const Text('确定要删除这条帖子吗？\n\n删除后无法恢复，但记录仍保留在私人记录中。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // 删除帖子（自动刷新列表）
    await AsyncActionHelper.execute(
      context,
      action: () => ref.read(myPostsProvider.notifier).deletePost(postId),
      successMessage: '帖子已删除',
      errorMessagePrefix: '删除失败',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPostsAsync = ref.watch(myPostsProvider);
    final filterCriteria = ref.watch(myPostsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的发布'),
        actions: [
          // 筛选按钮
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选',
            onPressed: () => MyPostsFilterDialog.show(context),
          ),
        ],
      ),
      body: myPostsAsync.when(
        data: (posts) => _buildPostsListView(context, ref, posts, filterCriteria),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, ref, error as Object?),
      ),
    );
  }

  /// 构建帖子列表视图
  Widget _buildPostsListView(BuildContext context, WidgetRef ref, List<CommunityPost> posts, MyPostsFilterCriteria filterCriteria) {
    final isFiltering = filterCriteria.isActive;
    
    // 空状态
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            EmptyStateWidget(
              icon: isFiltering ? Icons.search_off : Icons.cloud_off,
              title: isFiltering ? '没有符合条件的帖子' : '还没有发布到树洞',
              description: isFiltering ? '试试调整筛选条件' : '在记录详情页可以发布到社区',
            ),
          ],
        ),
      );
    }

    // 帖子列表
    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final favoritesState = ref.watch(favoritesProvider).valueOrNull;
          return CommunityPostCard(
            post: post,
            onDelete: () => _deletePost(context, ref, post.id),
            isFavorited: favoritesState?.isPostFavorited(post.id) ?? false,
            onFavorite: () => _toggleFavoritePost(context, ref, post.id,
                favoritesState?.isPostFavorited(post.id) ?? false),
            highlightKeywords: filterCriteria.tags,
            tagMatchMode: filterCriteria.tagMatchMode,
          );
        },
      ),
    );
  }

  /// 切换帖子收藏状态
  ///
  /// 调用者：_buildPostsListView() 的 CommunityPostCard.onFavorite
  Future<void> _toggleFavoritePost(
    BuildContext context,
    WidgetRef ref,
    String postId,
    bool isFavorited,
  ) async {
    final notifier = ref.read(favoritesProvider.notifier);
    try {
      if (isFavorited) {
        await notifier.unfavoritePost(postId);
      } else {
        await notifier.favoritePost(postId);
      }
    } catch (e) {
      if (!context.mounted) return;
      MessageHelper.showError(
        context,
        isFavorited
            ? '取消收藏失败：${AuthErrorHelper.extractErrorMessage(e)}'
            : '收藏失败：${AuthErrorHelper.extractErrorMessage(e)}',
      );
    }
  }

  /// 构建错误状态
  /// 
  /// 调用者：build()
  Widget _buildError(BuildContext context, WidgetRef ref, Object? error) {
    final errorMessage = error != null 
        ? AuthErrorHelper.extractErrorMessage(error)
        : '加载失败';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('加载失败：$errorMessage'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(myPostsProvider.notifier).refresh(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

