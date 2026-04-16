part of '../storage_service.dart';

mixin _StorageServiceSyncHistory on _StorageServiceCore {
  static const int maxSyncHistories = 100;

  @override
  Future<void> saveSyncHistory(SyncHistory history) async {
    assert(history.id.isNotEmpty, 'SyncHistory ID cannot be empty');
    await syncHistoriesBoxOrThrow.put(history.id, history);

    final box = syncHistoriesBoxOrThrow;
    if (box.length > maxSyncHistories) {
      final sorted = box.values.toList()
        ..sort((a, b) => a.syncTime.compareTo(b.syncTime));
      final toDelete = sorted.take(box.length - maxSyncHistories);
      for (final old in toDelete) {
        await box.delete(old.id);
      }
    }
  }

  @override
  List<SyncHistory> getAllSyncHistories() {
    final histories = syncHistoriesBoxOrThrow.values.toList();
    histories.sort((a, b) => b.syncTime.compareTo(a.syncTime));
    return histories;
  }

  @override
  List<SyncHistory> getSyncHistoriesByUser(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final histories = syncHistoriesBoxOrThrow.values
        .where((h) => h.userId == userId)
        .toList();
    histories.sort((a, b) => b.syncTime.compareTo(a.syncTime));
    return histories;
  }

  @override
  List<SyncHistory> getRecentSyncHistories(int limit) {
    if (limit <= 0) {
      throw ArgumentError('limit 必须大于 0');
    }

    final histories = getAllSyncHistories();
    return histories.take(limit).toList();
  }

  @override
  Future<void> deleteSyncHistory(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('SyncHistory ID 不能为空');
    }
    await syncHistoriesBoxOrThrow.delete(id);
  }

  @override
  Future<void> clearAllSyncHistories() async {
    await syncHistoriesBoxOrThrow.clear();
  }
}
