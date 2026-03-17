import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/theme/status_color_extension.dart';
import '../../core/utils/record_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../models/encounter_record.dart';
import '../record/record_detail_page.dart';
import '../community/widgets/community_post_card.dart';

/// 我的收藏页面
///
/// 职责：
/// - 双 Tab 展示：收藏的记录 + 收藏的社区帖子
/// - 支持下拉刷新
/// - 支持取消收藏
///
/// 调用者：SettingsPage
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 下拉刷新
  ///
  /// 调用者：RefreshIndicator
  Future<void> _onRefresh() async {
    await ref.read(favoritesProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.notes), text: '收藏的记录'),
            Tab(icon: Icon(Icons.people_outline), text: '收藏的帖子'),
          ],
        ),
      ),
      body: ref.watch(favoritesProvider).when(
        data: (favoritesState) => TabBarView(
          controller: _tabController,
          children: [
            _buildFavoritedRecordsTab(favoritesState),
            _buildFavoritedPostsTab(favoritesState),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(error),
      ),
    );
  }

  // ==================== 收藏的记录 Tab ====================

  /// 构建收藏的记录 Tab
  Widget _buildFavoritedRecordsTab(FavoritesState favoritesState) {
    final records = ref.read(favoritesProvider.notifier).getFavoritedRecords();

    if (records.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            EmptyStateWidget(
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
        itemCount: records.length,
        itemBuilder: (context, index) {
          return _buildRecordCard(records[index]);
        },
      ),
    );
  }

  /// 构建收藏的记录卡片
  ///
  /// 复用记录页面卡片的核心信息展示，但更简洁（只展示关键字段）
  Widget _buildRecordCard(EncounterRecord record) {
    final statusColor = record.status.getColor(context, ref);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => NavigationHelper.pushWithTransition(
          context,
          ref,
          RecordDetailPage(record: record),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 状态 + 时间 + 取消收藏
              Row(
                children: [
                  Text(record.status.icon,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.status.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    DateTimeHelper.formatRelativeTime(record.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark, size: 20),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: '取消收藏',
                    onPressed: () => _unfavoriteRecord(record.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 地点
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      RecordHelper.getLocationText(record.location),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // 描述（如果有）
              if (record.description != null &&
                  record.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  record.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 取消收藏记录
  ///
  /// 调用者：_buildRecordCard()
  Future<void> _unfavoriteRecord(String recordId) async {
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '取消收藏',
      content: '确定要取消收藏这条记录吗？',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(favoritesProvider.notifier).unfavoriteRecord(recordId);
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

  // ==================== 收藏的社区帖子 Tab ====================

  /// 构建收藏的社区帖子 Tab
  Widget _buildFavoritedPostsTab(FavoritesState favoritesState) {
    final posts = favoritesState.favoritedPosts;

    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            EmptyStateWidget(
              icon: Icons.bookmark_border,
              title: '还没有收藏的帖子',
              description: '在树洞浏览时点击收藏按钮',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return CommunityPostCard(
            post: post,
            isFavorited: true,
            onFavorite: () => _unfavoritePost(post.id),
          );
        },
      ),
    );
  }

  /// 取消收藏社区帖子
  ///
  /// 调用者：_buildFavoritedPostsTab() 的 CommunityPostCard.onFavorite
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

  /// 构建错误状态
  ///
  /// 调用者：build()
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

