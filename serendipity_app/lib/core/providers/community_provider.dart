import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community_post.dart';
import '../repositories/community_repository.dart';
import '../repositories/i_community_data_source.dart';
import '../repositories/remote_community_data_source.dart';
import '../repositories/test_community_data_source.dart';
import '../services/sync_service.dart';
import '../utils/auth_error_helper.dart';
import '../config/app_config.dart';
import 'auth_provider.dart';
import 'community_filter_provider.dart';
import 'favorites_provider.dart';
import 'my_posts_filter_provider.dart';

// 导出发布 Provider
export 'community_publish_provider.dart';
// 导出筛选 Provider
export 'community_filter_provider.dart';
export 'my_posts_filter_provider.dart';

/// 社区数据源 Provider
/// 
/// 根据配置选择数据源（策略模式）
/// - 测试模式：使用 TestCommunityDataSource
/// - 正常模式：使用 RemoteCommunityDataSource
final communityDataSourceProvider = Provider<ICommunityDataSource>((ref) {
  if (AppConfig.serverType == ServerType.test) {
    return TestCommunityDataSource();
  } else {
    final remoteData = ref.read(remoteDataRepositoryProvider);
    return RemoteCommunityDataSource(remoteData);
  }
});

/// 社区仓储 Provider
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final dataSource = ref.read(communityDataSourceProvider);
  return CommunityRepository(dataSource);
});

/// 社区状态
///
/// 职责：
/// - 存储帖子列表
/// - 存储分页状态
///
/// 设计原则：
/// - 单一职责（SRP）：只负责列表状态
/// - 筛选条件独立管理：使用 communityFilterProvider
/// - 不存储 isFiltering：通过 communityFilterProvider.isActive 判断，避免冗余状态
class CommunityState {
  final List<CommunityPost> posts;
  final bool hasMore;

  const CommunityState({
    required this.posts,
    this.hasMore = true,
  });

  CommunityState copyWith({
    List<CommunityPost>? posts,
    bool? hasMore,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// 社区状态管理
/// 
/// 职责：
/// - 管理社区帖子列表状态
/// - 监听筛选条件变化并自动过滤
/// - 删除自己的帖子
/// - 加载更多帖子（分页）
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责社区帖子列表管理
/// - 依赖倒置（DIP）：依赖 communityFilterProvider，不依赖具体的筛选UI
/// - 自动响应：监听 communityFilterProvider 变化，自动过滤
/// 
/// 注意：
/// - 发布功能已移至 CommunityPublishNotifier
/// - 筛选条件已移至 CommunityFilterNotifier
/// 
/// 调用者：
/// - CommunityPage（UI 层）
class CommunityNotifier extends AsyncNotifier<CommunityState> {
  late CommunityRepository _repository;
  
  /// 最后一条帖子的时间戳（用于分页）
  DateTime? _lastTimestamp;

  @override
  Future<CommunityState> build() async {
    _repository = ref.read(communityRepositoryProvider);
    
    // 监听筛选条件变化，自动重新过滤
    final filterCriteria = ref.watch(communityFilterProvider);
    
    // 如果有筛选条件，执行筛选；否则加载默认列表
    if (filterCriteria.isActive) {
      return await _filterPosts(filterCriteria);
    } else {
      // 初始化时加载第一页
      final posts = await _loadPosts();
      return CommunityState(
        posts: posts,
        hasMore: posts.length >= 20,
      );
    }
  }

  /// 根据筛选条件过滤帖子（内部方法）
  /// 
  /// 调用者：build()
  Future<CommunityState> _filterPosts(CommunityFilterCriteria criteria) async {
    _lastTimestamp = null;
    
    final posts = await _repository.filterPosts(
      startDate: criteria.startDate,
      endDate: criteria.endDate,
      publishStartDate: criteria.publishStartDate,
      publishEndDate: criteria.publishEndDate,
      province: criteria.province,
      city: criteria.city,
      area: criteria.area,
      placeTypes: criteria.placeTypes,
      tags: criteria.tags,
      statuses: criteria.statuses,
      tagMatchMode: criteria.tagMatchMode,
    );
    
    return CommunityState(
      posts: posts,
      hasMore: false, // 筛选结果不支持分页
    );
  }

  /// 加载帖子（内部方法）
  Future<List<CommunityPost>> _loadPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  }) async {
    final posts = await _repository.getPosts(
      limit: limit,
      lastTimestamp: lastTimestamp,
    );

    // 更新分页状态
    if (posts.isNotEmpty) {
      _lastTimestamp = posts.last.publishedAt;
    }

    return posts;
  }

  /// 刷新帖子列表
  ///
  /// 使用 invalidateSelf() 让 build() 重新执行，自动应用当前筛选条件。
  /// 这样无论筛选状态如何，刷新后的数据都与 communityFilterProvider 保持同步。
  ///
  /// 调用者：CommunityPage（下拉刷新）
  Future<void> refresh() async {
    _lastTimestamp = null;
    ref.invalidateSelf();
    await future;
  }

  /// 静默刷新帖子列表（不显示 loading 状态）
  ///
  /// 用于发布/删除帖子后的后台刷新，避免页面闪烁。
  /// 筛选激活时静默刷新会重新执行后端筛选查询，保持结果最新。
  ///
  /// 调用者：
  /// - deletePost（删除后刷新）
  /// - CommunityPublishNotifier.publishPost（发布后刷新）
  /// - MyPostsNotifier.deletePost（删除后同步）
  Future<void> refreshSilently() async {
    if (state.value == null) {
      await refresh();
      return;
    }
    _lastTimestamp = null;
    ref.invalidateSelf();
    await future;
  }

  /// 加载更多帖子
  /// 
  /// 调用者：CommunityPage（滚动到底部）
  /// 
  /// 优化说明：
  /// - 使用 AsyncValue.guard 自动处理错误
  /// - 失败时保持当前状态，用户仍可看到已加载的数据
  /// - 遵循"用户体验优先"原则
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null) return;
    
    // 如果没有更多数据，直接返回
    if (!currentState.hasMore) return;
    
    // 如果正在筛选，不支持加载更多
    if (ref.read(communityFilterProvider).isActive) return;

    // 如果正在加载，直接返回
    if (state.isLoading) return;
    
    // 使用 AsyncValue.guard 自动处理错误
    final result = await AsyncValue.guard(() async {
      final newPosts = await _loadPosts(lastTimestamp: _lastTimestamp);
      return currentState.copyWith(
        posts: [...currentState.posts, ...newPosts],
        hasMore: newPosts.length >= 20,
      );
    });
    
    // 只在成功时更新状态
    if (result.hasValue) {
      state = result;
    }
    // 失败时保持当前状态，用户仍可看到已加载的数据
    // 不显示错误提示，避免打扰用户（用户可以下拉刷新重试）
  }

  /// 删除帖子
  /// 
  /// Fail Fast:
  /// - 如果用户未登录，抛出 StateError
  /// - 如果 postId 为空，抛出 ArgumentError
  /// 
  /// 调用者：CommunityPostCard（长按菜单）
  Future<void> deletePost(String postId) async {
    // Fail Fast: 用户必须登录
    final authState = ref.read(authProvider);
    final currentUser = authState.value;
    
    if (currentUser == null) {
      throw Exception('必须登录后才可删除');
    }

    try {
      // 删除帖子
      await _repository.deletePost(postId, currentUser.id);

      // 通知收藏 Provider 刷新（帖子删除后收藏页需要展示「已被删除」标注）
      ref.invalidate(favoritesProvider);

      // 静默刷新帖子列表（避免页面闪烁）
      await refreshSilently();
    } catch (e) {
      // 使用 AuthErrorHelper 清理异常前缀
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 判断当前用户是否可以删除指定帖子
  /// 
  /// 规则：
  /// - 用户必须已登录
  /// - 帖子必须是当前用户发布的
  /// 
  /// 调用者：CommunityPage（决定是否显示删除按钮）
  bool canDeletePost(String postUserId) {
    final authState = ref.read(authProvider);
    final currentUser = authState.value;
    
    if (currentUser == null) return false;
    return currentUser.id == postUserId;
  }

}

/// 社区帖子列表 Provider
final communityProvider = AsyncNotifierProvider<CommunityNotifier, CommunityState>(() {
  return CommunityNotifier();
});

/// 我的帖子列表 Provider
/// 
/// 职责：
/// - 管理当前用户发布的帖子列表状态
/// - 支持刷新和删除
/// 
/// 调用者：MyPostsPage
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责"我的帖子"业务逻辑
/// - 依赖倒置（DIP）：直接依赖 CommunityRepository，与 CommunityNotifier 平级
/// - 无横向耦合：不依赖 communityProvider，避免 Notifier 间互相调用
final myPostsProvider = AsyncNotifierProvider<MyPostsNotifier, List<CommunityPost>>(() {
  return MyPostsNotifier();
});

/// 我的帖子状态管理
/// 
/// 职责：
/// - 加载当前用户的帖子列表
/// - 监听筛选条件变化并自动过滤
/// - 刷新帖子列表
/// - 删除帖子后自动刷新
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责"我的帖子"业务逻辑
/// - 依赖倒置（DIP）：直接依赖 CommunityRepository，与 CommunityNotifier 平级
/// - 自动响应：监听 myPostsFilterProvider 变化，自动过滤
/// 
/// 调用者：MyPostsPage
class MyPostsNotifier extends AsyncNotifier<List<CommunityPost>> {
  late CommunityRepository _repository;

  @override
  Future<List<CommunityPost>> build() async {
    _repository = ref.read(communityRepositoryProvider);

    // 监听筛选条件变化，自动重新执行
    final filterCriteria = ref.watch(myPostsFilterProvider);

    // Fail Fast：用户必须登录
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) {
      throw Exception('必须登录后才可查看我的发布');
    }

    try {
      if (filterCriteria.isActive) {
        // 筛选激活时：服务端过滤（与 CommunityNotifier 对齐）
        return await _repository.filterMyPosts(
          userId: currentUser.id,
          startDate: filterCriteria.startDate,
          endDate: filterCriteria.endDate,
          publishStartDate: filterCriteria.publishStartDate,
          publishEndDate: filterCriteria.publishEndDate,
          province: filterCriteria.province,
          city: filterCriteria.city,
          area: filterCriteria.area,
          placeTypes: filterCriteria.placeTypes,
          tags: filterCriteria.tags,
          statuses: filterCriteria.statuses,
          tagMatchMode: filterCriteria.tagMatchMode,
        );
      } else {
        // 无筛选：全量拉取当前用户帖子
        return await _repository.getMyPosts(currentUser.id);
      }
    } catch (e) {
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 刷新我的帖子列表
  ///
  /// 使用 invalidateSelf() 让 build() 重新执行，自动应用当前筛选条件。
  ///
  /// 调用者：MyPostsPage（下拉刷新）
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// 删除帖子
  ///
  /// 调用者：MyPostsPage（删除按钮）
  ///
  /// 设计说明：
  /// - 直接调用 _repository.deletePost，不经由 CommunityNotifier
  /// - 删除成功后通知 communityProvider 静默刷新（保持树洞列表同步）
  /// - 自身使用静默刷新，避免页面闪烁
  Future<void> deletePost(String postId) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) {
      throw Exception('必须登录后才可删除');
    }

    try {
      await _repository.deletePost(postId, currentUser.id);
    } catch (e) {
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }

    // 通知收藏 Provider 刷新（帖子删除后收藏页需要展示「已被删除」标注）
    ref.invalidate(favoritesProvider);

    // 通知树洞列表同步（静默，不阻塞当前页面）
    ref.read(communityProvider.notifier).refreshSilently();

    // 静默刷新自身列表（避免页面闪烁）
    ref.invalidateSelf();
    await future;
  }
}
