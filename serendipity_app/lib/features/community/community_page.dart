import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/community_post.dart';
import '../record/create_record_page.dart';
import 'widgets/community_post_card.dart';
import 'dialogs/community_filter_dialog.dart';
import 'dialogs/publish_to_community_dialog.dart';

/// 社区页面（树洞）
/// 
/// 职责：
/// - 显示社区帖子列表
/// - 支持下拉刷新
/// - 支持滚动加载更多
/// - 支持筛选
/// 
/// 调用者：MainNavigationPage（底部导航第3个标签）
class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听（加载更多）
  void _onScroll() {
    if (_isLoadingMore) return;

    // 滚动到底部时加载更多
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref.read(communityProvider.notifier).loadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await ref.read(communityProvider.notifier).refresh();
  }

  /// 显示筛选对话框
  Future<void> _showFilterDialog() async {
    await CommunityFilterDialog.show(context);
  }

  /// 处理发布
  /// 
  /// 调用者：FloatingActionButton 的 onPressed
  /// 
  /// Fail Fast：
  /// - 如果用户未登录，提示登录
  Future<void> _handlePublish() async {
    // Fail Fast：检查登录状态
    final authState = ref.read(authProvider);
    final currentUser = authState.value;
    
    if (currentUser == null) {
      // 未登录，提示用户登录
      if (!mounted) return;
      MessageHelper.showError(context, '请先登录后再发布');
      return;
    }

    // 已登录，显示选择对话框
    await _showPublishOptionsDialog();
  }

  /// 显示发布选项对话框
  /// 
  /// 调用者：_handlePublish()
  Future<void> _showPublishOptionsDialog() async {
    await DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发布到树洞'),
        content: const Text('选择发布方式'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToRecordsPage();
            },
            child: const Text('创建新记录'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showPublishDialog();
            },
            child: const Text('选择现有记录'),
          ),
        ],
      ),
    );
  }

  /// 跳转到创建记录页面
  /// 
  /// 调用者：_showPublishOptionsDialog()
  Future<void> _navigateToRecordsPage() async {
    await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (context, animation, secondaryAnimation) {
          return const CreateRecordPage(
            initialPublishToCommunity: true,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var slideTween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// 显示发布对话框
  /// 
  /// 调用者：_showPublishOptionsDialog()
  Future<void> _showPublishDialog() async {
    await DialogHelper.show(
      context: context,
      builder: (context) => const PublishToCommunityDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('树洞'),
        actions: [
          // 筛选按钮
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) => _buildPostsList(posts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('加载失败：$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _onRefresh,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handlePublish,
        icon: const Icon(Icons.add),
        label: const Text('发布到树洞'),
      ),
    );
  }

  /// 构建帖子列表
  Widget _buildPostsList(List<CommunityPost> posts) {
    // 空状态
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            EmptyStateWidget(
              icon: Icons.forest,
              title: '还没有人发布到树洞',
              description: '成为第一个分享者吧',
            ),
          ],
        ),
      );
    }

    // 帖子列表
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length + 1, // +1 for loading indicator
        itemBuilder: (context, index) {
          // 加载更多指示器
          if (index == posts.length) {
            return _buildLoadingIndicator();
          }

          // 帖子卡片
          final post = posts[index];
          
          return CommunityPostCard(
            post: post,
            onDelete: post.isOwner ? () => _deletePost(post.id) : null,
          );
        },
      ),
    );
  }

  /// 构建加载更多指示器
  Widget _buildLoadingIndicator() {
    if (!_isLoadingMore) {
      return const SizedBox(height: 80);
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 删除帖子
  Future<void> _deletePost(String postId) async {
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

    if (confirmed != true || !mounted) return;

    // 删除帖子
    await AsyncActionHelper.execute(
      context,
      action: () => ref.read(communityProvider.notifier).deletePost(postId),
      successMessage: '帖子已删除',
      errorMessagePrefix: '删除失败',
    );
  }
}

