import '../../models/encounter_record.dart';
import '../services/i_storage_service.dart';

/// 记录仓储
/// 封装记录相关的业务逻辑和数据访问
class RecordRepository {
  final IStorageService _storage;

  RecordRepository(this._storage);

  /// 保存记录
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

    // 保存记录（双向关联由 StoryLineRepository 统一维护）
    await _storage.saveRecord(record);
  }

  /// 更新记录
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

    // 更新记录（双向关联由 StoryLineRepository 统一维护）
    await _storage.updateRecord(record);
  }

  /// 删除记录
  /// 
  /// Fail Fast:
  /// - 如果记录不存在，抛出 StateError
  /// 
  /// 注意：删除记录前，调用方应先通过 StoryLineRepository 解除关联
  Future<void> deleteRecord(String recordId) async {
    final record = _storage.getRecord(recordId);
    if (record == null) {
      throw StateError('Cannot delete record: Record $recordId does not exist');
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
  
  /// 获取指定用户的记录列表（按时间倒序）
  /// 
  /// 参数：
  /// - userId: 用户ID，null 表示获取离线数据（未绑定账号）
  /// 
  /// 调用者：RecordsProvider
  List<EncounterRecord> getRecordsByUser(String? userId) {
    return _storage.getRecordsByUser(userId);
  }

  /// 根据故事线ID获取记录
  List<EncounterRecord> getRecordsByStoryLine(String storyLineId) {
    return _storage.getRecordsByStoryLine(storyLineId);
  }

  /// 获取未关联故事线的记录
  List<EncounterRecord> getRecordsWithoutStoryLine() {
    return _storage.getRecordsWithoutStoryLine();
  }

  /// 从后端筛选记录（支持多条件组合）
  /// 
  /// 设计原则：
  /// - 后端筛选：支持大数据量和复杂筛选
  /// - 分页支持：limit + offset
  /// - 排序支持：createdAt/updatedAt，升序/降序
  /// - 标签筛选：全词匹配或包含匹配
  /// 
  /// 调用者：
  /// - RecordsProvider.filterRecordsFromServer()
  /// 
  /// 返回：筛选结果列表
  /// 
  /// 注意：此方法由 RecordsProvider 通过 remoteDataRepositoryProvider 调用
  /// 不在此处实现，避免循环依赖
  Future<List<EncounterRecord>> filterRecordsFromServer({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? province,
    String? city,
    String? area,
    List<String>? placeTypes,
    List<String>? tags,
    String tagMatchMode = 'contains',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int limit = 20,
    int offset = 0,
  }) async {
    throw UnimplementedError(
      'filterRecordsFromServer should be called through remoteDataRepositoryProvider in RecordsProvider'
    );
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

}

