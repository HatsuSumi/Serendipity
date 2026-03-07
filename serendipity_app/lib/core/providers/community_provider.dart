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

// 导出发布 Provider
export 'community_publish_provider.dart';
// 导出筛选 Provider
export 'community_filter_provider.dart';

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
/// - 删除自己的帖子
/// - 筛选帖子
/// - 加载更多帖子（分页）
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
  
  /// 标志位：是否正在执行筛选（防止无限递归）
  bool _isFiltering = false;

  @override
  Future<CommunityState> build() async {
    _repository = ref.read(communityRepositoryProvider);
    
    // 监听筛选条件变化
    ref.listen(communityFilterProvider, (previous, next) {
      // 当筛选条件变化时，自动重新加载
      if (previous != next) {
        _onFilterChanged(next);
      }
    });
    
    // 初始化时加载第一页
    final posts = await _loadPosts();
    return CommunityState(
      posts: posts,
      isFiltering: false,
      hasMore: posts.length >= 20,
    );
  }

  /// 筛选条件变化时的处理
  /// 
  /// 自动响应筛选条件变化，重新加载数据
  Future<void> _onFilterChanged(CommunityFilterCriteria filter) async {
    // 如果正在执行筛选，忽略此次变化（防止无限递归）
    if (_isFiltering) return;
    
    if (filter.hasAnyFilter) {
      // 有筛选条件，执行筛选
      await filterPosts(
        startDate: filter.startDate,
        endDate: filter.endDate,
        publishStartDate: filter.publishStartDate,
        publishEndDate: filter.publishEndDate,
        province: filter.province,
        city: filter.city,
        area: filter.area,
        placeTypes: filter.placeTypes,
        tags: filter.tags,
        statuses: filter.statuses,
      );
    } else {
      // 无筛选条件，刷新列表
      await refresh();
    }
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

  /// 筛选帖子
  /// 
  /// 参数：
  /// - startDate: 错过时间开始日期（可选）
  /// - endDate: 错过时间结束日期（可选）
  /// - publishStartDate: 发布时间开始日期（可选）
  /// - publishEndDate: 发布时间结束日期（可选）
  /// - province: 省份（可选）
  /// - city: 城市（可选）
  /// - area: 区县（可选）
  /// - placeTypes: 场所类型列表（可选，多选OR逻辑）
  /// - tags: 标签名称列表（可选，多选OR逻辑）
  /// - statuses: 状态列表（可选，多选OR逻辑）
  /// 
  /// 调用者：
  /// - CommunityFilterDialog（筛选对话框）
  /// - _onFilterChanged（筛选条件变化时自动调用）
  Future<void> filterPosts({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? publishStartDate,
    DateTime? publishEndDate,
    String? province,
    String? city,
    String? area,
    List<PlaceType>? placeTypes,
    List<String>? tags,
    List<EncounterStatus>? statuses,
  }) async {
    // 设置标志位，防止无限递归
    _isFiltering = true;
    
    try {
      // 先更新筛选条件到 Provider，以便对话框下次打开时能读取
      final criteria = CommunityFilterCriteria(
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
      );
      ref.read(communityFilterProvider.notifier).updateFilter(criteria);
      
      state = const AsyncValue.loading();
      _lastTimestamp = null;

      state = await AsyncValue.guard(() async {
        final posts = await _repository.filterPosts(
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
        );
        
        return CommunityState(
          posts: posts,
          isFiltering: true,
          hasMore: false, // 筛选结果不支持分页
        );
      });
    } finally {
      // 无论成功还是失败，都要重置标志位
      _isFiltering = false;
    }
  }

  /// 清除筛选（恢复默认列表）
  /// 
  /// 调用者：CommunityPage（清除筛选按钮）
  Future<void> clearFilter() async {
    // 先清除筛选条件
    ref.read(communityFilterProvider.notifier).clearFilter();
    
    // 立即刷新列表，恢复到默认状态
    await refresh();
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

  /// 获取当前用户发布的所有帖子
  /// 
  /// Fail Fast:
  /// - 如果用户未登录，抛出 StateError
  /// 
  /// 调用者：MyPostsPage（我的发布页面）
  /// 
  /// 返回：用户发布的帖子列表
  Future<List<CommunityPost>> getMyPosts() async {
    // Fail Fast: 用户必须登录
    final authState = ref.read(authProvider);
    final currentUser = authState.value;
    
    if (currentUser == null) {
      throw Exception('必须登录后才可查看我的发布');
    }

    try {
      return await _repository.getMyPosts(currentUser.id);
    } catch (e) {
      // 使用 AuthErrorHelper 清理异常前缀
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
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
/// - 支持刷新
/// 
/// 调用者：MyPostsPage
/// 
/// 遵循原则：
/// - 单一数据源（Single Source of Truth）
/// - 状态管理规则：UI层不维护业务状态
/// - 分层约束：状态管理层负责业务逻辑
final myPostsProvider = AsyncNotifierProvider<MyPostsNotifier, List<CommunityPost>>(() {
  return MyPostsNotifier();
});

/// 我的帖子状态管理
/// 
/// 职责：
/// - 加载当前用户的帖子列表
/// - 刷新帖子列表
/// - 删除帖子后自动刷新
/// 
/// 调用者：MyPostsPage
class MyPostsNotifier extends AsyncNotifier<List<CommunityPost>> {
  @override
  Future<List<CommunityPost>> build() async {
    final communityNotifier = ref.read(communityProvider.notifier);
    return await communityNotifier.getMyPosts();
  }

  /// 刷新我的帖子列表
  /// 
  /// 调用者：MyPostsPage（下拉刷新）
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final communityNotifier = ref.read(communityProvider.notifier);
      return await communityNotifier.getMyPosts();
    });
  }

  /// 删除帖子
  /// 
  /// 调用者：MyPostsPage（删除按钮）
  /// 
  /// 优化说明：
  /// - 删除成功后自动刷新列表
  /// - 使用静默刷新避免页面闪烁
  Future<void> deletePost(String postId) async {
    final communityNotifier = ref.read(communityProvider.notifier);
    
    // 删除帖子
    await communityNotifier.deletePost(postId);
    
    // 删除成功后静默刷新列表（避免页面闪烁）
    await _refreshSilently();
  }

  /// 静默刷新我的帖子列表（不显示 loading 状态）
  /// 
  /// 用于删除帖子后的刷新，避免页面闪烁
  /// 
  /// 调用者：deletePost
  Future<void> _refreshSilently() async {
    final currentState = state.value;
    if (currentState == null) {
      // 如果当前没有数据，使用普通刷新
      await refresh();
      return;
    }

    // 使用 AsyncValue.guard，它会自动捕获错误
    final result = await AsyncValue.guard(() async {
      final communityNotifier = ref.read(communityProvider.notifier);
      return await communityNotifier.getMyPosts();
    });
    
    // 只在成功时更新状态，失败时保持当前状态不变
    if (result.hasValue) {
      state = result;
    }
  }
}

