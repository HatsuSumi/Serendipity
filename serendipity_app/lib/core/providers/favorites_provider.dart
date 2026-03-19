import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import '../repositories/community_repository.dart';
import '../utils/auth_error_helper.dart';
import 'auth_provider.dart';
import 'community_provider.dart';
import 'records_provider.dart';

/// 获取收藏记录的结果
///
/// 区分仍存在的记录 ID 和已被删除的记录 ID，
/// 避免将「记录不存在」与「网络错误」混淆。
class FavoritedRecordsResult {
  /// 仍然存在的收藏记录 ID
  final Set<String> recordIds;

  /// 已被删除但收藏关系仍存在的记录 ID
  final Set<String> deletedRecordIds;

  const FavoritedRecordsResult({
    required this.recordIds,
    required this.deletedRecordIds,
  });
}

/// 获取收藏帖子的结果
///
/// 区分仍存在的帖子和已被删除的帖子 ID，
/// 避免将「帖子不存在」与「网络错误」混淆。
class FavoritedPostsResult {
  /// 仍然存在的收藏帖子
  final List<CommunityPost> posts;

  /// 已被删除但收藏关系仍存在的帖子 ID
  final Set<String> deletedPostIds;

  const FavoritedPostsResult({
    required this.posts,
    required this.deletedPostIds,
  });
}

/// 收藏状态
///
/// 职责：
/// - 存储收藏的社区帖子列表
/// - 存储已被删除但仍在收藏中的帖子完整数据（从本地快照读取）
/// - 存储收藏的记录 ID 集合（用于判断某条记录是否已收藏）
/// - 存储已被删除但仍在收藏中的记录完整数据（从本地快照读取）
///
/// 设计原则：
/// - 单一职责（SRP）：只负责收藏状态
/// - 不可变对象：使用 copyWith 模式
class FavoritesState {
  /// 收藏的社区帖子列表（从服务端拉取，帖子仍存在）
  final List<CommunityPost> favoritedPosts;

  /// 已被删除但仍在收藏中的帖子完整数据（从本地快照读取）
  ///
  /// UI 层在卡片右下角显示「该帖子已被删除」。
  final List<CommunityPost> deletedFavoritedPosts;

  /// 收藏的记录 ID 集合（仍存在的记录，从服务端拉取）
  final Set<String> favoritedRecordIds;

  /// 已被删除但仍在收藏中的记录完整数据（从本地快照读取）
  ///
  /// UI 层在卡片右下角显示「该记录已被删除」。
  final List<EncounterRecord> deletedFavoritedRecords;

  /// 收藏的帖子 ID 集合（派生自 favoritedPosts，用于 O(1) 查找）
  final Set<String> _favoritedPostIds;

  /// 已被删除的帖子 ID 集合（派生自 deletedFavoritedPosts，用于 O(1) 查找）
  final Set<String> _deletedFavoritedPostIds;

  /// 已被删除的记录 ID 集合（派生自 deletedFavoritedRecords，用于 O(1) 查找）
  final Set<String> _deletedFavoritedRecordIds;

  FavoritesState({
    this.favoritedPosts = const [],
    this.deletedFavoritedPosts = const [],
    this.favoritedRecordIds = const {},
    this.deletedFavoritedRecords = const [],
  })  : _favoritedPostIds = {for (final p in favoritedPosts) p.id},
        _deletedFavoritedPostIds = {for (final p in deletedFavoritedPosts) p.id},
        _deletedFavoritedRecordIds = {for (final r in deletedFavoritedRecords) r.id};

  FavoritesState copyWith({
    List<CommunityPost>? favoritedPosts,
    List<CommunityPost>? deletedFavoritedPosts,
    Set<String>? favoritedRecordIds,
    List<EncounterRecord>? deletedFavoritedRecords,
  }) {
    return FavoritesState(
      favoritedPosts: favoritedPosts ?? this.favoritedPosts,
      deletedFavoritedPosts: deletedFavoritedPosts ?? this.deletedFavoritedPosts,
      favoritedRecordIds: favoritedRecordIds ?? this.favoritedRecordIds,
      deletedFavoritedRecords: deletedFavoritedRecords ?? this.deletedFavoritedRecords,
    );
  }

  /// 判断某个帖子是否已收藏（O(1) 查找）
  bool isPostFavorited(String postId) => _favoritedPostIds.contains(postId);

  /// 判断某条记录是否已收藏（O(1) 查找）
  bool isRecordFavorited(String recordId) =>
      favoritedRecordIds.contains(recordId);

  /// 判断某个帖子是否已被删除（O(1) 查找）
  bool isPostDeleted(String postId) =>
      _deletedFavoritedPostIds.contains(postId);

  /// 判断某条记录是否已被删除（O(1) 查找）
  bool isRecordDeleted(String recordId) =>
      _deletedFavoritedRecordIds.contains(recordId);
}

/// 收藏状态管理
///
/// 职责：
/// - 初始化时从服务端加载收藏数据，从本地快照读已删除条目的完整数据
/// - 收藏时同步写入本地快照
/// - 取消收藏时同步删除本地快照
/// - 提供收藏的记录列表
///
/// 设计原则：
/// - 单一职责（SRP）：只负责收藏业务逻辑
/// - 依赖倒置（DIP）：依赖 CommunityRepository 抽象
/// - Fail Fast：用户未登录时立即抛出
///
/// 调用者：
/// - FavoritesPage（我的收藏页面）
/// - CommunityPostCard（收藏按钮状态）
/// - TimelinePage（记录卡片收藏菜单）
class FavoritesNotifier extends AsyncNotifier<FavoritesState> {
  late CommunityRepository _repository;

  @override
  Future<FavoritesState> build() async {
    _repository = ref.read(communityRepositoryProvider);
    final storage = ref.read(storageServiceProvider);

    // Fail Fast：用户必须登录
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) {
      throw Exception('必须登录后才可查看收藏');
    }

    try {
      // 并发加载两类收藏数据
      final results = await Future.wait([
        _repository.getFavoritedPostsResult(currentUser.id),
        _repository.getFavoritedRecordsResult(currentUser.id),
      ]);

      final postsResult = results[0] as FavoritedPostsResult;
      final recordsResult = results[1] as FavoritedRecordsResult;

      // 从本地快照读已删除帖子的完整数据
      final deletedFavoritedPosts = postsResult.deletedPostIds
          .map((id) {
            final json = storage.getFavoritedPostSnapshot(id);
            if (json == null) return null;
            return CommunityPost.fromJson(json);
          })
          .whereType<CommunityPost>()
          .toList();

      // 从本地快照读已删除记录的完整数据
      final deletedFavoritedRecords = recordsResult.deletedRecordIds
          .map((id) => storage.getFavoritedRecordSnapshot(id))
          .whereType<EncounterRecord>()
          .toList();

      return FavoritesState(
        favoritedPosts: postsResult.posts,
        deletedFavoritedPosts: deletedFavoritedPosts,
        favoritedRecordIds: recordsResult.recordIds,
        deletedFavoritedRecords: deletedFavoritedRecords,
      );
    } catch (e) {
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 刷新收藏列表
  ///
  /// 调用者：FavoritesPage（下拉刷新）
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// 收藏社区帖子
  ///
  /// 乐观更新：先更新本地状态，再发请求，失败时回滚。
  /// 同时写入本地快照，以便帖子被删除后仍能展示完整数据。
  ///
  /// 注意：签名从 favoritePost(String postId) 改为 favoritePost(CommunityPost post)
  /// 调用方需传入完整帖子对象以便写入快照。
  ///
  /// 调用者：CommunityPostCard、MyPostsPage
  Future<void> favoritePost(CommunityPost post) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) throw Exception('必须登录后才可收藏');

    final currentState = state.value;
    if (currentState == null) return;

    // Fail Fast：已收藏则幂等返回
    if (currentState.isPostFavorited(post.id)) return;

    // 写入本地快照
    final storage = ref.read(storageServiceProvider);
    await storage.saveFavoritedPostSnapshot(post.id, post.toJson());

    try {
      await _repository.favoritePost(currentUser.id, post.id);
      // 重新拉取以获得完整帖子数据
      final updatedPosts = await _repository.getFavoritedPosts(currentUser.id);
      state = AsyncData(
        currentState.copyWith(favoritedPosts: updatedPosts),
      );
    } catch (e) {
      // 快照无需回滚（下次收藏会覆盖）
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 取消收藏社区帖子
  ///
  /// 乐观更新：先从本地移除，再发请求，失败时回滚。
  /// 同时删除本地快照。
  ///
  /// 调用者：CommunityPostCard、MyPostsPage、FavoritesPage
  Future<void> unfavoritePost(String postId) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) throw Exception('必须登录后才可取消收藏');

    final currentState = state.value;
    if (currentState == null) return;

    // 乐观更新：从正常列表或已删除列表中移除
    final optimisticPosts =
        currentState.favoritedPosts.where((p) => p.id != postId).toList();
    final optimisticDeletedPosts =
        currentState.deletedFavoritedPosts.where((p) => p.id != postId).toList();
    state = AsyncData(currentState.copyWith(
      favoritedPosts: optimisticPosts,
      deletedFavoritedPosts: optimisticDeletedPosts,
    ));

    // 删除本地快照
    final storage = ref.read(storageServiceProvider);
    await storage.deleteFavoritedPostSnapshot(postId);

    try {
      await _repository.unfavoritePost(currentUser.id, postId);
    } catch (e) {
      // 回滚
      state = AsyncData(currentState);
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 收藏私人记录
  ///
  /// 同时写入本地快照，以便记录被删除后仍能展示完整数据。
  ///
  /// 注意：签名从 favoriteRecord(String recordId) 改为 favoriteRecord(EncounterRecord record)
  /// 调用方需传入完整记录对象以便写入快照。
  ///
  /// 调用者：TimelinePage（记录卡片菜单）
  Future<void> favoriteRecord(EncounterRecord record) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) throw Exception('必须登录后才可收藏');

    final currentState = state.value;
    if (currentState == null) return;

    // Fail Fast：已收藏则幂等返回
    if (currentState.isRecordFavorited(record.id)) return;

    // 写入本地快照
    final storage = ref.read(storageServiceProvider);
    await storage.saveFavoritedRecordSnapshot(record);

    // 乐观更新
    final optimisticIds = {...currentState.favoritedRecordIds, record.id};
    state = AsyncData(currentState.copyWith(favoritedRecordIds: optimisticIds));

    try {
      await _repository.favoriteRecord(currentUser.id, record.id);
    } catch (e) {
      // 回滚
      state = AsyncData(currentState);
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 取消收藏私人记录
  ///
  /// 同时删除本地快照。
  ///
  /// 调用者：TimelinePage、FavoritesPage
  Future<void> unfavoriteRecord(String recordId) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) throw Exception('必须登录后才可取消收藏');

    final currentState = state.value;
    if (currentState == null) return;

    // 乐观更新：从正常列表或已删除列表中移除
    final optimisticIds = {...currentState.favoritedRecordIds}..remove(recordId);
    final optimisticDeletedRecords =
        currentState.deletedFavoritedRecords.where((r) => r.id != recordId).toList();
    state = AsyncData(currentState.copyWith(
      favoritedRecordIds: optimisticIds,
      deletedFavoritedRecords: optimisticDeletedRecords,
    ));

    // 删除本地快照
    final storage = ref.read(storageServiceProvider);
    await storage.deleteFavoritedRecordSnapshot(recordId);

    try {
      await _repository.unfavoriteRecord(currentUser.id, recordId);
    } catch (e) {
      // 回滚
      state = AsyncData(currentState);
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 获取收藏的记录列表
  ///
  /// 返回：
  /// - records：仍存在的收藏记录列表（从本地 Hive 按 ID 过滤）
  /// - deletedRecords：已被删除的收藏记录完整数据（从本地快照读取）
  ///
  /// 调用者：FavoritesPage（收藏的记录 Tab）
  ({List<EncounterRecord> records, List<EncounterRecord> deletedRecords}) getFavoritedRecords() {
    final favoritedIds = state.value?.favoritedRecordIds ?? {};
    final deletedRecords = state.value?.deletedFavoritedRecords ?? [];

    final allRecords = ref.read(recordsProvider).value ?? [];
    final records = favoritedIds.isEmpty
        ? <EncounterRecord>[]
        : allRecords.where((r) => favoritedIds.contains(r.id)).toList();

    return (records: records, deletedRecords: deletedRecords);
  }
}

/// 收藏 Provider
///
/// 调用者：
/// - FavoritesPage
/// - CommunityPostCard
/// - TimelinePage
final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, FavoritesState>(() {
  return FavoritesNotifier();
});
