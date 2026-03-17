import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import '../repositories/community_repository.dart';
import '../utils/auth_error_helper.dart';
import 'auth_provider.dart';
import 'community_provider.dart';
import 'records_provider.dart';

/// 收藏状态
///
/// 职责：
/// - 存储收藏的社区帖子列表
/// - 存储收藏的记录 ID 集合（用于判断某条记录是否已收藏）
///
/// 设计原则：
/// - 单一职责（SRP）：只负责收藏状态
/// - 不可变对象：使用 copyWith 模式
class FavoritesState {
  /// 收藏的社区帖子列表（从服务端拉取）
  final List<CommunityPost> favoritedPosts;

  /// 收藏的记录 ID 集合（从服务端拉取，用于本地 Hive 过滤展示）
  final Set<String> favoritedRecordIds;

  const FavoritesState({
    this.favoritedPosts = const [],
    this.favoritedRecordIds = const {},
  });

  FavoritesState copyWith({
    List<CommunityPost>? favoritedPosts,
    Set<String>? favoritedRecordIds,
  }) {
    return FavoritesState(
      favoritedPosts: favoritedPosts ?? this.favoritedPosts,
      favoritedRecordIds: favoritedRecordIds ?? this.favoritedRecordIds,
    );
  }

  /// 判断某个帖子是否已收藏（O(1) 查找）
  bool isPostFavorited(String postId) =>
      favoritedPosts.any((p) => p.id == postId);

  /// 判断某条记录是否已收藏（O(1) 查找）
  bool isRecordFavorited(String recordId) =>
      favoritedRecordIds.contains(recordId);
}

/// 收藏状态管理
///
/// 职责：
/// - 初始化时从服务端加载收藏数据
/// - 收藏/取消收藏帖子和记录
/// - 提供收藏的记录列表（本地 Hive 过滤）
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

    // Fail Fast：用户必须登录
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) {
      throw Exception('必须登录后才可查看收藏');
    }

    try {
      // 并发加载两类收藏数据
      final results = await Future.wait([
        _repository.getFavoritedPosts(currentUser.id),
        _repository.getFavoritedRecordIds(currentUser.id),
      ]);

      return FavoritesState(
        favoritedPosts: results[0] as List<CommunityPost>,
        favoritedRecordIds: results[1] as Set<String>,
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
  ///
  /// 调用者：CommunityPostCard、MyPostsPage
  Future<void> favoritePost(String postId) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) throw Exception('必须登录后才可收藏');

    final currentState = state.value;
    if (currentState == null) return;

    // Fail Fast：已收藏则幂等返回
    if (currentState.isPostFavorited(postId)) return;

    try {
      await _repository.favoritePost(currentUser.id, postId);
      // 重新拉取以获得完整帖子数据
      final updatedPosts =
          await _repository.getFavoritedPosts(currentUser.id);
      state = AsyncData(
        currentState.copyWith(favoritedPosts: updatedPosts),
      );
    } catch (e) {
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 取消收藏社区帖子
  ///
  /// 乐观更新：先从本地移除，再发请求，失败时回滚。
  ///
  /// 调用者：CommunityPostCard、MyPostsPage、FavoritesPage
  Future<void> unfavoritePost(String postId) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) throw Exception('必须登录后才可取消收藏');

    final currentState = state.value;
    if (currentState == null) return;

    // 乐观更新本地状态
    final optimisticPosts =
        currentState.favoritedPosts.where((p) => p.id != postId).toList();
    state = AsyncData(currentState.copyWith(favoritedPosts: optimisticPosts));

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
  /// 调用者：TimelinePage（记录卡片菜单）
  Future<void> favoriteRecord(String recordId) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) throw Exception('必须登录后才可收藏');

    final currentState = state.value;
    if (currentState == null) return;

    // Fail Fast：已收藏则幂等返回
    if (currentState.isRecordFavorited(recordId)) return;

    // 乐观更新
    final optimisticIds = {...currentState.favoritedRecordIds, recordId};
    state = AsyncData(currentState.copyWith(favoritedRecordIds: optimisticIds));

    try {
      await _repository.favoriteRecord(currentUser.id, recordId);
    } catch (e) {
      // 回滚
      state = AsyncData(currentState);
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 取消收藏私人记录
  ///
  /// 调用者：TimelinePage、FavoritesPage
  Future<void> unfavoriteRecord(String recordId) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) throw Exception('必须登录后才可取消收藏');

    final currentState = state.value;
    if (currentState == null) return;

    // 乐观更新
    final optimisticIds = {...currentState.favoritedRecordIds}..remove(recordId);
    state = AsyncData(currentState.copyWith(favoritedRecordIds: optimisticIds));

    try {
      await _repository.unfavoriteRecord(currentUser.id, recordId);
    } catch (e) {
      // 回滚
      state = AsyncData(currentState);
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 获取收藏的记录列表（从本地 Hive 按 ID 过滤）
  ///
  /// 调用者：FavoritesPage（收藏的记录 Tab）
  List<EncounterRecord> getFavoritedRecords() {
    final favoritedIds = state.value?.favoritedRecordIds ?? {};
    if (favoritedIds.isEmpty) return [];

    final allRecords = ref.read(recordsProvider).value ?? [];
    return allRecords
        .where((r) => favoritedIds.contains(r.id))
        .toList();
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

