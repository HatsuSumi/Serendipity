import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community_post.dart';
import '../../models/enums.dart';
import '../repositories/community_repository.dart';
import '../repositories/i_community_data_source.dart';
import '../repositories/remote_community_data_source.dart';
import '../repositories/test_community_data_source.dart';
import '../services/sync_service.dart';
import '../utils/auth_error_helper.dart';
import '../config/app_config.dart';
import 'auth_provider.dart';
import 'community_filter_provider.dart';
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
/// - 存储筛选状态
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责列表状态
/// - 筛选条件独立管理：使用 communityFilterProvider
class CommunityState {
  final List<CommunityPost> posts;
  final bool isFiltering;
  final bool hasMore;

  const CommunityState({
    required this.posts,
    this.isFiltering = false,
    this.hasMore = true,
  });

  CommunityState copyWith({
    List<CommunityPost>? posts,
    bool? isFiltering,
    bool? hasMore,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      isFiltering: isFiltering ?? this.isFiltering,
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
        isFiltering: false,
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
      isFiltering: true,
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
  /// 调用者：CommunityPage（下拉刷新）
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _lastTimestamp = null;
    
    state = await AsyncValue.guard(() async {
      final posts = await _loadPosts();
      return CommunityState(
        posts: posts,
        isFiltering: false,
        hasMore: posts.length >= 20,
      );
    });
  }

  /// 静默刷新帖子列表（不显示 loading 状态）
  /// 
  /// 用于发布/删除帖子后的刷新，避免页面闪烁
  /// 
  /// 优化说明：
  /// - 使用 AsyncValue.guard 自动捕获错误
  /// - 失败时保持当前状态不变
  /// - 利用 Riverpod 的内置错误处理机制
  /// 
  /// 调用者：
  /// - publishPost（发布后刷新）
  /// - deletePost（删除后刷新）
  /// - MyPostsNotifier.deletePost（删除后同步）
  Future<void> refreshSilently() async {
    final currentState = state.value;
    if (currentState == null) {
      // 如果当前没有数据，使用普通刷新
      await refresh();
      return;
    }

    _lastTimestamp = null;
    
    // 使用 AsyncValue.guard，它会自动捕获错误
    final result = await AsyncValue.guard(() async {
      final posts = await _loadPosts();
      return CommunityState(
        posts: posts,
        isFiltering: false,
        hasMore: posts.length >= 20,
      );
    });
    
    // 只在成功时更新状态，失败时保持当前状态不变
    if (result.hasValue) {
      state = result;
    }
    // 失败时什么都不做，保持当前状态，用户仍可看到旧数据
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
    if (currentState.isFiltering) return;

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
    
    // 监听筛选条件变化，自动重新过滤
    final filterCriteria = ref.watch(myPostsFilterProvider);
    
    // 获取当前用户的帖子
    var posts = await _fetchMyPosts();
    
    // 应用筛选条件
    if (filterCriteria.isActive) {
      posts = _applyFilterCriteria(posts, filterCriteria);
    }
    
    return posts;
  }

  /// 从仓储获取当前用户的帖子（内部方法）
  /// 
  /// Fail Fast：用户未登录时抛出 Exception
  Future<List<CommunityPost>> _fetchMyPosts() async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) {
      throw Exception('必须登录后才可查看我的发布');
    }
    try {
      return await _repository.getMyPosts(currentUser.id);
    } catch (e) {
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 应用筛选条件到帖子列表
  /// 
  /// 职责：
  /// - 根据筛选条件过滤帖子
  /// - 支持多条件组合（AND 逻辑）
  /// 
  /// 设计原则：
  /// - Fail Fast：条件不合法时直接返回空列表
  /// - 高效过滤：使用 where 链式调用
  /// - 不修改原列表：返回新列表
  /// 
  /// 调用者：build()
  List<CommunityPost> _applyFilterCriteria(
    List<CommunityPost> posts,
    MyPostsFilterCriteria criteria,
  ) {
    return posts.where((post) {
      // 时间范围筛选（错过时间）
      if (criteria.startDate != null && post.timestamp.isBefore(criteria.startDate!)) {
        return false;
      }
      if (criteria.endDate != null && post.timestamp.isAfter(criteria.endDate!)) {
        return false;
      }

      // 发布时间范围筛选
      if (criteria.publishStartDate != null && post.publishedAt.isBefore(criteria.publishStartDate!)) {
        return false;
      }
      if (criteria.publishEndDate != null && post.publishedAt.isAfter(criteria.publishEndDate!)) {
        return false;
      }

      // 场所类型筛选
      if (criteria.placeTypes != null && criteria.placeTypes!.isNotEmpty) {
        if (!criteria.placeTypes!.contains(post.placeType)) {
          return false;
        }
      }

      // 状态筛选
      if (criteria.statuses != null && criteria.statuses!.isNotEmpty) {
        if (!criteria.statuses!.contains(post.status)) {
          return false;
        }
      }

      // 地区筛选
      if (criteria.province != null && post.province != criteria.province) {
        return false;
      }
      if (criteria.city != null && post.city != criteria.city) {
        return false;
      }
      if (criteria.area != null && post.area != criteria.area) {
        return false;
      }

      // 标签筛选
      if (criteria.tags != null && criteria.tags!.isNotEmpty) {
        final postTags = post.tags.map((t) => t.tag).toList();
        final hasMatch = criteria.tags!.any((tag) {
          if (criteria.tagMatchMode == TagMatchMode.wholeWord) {
            return postTags.contains(tag);
          } else {
            return postTags.any((postTag) => postTag.contains(tag));
          }
        });
        if (!hasMatch) return false;
      }

      return true;
    }).toList();
  }

  /// 刷新我的帖子列表
  /// 
  /// 调用者：MyPostsPage（下拉刷新）
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchMyPosts);
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

    // 通知树洞列表同步（静默，不阻塞当前页面）
    ref.read(communityProvider.notifier).refreshSilently();

    // 静默刷新自身列表
    await _refreshSilently();
  }

  /// 静默刷新我的帖子列表（不显示 loading 状态）
  /// 
  /// 调用者：deletePost
  Future<void> _refreshSilently() async {
    if (state.value == null) {
      await refresh();
      return;
    }
    final result = await AsyncValue.guard(_fetchMyPosts);
    if (result.hasValue) {
      state = result;
    }
  }

  /// 从后端筛选我的帖子
  /// 
  /// 调用者：MyPostsPage._fetchFilteredPosts()
  Future<List<CommunityPost>> filterPostsFromServer({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? publishStartDate,
    DateTime? publishEndDate,
    String? province,
    String? city,
    String? area,
    List<String>? placeTypes,
    List<String>? tags,
    List<String>? statuses,
    String tagMatchMode = 'contains',
    int limit = 20,
  }) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) {
      throw Exception('必须登录后才可筛选');
    }

    try {
      return await _repository.filterPostsFromServer(
        userId: currentUser.id,
        startDate: startDate,
        endDate: endDate,
        publishStartDate: publishStartDate,
        publishEndDate: publishEndDate,
        province: province,
        city: city,
        area: area,
        placeTypes: placeTypes,
        tags: tags,
        statuses: statuses,
        tagMatchMode: tagMatchMode,
        limit: limit,
      );
    } catch (e) {
      throw Exception('筛选帖子失败：${AuthErrorHelper.extractErrorMessage(e)}');
    }
  }
}
