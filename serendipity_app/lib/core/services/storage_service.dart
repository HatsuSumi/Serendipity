import 'package:hive_flutter/hive_flutter.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/achievement.dart';
import '../../models/check_in_record.dart';
import '../../models/user_settings.dart';
import '../../models/sync_history.dart';
import 'i_storage_service.dart';

/// 本地存储服务（Hive 实现）
/// 使用 Hive 进行数据持久化
class StorageService implements IStorageService {
  // Box 名称常量
  static const String _recordsBoxName = 'records';
  static const String _settingsBoxName = 'settings';
  static const String _storyLinesBoxName = 'story_lines';
  static const String _achievementsBoxName = 'achievements';
  static const String _checkInsBoxName = 'check_ins';
  static const String _syncHistoriesBoxName = 'sync_histories';
  
  // 单例模式
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  // Box 实例
  Box<EncounterRecord>? _recordsBox;
  Box? _settingsBox;
  Box<StoryLine>? _storyLinesBox;
  Box<Achievement>? _achievementsBox;
  Box<CheckInRecord>? _checkInsBox;
  Box<SyncHistory>? _syncHistoriesBox;
  
  // Box getters with initialization check
  Box<EncounterRecord> get _recordsBoxOrThrow {
    if (_recordsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _recordsBox!;
  }
  
  Box get _settingsBoxOrThrow {
    if (_settingsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _settingsBox!;
  }
  
  Box<StoryLine> get _storyLinesBoxOrThrow {
    if (_storyLinesBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _storyLinesBox!;
  }
  
  Box<Achievement> get _achievementsBoxOrThrow {
    if (_achievementsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _achievementsBox!;
  }
  
  Box<CheckInRecord> get _checkInsBoxOrThrow {
    if (_checkInsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _checkInsBox!;
  }
  
  Box<SyncHistory> get _syncHistoriesBoxOrThrow {
    if (_syncHistoriesBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _syncHistoriesBox!;
  }
  
  /// 初始化所有 Box
  @override
  Future<void> init() async {
    _recordsBox = await Hive.openBox<EncounterRecord>(_recordsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _storyLinesBox = await Hive.openBox<StoryLine>(_storyLinesBoxName);
    _achievementsBox = await Hive.openBox<Achievement>(_achievementsBoxName);
    _checkInsBox = await Hive.openBox<CheckInRecord>(_checkInsBoxName);
    _syncHistoriesBox = await Hive.openBox<SyncHistory>(_syncHistoriesBoxName);
  }
  
  /// 关闭所有 Box
  @override
  Future<void> close() async {
    await _recordsBox?.close();
    await _settingsBox?.close();
    await _storyLinesBox?.close();
    await _achievementsBox?.close();
    await _checkInsBox?.close();
    await _syncHistoriesBox?.close();
  }
  
  // ==================== 记录相关操作 ====================
  
  /// 保存记录
  @override
  Future<void> saveRecord(EncounterRecord record) async {
    assert(record.id.isNotEmpty, 'Record ID cannot be empty');
    await _recordsBoxOrThrow.put(record.id, record);
  }
  
  /// 获取单条记录
  @override
  EncounterRecord? getRecord(String id) {
    assert(id.isNotEmpty, 'Record ID cannot be empty');
    return _recordsBoxOrThrow.get(id);
  }
  
  /// 获取所有记录
  @override
  List<EncounterRecord> getAllRecords() {
    return _recordsBoxOrThrow.values.toList();
  }
  
  /// 获取记录列表（按时间倒序）
  @override
  List<EncounterRecord> getRecordsSortedByTime() {
    final records = getAllRecords();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }
  
  /// 删除记录
  @override
  Future<void> deleteRecord(String id) async {
    assert(id.isNotEmpty, 'Record ID cannot be empty');
    await _recordsBoxOrThrow.delete(id);
  }
  
  /// 更新记录
  @override
  Future<void> updateRecord(EncounterRecord record) async {
    assert(record.id.isNotEmpty, 'Record ID cannot be empty');
    await _recordsBoxOrThrow.put(record.id, record);
  }
  
  /// 根据故事线ID获取记录
  @override
  List<EncounterRecord> getRecordsByStoryLine(String storyLineId) {
    assert(storyLineId.isNotEmpty, 'Story line ID cannot be empty');
    return getAllRecords()
        .where((record) => record.storyLineId == storyLineId)
        .toList();
  }
  
  /// 获取未关联故事线的记录
  @override
  List<EncounterRecord> getRecordsWithoutStoryLine() {
    return getAllRecords()
        .where((record) => record.storyLineId == null)
        .toList();
  }
  
  // ==================== 故事线相关操作 ====================
  
  /// 保存故事线
  @override
  Future<void> saveStoryLine(StoryLine storyLine) async {
    assert(storyLine.id.isNotEmpty, 'Story line ID cannot be empty');
    await _storyLinesBoxOrThrow.put(storyLine.id, storyLine);
  }
  
  /// 获取单条故事线
  @override
  StoryLine? getStoryLine(String id) {
    assert(id.isNotEmpty, 'Story line ID cannot be empty');
    return _storyLinesBoxOrThrow.get(id);
  }
  
  /// 获取所有故事线
  @override
  List<StoryLine> getAllStoryLines() {
    return _storyLinesBoxOrThrow.values.toList();
  }
  
  /// 获取故事线列表（按更新时间倒序）
  @override
  List<StoryLine> getStoryLinesSortedByTime() {
    final storyLines = getAllStoryLines();
    storyLines.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return storyLines;
  }
  
  /// 删除故事线
  @override
  Future<void> deleteStoryLine(String id) async {
    assert(id.isNotEmpty, 'Story line ID cannot be empty');
    await _storyLinesBoxOrThrow.delete(id);
  }
  
  /// 更新故事线
  @override
  Future<void> updateStoryLine(StoryLine storyLine) async {
    assert(storyLine.id.isNotEmpty, 'Story line ID cannot be empty');
    await _storyLinesBoxOrThrow.put(storyLine.id, storyLine);
  }
  
  // ==================== 成就相关操作 ====================
  
  /// 保存成就
  @override
  Future<void> saveAchievement(Achievement achievement) async {
    assert(achievement.id.isNotEmpty, 'Achievement ID cannot be empty');
    await _achievementsBoxOrThrow.put(achievement.id, achievement);
  }
  
  /// 获取单个成就
  @override
  Achievement? getAchievement(String id) {
    assert(id.isNotEmpty, 'Achievement ID cannot be empty');
    return _achievementsBoxOrThrow.get(id);
  }
  
  /// 获取所有成就
  @override
  List<Achievement> getAllAchievements() {
    return _achievementsBoxOrThrow.values.toList();
  }
  
  /// 更新成就
  @override
  Future<void> updateAchievement(Achievement achievement) async {
    assert(achievement.id.isNotEmpty, 'Achievement ID cannot be empty');
    await _achievementsBoxOrThrow.put(achievement.id, achievement);
  }
  
  // ==================== 签到相关操作 ====================
  
  /// 保存签到记录
  @override
  Future<void> saveCheckIn(CheckInRecord checkIn) async {
    assert(checkIn.id.isNotEmpty, 'CheckIn ID cannot be empty');
    await _checkInsBoxOrThrow.put(checkIn.id, checkIn);
  }
  
  /// 获取单个签到记录
  @override
  CheckInRecord? getCheckIn(String id) {
    assert(id.isNotEmpty, 'CheckIn ID cannot be empty');
    return _checkInsBoxOrThrow.get(id);
  }
  
  /// 获取所有签到记录
  @override
  List<CheckInRecord> getAllCheckIns() {
    return _checkInsBoxOrThrow.values.toList();
  }
  
  /// 获取签到记录列表（按日期倒序）
  @override
  List<CheckInRecord> getCheckInsSortedByDate() {
    final checkIns = getAllCheckIns();
    checkIns.sort((a, b) => b.date.compareTo(a.date));
    return checkIns;
  }

  /// 删除签到记录
  @override
  Future<void> deleteCheckIn(String id) async {
    assert(id.isNotEmpty, 'CheckIn ID cannot be empty');
    await _checkInsBoxOrThrow.delete(id);
  }
  
  // ==================== 用户设置相关操作 ====================
  
  /// 获取用户设置
  /// 
  /// 使用固定的 key 'user_settings' 存储
  @override
  UserSettings? getUserSettings() {
    final json = _settingsBoxOrThrow.get('user_settings');
    if (json == null) return null;
    return UserSettings.fromJson(Map<String, dynamic>.from(json as Map));
  }
  
  /// 保存用户设置
  /// 
  /// 使用固定的 key 'user_settings' 存储
  @override
  Future<void> saveUserSettings(UserSettings settings) async {
    await _settingsBoxOrThrow.put('user_settings', settings.toJson());
  }
  
  // ==================== 同步历史相关操作 ====================
  
  /// 保存同步历史记录
  /// 
  /// 调用者：SyncStatusNotifier.syncSuccess() / syncError()
  /// 
  /// Fail Fast：
  /// - history.id 为空：由 SyncHistory 构造函数保证
  @override
  Future<void> saveSyncHistory(SyncHistory history) async {
    assert(history.id.isNotEmpty, 'SyncHistory ID cannot be empty');
    await _syncHistoriesBoxOrThrow.put(history.id, history);
  }
  
  /// 获取所有同步历史记录（按时间倒序）
  /// 
  /// 调用者：SyncHistoryDialog.build()
  @override
  List<SyncHistory> getAllSyncHistories() {
    final histories = _syncHistoriesBoxOrThrow.values.toList();
    histories.sort((a, b) => b.syncTime.compareTo(a.syncTime));
    return histories;
  }
  
  /// 获取最近 N 条同步历史记录
  /// 
  /// 调用者：SettingsPage（显示最近一次同步）
  /// 
  /// Fail Fast：
  /// - limit <= 0：抛出 ArgumentError
  @override
  List<SyncHistory> getRecentSyncHistories(int limit) {
    if (limit <= 0) {
      throw ArgumentError('limit 必须大于 0');
    }
    
    final histories = getAllSyncHistories();
    return histories.take(limit).toList();
  }
  
  /// 删除同步历史记录
  /// 
  /// 调用者：SyncHistoryDialog（未来可能添加删除功能）
  /// 
  /// Fail Fast：
  /// - id 为空：抛出 ArgumentError
  @override
  Future<void> deleteSyncHistory(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('SyncHistory ID 不能为空');
    }
    await _syncHistoriesBoxOrThrow.delete(id);
  }
  
  /// 清空所有同步历史记录
  /// 
  /// 调用者：SettingsPage（开发者功能）
  @override
  Future<void> clearAllSyncHistories() async {
    await _syncHistoriesBoxOrThrow.clear();
  }
  
  // ==================== 键值对存储（用于 Token 等） ====================
  
  /// 保存值（泛型）
  @override
  Future<void> set<T>(String key, T value) async {
    await _settingsBoxOrThrow.put(key, value);
  }
  
  /// 获取值（泛型）
  @override
  T? get<T>(String key) {
    return _settingsBoxOrThrow.get(key) as T?;
  }
  
  /// 保存字符串
  @override
  Future<void> saveString(String key, String value) async {
    await _settingsBoxOrThrow.put(key, value);
  }
  
  /// 获取字符串
  @override
  Future<String?> getString(String key) async {
    return _settingsBoxOrThrow.get(key) as String?;
  }
  
  /// 删除键值对
  @override
  Future<void> remove(String key) async {
    await _settingsBoxOrThrow.delete(key);
  }
  
  // ==================== 用户数据清理 ====================
  
  /// 清空用户数据（登出时调用）
  /// 
  /// 调用者：AuthNotifier.signOut()
  /// 
  /// 清空策略：
  /// - 清空所有用户相关数据
  /// - 保留 Token（由 AuthRepository 管理）
  /// - 保留首次启动标记
  /// 
  /// Fail Fast：
  /// - Box 未初始化：抛出 StateError
  @override
  Future<void> clearUserData() async {
    // 清空记录
    await _recordsBoxOrThrow.clear();
    
    // 清空故事线
    await _storyLinesBoxOrThrow.clear();
    
    // 清空签到记录
    await _checkInsBoxOrThrow.clear();
    
    // 清空成就
    await _achievementsBoxOrThrow.clear();
    
    // 清空同步历史
    await _syncHistoriesBoxOrThrow.clear();
    
    // 清空用户设置（但保留其他全局设置）
    await _settingsBoxOrThrow.delete('user_settings');
  }
}

