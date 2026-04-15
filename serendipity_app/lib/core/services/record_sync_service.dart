import '../../models/encounter_record.dart';
import '../../models/user.dart';
import '../repositories/i_remote_data_repository.dart';
import 'i_storage_service.dart';

class RecordSyncService {
  final IRemoteDataRepository _remoteRepository;
  final IStorageService _storageService;

  RecordSyncService({
    required IRemoteDataRepository remoteRepository,
    required IStorageService storageService,
  }) : _remoteRepository = remoteRepository,
       _storageService = storageService;

  Future<void> uploadRecord(User user, EncounterRecord record) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    await _remoteRepository.uploadRecord(user.id, record);
  }

  Future<void> updateRecord(User user, EncounterRecord record) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    await _remoteRepository.updateRecord(user.id, record);
  }

  Future<void> deleteRecord(User user, String recordId) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (recordId.isEmpty) {
      throw ArgumentError('记录 ID 不能为空');
    }

    await _remoteRepository.deleteRecord(user.id, recordId);
  }

  Future<int> uploadChangedRecords(User user, {DateTime? lastSyncTime}) async {
    final userRecords = _storageService.getRecordsByUser(user.id);
    final changedRecords = lastSyncTime == null
        ? userRecords
        : userRecords.where((r) => r.updatedAt.isAfter(lastSyncTime)).toList();
    if (changedRecords.isEmpty) {
      return 0;
    }

    await _remoteRepository.uploadRecords(user.id, changedRecords);
    return changedRecords.length;
  }

  Future<RecordDownloadResult> downloadAndMergeRecords(
    User user, {
    required DateTime? lastSyncTime,
    required bool isFullSync,
  }) async {
    final remoteRecords = isFullSync
        ? await _remoteRepository.downloadRecords(user.id)
        : await _remoteRepository.downloadRecordsSince(user.id, lastSyncTime!);
    final mergedRecords = await mergeRecords(remoteRecords, user.id, isFullSync);
    return RecordDownloadResult(
      downloadedRecords: remoteRecords.length,
      mergedRecords: mergedRecords,
    );
  }

  Future<int> mergeRecords(
    List<EncounterRecord> remoteRecords,
    String userId,
    bool isFullSync,
  ) async {
    int mergedCount = 0;

    for (final remoteRecord in remoteRecords) {
      if (remoteRecord.deletedAt != null) {
        final localRecord = _storageService.getRecord(remoteRecord.id);
        if (localRecord != null) {
          await _storageService.deleteRecord(remoteRecord.id);
          mergedCount++;
        }
        continue;
      }

      final localRecord = _storageService.getRecord(remoteRecord.id);
      if (localRecord == null ||
          remoteRecord.updatedAt.isAfter(localRecord.updatedAt)) {
        await _storageService.saveRecord(remoteRecord);
        if (localRecord != null) mergedCount++;
      }
    }

    if (isFullSync) {
      final remoteRecordIds = remoteRecords.map((r) => r.id).toSet();
      final localRecords = _storageService.getRecordsByUser(userId);
      for (final local in localRecords) {
        if (!remoteRecordIds.contains(local.id)) {
          await _storageService.deleteRecord(local.id);
        }
      }
    }

    return mergedCount;
  }
}

class RecordDownloadResult {
  final int downloadedRecords;
  final int mergedRecords;

  const RecordDownloadResult({
    required this.downloadedRecords,
    required this.mergedRecords,
  });
}

