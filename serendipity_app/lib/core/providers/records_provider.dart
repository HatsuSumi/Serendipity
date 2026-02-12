import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../services/storage_service.dart';

/// 记录列表状态管理
class RecordsNotifier extends AsyncNotifier<List<EncounterRecord>> {
  @override
  Future<List<EncounterRecord>> build() async {
    // 初始化时加载所有记录
    return await StorageService().getAllRecords();
  }

  /// 刷新记录列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await StorageService().getAllRecords();
    });
  }

  /// 添加记录后刷新
  Future<void> addRecord(EncounterRecord record) async {
    await StorageService().saveRecord(record);
    await refresh();
  }

  /// 删除记录后刷新
  Future<void> deleteRecord(String id) async {
    await StorageService().deleteRecord(id);
    await refresh();
  }

  /// 更新记录后刷新
  Future<void> updateRecord(EncounterRecord record) async {
    await StorageService().updateRecord(record);
    await refresh();
  }
}

/// 记录列表 Provider
final recordsProvider = AsyncNotifierProvider<RecordsNotifier, List<EncounterRecord>>(() {
  return RecordsNotifier();
});

