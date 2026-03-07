import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/community_post.dart';
import '../../models/check_in_record.dart';

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
  
  /// 上传单条记录到云端
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [record]：要上传的记录
  /// 
  /// 调用者：
  /// - SyncService.syncRecord()
  /// - RecordsProvider 创建/编辑记录后通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - record 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> uploadRecord(String userId, EncounterRecord record);
  
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
  
  // ==================== 故事线相关操作 ====================
  
  /// 上传单条故事线到云端
  /// 
  /// 参数：
  /// - [userId]：用户 ID
  /// - [storyLine]：要上传的故事线
  /// 
  /// 调用者：
  /// - SyncService.syncStoryLine()
  /// - StoryLinesProvider 创建/编辑故事线后通过 SyncService 调用
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  /// - storyLine 为 null：抛出 ArgumentError
  /// - 网络错误：抛出具体的网络异常（由实现类定义）
  Future<void> uploadStoryLine(String userId, StoryLine storyLine);
  
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
}

