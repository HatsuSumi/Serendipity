part of '../storage_service.dart';

mixin _StorageServiceUserData on _StorageServiceCore {
  @override
  Future<void> bindOfflineDataToUser(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final offlineRecords = getAllRecords()
        .where((record) => record.ownerId == null)
        .toList();
    for (final record in offlineRecords) {
      final boundRecord = record.copyWith(ownerId: () => userId);
      await saveRecord(boundRecord);
    }

    final offlineStoryLines = getAllStoryLines()
        .where((storyLine) => storyLine.userId == null)
        .toList();
    for (final storyLine in offlineStoryLines) {
      final boundStoryLine = storyLine.copyWith(userId: () => userId);
      await saveStoryLine(boundStoryLine);
    }

    final offlineCheckIns = getAllCheckIns()
        .where((checkIn) => checkIn.userId == null)
        .toList();
    for (final checkIn in offlineCheckIns) {
      final boundCheckIn = checkIn.copyWith(userId: () => userId);
      await saveCheckIn(boundCheckIn);
    }

    final offlineSettings = getUserSettings();
    if (offlineSettings != null && offlineSettings.userId == 'guest') {
      final boundSettings = offlineSettings.copyWith(
        id: 'settings_$userId',
        userId: userId,
      );
      await saveUserSettings(boundSettings);
    }
  }

  @override
  Future<void> deleteOfflineData() async {
    final offlineRecords = getAllRecords()
        .where((record) => record.ownerId == null)
        .toList();
    for (final record in offlineRecords) {
      await deleteRecord(record.id);
    }

    final offlineStoryLines = getAllStoryLines()
        .where((storyLine) => storyLine.userId == null)
        .toList();
    for (final storyLine in offlineStoryLines) {
      await deleteStoryLine(storyLine.id);
    }

    final offlineCheckIns = getAllCheckIns()
        .where((checkIn) => checkIn.userId == null)
        .toList();
    for (final checkIn in offlineCheckIns) {
      await deleteCheckIn(checkIn.id);
    }
  }

  @override
  Future<void> deleteUserData(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final userRecords = getRecordsByUser(userId);
    for (final record in userRecords) {
      await deleteRecord(record.id);
    }

    final userStoryLines = getStoryLinesByUser(userId);
    for (final storyLine in userStoryLines) {
      await deleteStoryLine(storyLine.id);
    }

    final userCheckIns = getCheckInsByUser(userId);
    for (final checkIn in userCheckIns) {
      await deleteCheckIn(checkIn.id);
    }

    await achievementsBoxOrThrow.clear();
    await favoritedRecordSnapshotsBoxOrThrow.clear();
    await favoritedPostSnapshotsBoxOrThrow.clear();
    await deleteMembership(userId);

    final userSyncHistories = getSyncHistoriesByUser(userId);
    for (final history in userSyncHistories) {
      await deleteSyncHistory(history.id);
    }

    final syncTimeKey = '${_StorageServiceSettings.lastSyncTimeKeyPrefix}$userId';
    await settingsBoxOrThrow.delete(syncTimeKey);

    await clearAuthData();
  }
}
