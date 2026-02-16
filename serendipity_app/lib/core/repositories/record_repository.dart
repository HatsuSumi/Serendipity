import '../../models/encounter_record.dart';
import '../services/i_storage_service.dart';

/// 记录仓储
/// 封装记录相关的业务逻辑和数据访问
class RecordRepository {
  final IStorageService _storage;

  RecordRepository(this._storage);

  /// 保存记录
  /// 
  /// 如果记录关联了故事线，会自动建立双向关联
  /// 
  /// Fail Fast:
  /// - 如果故事线不存在，抛出 StateError
  Future<void> saveRecord(EncounterRecord record) async {
    // 如果关联了故事线，验证故事线存在
    if (record.storyLineId != null) {
      final storyLine = _storage.getStoryLine(record.storyLineId!);
      if (storyLine == null) {
        throw StateError(
          'Cannot save record: Story line ${record.storyLineId} does not exist'
        );
      }
    }

    // 保存记录
    await _storage.saveRecord(record);

    // 如果关联了故事线，建立双向关联
    if (record.storyLineId != null) {
      await _linkRecordToStoryLine(record.id, record.storyLineId!);
    }
  }

  /// 更新记录
  /// 
  /// 如果故事线ID发生变化，会自动更新双向关联
  /// 
  /// Fail Fast:
  /// - 如果记录不存在，抛出 StateError
  /// - 如果新故事线不存在，抛出 StateError
  Future<void> updateRecord(EncounterRecord record) async {
    // 验证记录存在
    final oldRecord = _storage.getRecord(record.id);
    if (oldRecord == null) {
      throw StateError('Cannot update record: Record ${record.id} does not exist');
    }

    // 如果新关联的故事线存在，验证其存在性
    if (record.storyLineId != null) {
      final storyLine = _storage.getStoryLine(record.storyLineId!);
      if (storyLine == null) {
        throw StateError(
          'Cannot update record: Story line ${record.storyLineId} does not exist'
        );
      }
    }

    // 检查故事线是否发生变化
    final oldStoryLineId = oldRecord.storyLineId;
    final newStoryLineId = record.storyLineId;

    if (oldStoryLineId != newStoryLineId) {
      // 从旧故事线移除
      if (oldStoryLineId != null) {
        await _unlinkRecordFromStoryLine(record.id, oldStoryLineId);
      }
      // 关联到新故事线
      if (newStoryLineId != null) {
        await _linkRecordToStoryLine(record.id, newStoryLineId);
      }
    }

    // 更新记录
    await _storage.updateRecord(record);
  }

  /// 删除记录
  /// 
  /// 会自动从关联的故事线中移除
  /// 
  /// Fail Fast:
  /// - 如果记录不存在，抛出 StateError
  Future<void> deleteRecord(String recordId) async {
    final record = _storage.getRecord(recordId);
    if (record == null) {
      throw StateError('Cannot delete record: Record $recordId does not exist');
    }

    // 如果关联了故事线，先移除关联
    if (record.storyLineId != null) {
      await _unlinkRecordFromStoryLine(recordId, record.storyLineId!);
    }

    // 删除记录
    await _storage.deleteRecord(recordId);
  }

  /// 获取单条记录
  EncounterRecord? getRecord(String id) {
    return _storage.getRecord(id);
  }

  /// 获取所有记录
  List<EncounterRecord> getAllRecords() {
    return _storage.getAllRecords();
  }

  /// 获取记录列表（按时间倒序）
  List<EncounterRecord> getRecordsSortedByTime() {
    return _storage.getRecordsSortedByTime();
  }

  /// 根据故事线ID获取记录
  List<EncounterRecord> getRecordsByStoryLine(String storyLineId) {
    return _storage.getRecordsByStoryLine(storyLineId);
  }

  /// 获取未关联故事线的记录
  List<EncounterRecord> getRecordsWithoutStoryLine() {
    return _storage.getRecordsWithoutStoryLine();
  }

  /// 验证数据一致性
  /// 
  /// 检查记录和故事线的双向关联是否一致
  /// 
  /// Fail Fast: 如果发现不一致，抛出 StateError
  void validateDataConsistency() {
    final records = _storage.getAllRecords();
    final storyLines = _storage.getAllStoryLines();

    // 检查每条记录的 storyLineId
    for (final record in records) {
      if (record.storyLineId != null) {
        final storyLine = _storage.getStoryLine(record.storyLineId!);
        
        // 故事线必须存在
        if (storyLine == null) {
          throw StateError(
            'Data inconsistency: Record ${record.id} references non-existent '
            'story line ${record.storyLineId}'
          );
        }
        
        // 故事线的 recordIds 必须包含该记录
        if (!storyLine.recordIds.contains(record.id)) {
          throw StateError(
            'Data inconsistency: Record ${record.id} has storyLineId=${record.storyLineId}, '
            'but story line does not contain this record in recordIds'
          );
        }
      }
    }

    // 检查每个故事线的 recordIds
    for (final storyLine in storyLines) {
      for (final recordId in storyLine.recordIds) {
        final record = _storage.getRecord(recordId);
        
        // 记录必须存在
        if (record == null) {
          throw StateError(
            'Data inconsistency: Story line ${storyLine.id} references non-existent '
            'record $recordId'
          );
        }
        
        // 记录的 storyLineId 必须指向该故事线
        if (record.storyLineId != storyLine.id) {
          throw StateError(
            'Data inconsistency: Story line ${storyLine.id} contains record $recordId, '
            'but record has storyLineId=${record.storyLineId}'
          );
        }
      }
    }
  }

  // ==================== 私有方法 ====================

  /// 将记录关联到故事线（内部方法）
  Future<void> _linkRecordToStoryLine(String recordId, String storyLineId) async {
    final storyLine = _storage.getStoryLine(storyLineId);
    if (storyLine != null && !storyLine.recordIds.contains(recordId)) {
      final updatedStoryLine = storyLine.copyWith(
        recordIds: [...storyLine.recordIds, recordId],
        updatedAt: DateTime.now(),
      );
      await _storage.updateStoryLine(updatedStoryLine);
    }
  }

  /// 从故事线移除记录（内部方法）
  Future<void> _unlinkRecordFromStoryLine(String recordId, String storyLineId) async {
    final storyLine = _storage.getStoryLine(storyLineId);
    if (storyLine != null) {
      final updatedRecordIds = storyLine.recordIds.where((id) => id != recordId).toList();
      final updatedStoryLine = storyLine.copyWith(
        recordIds: updatedRecordIds,
        updatedAt: DateTime.now(),
      );
      await _storage.updateStoryLine(updatedStoryLine);
    }
  }
}

