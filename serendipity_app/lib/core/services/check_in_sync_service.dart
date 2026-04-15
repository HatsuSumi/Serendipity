import '../../models/check_in_record.dart';
import '../../models/remote_check_in_status.dart';
import '../../models/user.dart';
import '../repositories/i_remote_data_repository.dart';
import 'i_storage_service.dart';

class CheckInSyncService {
  final IRemoteDataRepository _remoteRepository;
  final IStorageService _storageService;

  CheckInSyncService({
    required IRemoteDataRepository remoteRepository,
    required IStorageService storageService,
  }) : _remoteRepository = remoteRepository,
       _storageService = storageService;

  Future<CheckInRecord> createTodayCheckIn(User user) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    return await _remoteRepository.createTodayCheckIn(user.id);
  }

  Future<RemoteCheckInStatus> getCheckInStatus(
    User user,
    int year,
    int month,
  ) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final json = await _remoteRepository.getCheckInStatus(user.id, year, month);
    return RemoteCheckInStatus.fromJson(json);
  }

  Future<void> refreshCheckIns(User user) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final remoteCheckIns = await _remoteRepository.downloadCheckIns(user.id);
    await mergeCheckIns(remoteCheckIns, user.id, true);
  }

  Future<void> deleteCheckIn(User user, String checkInId) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (checkInId.isEmpty) {
      throw ArgumentError('签到记录 ID 不能为空');
    }

    await _remoteRepository.deleteCheckIn(user.id, checkInId);
  }

  Future<CheckInDownloadResult> downloadAndMergeCheckIns(
    User user, {
    required DateTime? lastSyncTime,
    required bool isFullSync,
  }) async {
    final remoteCheckIns = isFullSync
        ? await _remoteRepository.downloadCheckIns(user.id)
        : await _remoteRepository.downloadCheckInsSince(user.id, lastSyncTime!);
    final mergedCheckIns = await mergeCheckIns(
      remoteCheckIns,
      user.id,
      isFullSync,
    );
    return CheckInDownloadResult(
      downloadedCheckIns: remoteCheckIns.length,
      mergedCheckIns: mergedCheckIns,
    );
  }

  Future<int> mergeCheckIns(
    List<CheckInRecord> remoteCheckIns,
    String userId,
    bool isFullSync,
  ) async {
    int mergedCount = 0;

    for (final remoteCheckIn in remoteCheckIns) {
      if (remoteCheckIn.deletedAt != null) {
        final localCheckIn = _storageService.getCheckIn(remoteCheckIn.id);
        if (localCheckIn != null) {
          await _storageService.deleteCheckIn(remoteCheckIn.id);
          mergedCount++;
        }
        continue;
      }

      final localCheckIn = _storageService.getCheckIn(remoteCheckIn.id);
      if (localCheckIn == null ||
          remoteCheckIn.updatedAt.isAfter(localCheckIn.updatedAt)) {
        await _storageService.saveCheckIn(remoteCheckIn);
        if (localCheckIn != null) {
          mergedCount++;
        }
      }
    }

    if (isFullSync) {
      final remoteCheckInIds = remoteCheckIns.map((checkIn) => checkIn.id).toSet();
      final localCheckIns = _storageService.getCheckInsByUser(userId);
      for (final localCheckIn in localCheckIns) {
        if (!remoteCheckInIds.contains(localCheckIn.id)) {
          await _storageService.deleteCheckIn(localCheckIn.id);
        }
      }
    }

    return mergedCount;
  }
}

class CheckInDownloadResult {
  final int downloadedCheckIns;
  final int mergedCheckIns;

  const CheckInDownloadResult({
    required this.downloadedCheckIns,
    required this.mergedCheckIns,
  });
}

