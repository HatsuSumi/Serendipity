import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../providers/favorites_provider.dart' show FavoritedPostsResult, FavoritedRecordsResult;

/// 社区数据源接口
///
/// 定义社区数据访问的契约，遵循依赖倒置原则（DIP）
///
/// 实现类：
/// - RemoteCommunityDataSource：远程数据源（真实服务器）
/// - TestCommunityDataSource：测试数据源（本地模拟）
///
/// 设计原则：
/// - 依赖倒置（DIP）：Repository 依赖抽象而非具体实现
/// - 开闭原则（OCP）：添加新数据源不需要修改 Repository
/// - 策略模式：运行时切换数据源
abstract class ICommunityDataSource {
  /// 发布记录到社区
  ///
  /// 参数：
  /// - post: 要发布的帖子
  /// - forceReplace: 是否强制替换
  ///
  /// 返回：
  /// - replaced: 是否替换了旧帖子
  Future<bool> publishPost(CommunityPost post, {bool forceReplace = false});

  /// 批量检查发布状态
  ///
  /// 参数：
  /// - records: 要检查的记录列表
  ///
  /// 返回：
  /// - Map: recordId -> PublishStatus，每条记录的发布状态
  Future<Map<String, String>> checkPublishStatus(List<EncounterRecord> records);

  /// 获取社区帖子列表（分页）
  ///
  /// 参数：
  /// - limit: 每页数量
  /// - lastTimestamp: 上一页最后一条帖子的时间戳
  ///
  /// 返回：按发布时间倒序排列的帖子列表
  Future<List<CommunityPost>> getPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  });

  /// 获取用户自己的帖子
  ///
  /// 参数：
  /// - userId: 用户ID
  ///
  /// 返回：用户发布的帖子列表
  Future<List<CommunityPost>> getMyPosts(String userId);

  /// 删除帖子
  ///
  /// 参数：
  /// - postId: 帖子ID
  /// - userId: 用户ID
  Future<void> deletePost(String postId, String userId);

  /// 按 recordId 删除帖子（幂等，帖子不存在时静默成功）
  ///
  /// 参数：
  /// - recordId: 记录ID
  Future<void> deletePostByRecordId(String recordId);

  /// 筛选社区帖子（公开列表，不带 userId）
  ///
  /// 调用者：CommunityNotifier.build()（筛选激活时）
  Future<List<CommunityPost>> filterPosts({
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
    TagMatchMode tagMatchMode = TagMatchMode.contains,
    int limit = 20,
  });

  /// 筛选我的帖子（带 userId，服务端过滤）
  ///
  /// 职责：
  /// - 从服务端按条件筛选当前用户的帖子
  /// - 替代全量拉取后本地过滤，支持大数据量
  ///
  /// 参数：
  /// - userId: 用户 ID（必填）
  /// - 其余参数与 filterPosts 一致
  ///
  /// 调用者：MyPostsNotifier.build()（筛选激活时）
  Future<List<CommunityPost>> filterMyPosts({
    required String userId,
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
    TagMatchMode tagMatchMode = TagMatchMode.contains,
    int limit = 50,
  });

  // ==================== 收藏相关操作 ====================

  /// 收藏社区帖子
  /// 调用者：CommunityRepository.favoritePost()
  Future<void> favoritePost(String userId, String postId);

  /// 取消收藏社区帖子
  /// 调用者：CommunityRepository.unfavoritePost()
  Future<void> unfavoritePost(String userId, String postId);

  /// 获取用户收藏的社区帖子列表
  /// 调用者：CommunityRepository.getFavoritedPosts()
  Future<List<CommunityPost>> getFavoritedPosts(String userId);

  /// 获取用户收藏的社区帖子（区分存在和已删除）
  /// 调用者：CommunityRepository.getFavoritedPostsResult()
  Future<FavoritedPostsResult> getFavoritedPostsResult(String userId);

  /// 收藏私人记录
  /// 调用者：CommunityRepository.favoriteRecord()
  Future<void> favoriteRecord(String userId, String recordId);

  /// 取消收藏私人记录
  /// 调用者：CommunityRepository.unfavoriteRecord()
  Future<void> unfavoriteRecord(String userId, String recordId);

  /// 获取用户收藏的记录 ID 集合
  /// 调用者：CommunityRepository.getFavoritedRecordIds()
  Future<Set<String>> getFavoritedRecordIds(String userId);

  /// 获取用户收藏的记录（区分存在和已删除）
  /// 调用者：CommunityRepository.getFavoritedRecordsResult()
  Future<FavoritedRecordsResult> getFavoritedRecordsResult(String userId);
}
