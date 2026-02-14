import 'package:hive_flutter/hive_flutter.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';

/// 本地存储服务
/// 使用 Hive 进行数据持久化
class StorageService {
  // Box 名称常量
  static const String _recordsBoxName = 'records';
  static const String _settingsBoxName = 'settings';
  static const String _storyLinesBoxName = 'story_lines';
  
  // 单例模式
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  // Box 实例
  Box<EncounterRecord>? _recordsBox;
  Box? _settingsBox;
  Box? _storyLinesBox;
  
  /// 初始化所有 Box
  Future<void> init() async {
    _recordsBox = await Hive.openBox<EncounterRecord>(_recordsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _storyLinesBox = await Hive.openBox(_storyLinesBoxName);
  }
  
  /// 关闭所有 Box
  Future<void> close() async {
    await _recordsBox?.close();
    await _settingsBox?.close();
    await _storyLinesBox?.close();
  }
  
  // ==================== 记录相关操作 ====================
  
  /// 保存记录
  Future<void> saveRecord(EncounterRecord record) async {
    await _recordsBox?.put(record.id, record);
  }
  
  /// 获取单条记录
  EncounterRecord? getRecord(String id) {
    return _recordsBox?.get(id);
  }
  
  /// 获取所有记录
  List<EncounterRecord> getAllRecords() {
    return _recordsBox?.values.toList() ?? [];
  }
  
  /// 获取记录列表（按时间倒序）
  List<EncounterRecord> getRecordsSortedByTime() {
    final records = getAllRecords();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }
  
  /// 删除记录
  Future<void> deleteRecord(String id) async {
    await _recordsBox?.delete(id);
  }
  
  /// 更新记录
  Future<void> updateRecord(EncounterRecord record) async {
    await _recordsBox?.put(record.id, record);
  }
  
  /// 获取记录数量
  int getRecordCount() {
    return _recordsBox?.length ?? 0;
  }
  
  /// 清空所有记录
  Future<void> clearAllRecords() async {
    await _recordsBox?.clear();
  }
  
  /// 根据故事线ID获取记录
  List<EncounterRecord> getRecordsByStoryLine(String storyLineId) {
    return getAllRecords()
        .where((record) => record.storyLineId == storyLineId)
        .toList();
  }
  
  /// 获取未关联故事线的记录
  List<EncounterRecord> getRecordsWithoutStoryLine() {
    return getAllRecords()
        .where((record) => record.storyLineId == null)
        .toList();
  }
  
  // ==================== 设置相关操作 ====================
  
  /// 保存设置
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }
  
  /// 获取设置
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox?.get(key, defaultValue: defaultValue);
  }
  
  /// 删除设置
  Future<void> deleteSetting(String key) async {
    await _settingsBox?.delete(key);
  }
  
  /// 清空所有设置
  Future<void> clearAllSettings() async {
    await _settingsBox?.clear();
  }
  
  // ==================== 故事线相关操作 ====================
  
  /// 保存故事线
  Future<void> saveStoryLine(StoryLine storyLine) async {
    await _storyLinesBox?.put(storyLine.id, storyLine.toJson());
  }
  
  /// 获取单条故事线
  StoryLine? getStoryLine(String id) {
    final json = _storyLinesBox?.get(id);
    if (json == null) return null;
    return StoryLine.fromJson(Map<String, dynamic>.from(json as Map));
  }
  
  /// 获取所有故事线
  List<StoryLine> getAllStoryLines() {
    return _storyLinesBox?.values
        .map((json) => StoryLine.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList() ?? [];
  }
  
  /// 获取故事线列表（按更新时间倒序）
  List<StoryLine> getStoryLinesSortedByTime() {
    final storyLines = getAllStoryLines();
    storyLines.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return storyLines;
  }
  
  /// 删除故事线
  Future<void> deleteStoryLine(String id) async {
    await _storyLinesBox?.delete(id);
  }
  
  /// 更新故事线
  Future<void> updateStoryLine(StoryLine storyLine) async {
    await _storyLinesBox?.put(storyLine.id, storyLine.toJson());
  }
  
  /// 获取故事线数量
  int getStoryLineCount() {
    return _storyLinesBox?.length ?? 0;
  }
  
  /// 清空所有故事线
  Future<void> clearAllStoryLines() async {
    await _storyLinesBox?.clear();
  }
  
  /// 将记录关联到故事线
  Future<void> linkRecordToStoryLine(String recordId, String storyLineId) async {
    // 更新记录的 storyLineId
    final record = getRecord(recordId);
    if (record != null) {
      final updatedRecord = record.copyWith(
        storyLineId: storyLineId,
        updatedAt: DateTime.now(),
      );
      await updateRecord(updatedRecord);
    }
    
    // 更新故事线的 recordIds
    final storyLine = getStoryLine(storyLineId);
    if (storyLine != null && !storyLine.recordIds.contains(recordId)) {
      final updatedStoryLine = storyLine.copyWith(
        recordIds: [...storyLine.recordIds, recordId],
        updatedAt: DateTime.now(),
      );
      await updateStoryLine(updatedStoryLine);
    }
  }
  
  /// 从故事线移除记录
  Future<void> unlinkRecordFromStoryLine(String recordId, String storyLineId) async {
    // 更新记录的 storyLineId 为 null
    final record = getRecord(recordId);
    if (record != null) {
      final updatedRecord = record.copyWith(
        storyLineId: null,
        updatedAt: DateTime.now(),
      );
      await updateRecord(updatedRecord);
    }
    
    // 从故事线的 recordIds 中移除
    final storyLine = getStoryLine(storyLineId);
    if (storyLine != null) {
      final updatedRecordIds = storyLine.recordIds.where((id) => id != recordId).toList();
      final updatedStoryLine = storyLine.copyWith(
        recordIds: updatedRecordIds,
        updatedAt: DateTime.now(),
      );
      await updateStoryLine(updatedStoryLine);
    }
  }
}

