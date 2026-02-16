import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../services/i_storage_service.dart';
import '../services/storage_service.dart';
import '../repositories/record_repository.dart';

/// 存储服务 Provider
final storageServiceProvider = Provider<IStorageService>((ref) {
  return StorageService();
});

/// 记录仓储 Provider
final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(ref.read(storageServiceProvider));
});

/// 记录列表状态管理
class RecordsNotifier extends AsyncNotifier<List<EncounterRecord>> {
  late RecordRepository _repository;

  @override
  Future<List<EncounterRecord>> build() async {
    _repository = ref.read(recordRepositoryProvider);
    // 初始化时加载所有记录
    return _repository.getRecordsSortedByTime();
  }

  /// 刷新记录列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.getRecordsSortedByTime();
    });
  }

  /// 保存记录（自动处理故事线关联）
  Future<void> saveRecord(EncounterRecord record) async {
    await _repository.saveRecord(record);
    await refresh();
  }

  /// 更新记录（自动处理故事线关联变化）
  Future<void> updateRecord(EncounterRecord record) async {
    await _repository.updateRecord(record);
    await refresh();
  }

  /// 删除记录（自动从故事线移除）
  Future<void> deleteRecord(String id) async {
    await _repository.deleteRecord(id);
    await refresh();
  }
}

/// 记录列表 Provider
final recordsProvider = AsyncNotifierProvider<RecordsNotifier, List<EncounterRecord>>(() {
  return RecordsNotifier();
});

