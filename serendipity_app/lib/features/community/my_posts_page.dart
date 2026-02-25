import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/community_provider.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/community_post.dart';
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
/// - DRY：复用 CommunityPostCard 组件
/// - Fail Fast：依赖 Provider 层的参数校验
class MyPostsPage extends ConsumerStatefulWidget {
  const MyPostsPage({super.key});

  @override
  ConsumerState<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends ConsumerState<MyPostsPage> {
  /// 我的帖子列表（本地状态）
  List<CommunityPost>? _myPosts;
  
  /// 是否正在加载
  bool _isLoading = false;
  
  /// 错误信息
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  /// 加载我的帖子
  /// 
  /// 调用者：
  /// - initState()（初始化时）
  /// - _onRefresh()（下拉刷新时）
  Future<void> _loadMyPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await ref.read(communityProvider.notifier).getMyPosts();
      if (mounted) {
        setState(() {
          _myPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 下拉刷新
  /// 
  /// 调用者：RefreshIndicator
  Future<void> _onRefresh() async {
    await _loadMyPosts();
  }

  /// 删除帖子
  /// 
  /// 调用者：CommunityPostCard（长按菜单）
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
      onSuccess: () {
        // 刷新列表
        _loadMyPosts();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的发布'),
      ),
      body: _buildBody(),
    );
  }

  /// 构建页面主体
  /// 
  /// 调用者：build()
  Widget _buildBody() {
    // 加载中
    if (_isLoading && _myPosts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 加载失败
    if (_errorMessage != null && _myPosts == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('加载失败：$_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyPosts,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 空状态
    if (_myPosts == null || _myPosts!.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
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
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _myPosts!.length,
        itemBuilder: (context, index) {
          final post = _myPosts![index];
          return CommunityPostCard(
            post: post,
            onDelete: () => _deletePost(post.id),
          );
        },
      ),
    );
  }
}

