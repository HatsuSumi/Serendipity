import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/achievement.dart';
import '../../models/check_in_record.dart';
import '../../models/user_settings.dart';
import '../../models/sync_history.dart';
import '../../models/membership.dart';
import 'i_storage_service.dart';

/// 本地存储服务（Hive 实现）
/// 使用 Hive 进行数据持久化
class StorageService implements IStorageService {
  static const String _legacySourceDeviceId = EncounterRecord.legacySourceDeviceId;
  static const String _deviceScopeMigrationVersionKey = 'device_scope_migration_version';
  static const int _deviceScopeMigrationVersion = 1;

  // Box 名称常量
  static const String _recordsBoxName = 'records';
  static const String _settingsBoxName = 'settings';
  static const String _storyLinesBoxName = 'story_lines';
  static const String _achievementsBoxName = 'achievements';
  static const String _checkInsBoxName = 'check_ins';
  static const String _syncHistoriesBoxName = 'sync_histories';
  static const String _favoritedRecordSnapshotsBoxName = 'favorited_record_snapshots';
  static const String _favoritedPostSnapshotsBoxName = 'favorited_post_snapshots';
  static const String _membershipsBoxName = 'memberships';
  
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
  Box<EncounterRecord>? _favoritedRecordSnapshotsBox;
  Box<String>? _favoritedPostSnapshotsBox;
  Box<String>? _membershipsBox;
  
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

  Box<EncounterRecord> get _favoritedRecordSnapshotsBoxOrThrow {
    if (_favoritedRecordSnapshotsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _favoritedRecordSnapshotsBox!;
  }

  Box<String> get _favoritedPostSnapshotsBoxOrThrow {
    if (_favoritedPostSnapshotsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _favoritedPostSnapshotsBox!;
  }
  
  Box<String> get _membershipsBoxOrThrow {
    if (_membershipsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _membershipsBox!;
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
    _favoritedRecordSnapshotsBox = await Hive.openBox<EncounterRecord>(_favoritedRecordSnapshotsBoxName);
    _favoritedPostSnapshotsBox = await Hive.openBox<String>(_favoritedPostSnapshotsBoxName);
    _membershipsBox = await Hive.openBox<String>(_membershipsBoxName);

    await _migrateLegacyDeviceScopedData();
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
    await _favoritedRecordSnapshotsBox?.close();
    await _favoritedPostSnapshotsBox?.close();
    await _membershipsBox?.close();
  }

  Future<void> _migrateLegacyDeviceScopedData() async {
    final settingsBox = _settingsBoxOrThrow;
    final migratedVersion = settingsBox.get(_deviceScopeMigrationVersionKey) as int?;
    if (migratedVersion == _deviceScopeMigrationVersion) {
      return;
    }

    final migratedRecords = _recordsBoxOrThrow.values
        .where((record) => record.sourceDeviceId == _legacySourceDeviceId)
        .map(
          (record) => record.copyWith(sourceDeviceId: _legacySourceDeviceId),
        )
        .toList();
    for (final record in migratedRecords) {
      await _recordsBoxOrThrow.put(record.id, record);
    }

    final migratedFavoritedRecordSnapshots = _favoritedRecordSnapshotsBoxOrThrow.values
        .where((record) => record.sourceDeviceId == _legacySourceDeviceId)
        .map(
          (record) => record.copyWith(sourceDeviceId: _legacySourceDeviceId),
        )
        .toList();
    for (final record in migratedFavoritedRecordSnapshots) {
      await _favoritedRecordSnapshotsBoxOrThrow.put(record.id, record);
    }

    final migratedStoryLines = _storyLinesBoxOrThrow.values
        .where((storyLine) => (storyLine.sourceDeviceId ?? '').isEmpty)
        .map(
          (storyLine) => storyLine.copyWith(sourceDeviceId: _legacySourceDeviceId),
        )
        .toList();
    for (final storyLine in migratedStoryLines) {
      await _storyLinesBoxOrThrow.put(storyLine.id, storyLine);
    }

    await settingsBox.put(_deviceScopeMigrationVersionKey, _deviceScopeMigrationVersion);
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
  
  /// 获取指定用户的记录列表（按时间倒序）
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  /// 
  /// 调用者：RecordRepository
  /// 
  /// Fail Fast：不验证 userId，允许 null（表示离线数据）
  @override
  List<EncounterRecord> getRecordsByUser(String? userId) {
    final records = getAllRecords()
        .where((record) => record.ownerId == userId)
        .toList();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
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
  
  /// 获取指定用户的故事线列表（按更新时间倒序）
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  /// 
  /// 调用者：StoryLineRepository
  /// 
  /// Fail Fast：不验证 userId，允许 null（表示离线数据）
  @override
  List<StoryLine> getStoryLinesByUser(String? userId) {
    final storyLines = getAllStoryLines()
        .where((storyLine) => storyLine.userId == userId)
        .toList();
    storyLines.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return storyLines;
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
  
  /// 获取指定用户的签到记录列表（按日期倒序）
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  /// 
  /// 调用者：CheckInRepository
  /// 
  /// Fail Fast：不验证 userId，允许 null（表示离线数据）
  @override
  List<CheckInRecord> getCheckInsByUser(String? userId) {
    final checkIns = getAllCheckIns()
        .where((checkIn) => checkIn.userId == userId)
        .toList();
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
  
  /// 同步历史记录最大保留条数
  /// 
  /// 超出此数量时，自动删除最旧的记录（按 syncTime 排序）。
  /// 用户没有手动清理入口，因此由存储层自动维护上限。
  static const int _maxSyncHistories = 100;

  /// 保存同步历史记录
  /// 
  /// 调用者：SyncStatusNotifier.syncSuccess() / syncError()
  /// 
  /// 自动维护上限：保存后若总数超过 [_maxSyncHistories]，
  /// 删除最旧的记录，保证存储不无限增长。
  /// 
  /// Fail Fast：
  /// - history.id 为空：由 SyncHistory 构造函数保证
  @override
  Future<void> saveSyncHistory(SyncHistory history) async {
    assert(history.id.isNotEmpty, 'SyncHistory ID cannot be empty');
    await _syncHistoriesBoxOrThrow.put(history.id, history);
    
    // 超出上限时，删除最旧的记录
    final box = _syncHistoriesBoxOrThrow;
    if (box.length > _maxSyncHistories) {
      final sorted = box.values.toList()
        ..sort((a, b) => a.syncTime.compareTo(b.syncTime)); // 升序，最旧在前
      final toDelete = sorted.take(box.length - _maxSyncHistories);
      for (final old in toDelete) {
        await box.delete(old.id);
      }
    }
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
  
  /// 获取指定用户的同步历史记录（按时间倒序）
  /// 
  /// 参数：
  /// - userId: 用户 ID
  /// 
  /// 调用者：SyncService.getLastSyncTime()
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  @override
  List<SyncHistory> getSyncHistoriesByUser(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    final histories = _syncHistoriesBoxOrThrow.values
        .where((h) => h.userId == userId)
        .toList();
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
  
  // ==================== 同步时间（增量同步用） ====================
  
  static const String _lastSyncTimeKeyPrefix = 'last_sync_time_';
  
  /// 获取指定用户的上次同步时间
  /// 
  /// 调用者：SyncService.getLastSyncTime()
  @override
  DateTime? getLastSyncTime(String userId) {
    assert(userId.isNotEmpty, 'User ID cannot be empty');
    final key = '$_lastSyncTimeKeyPrefix$userId';
    final timeStr = _settingsBoxOrThrow.get(key) as String?;
    if (timeStr == null) return null;
    try {
      return DateTime.parse(timeStr);
    } catch (_) {
      return null;
    }
  }
  
  /// 保存指定用户的上次同步时间
  /// 
  /// 调用者：SyncService._saveLastSyncTime()
  @override
  Future<void> setLastSyncTime(String userId, DateTime syncStartTime) async {
    assert(userId.isNotEmpty, 'User ID cannot be empty');
    final key = '$_lastSyncTimeKeyPrefix$userId';
    await _settingsBoxOrThrow.put(key, syncStartTime.toIso8601String());
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
  @override
  Future<void> bindOfflineDataToUser(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    // 绑定记录
    final offlineRecords = getAllRecords()
        .where((record) => record.ownerId == null)
        .toList();
    for (final record in offlineRecords) {
      final boundRecord = record.copyWith(ownerId: () => userId);
      await saveRecord(boundRecord);
    }
    
    // 绑定故事线
    final offlineStoryLines = getAllStoryLines()
        .where((storyLine) => storyLine.userId == null)
        .toList();
    for (final storyLine in offlineStoryLines) {
      final boundStoryLine = storyLine.copyWith(userId: () => userId);
      await saveStoryLine(boundStoryLine);
    }
    
    // 绑定签到记录
    final offlineCheckIns = getAllCheckIns()
        .where((checkIn) => checkIn.userId == null)
        .toList();
    for (final checkIn in offlineCheckIns) {
      final boundCheckIn = checkIn.copyWith(userId: () => userId);
      await saveCheckIn(boundCheckIn);
    }

    // 绑定用户设置（将 guest 设置迁移到新用户）
    final offlineSettings = getUserSettings();
    if (offlineSettings != null && offlineSettings.userId == 'guest') {
      final boundSettings = offlineSettings.copyWith(
        id: 'settings_$userId',
        userId: userId,
      );
      await saveUserSettings(boundSettings);
    }
  }
  
  /// 删除所有离线数据
  /// 
  /// 删除所有 userId = null 的数据
  /// 
  /// 调用者：AuthNotifier（用户选择不绑定离线数据时）
  @override
  Future<void> deleteOfflineData() async {
    // 删除离线记录
    final offlineRecords = getAllRecords()
        .where((record) => record.ownerId == null)
        .toList();
    for (final record in offlineRecords) {
      await deleteRecord(record.id);
    }
    
    // 删除离线故事线
    final offlineStoryLines = getAllStoryLines()
        .where((storyLine) => storyLine.userId == null)
        .toList();
    for (final storyLine in offlineStoryLines) {
      await deleteStoryLine(storyLine.id);
    }
    
    // 删除离线签到记录
    final offlineCheckIns = getAllCheckIns()
        .where((checkIn) => checkIn.userId == null)
        .toList();
    for (final checkIn in offlineCheckIns) {
      await deleteCheckIn(checkIn.id);
    }
  }
  
  /// 清空认证数据（登出时调用）
  /// 
  /// 调用者：AuthNotifier.signOut()
  /// 
  /// 清空策略：
  /// - 只清空 Token 和认证相关信息
  /// - 保留所有用户的业务数据（记录、故事线、签到、成就等）
  /// 
  /// 设计说明：
  /// - 支持多用户场景：用户 A 登出后，A 的数据保留在本地
  /// - 用户 B 登录，只看到 B 的数据（通过 userId 过滤）
  /// - 用户 A 重新登录，数据立即可用（无需等待同步）
  /// 
  /// Fail Fast：
  /// - Box 未初始化：抛出 StateError
  @override
  Future<void> clearAuthData() async {
    await _settingsBoxOrThrow.delete('user_settings');
  }

  /// 删除指定用户的所有本地数据（注销账号时调用）
  ///
  /// 调用者：AuthNotifier.deleteAccount()
  ///
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  @override
  Future<void> deleteUserData(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    // 删除记录
    final userRecords = getRecordsByUser(userId);
    for (final record in userRecords) {
      await deleteRecord(record.id);
    }

    // 删除故事线
    final userStoryLines = getStoryLinesByUser(userId);
    for (final storyLine in userStoryLines) {
      await deleteStoryLine(storyLine.id);
    }

    // 删除签到记录
    final userCheckIns = getCheckInsByUser(userId);
    for (final checkIn in userCheckIns) {
      await deleteCheckIn(checkIn.id);
    }

    // 删除会员信息
    await deleteMembership(userId);

    // 删除同步历史
    final userSyncHistories = getSyncHistoriesByUser(userId);
    for (final history in userSyncHistories) {
      await deleteSyncHistory(history.id);
    }

    // 删除 lastSyncTime
    final syncTimeKey = '$_lastSyncTimeKeyPrefix$userId';
    await _settingsBoxOrThrow.delete(syncTimeKey);

    // 清除认证数据（Token 等）
    await clearAuthData();
  }

  // ==================== 收藏快照 ====================

  @override
  Future<void> saveFavoritedRecordSnapshot(EncounterRecord record) async {
    await _favoritedRecordSnapshotsBoxOrThrow.put(record.id, record);
  }

  @override
  EncounterRecord? getFavoritedRecordSnapshot(String recordId) {
    return _favoritedRecordSnapshotsBoxOrThrow.get(recordId);
  }

  @override
  Future<void> deleteFavoritedRecordSnapshot(String recordId) async {
    await _favoritedRecordSnapshotsBoxOrThrow.delete(recordId);
  }

  @override
  Future<void> saveFavoritedPostSnapshot(String postId, Map<String, dynamic> postJson) async {
    await _favoritedPostSnapshotsBoxOrThrow.put(postId, jsonEncode(postJson));
  }

  @override
  Map<String, dynamic>? getFavoritedPostSnapshot(String postId) {
    final raw = _favoritedPostSnapshotsBoxOrThrow.get(postId);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> deleteFavoritedPostSnapshot(String postId) async {
    await _favoritedPostSnapshotsBoxOrThrow.delete(postId);
  }
  
  // ==================== 会员相关操作 ====================
  
  /// 获取用户的会员信息
  @override
  Future<Membership?> getMembership(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    final json = _membershipsBoxOrThrow.get(userId);
    if (json == null) return null;
    return Membership.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
  
  /// 保存会员信息
  @override
  Future<void> saveMembership(Membership membership) async {
    if (membership.userId.isEmpty) {
      throw ArgumentError('membership.userId cannot be empty');
    }
    await _membershipsBoxOrThrow.put(membership.userId, jsonEncode(membership.toJson()));
  }
  
  /// 删除会员信息
  @override
  Future<void> deleteMembership(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    await _membershipsBoxOrThrow.delete(userId);
  }
}

