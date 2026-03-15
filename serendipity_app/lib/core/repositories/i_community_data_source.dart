import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';

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

  /// 筛选帖子
  /// 
  /// 参数：
  /// - startDate: 错过时间开始日期
  /// - endDate: 错过时间结束日期
  /// - publishStartDate: 发布时间开始日期
  /// - publishEndDate: 发布时间结束日期
  /// - province: 省份
  /// - city: 城市
  /// - area: 区县
  /// - placeTypes: 场所类型列表
  /// - tags: 标签名称列表
  /// - statuses: 状态列表
  /// - tagMatchMode: 标签匹配模式（wholeWord 或 contains）
  /// - limit: 每页数量
  /// 
  /// 返回：符合条件的帖子列表
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
}

