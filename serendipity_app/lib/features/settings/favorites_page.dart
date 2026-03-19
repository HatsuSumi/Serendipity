import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/utils/auth_error_helper.dart';
import 'dialogs/favorites_intro_dialog.dart';
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
    _showIntroDialogIfNeeded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 首次进入时显示收藏页介绍对话框
  ///
  /// 调用者：initState()
  ///
  /// 是否显示的判断完全委托给 [FavoritesIntroDialog.show]，
  /// 此处不做二次检查，遵循单一职责原则。
  void _showIntroDialogIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await FavoritesIntroDialog.show(context, ref);
    });
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
    final allRecords = ref.watch(recordsProvider).value ?? [];
    final favoritedIds = favoritesState.favoritedRecordIds;
    final records = favoritedIds.isEmpty
        ? <EncounterRecord>[]
        : allRecords.where((r) => favoritedIds.contains(r.id)).toList();
    final deletedRecords = favoritesState.deletedFavoritedRecords;
    final totalCount = records.length + deletedRecords.length;

    if (totalCount == 0) {
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
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < records.length) {
            return _buildRecordCard(records[index]);
          } else {
            return _buildDeletedRecordCard(deletedRecords[index - records.length]);
          }
        },
      ),
    );
  }

  /// 构建记录卡片（统一处理正常记录和已删除记录）
  ///
  /// [isDeleted] 为 true 时：
  /// - 不可点击（无 InkWell 包裹）
  /// - 状态颜色半透明，视觉区分
  /// - 底部显示「该记录已被删除」错误标注
  /// - 书签图标半透明
  ///
  /// 调用者：_buildFavoritedRecordsTab()
  Widget _buildDeletedRecordCard(EncounterRecord record) {
    final statusColor = record.status.getColor(context, ref);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态 + 创建时间
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
                      color: statusColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Text(
                  '创建：${DateTimeHelper.formatRelativeTime(record.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 地点
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    RecordHelper.getLocationText(record.location),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // 描述
            if (record.description != null && record.description!.isNotEmpty) ...[  
              const SizedBox(height: 8),
              Text(
                record.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // 标签
            if (record.tags.isNotEmpty) ...[  
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: record.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag.tag,
                        style: TextStyle(
                            fontSize: 12,
                            color: statusColor.withValues(alpha: 0.7))),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            // 底部：发生时间 + 「已被删除」标注 + 取消收藏
            Row(
              children: [
                Expanded(
                  child: Text(
                    '发生：${DateTimeHelper.formatRelativeTime(record.timestamp)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '该记录已被删除',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _unfavoriteDeletedRecord(record.id),
                  child: Icon(
                    Icons.bookmark,
                    size: 16,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 取消收藏已删除的记录
  ///
  /// 调用者：_buildDeletedRecordCard()
  Future<void> _unfavoriteDeletedRecord(String recordId) async {
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '取消收藏',
      content: '该记录已被删除，确定要移除这条收藏记录吗？',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(favoritesProvider.notifier).unfavoriteRecord(recordId);
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

  /// 构建收藏的记录卡片
  ///
  /// 与时间轴卡片保持一致的信息密度，菜单只保留「编辑」和「取消收藏」。
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 状态 + 创建时间 + 更多菜单
              Row(
                children: [
                  Text(record.status.icon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.status.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    '创建：${DateTimeHelper.formatRelativeTime(record.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
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

              // 地点
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      RecordHelper.getLocationText(record.location),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // 描述（如果有）
              if (record.description != null &&
                  record.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  record.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 标签（如果有）
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
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.tag,
                        style: TextStyle(fontSize: 12, color: statusColor),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // 底部：发生时间 + 更新时间 + 故事线
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '发生：${DateTimeHelper.formatRelativeTime(record.timestamp)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        if (record.createdAt != record.updatedAt) ...[
                          Text(
                            ' | ',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          Text(
                            '更新：${DateTimeHelper.formatRelativeTime(record.updatedAt)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (record.storyLineId != null)
                    _buildStoryLineInfo(record.storyLineId!),
                  // 取消收藏按钮
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _unfavoriteRecord(record.id),
                    child: Icon(
                      Icons.bookmark,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 故事线信息（右下角）
  Widget _buildStoryLineInfo(String storyLineId) {
    final storyLinesAsync = ref.watch(storyLinesProvider);
    return storyLinesAsync.when(
      data: (storyLines) {
        try {
          final storyLine =
              storyLines.firstWhere((sl) => sl.id == storyLineId);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                storyLine.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  /// 处理记录卡片菜单操作
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
        _unfavoriteRecord(record.id);
        break;
    }
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

  /// 构建已删除帖子的卡片（保留完整信息，右下角标注「该帖子已被删除」）
  ///
  /// 调用者：_buildFavoritedPostsTab()
  Widget _buildDeletedPostCard(CommunityPost post) {
    return CommunityPostCard(
      post: post,
      isFavorited: true,
      isDeleted: true,
      onFavorite: () => _unfavoriteDeletedPost(post.id),
    );
  }

  /// 取消收藏已删除的帖子
  ///
  /// 调用者：_buildDeletedPostCard()
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

