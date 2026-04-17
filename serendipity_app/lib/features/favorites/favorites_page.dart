import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/favorites_provider.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/message_helper.dart';
import 'favorites_intro_dialog.dart';
import 'widgets/favorite_posts_tab.dart';
import 'widgets/favorite_records_tab.dart';
import 'widgets/favorites_page_error_state.dart';
import 'widgets/favorites_page_tabs.dart';

/// 我的收藏页面
///
/// 职责：
/// - 双 Tab 展示：收藏的记录 + 收藏的社区帖子
/// - 支持下拉刷新
/// - 支持取消收藏
///
/// 调用者：ProfilePage
///
/// 设计原则：
/// - 单一职责（SRP）：只负责展示收藏列表
/// - 分层约束：UI 层不包含业务逻辑，通过 favoritesProvider 调用
/// - 单一数据源：状态完全来自 favoritesProvider
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _showIntroDialogIfNeeded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showIntroDialogIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await FavoritesIntroDialog.show(context, ref);
      if (!mounted) return;
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(favoritesProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: FavoritesPageTabs(
            controller: _tabController,
            favoritesAsync: favoritesAsync,
          ),
        ),
      ),
      body: favoritesAsync.when(
        data: (favoritesState) => TabBarView(
          controller: _tabController,
          children: [
            FavoriteRecordsTab(
              favoritesState: favoritesState,
              onRefresh: _onRefresh,
              onUnfavoriteRecord: _unfavoriteRecord,
            ),
            FavoritePostsTab(
              favoritesState: favoritesState,
              onRefresh: _onRefresh,
              onUnfavoritePost: _unfavoritePost,
              onUnfavoriteDeletedPost: _unfavoriteDeletedPost,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => FavoritesPageErrorState(
          error: error,
          onRetry: _onRefresh,
        ),
      ),
    );
  }

  Future<void> _unfavoriteRecord({
    required String recordId,
    required bool isDeleted,
  }) async {
    final content = isDeleted
        ? '该记录已被删除，确定要移除这条收藏记录吗？'
        : '确定要取消收藏这条记录吗？';
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '取消收藏',
      content: content,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(favoritesProvider.notifier).unfavoriteRecord(recordId);
      if (mounted) {
        MessageHelper.showSuccess(
          context,
          isDeleted ? '已移除收藏' : '已取消收藏',
        );
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(
          context,
          '${isDeleted ? '移除' : '取消收藏'}失败：${AuthErrorHelper.extractErrorMessage(e)}',
        );
      }
    }
  }

  Future<void> _unfavoriteDeletedPost(String postId) async {
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '取消收藏',
      content: '该帖子已被删除，确定要移除这条收藏记录吗？',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(favoritesProvider.notifier).unfavoritePost(postId);
      if (mounted) MessageHelper.showSuccess(context, '已移除收藏');
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(
          context,
          '移除失败：${AuthErrorHelper.extractErrorMessage(e)}',
        );
      }
    }
  }

  Future<void> _unfavoritePost(String postId) async {
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '取消收藏',
      content: '确定要取消收藏这条帖子吗？',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(favoritesProvider.notifier).unfavoritePost(postId);
      if (mounted) MessageHelper.showSuccess(context, '已取消收藏');
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(
          context,
          '取消收藏失败：${AuthErrorHelper.extractErrorMessage(e)}',
        );
      }
    }
  }
}

