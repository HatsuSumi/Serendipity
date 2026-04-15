import '../../models/sync_history.dart';
import 'i_storage_service.dart';
import 'sync_result.dart';

class SyncMetadataService {
  final IStorageService _storageService;

  SyncMetadataService({
    required IStorageService storageService,
  }) : _storageService = storageService;

  Future<DateTime?> getLastSyncTime(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final persisted = _storageService.getLastSyncTime(userId);
    if (persisted != null) {
      return persisted;
    }

    final userHistories = _storageService.getSyncHistoriesByUser(userId);
    if (userHistories.isEmpty) {
      return null;
    }

    final successHistories = userHistories.where((history) => history.success).toList();
    if (successHistories.isEmpty) {
      return null;
    }

    return successHistories.first.syncTime;
  }

  Future<void> saveLastSyncTime(String userId, DateTime syncStartTime) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    await _storageService.setLastSyncTime(userId, syncStartTime);
  }

  Future<void> saveSuccessHistory({
    required SyncResult result,
    required String userId,
    required DateTime syncStartTime,
    required DateTime syncEndTime,
    required SyncSource source,
  }) async {
    final history = SyncHistory.fromSuccess(
      result: result,
      userId: userId,
      syncStartTime: syncStartTime,
      syncEndTime: syncEndTime,
      source: source,
    );
    await _storageService.saveSyncHistory(history);
  }

  Future<void> saveFailureHistory({
    required String errorMessage,
    required String userId,
    required DateTime syncStartTime,
    required DateTime syncEndTime,
    required SyncSource source,
  }) async {
    final history = SyncHistory.fromError(
      errorMessage: errorMessage,
      userId: userId,
      syncStartTime: syncStartTime,
      syncEndTime: syncEndTime,
      source: source,
    );
    await _storageService.saveSyncHistory(history);
  }
}

