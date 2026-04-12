import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/utils/auth_error_helper.dart';
import 'favorites_intro_dialog.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/theme/status_color_extension.dart';

import '../../models/community_post.dart';
import '../../core/utils/record_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../models/encounter_record.dart';
import '../record/record_detail_page.dart';
import '../record/create_record_page.dart';
import '../community/widgets/community_post_card.dart';

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

  // 主题颜色缓存（每次 build 从 Provider 更新，子方法直接使用）
  late ColorScheme _colorScheme;
  late TextTheme _textTheme;

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
    _colorScheme = Theme.of(context).colorScheme;
    _textTheme = Theme.of(context).textTheme;
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _buildTabs(favoritesAsync),
        ),
      ),
      body: favoritesAsync.when(
        data: (favoritesState) => TabBarView(
          controller: _tabController,
          children: [
            _buildFavoritedRecordsTab(favoritesState),
            _buildFavoritedPostsTab(favoritesState),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, e) => _buildError(error),
      ),
    );
  }

  List<Widget> _buildTabs(AsyncValue<FavoritesState> favoritesAsync) {
    return favoritesAsync.when(
      data: (favoritesState) {
        final recordCount = _getFavoritedRecordCount(favoritesState);
        final postCount = _getFavoritedPostCount(favoritesState);
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
      error: (e, st) => const [
        Tab(icon: Icon(Icons.notes), text: '收藏的记录'),
        Tab(icon: Icon(Icons.people_outline), text: '收藏的帖子'),
      ],
    );
  }

  int _getFavoritedRecordCount(FavoritesState favoritesState) {
    return favoritesState.favoritedRecords.length +
        favoritesState.deletedFavoritedRecords.length;
  }

  int _getFavoritedPostCount(FavoritesState favoritesState) {
    return favoritesState.favoritedPosts.length +
        favoritesState.deletedFavoritedPosts.length;
  }

  // ==================== 收藏的记录 Tab ====================

  Widget _buildFavoritedRecordsTab(FavoritesState favoritesState) {
    final records = favoritesState.favoritedRecords;
    final deletedRecords = favoritesState.deletedFavoritedRecords;
    final totalCount = records.length + deletedRecords.length;

    if (totalCount == 0) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            const EmptyStateWidget(
              icon: Icons.bookmark_border,
              title: '还没有收藏的记录',
              description: '在记录列表长按记录卡片可以收藏',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < records.length) {
            return _buildRecordCard(records[index], isDeleted: false);
          } else {
            return _buildRecordCard(
                deletedRecords[index - records.length], isDeleted: true);
          }
        },
      ),
    );
  }

  Widget _buildRecordCard(EncounterRecord record, {required bool isDeleted}) {
    final statusColor = record.status.getColor(context, ref);
    final borderAlpha = isDeleted ? 0.2 : 0.3;
    final labelAlpha = isDeleted ? 0.6 : 1.0;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(record.status.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.status.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor.withValues(alpha: labelAlpha),
                  ),
                ),
              ),
              Text(
                '创建：${DateTimeHelper.formatRelativeTime(record.createdAt)}',
                style: _textTheme.bodySmall?.copyWith(
                  color: _colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isDeleted)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleRecordMenuAction(record, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 16,
                  color: _colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  RecordHelper.getLocationText(record.location),
                  style: _textTheme.bodyMedium?.copyWith(
                    color: isDeleted
                        ? _colorScheme.onSurfaceVariant
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (record.description != null &&
              record.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.description!,
              style: _textTheme.bodySmall?.copyWith(
                color: _colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (record.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: record.tags.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor
                        .withValues(alpha: isDeleted ? 0.08 : 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag.tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor
                          .withValues(alpha: isDeleted ? 0.7 : 1.0),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '发生：${DateTimeHelper.formatRelativeTime(record.timestamp)}',
                      style: _textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: _colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!isDeleted &&
                        record.createdAt != record.updatedAt) ...[
                      Text(' | ',
                          style: _textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color:
                                  _colorScheme.onSurfaceVariant)),
                      Text(
                        '更新：${DateTimeHelper.formatRelativeTime(record.updatedAt)}',
                        style: _textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: _colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isDeleted) ...[
                Text(
                  '该记录已被删除',
                  style: _textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: _colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (record.storyLineId != null) ...[
                _buildStoryLineInfo(record.storyLineId!),
                const SizedBox(width: 4),
              ],
              GestureDetector(
                onTap: () => _unfavoriteRecord(
                  recordId: record.id,
                  isDeleted: isDeleted,
                ),
                child: Icon(
                  Icons.bookmark,
                  size: 16,
                  color: _colorScheme.primary
                      .withValues(alpha: isDeleted ? 0.5 : 1.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: borderAlpha),
          width: 2,
        ),
      ),
      child: isDeleted
          ? content
          : InkWell(
              onTap: () => NavigationHelper.pushWithTransition(
                  context, ref, RecordDetailPage(record: record)),
              borderRadius: BorderRadius.circular(16),
              child: content,
            ),
    );
  }

  Widget _buildStoryLineInfo(String storyLineId) {
    final storyLines = ref.watch(storyLinesProvider).valueOrNull ?? [];
    final storyLine =
        storyLines.where((sl) => sl.id == storyLineId).firstOrNull;
    if (storyLine == null) return const SizedBox.shrink();

    final primary = _colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_stories, size: 12, color: primary),
        const SizedBox(width: 4),
        Text(
          storyLine.name,
          style: _textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: primary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _handleRecordMenuAction(EncounterRecord record, String action) {
    switch (action) {
      case 'edit':
        NavigationHelper.pushWithTransition(
          context,
          ref,
          CreateRecordPage(recordToEdit: record),
        );
        break;
      case 'unfavorite':
        _unfavoriteRecord(recordId: record.id, isDeleted: false);
        break;
    }
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

  // ==================== 收藏的社区帖子 Tab ====================

  Widget _buildFavoritedPostsTab(FavoritesState favoritesState) {
    final posts = favoritesState.favoritedPosts;
    final deletedPosts = favoritesState.deletedFavoritedPosts;
    final totalCount = posts.length + deletedPosts.length;

    if (totalCount == 0) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            EmptyStateWidget(
              icon: Icons.bookmark_border,
              title: '你还没有收藏过任何人的故事。',
              description: '也许是因为\n没有哪个故事\n让你觉得——\n\n这说的是我。',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < posts.length) {
            final post = posts[index];
            return CommunityPostCard(
              post: post,
              isFavorited: true,
              onFavorite: () => _unfavoritePost(post.id),
            );
          } else {
            final deletedPost = deletedPosts[index - posts.length];
            return _buildDeletedPostCard(deletedPost);
          }
        },
      ),
    );
  }

  Widget _buildDeletedPostCard(CommunityPost post) {
    return CommunityPostCard(
      post: post,
      isFavorited: true,
      isDeleted: true,
      onFavorite: () => _unfavoriteDeletedPost(post.id),
    );
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

  // ==================== 错误状态 ====================

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('加载失败：${AuthErrorHelper.extractErrorMessage(error)}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onRefresh,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

