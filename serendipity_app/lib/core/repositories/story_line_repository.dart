import '../../models/story_line.dart';
import '../../models/encounter_record.dart';
import '../services/i_storage_service.dart';

/// 故事线仓储
/// 封装故事线相关的业务逻辑和数据访问
class StoryLineRepository {
  final IStorageService _storage;

  StoryLineRepository(this._storage);

  /// 保存故事线
  Future<void> saveStoryLine(StoryLine storyLine) async {
    await _storage.saveStoryLine(storyLine);
  }

  /// 更新故事线
  /// 
  /// Fail Fast:
  /// - 如果故事线不存在，抛出 StateError
  Future<void> updateStoryLine(StoryLine storyLine) async {
    final oldStoryLine = _storage.getStoryLine(storyLine.id);
    if (oldStoryLine == null) {
      throw StateError('Cannot update story line: Story line ${storyLine.id} does not exist');
    }

    await _storage.updateStoryLine(storyLine);
  }

  /// 删除故事线
  /// 
  /// 会自动取消所有关联记录的 storyLineId
  /// 
  /// Fail Fast:
  /// - 如果故事线不存在，抛出 StateError
  Future<void> deleteStoryLine(String storyLineId) async {
    final storyLine = _storage.getStoryLine(storyLineId);
    if (storyLine == null) {
      throw StateError('Cannot delete story line: Story line $storyLineId does not exist');
    }

    // 取消所有关联记录的 storyLineId
    for (final recordId in storyLine.recordIds) {
      final record = _storage.getRecord(recordId);
      if (record != null && record.storyLineId == storyLineId) {
        final updatedRecord = record.copyWith(
          storyLineId: () => null,
          updatedAt: DateTime.now(),
        );
        await _storage.updateRecord(updatedRecord);
      }
    }

    // 删除故事线
    await _storage.deleteStoryLine(storyLineId);
  }

  /// 获取单条故事线
  StoryLine? getStoryLine(String id) {
    return _storage.getStoryLine(id);
  }

  /// 获取所有故事线
  List<StoryLine> getAllStoryLines() {
    return _storage.getAllStoryLines();
  }

  /// 获取故事线列表（按更新时间倒序）
  List<StoryLine> getStoryLinesSortedByTime() {
    return _storage.getStoryLinesSortedByTime();
  }

  /// 将记录关联到故事线
  /// 
  /// Fail Fast:
  /// - 如果记录不存在，抛出 StateError
  /// - 如果故事线不存在，抛出 StateError
  /// - 如果记录已关联到其他故事线，抛出 StateError
  Future<void> linkRecord(String recordId, String storyLineId) async {
    final record = _storage.getRecord(recordId);
    if (record == null) {
      throw StateError('Cannot link record: Record $recordId does not exist');
    }

    final storyLine = _storage.getStoryLine(storyLineId);
    if (storyLine == null) {
      throw StateError('Cannot link record: Story line $storyLineId does not exist');
    }

    // 如果记录已关联到其他故事线，抛出错误
    if (record.storyLineId != null && record.storyLineId != storyLineId) {
      throw StateError(
        'Cannot link record: Record $recordId is already linked to story line ${record.storyLineId}'
      );
    }

    // 更新记录的 storyLineId
    final updatedRecord = record.copyWith(
      storyLineId: () => storyLineId,
      updatedAt: DateTime.now(),
    );
    await _storage.updateRecord(updatedRecord);

    // 更新故事线的 recordIds
    if (!storyLine.recordIds.contains(recordId)) {
      final updatedStoryLine = storyLine.copyWith(
        recordIds: [...storyLine.recordIds, recordId],
        updatedAt: DateTime.now(),
      );
      await _storage.updateStoryLine(updatedStoryLine);
    }
  }

  /// 从故事线移除记录
  /// 
  /// Fail Fast:
  /// - 如果记录不存在，抛出 StateError
  /// - 如果故事线不存在，抛出 StateError
  Future<void> unlinkRecord(String recordId, String storyLineId) async {
    final record = _storage.getRecord(recordId);
    if (record == null) {
      throw StateError('Cannot unlink record: Record $recordId does not exist');
    }

    final storyLine = _storage.getStoryLine(storyLineId);
    if (storyLine == null) {
      throw StateError('Cannot unlink record: Story line $storyLineId does not exist');
    }

    // 更新记录的 storyLineId 为 null
    final updatedRecord = record.copyWith(
      storyLineId: () => null,
      updatedAt: DateTime.now(),
    );
    await _storage.updateRecord(updatedRecord);

    // 从故事线的 recordIds 中移除
    final updatedRecordIds = storyLine.recordIds.where((id) => id != recordId).toList();
    final updatedStoryLine = storyLine.copyWith(
      recordIds: updatedRecordIds,
      updatedAt: DateTime.now(),
    );
    await _storage.updateStoryLine(updatedStoryLine);
  }

  /// 获取故事线的所有记录
  /// 
  /// 按时间排序
  List<EncounterRecord> getRecordsInStoryLine(String storyLineId) {
    final storyLine = _storage.getStoryLine(storyLineId);
    if (storyLine == null) return [];

    final records = <EncounterRecord>[];
    for (final recordId in storyLine.recordIds) {
      final record = _storage.getRecord(recordId);
      if (record != null) {
        records.add(record);
      }
    }

    // 按时间排序
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return records;
  }
}

