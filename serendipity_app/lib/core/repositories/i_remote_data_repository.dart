import '../../models/encounter_record.dart';
import '../../models/story_line.dart';

/// 远程数据仓库接口
/// 
/// 定义所有远程数据操作的契约，遵循依赖倒置原则（DIP）。
/// 具体实现可以是 Firebase Firestore、自建服务器 API 或其他数据服务。
/// 
/// 调用者：
/// - SyncService：数据同步服务，调用所有方法
/// - RecordsProvider/StoryLinesProvider：通过 SyncService 间接调用
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
}

