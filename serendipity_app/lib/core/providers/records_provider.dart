import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../services/i_storage_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../repositories/record_repository.dart';
import 'auth_provider.dart';

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
  late SyncService _syncService;

  @override
  Future<List<EncounterRecord>> build() async {
    _repository = ref.read(recordRepositoryProvider);
    _syncService = ref.read(syncServiceProvider);
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
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，保存到本地后自动上传到云端
  /// - 如果用户未登录，只保存到本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> saveRecord(EncounterRecord record) async {
    // 1. 保存到本地
    await _repository.saveRecord(record);
    
    // 2. 如果用户已登录，上传到云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.uploadRecord(currentUser, record);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 但需要向上抛出异常，让 UI 层显示提示
        // 用户可以稍后手动触发全量同步
        rethrow;
      }
    }
    
    // 3. 刷新列表
    await refresh();
  }

  /// 更新记录（自动处理故事线关联变化）
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，更新本地后自动上传到云端
  /// - 如果用户未登录，只更新本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> updateRecord(EncounterRecord record) async {
    // 1. 更新本地
    await _repository.updateRecord(record);
    
    // 2. 如果用户已登录，上传到云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.uploadRecord(currentUser, record);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 但需要向上抛出异常，让 UI 层显示提示
        rethrow;
      }
    }
    
    // 3. 刷新列表
    await refresh();
  }

  /// 删除记录（自动从故事线移除）
  /// 
  /// 集成云端同步：
  /// - 如果用户已登录，删除本地后自动删除云端数据
  /// - 如果用户未登录，只删除本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> deleteRecord(String id) async {
    // 1. 删除本地
    await _repository.deleteRecord(id);
    
    // 2. 如果用户已登录，删除云端
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.deleteRecord(currentUser, id);
      } catch (e) {
        // 云端同步失败不影响本地操作
        // 但需要向上抛出异常，让 UI 层显示提示
        rethrow;
      }
    }
    
    // 3. 刷新列表
    await refresh();
  }

  /// 置顶记录
  Future<void> pinRecord(String id) async {
    final record = _repository.getRecord(id);
    if (record == null) {
      throw StateError('Record $id does not exist');
    }
    
    final updatedRecord = record.copyWith(
      isPinned: true,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateRecord(updatedRecord);
    await refresh();
  }

  /// 取消置顶记录
  Future<void> unpinRecord(String id) async {
    final record = _repository.getRecord(id);
    if (record == null) {
      throw StateError('Record $id does not exist');
    }
    
    final updatedRecord = record.copyWith(
      isPinned: false,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateRecord(updatedRecord);
    await refresh();
  }

  /// 切换置顶状态
  Future<void> togglePin(String id) async {
    final record = _repository.getRecord(id);
    if (record == null) {
      throw StateError('Record $id does not exist');
    }
    
    if (record.isPinned) {
      await unpinRecord(id);
    } else {
      await pinRecord(id);
    }
  }
}

/// 记录列表 Provider
final recordsProvider = AsyncNotifierProvider<RecordsNotifier, List<EncounterRecord>>(() {
  return RecordsNotifier();
});

