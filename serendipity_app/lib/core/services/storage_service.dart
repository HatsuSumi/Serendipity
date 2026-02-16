import 'package:hive_flutter/hive_flutter.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import 'i_storage_service.dart';

/// 本地存储服务（Hive 实现）
/// 使用 Hive 进行数据持久化
class StorageService implements IStorageService {
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
  Box<StoryLine>? _storyLinesBox;
  
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
  
  /// 初始化所有 Box
  @override
  Future<void> init() async {
    _recordsBox = await Hive.openBox<EncounterRecord>(_recordsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _storyLinesBox = await Hive.openBox<StoryLine>(_storyLinesBoxName);
  }
  
  /// 关闭所有 Box
  @override
  Future<void> close() async {
    await _recordsBox?.close();
    await _settingsBox?.close();
    await _storyLinesBox?.close();
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
  

}

