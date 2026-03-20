import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/community_post.dart';
import '../../models/check_in_record.dart';
import '../../models/achievement_unlock.dart';
import '../../models/user_settings.dart';
import '../providers/favorites_provider.dart' show FavoritedPostsResult, FavoritedRecordsResult;

/// 远程数据仓库接口
/// 
/// 定义所有远程数据操作的契约，遵循依赖倒置原则（DIP）。
/// 具体实现可以是自建服务器 API 或其他数据服务。
/// 
/// 调用者：
/// - SyncService：数据同步服务，调用所有方法
/// - RecordsProvider/StoryLinesProvider：通过 SyncService 间接调用
/// - CommunityRepository：社区功能，调用社区相关方法
abstract class IRemoteDataRepository {
  // ==================== 记录相关操作 ====================
  
  /// 上传单条记录到云端（创建或更新）
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [record]：要上传的记录
  /// 
  /// 调用者：
  /// - SyncService.uploadRecord()
  /// - RecordsProvider 创建记录后通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - record 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> uploadRecord(String userId, EncounterRecord record);
  
  /// 更新云端记录（增量更新）
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [record]：要更新的记录（只传输修改的字段）
  /// 
  /// 调用者：
  /// - SyncService.updateRecord()
  /// - RecordsProvider 更新记录后通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - record 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> updateRecord(String userId, EncounterRecord record);
  
  /// 批量上传记录到云端
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [records]：要上传的记录列表
  /// 
  /// 调用者：
  /// - SyncService.syncAllRecords()
  /// - 用户首次登录时，将本地数据批量上传
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - records 为空列表：直接返回，不抛异常（允许空列表）
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> uploadRecords(String userId, List<EncounterRecord> records);
  
  /// 下载用户所有记录
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// 
  /// 返回：用户的所有记录列表
  /// 
  /// 调用者：
  /// - SyncService.downloadData()
  /// - 用户登录后，下载云端数据到本地
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<EncounterRecord>> downloadRecords(String userId);
  
  /// 下载用户增量记录（自上次同步后的变化）
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [lastSyncTime]：上次同步时间
  /// 
  /// 返回：自上次同步后有变化的记录列表
  /// 
  /// 调用者：
  /// - SyncService.downloadData()（增量同步）
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - lastSyncTime 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<EncounterRecord>> downloadRecordsSince(String userId, DateTime lastSyncTime);
  
  /// 删除云端记录
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [recordId]：记录 ID
  /// 
  /// 调用者：
  /// - SyncService.deleteRecord()
  /// - RecordsProvider.deleteRecord() 通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - recordId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> deleteRecord(String userId, String recordId);

  /// 筛选用户的记录（支持多条件组合）
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [startDate]：错过时间开始日期（可选）
  /// - [endDate]：错过时间结束日期（可选）
  /// - [province]：省份（可选）
  /// - [city]：城市（可选）
  /// - [area]：区县（可选）
  /// - [placeTypes]：场所类型列表（可选，多选OR逻辑）
  /// - [tags]：标签名称列表（可选，多选OR逻辑）
  /// - [statuses]：状态列表（可选，多选OR逻辑）
  /// - [tagMatchMode]：标签匹配模式（wholeWord 或 contains）
  /// - [sortBy]：排序字段（createdAt 或 updatedAt）
  /// - [sortOrder]：排序顺序（asc 或 desc）
  /// - [limit]：每页数量
  /// - [offset]：偏移量
  /// 
  /// 返回：符合条件的记录列表
  /// 
  /// 调用者：
  /// - RecordsProvider.filterRecords()
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - limit <= 0：抛出 ArgumentError
  /// - offset < 0：抛出 ArgumentError
  /// - startDate > endDate：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<EncounterRecord>> filterRecords({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? province,
    String? city,
    String? area,
    List<String>? placeTypes,
    List<String>? tags,
    List<String>? statuses,
    List<String>? emotionIntensities,
    List<String>? weathers,
    String tagMatchMode = 'contains',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int limit = 20,
    int offset = 0,
  });
  
  // ==================== 故事线相关操作 ====================
  
  /// 上传单条故事线到云端（创建或更新）
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [storyLine]：要上传的故事线
  /// 
  /// 调用者：
  /// - SyncService.uploadStoryLine()
  /// - StoryLinesProvider 创建故事线后通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - storyLine 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> uploadStoryLine(String userId, StoryLine storyLine);
  
  /// 更新云端故事线（增量更新）
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [storyLine]：要更新的故事线（只传输修改的字段）
  /// 
  /// 调用者：
  /// - SyncService.updateStoryLine()
  /// - StoryLinesProvider 更新故事线后通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - storyLine 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> updateStoryLine(String userId, StoryLine storyLine);
  
  /// 批量上传故事线到云端
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [storyLines]：要上传的故事线列表
  /// 
  /// 调用者：
  /// - SyncService.syncAllStoryLines()
  /// - 用户首次登录时，将本地数据批量上传
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - storyLines 为空列表：直接返回，不抛异常（允许空列表）
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> uploadStoryLines(String userId, List<StoryLine> storyLines);
  
  /// 下载用户所有故事线
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// 
  /// 返回：用户的所有故事线列表
  /// 
  /// 调用者：
  /// - SyncService.downloadData()
  /// - 用户登录后，下载云端数据到本地
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<StoryLine>> downloadStoryLines(String userId);
  
  /// 下载用户增量故事线（自上次同步后的变化）
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [lastSyncTime]：上次同步时间
  /// 
  /// 返回：自上次同步后有变化的故事线列表
  /// 
  /// 调用者：
  /// - SyncService.downloadData()（增量同步）
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - lastSyncTime 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<StoryLine>> downloadStoryLinesSince(String userId, DateTime lastSyncTime);
  
  /// 删除云端故事线
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [storyLineId]：故事线 ID
  /// 
  /// 调用者：
  /// - SyncService.deleteStoryLine()
  /// - StoryLinesProvider.deleteStoryLine() 通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - storyLineId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> deleteStoryLine(String userId, String storyLineId);
  
  // ==================== 社区相关操作 ====================
  
  /// 保存社区帖子到云端
  /// 
  /// 参数：
  /// - [post]：要保存的社区帖子
  /// - [forceReplace]：是否强制替换（用户已确认）
  /// 
  /// 返回：
  /// - replaced: 是否替换了旧帖子
  /// 
  /// 调用者：
  /// - CommunityRepository.publishPost()
  /// 
  /// Fail Fast：
  /// - post 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<bool> saveCommunityPost(CommunityPost post, {bool forceReplace = false});
  
  /// 批量检查记录的发布状态
  /// 
  /// 参数：
  /// - [records]：要检查的记录列表
  /// 
  /// 返回：
  /// - `Map<recordId, PublishStatus>`：每条记录的发布状态
  /// 
  /// 调用者：
  /// - CommunityRepository.checkPublishStatus()
  /// 
  /// Fail Fast：
  /// - records 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<Map<String, String>> checkPublishStatus(List<EncounterRecord> records);
  
  /// 获取社区帖子列表（分页）
  /// 
  /// 参数：
  /// - [limit]：每页数量
  /// - [lastTimestamp]：上一页最后一条帖子的时间戳（用于分页）
  /// 
  /// 返回：按发布时间倒序排列的帖子列表
  /// 
  /// 调用者：
  /// - CommunityRepository.getPosts()
  /// 
  /// Fail Fast：
  /// - limit <= 0：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<CommunityPost>> getCommunityPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  });
  
  /// 获取用户自己的社区帖子
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// 
  /// 返回：用户发布的所有帖子列表
  /// 
  /// 调用者：
  /// - CommunityRepository.getMyPosts()
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<CommunityPost>> getMyCommunityPosts(String userId);
  
  /// 删除社区帖子
  /// 
  /// 参数：
  /// - [postId]：帖子 ID
  /// - [userId]：用户 ID（用于验证权限）
  /// 
  /// 调用者：
  /// - CommunityRepository.deletePost()
  /// 
  /// Fail Fast：
  /// - postId 为空：抛出 ArgumentError
  /// - userId 为空：抛出 ArgumentError
  /// - 帖子不存在：抛出 StateError
  /// - 不是帖子作者：抛出 StateError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> deleteCommunityPost(String postId, String userId);
  
  /// 按 recordId 删除社区帖子（幂等，帖子不存在时静默成功）
  /// 
  /// 调用者：
  /// - CommunityRepository.deletePostByRecordId()
  /// 
  /// Fail Fast：
  /// - recordId 为空：抛出 ArgumentError
  Future<void> deleteCommunityPostByRecordId(String recordId);
  
  /// 筛选社区帖子
  /// 
  /// 参数：
  /// - [startDate]：错过时间开始日期（可选）
  /// - [endDate]：错过时间结束日期（可选）
  /// - [publishStartDate]：发布时间开始日期（可选）
  /// - [publishEndDate]：发布时间结束日期（可选）
  /// - [province]：省份（可选）
  /// - [city]：城市（可选）
  /// - [area]：区县（可选）
  /// - [placeTypes]：场所类型列表（可选，多选OR逻辑）
  /// - [tags]：标签名称列表（可选，多选OR逻辑）
  /// - [statuses]：状态列表（可选，多选OR逻辑）
  /// - [tagMatchMode]：标签匹配模式（wholeWord 或 contains）
  /// - [limit]：每页数量
  /// 
  /// 返回：符合条件的帖子列表
  /// 
  /// 调用者：
  /// - CommunityRepository.filterPosts()
  /// 
  /// Fail Fast：
  /// - limit <= 0：抛出 ArgumentError
  /// - startDate > endDate：抛出 ArgumentError
  /// - publishStartDate > publishEndDate：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<CommunityPost>> filterCommunityPosts({
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
  });
  
  // ==================== 签到相关操作 ====================
  
  /// 上传单条签到记录到云端
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [checkIn]：要上传的签到记录
  /// 
  /// 调用者：
  /// - SyncService.uploadCheckIn()
  /// - CheckInProvider.checkIn() 通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - checkIn 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> uploadCheckIn(String userId, CheckInRecord checkIn);
  
  /// 批量上传签到记录到云端
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [checkIns]：要上传的签到记录列表
  /// 
  /// 调用者：
  /// - SyncService.syncAllCheckIns()
  /// - 用户首次登录时，将本地数据批量上传
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - checkIns 为空列表：直接返回，不抛异常（允许空列表）
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> uploadCheckIns(String userId, List<CheckInRecord> checkIns);
  
  /// 下载用户所有签到记录
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// 
  /// 返回：用户的所有签到记录列表
  /// 
  /// 调用者：
  /// - SyncService.downloadData()
  /// - 用户登录后，下载云端数据到本地
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<CheckInRecord>> downloadCheckIns(String userId);
  
  /// 下载用户增量签到记录（自上次同步后的变化）
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [lastSyncTime]：上次同步时间
  /// 
  /// 返回：自上次同步后有变化的签到记录列表
  /// 
  /// 调用者：
  /// - SyncService.downloadData()（增量同步）
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - lastSyncTime 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<CheckInRecord>> downloadCheckInsSince(String userId, DateTime lastSyncTime);
  
  /// 删除云端签到记录
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [checkInId]：签到记录 ID
  /// 
  /// 调用者：
  /// - SyncService.deleteCheckIn()
  /// - CheckInProvider.resetAllCheckIns() 通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - checkInId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> deleteCheckIn(String userId, String checkInId);
  
  // ==================== 成就相关操作 ====================
  
  /// 上传成就解锁记录到云端
  /// 
  /// 参数：
  /// - [unlock]：成就解锁记录
  /// 
  /// 调用者：
  /// - SyncService.uploadAchievementUnlock()
  /// - AchievementRepository.unlockAchievement() 通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - unlock 为 null：抛出 ArgumentError
  /// - unlock.userId 为空：抛出 ArgumentError
  /// - unlock.achievementId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> uploadAchievementUnlock(AchievementUnlock unlock);
  
  /// 下载用户所有成就解锁记录
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// 
  /// 返回：用户的所有成就解锁记录列表
  /// 
  /// 调用者：
  /// - SyncService.syncAllData()
  /// - 用户登录后，下载云端成就解锁状态到本地
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<List<AchievementUnlock>> downloadAchievementUnlocks(String userId);
  
  // ==================== 用户设置相关操作 ====================
  
  /// 上传用户设置到云端
  /// 
  /// 参数：
  /// - [settings]：用户设置
  /// 
  /// 调用者：
  /// - SyncService.uploadSettings()
  /// - UserSettingsProvider 修改设置后通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - settings 为 null：抛出 ArgumentError
  /// - settings.userId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  /// 上传用户设置（返回服务端保存后的最新设置，含服务端生成的 updatedAt）
  Future<UserSettings> uploadSettings(UserSettings settings);
  
  /// 下载用户设置
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// 
  /// 返回：用户设置，如果不存在则返回 null
  /// 
  /// 调用者：
  /// - SyncService.downloadSettings()
  /// - 用户登录后，下载云端设置到本地
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<UserSettings?> downloadSettings(String userId);

  // ==================== 收藏相关操作 ====================

  /// 收藏社区帖子
  ///
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - postId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常
  ///
  /// 调用者：CommunityRepository.favoritePost()
  Future<void> favoritePost(String userId, String postId);

  /// 取消收藏社区帖子
  ///
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - postId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常
  ///
  /// 调用者：CommunityRepository.unfavoritePost()
  Future<void> unfavoritePost(String userId, String postId);

  /// 获取用户收藏的社区帖子（区分存在和已删除）
  ///
  /// 返回 [FavoritedPostsResult]，包含正常帖子列表和已删除帖子 ID 集合。
  ///
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常
  ///
  /// 调用者：CommunityRepository.getFavoritedPostsResult()
  Future<FavoritedPostsResult> getFavoritedPostsResult(String userId);

  /// 收藏私人记录
  ///
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - recordId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常
  ///
  /// 调用者：CommunityRepository.favoriteRecord()
  Future<void> favoriteRecord(String userId, String recordId);

  /// 取消收藏私人记录
  ///
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - recordId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常
  ///
  /// 调用者：CommunityRepository.unfavoriteRecord()
  Future<void> unfavoriteRecord(String userId, String recordId);

  /// 获取用户收藏的记录（区分存在和已删除）
  ///
  /// 返回 [FavoritedRecordsResult]，包含正常记录 ID 集合和已删除记录 ID 集合。
  ///
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常
  ///
  /// 调用者：CommunityRepository.getFavoritedRecordsResult()
  Future<FavoritedRecordsResult> getFavoritedRecordsResult(String userId);
}

