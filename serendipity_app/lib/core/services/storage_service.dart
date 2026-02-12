import 'package:hive_flutter/hive_flutter.dart';
import '../../models/encounter_record.dart';

/// 本地存储服务
/// 使用 Hive 进行数据持久化
class StorageService {
  // Box 名称常量
  static const String _recordsBoxName = 'records';
  static const String _settingsBoxName = 'settings';
  
  // 单例模式
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  // Box 实例
  Box<EncounterRecord>? _recordsBox;
  Box? _settingsBox;
  
  /// 初始化所有 Box
  Future<void> init() async {
    _recordsBox = await Hive.openBox<EncounterRecord>(_recordsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }
  
  /// 关闭所有 Box
  Future<void> close() async {
    await _recordsBox?.close();
    await _settingsBox?.close();
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
}

