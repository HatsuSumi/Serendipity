import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/community_provider.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import 'widgets/community_post_card.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的发布'),
      ),
      body: myPostsAsync.when(
        data: (posts) => _buildPostsList(context, ref, posts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, ref, error),
      ),
    );
  }

  /// 构建帖子列表
  /// 
  /// 调用者：build()
  /// 
  /// 性能说明：
  /// - 社区帖子高度差异很大（100px-300px+）
  /// - 使用默认的动态高度计算，确保布局正确
  Widget _buildPostsList(BuildContext context, WidgetRef ref, List<dynamic> posts) {
    // 空状态
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            EmptyStateWidget(
              icon: Icons.cloud_off,
              title: '还没有发布到树洞',
              description: '在记录详情页可以发布到社区',
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
          // 我的帖子页面：后端保证所有帖子都是 isOwner = true
          // 直接传递 onDelete，不需要判断
          return CommunityPostCard(
            post: post,
            onDelete: () => _deletePost(context, ref, post.id),
          );
        },
      ),
    );
  }

  /// 构建错误状态
  /// 
  /// 调用者：build()
  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('加载失败：${AuthErrorHelper.extractErrorMessage(error)}'),
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

