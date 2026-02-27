import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../repositories/community_repository.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';
import 'achievement_provider.dart';
import '../services/achievement_detector.dart';

/// 社区仓储 Provider
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.read(remoteDataRepositoryProvider));
});

/// 社区状态管理
/// 
/// 职责：
/// - 管理社区帖子列表状态
/// - 发布记录到社区
/// - 删除自己的帖子
/// - 筛选帖子
/// - 加载更多帖子（分页）
/// 
/// 调用者：
/// - CommunityPage（UI 层）
class CommunityNotifier extends AsyncNotifier<List<CommunityPost>> {
  late CommunityRepository _repository;
  
  /// 是否还有更多数据
  bool _hasMore = true;
  
  /// 最后一条帖子的时间戳（用于分页）
  DateTime? _lastTimestamp;

  @override
  Future<List<CommunityPost>> build() async {
    _repository = ref.read(communityRepositoryProvider);
    // 初始化时加载第一页
    return await _loadPosts();
  }

  /// 获取成就检测服务
  AchievementDetector get _achievementDetector => ref.read(achievementDetectorProvider);

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
    if (posts.length < limit) {
      _hasMore = false;
    }
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
    _hasMore = true;
    _lastTimestamp = null;
    
    state = await AsyncValue.guard(() async {
      return await _loadPosts();
    });
  }

  /// 加载更多帖子
  /// 
  /// 调用者：CommunityPage（滚动到底部）
  Future<void> loadMore() async {
    // 如果没有更多数据，直接返回
    if (!_hasMore) return;

    // 如果正在加载，直接返回
    if (state.isLoading) return;

    final currentPosts = state.value ?? [];
    
    // 加载下一页
    final newPosts = await _loadPosts(lastTimestamp: _lastTimestamp);
    
    // 合并数据
    state = AsyncValue.data([...currentPosts, ...newPosts]);
  }

  /// 发布记录到社区
  /// 
  /// Fail Fast:
  /// - 如果用户未登录，抛出 StateError
  /// - 如果记录为 null，抛出 ArgumentError
  /// 
  /// 调用者：
  /// - RecordDetailPage（记录详情页菜单）
  /// - CreateRecordPage（创建记录时勾选"发布到树洞"）
  /// - TimelinePage（时间轴页面菜单）
  Future<void> publishPost(EncounterRecord record) async {
    // Fail Fast: 用户必须登录
    final authState = ref.read(authProvider);
    final currentUser = authState.value;
    
    if (currentUser == null) {
      throw StateError('必须登录后才可发布');
    }

    // 发布到社区
    await _repository.publishPost(record, currentUser.id);

    // 检测社区成就
    try {
      final unlockedAchievements = await _achievementDetector.checkCommunityAchievements(currentUser.id);
      if (unlockedAchievements.isNotEmpty) {
        // 通知UI层显示成就解锁通知
        ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
        // 刷新成就列表
        ref.invalidate(achievementsProvider);
      }
    } catch (e) {
      // 成就检测失败不影响发布
    }

    // 刷新帖子列表
    await refresh();
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
      throw StateError('必须登录后才可删除');
    }

    // 删除帖子
    await _repository.deletePost(postId, currentUser.id);

    // 刷新帖子列表
    await refresh();
  }

  /// 筛选帖子
  /// 
  /// 参数：
  /// - startDate: 开始日期（可选）
  /// - endDate: 结束日期（可选）
  /// - cityName: 城市名称（可选）
  /// - placeType: 场所类型（可选）
  /// - tag: 标签名称（可选）
  /// - status: 状态（可选）
  /// 
  /// 调用者：CommunityPage（筛选对话框）
  Future<void> filterPosts({
    DateTime? startDate,
    DateTime? endDate,
    String? cityName,
    PlaceType? placeType,
    String? tag,
    EncounterStatus? status,
  }) async {
    state = const AsyncValue.loading();
    _hasMore = false; // 筛选结果不支持分页
    _lastTimestamp = null;

    state = await AsyncValue.guard(() async {
      return await _repository.filterPosts(
        startDate: startDate,
        endDate: endDate,
        cityName: cityName,
        placeType: placeType,
        tag: tag,
        status: status,
      );
    });
  }

  /// 清除筛选（恢复默认列表）
  /// 
  /// 调用者：CommunityPage（清除筛选按钮）
  Future<void> clearFilter() async {
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
      throw StateError('必须登录后才可查看我的发布');
    }

    return await _repository.getMyPosts(currentUser.id);
  }
}

/// 社区帖子列表 Provider
final communityProvider = AsyncNotifierProvider<CommunityNotifier, List<CommunityPost>>(() {
  return CommunityNotifier();
});

