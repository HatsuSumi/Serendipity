import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/achievement.dart';
import '../../models/check_in_record.dart';
import '../../models/user_settings.dart';
import '../../models/sync_history.dart';

/// 存储服务接口
/// 
/// 定义数据持久化的抽象接口，支持多种实现：
/// - HiveStorageService: 本地存储（Hive）
/// - SyncStorageService: 同步存储（本地+云端）
abstract class IStorageService {
  /// 初始化存储服务
  Future<void> init();
  
  /// 关闭存储服务
  Future<void> close();
  
  // ==================== 记录相关操作 ====================
  
  /// 保存记录
  Future<void> saveRecord(EncounterRecord record);
  
  /// 获取单条记录
  EncounterRecord? getRecord(String id);
  
  /// 获取所有记录
  List<EncounterRecord> getAllRecords();
  
  /// 获取记录列表（按时间倒序）
  List<EncounterRecord> getRecordsSortedByTime();
  
  /// 获取指定用户的记录列表（按时间倒序）
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  /// 
  /// 调用者：RecordRepository
  List<EncounterRecord> getRecordsByUser(String? userId);
  
  /// 删除记录
  Future<void> deleteRecord(String id);
  
  /// 更新记录
  Future<void> updateRecord(EncounterRecord record);
  
  /// 根据故事线ID获取记录
  List<EncounterRecord> getRecordsByStoryLine(String storyLineId);
  
  /// 获取未关联故事线的记录
  List<EncounterRecord> getRecordsWithoutStoryLine();
  
  // ==================== 故事线相关操作 ====================
  
  /// 保存故事线
  Future<void> saveStoryLine(StoryLine storyLine);
  
  /// 获取单条故事线
  StoryLine? getStoryLine(String id);
  
  /// 获取所有故事线
  List<StoryLine> getAllStoryLines();
  
  /// 获取故事线列表（按更新时间倒序）
  List<StoryLine> getStoryLinesSortedByTime();
  
  /// 获取指定用户的故事线列表（按更新时间倒序）
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  /// 
  /// 调用者：StoryLineRepository
  List<StoryLine> getStoryLinesByUser(String? userId);
  
  /// 删除故事线
  Future<void> deleteStoryLine(String id);
  
  /// 更新故事线
  Future<void> updateStoryLine(StoryLine storyLine);
  
  // ==================== 成就相关操作 ====================
  
  /// 保存成就
  Future<void> saveAchievement(Achievement achievement);
  
  /// 获取单个成就
  Achievement? getAchievement(String id);
  
  /// 获取所有成就
  List<Achievement> getAllAchievements();
  
  /// 更新成就
  Future<void> updateAchievement(Achievement achievement);
  
  // ==================== 签到相关操作 ====================
  
  /// 保存签到记录
  Future<void> saveCheckIn(CheckInRecord checkIn);
  
  /// 获取单个签到记录
  CheckInRecord? getCheckIn(String id);
  
  /// 获取所有签到记录
  List<CheckInRecord> getAllCheckIns();
  
  /// 获取签到记录列表（按日期倒序）
  List<CheckInRecord> getCheckInsSortedByDate();
  
  /// 获取指定用户的签到记录列表（按日期倒序）
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  /// 
  /// 调用者：CheckInRepository
  List<CheckInRecord> getCheckInsByUser(String? userId);
  
  /// 删除签到记录
  Future<void> deleteCheckIn(String id);
  
  // ==================== 用户设置相关操作 ====================
  
  /// 获取用户设置
  UserSettings? getUserSettings();
  
  /// 保存用户设置
  Future<void> saveUserSettings(UserSettings settings);
  
  // ==================== 同步历史相关操作 ====================
  
  /// 保存同步历史记录
  Future<void> saveSyncHistory(SyncHistory history);
  
  /// 获取所有同步历史记录（按时间倒序）
  List<SyncHistory> getAllSyncHistories();
  
  /// 获取最近 N 条同步历史记录
  List<SyncHistory> getRecentSyncHistories(int limit);
  
  /// 删除同步历史记录
  Future<void> deleteSyncHistory(String id);
  
  /// 清空所有同步历史记录
  Future<void> clearAllSyncHistories();
  
  // ==================== 键值对存储（用于 Token 等） ====================
  
  /// 保存值（泛型）
  Future<void> set<T>(String key, T value);
  
  /// 获取值（泛型）
  T? get<T>(String key);
  
  /// 保存字符串
  Future<void> saveString(String key, String value);
  
  /// 获取字符串
  Future<String?> getString(String key);
  
  /// 删除键值对
  Future<void> remove(String key);
  
  // ==================== 用户数据管理 ====================
  
  /// 绑定离线数据到指定用户
  /// 
  /// 将所有 ownerId = null 的数据绑定到指定用户
  /// 
  /// 参数：
  /// - userId: 目标用户ID
  /// 
  /// 调用者：AuthNotifier（首次登录/注册时）
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  Future<void> bindOfflineDataToUser(String userId);
  
  /// 删除所有离线数据
  /// 
  /// 删除所有 ownerId = null 的数据
  /// 
  /// 调用者：AuthNotifier（用户选择不绑定离线数据时）
  Future<void> deleteOfflineData();
  
  /// 清空用户数据（登出时调用）
  /// 
  /// 清空内容：
  /// - 记录
  /// - 故事线
  /// - 签到记录
  /// - 成就
  /// - 用户设置
  /// - 同步历史
  /// 
  /// 保留内容：
  /// - Token（由 AuthRepository 管理）
  /// - 首次启动标记
  /// 
  /// 调用者：AuthNotifier.signOut()
  Future<void> clearUserData();
}

