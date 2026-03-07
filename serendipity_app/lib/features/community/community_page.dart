import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_settings_provider.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../record/create_record_page.dart';
import 'widgets/community_post_card.dart';
import 'dialogs/community_filter_dialog.dart';
import 'dialogs/community_intro_dialog.dart';
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
  final bool isVisible;
  
  const CommunityPage({
    super.key,
    this.isVisible = true,
  });

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CommunityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 当页面从不可见变为可见时，检查是否需要显示对话框
    if (!oldWidget.isVisible && widget.isVisible) {
      _checkAndShowIntroDialog();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 检查并显示介绍对话框
  /// 
  /// 职责：
  /// - 检查用户是否已看过介绍
  /// - 如果未看过，显示介绍对话框
  /// 
  /// 调用者：
  /// - didUpdateWidget()（当页面变为可见时）
  /// 
  /// 说明：
  /// - 使用 userSettingsProvider 的状态作为唯一数据源
  /// - 通过 isVisible 参数判断页面是否真正可见
  void _checkAndShowIntroDialog() {
    // 读取最新的设置状态
    final hasSeenIntro = ref.read(userSettingsProvider).hasSeenCommunityIntro;
    
    // 如果已看过，不显示
    if (hasSeenIntro) return;
    
    // 延迟到下一帧显示，避免在 build 期间显示对话框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // 再次检查状态（防止在延迟期间状态已改变）
      final currentHasSeenIntro = ref.read(userSettingsProvider).hasSeenCommunityIntro;
      if (!currentHasSeenIntro) {
        CommunityIntroDialog.show(context, ref);
      }
    });
  }

  /// 滚动监听（加载更多）
  /// 
  /// 优化说明：
  /// - 移除本地 _isLoadingMore 状态
  /// - 直接使用 Provider 的 isLoading 状态
  /// - 遵循"单一数据源"原则
  void _onScroll() {
    final communityStateAsync = ref.read(communityProvider);
    
    // 使用 Provider 的状态判断
    if (communityStateAsync.isLoading) return;
    
    final communityState = communityStateAsync.value;
    if (communityState == null) return;
    
    // 如果没有更多数据，不触发加载
    if (!communityState.hasMore) return;

    // 滚动到底部时加载更多
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(communityProvider.notifier).loadMore();
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
    super.build(context); // 必须调用，因为使用了 AutomaticKeepAliveClientMixin
    
    final communityStateAsync = ref.watch(communityProvider);

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
      body: communityStateAsync.when(
        data: (communityState) => _buildPostsList(communityState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
  /// 
  /// 性能说明：
  /// - 社区帖子高度差异很大（100px-300px+）
  /// - prototypeItem 不适用于高度差异大的场景
  /// - 使用默认的动态高度计算，确保布局正确
  Widget _buildPostsList(CommunityState communityState) {
    final posts = communityState.posts;
    final isFiltering = communityState.isFiltering;
    
    // 空状态
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            EmptyStateWidget(
              icon: isFiltering ? Icons.search_off : Icons.forest,
              title: isFiltering ? '没有符合条件的帖子' : '还没有人发布到树洞',
              description: isFiltering ? '试试调整筛选条件' : '成为第一个分享者吧',
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
  /// 
  /// 优化说明：
  /// - 使用 Provider 的状态判断，遵循"单一数据源"原则
  /// - 移除本地 _isLoadingMore 状态，避免状态重复
  Widget _buildLoadingIndicator() {
    final communityStateAsync = ref.read(communityProvider);
    final communityState = communityStateAsync.value;
    
    // 如果没有更多数据或正在加载，不显示加载指示器
    if (communityState == null || !communityState.hasMore) {
      return const SizedBox(height: 80);
    }

    // 如果正在加载，显示加载指示器
    if (communityStateAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const SizedBox(height: 80);
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

