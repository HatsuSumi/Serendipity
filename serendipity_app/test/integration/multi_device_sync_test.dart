import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/core/repositories/record_repository.dart';
import 'package:serendipity_app/core/repositories/story_line_repository.dart';
import 'package:serendipity_app/core/services/i_storage_service.dart';
import 'package:serendipity_app/models/encounter_record.dart';
import 'package:serendipity_app/models/story_line.dart';
import 'package:serendipity_app/models/enums.dart';
import 'package:serendipity_app/models/check_in_record.dart';
import 'package:serendipity_app/models/user_settings.dart';
import 'package:serendipity_app/models/achievement.dart';
import 'package:serendipity_app/models/sync_history.dart';

/// 简单的内存存储实现，用于测试
class InMemoryStorageService implements IStorageService {
  final Map<String, EncounterRecord> _records = {};
  final Map<String, StoryLine> _storyLines = {};
  final Map<String, Achievement> _achievements = {};
  final Map<String, CheckInRecord> _checkIns = {};
  final Map<String, dynamic> _keyValues = {};
  UserSettings? _userSettings;

  @override
  Future<void> init() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> saveRecord(EncounterRecord record) async {
    _records[record.id] = record;
  }

  @override
  EncounterRecord? getRecord(String id) {
    return _records[id];
  }

  @override
  List<EncounterRecord> getAllRecords() {
    return _records.values.toList();
  }

  @override
  List<EncounterRecord> getRecordsSortedByTime() {
    final records = _records.values.toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  List<EncounterRecord> getRecordsByUser(String? userId) {
    return _records.values
        .where((r) => r.ownerId == userId)
        .toList();
  }

  @override
  Future<void> deleteRecord(String id) async {
    _records.remove(id);
  }

  @override
  Future<void> updateRecord(EncounterRecord record) async {
    _records[record.id] = record;
  }

  @override
  List<EncounterRecord> getRecordsByStoryLine(String storyLineId) {
    return _records.values
        .where((r) => r.storyLineId == storyLineId)
        .toList();
  }

  @override
  List<EncounterRecord> getRecordsWithoutStoryLine() {
    return _records.values
        .where((r) => r.storyLineId == null)
        .toList();
  }

  @override
  Future<void> saveStoryLine(StoryLine storyLine) async {
    _storyLines[storyLine.id] = storyLine;
  }

  @override
  StoryLine? getStoryLine(String id) {
    return _storyLines[id];
  }

  @override
  List<StoryLine> getAllStoryLines() {
    return _storyLines.values.toList();
  }

  @override
  List<StoryLine> getStoryLinesSortedByTime() {
    final storyLines = _storyLines.values.toList();
    storyLines.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return storyLines;
  }

  @override
  List<StoryLine> getStoryLinesByUser(String? userId) {
    return _storyLines.values
        .where((s) => s.ownerId == userId)
        .toList();
  }

  @override
  Future<void> deleteStoryLine(String id) async {
    _storyLines.remove(id);
  }

  @override
  Future<void> updateStoryLine(StoryLine storyLine) async {
    _storyLines[storyLine.id] = storyLine;
  }

  @override
  Future<void> saveAchievement(Achievement achievement) async {
    _achievements[achievement.id] = achievement;
  }

  @override
  Achievement? getAchievement(String id) {
    return _achievements[id];
  }

  @override
  List<Achievement> getAllAchievements() {
    return _achievements.values.toList();
  }

  @override
  Future<void> updateAchievement(Achievement achievement) async {
    _achievements[achievement.id] = achievement;
  }

  @override
  Future<void> saveCheckIn(CheckInRecord checkIn) async {
    _checkIns[checkIn.id] = checkIn;
  }

  @override
  CheckInRecord? getCheckIn(String id) {
    return _checkIns[id];
  }

  @override
  List<CheckInRecord> getAllCheckIns() {
    return _checkIns.values.toList();
  }

  @override
  List<CheckInRecord> getCheckInsSortedByDate() {
    final checkIns = _checkIns.values.toList();
    checkIns.sort((a, b) => b.date.compareTo(a.date));
    return checkIns;
  }

  @override
  List<CheckInRecord> getCheckInsByUser(String? userId) {
    return _checkIns.values
        .where((c) => c.userId == userId)
        .toList();
  }

  @override
  Future<void> deleteCheckIn(String id) async {
    _checkIns.remove(id);
  }

  @override
  UserSettings? getUserSettings() {
    return _userSettings;
  }

  @override
  Future<void> saveUserSettings(UserSettings settings) async {
    _userSettings = settings;
  }

  @override
  Future<void> saveSyncHistory(SyncHistory history) async {}

  @override
  List<SyncHistory> getAllSyncHistories() => [];

  @override
  List<SyncHistory> getSyncHistoriesByUser(String userId) => [];

  @override
  List<SyncHistory> getRecentSyncHistories(int limit) => [];

  @override
  Future<void> deleteSyncHistory(String id) async {}

  @override
  Future<void> clearAllSyncHistories() async {}

  @override
  DateTime? getLastSyncTime(String userId) => null;

  @override
  Future<void> setLastSyncTime(String userId, DateTime syncStartTime) async {}

  @override
  Future<void> set<T>(String key, T value) async {
    _keyValues[key] = value;
  }

  @override
  T? get<T>(String key) {
    return _keyValues[key] as T?;
  }

  @override
  Future<void> saveString(String key, String value) async {
    _keyValues[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _keyValues[key] as String?;
  }

  @override
  Future<void> remove(String key) async {
    _keyValues.remove(key);
  }

  @override
  Future<void> bindOfflineDataToUser(String userId) async {
    for (final record in _records.values.toList()) {
      if (record.ownerId == null) {
        _records[record.id] = record.copyWith(ownerId: () => userId);
      }
    }
    for (final storyLine in _storyLines.values.toList()) {
      if (storyLine.ownerId == null) {
        _storyLines[storyLine.id] = storyLine.copyWith(ownerId: () => userId);
      }
    }
  }

  @override
  Future<void> deleteOfflineData() async {
    _records.removeWhere((_, r) => r.ownerId == null);
    _storyLines.removeWhere((_, s) => s.ownerId == null);
    _checkIns.removeWhere((_, c) => c.userId == null);
  }

  @override
  Future<void> clearAuthData() async {
    _userSettings = null;
  }

  // ==================== 收藏快照（测试模式：内存存储） ====================

  final Map<String, EncounterRecord> _favoritedRecordSnapshots = {};
  final Map<String, Map<String, dynamic>> _favoritedPostSnapshots = {};

  @override
  Future<void> saveFavoritedRecordSnapshot(EncounterRecord record) async {
    _favoritedRecordSnapshots[record.id] = record;
  }

  @override
  EncounterRecord? getFavoritedRecordSnapshot(String recordId) {
    return _favoritedRecordSnapshots[recordId];
  }

  @override
  Future<void> deleteFavoritedRecordSnapshot(String recordId) async {
    _favoritedRecordSnapshots.remove(recordId);
  }

  @override
  Future<void> saveFavoritedPostSnapshot(String postId, Map<String, dynamic> postJson) async {
    _favoritedPostSnapshots[postId] = postJson;
  }

  @override
  Map<String, dynamic>? getFavoritedPostSnapshot(String postId) {
    return _favoritedPostSnapshots[postId];
  }

  @override
  Future<void> deleteFavoritedPostSnapshot(String postId) async {
    _favoritedPostSnapshots.remove(postId);
  }

  void validateDataConsistency() {}
}

void main() {
  group('Multi-Device Sync - Data Isolation', () {
    late RecordRepository recordRepository;
    late StoryLineRepository storyLineRepository;
    late InMemoryStorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
      recordRepository = RecordRepository(storage);
      storyLineRepository = StoryLineRepository(storage);
    });

    group('Device A and Device B Sync Scenario', () {
      test('should isolate data between two devices of the same user', () async {
        const userId = 'user_1';

        final deviceARecord = EncounterRecord(
          id: 'device_a_record_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 39.9, longitude: 116.4),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userId,
          description: 'Created on Device A',
        );

        final deviceBRecord = EncounterRecord(
          id: 'device_b_record_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 39.9, longitude: 116.4),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userId,
          description: 'Created on Device B',
        );

        await recordRepository.saveRecord(deviceARecord);
        await recordRepository.saveRecord(deviceBRecord);

        final userRecords = recordRepository.getRecordsByUser(userId);
        expect(userRecords, hasLength(2));
        expect(
          userRecords.map((r) => r.id),
          containsAll(['device_a_record_1', 'device_b_record_1']),
        );
      });

      test('should not mix data between different users on same device', () async {
        const userA = 'user_a';
        const userB = 'user_b';

        final userARecord = EncounterRecord(
          id: 'user_a_record_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 39.9, longitude: 116.4),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userA,
        );

        final userBRecord = EncounterRecord(
          id: 'user_b_record_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 39.9, longitude: 116.4),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userB,
        );

        await recordRepository.saveRecord(userARecord);
        await recordRepository.saveRecord(userBRecord);

        final recordsA = recordRepository.getRecordsByUser(userA);
        expect(recordsA, hasLength(1));
        expect(recordsA[0].ownerId, equals(userA));

        final recordsB = recordRepository.getRecordsByUser(userB);
        expect(recordsB, hasLength(1));
        expect(recordsB[0].ownerId, equals(userB));
      });

      test('should handle story line isolation across devices', () async {
        const userId = 'user_1';

        final storyLineA = StoryLine(
          id: 'story_a_1',
          name: 'Story from Device A',
          recordIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userId,
        );

        final storyLineB = StoryLine(
          id: 'story_b_1',
          name: 'Story from Device B',
          recordIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userId,
        );

        await storyLineRepository.saveStoryLine(storyLineA);
        await storyLineRepository.saveStoryLine(storyLineB);

        final userStoryLines = storyLineRepository.getStoryLinesByUser(userId);
        expect(userStoryLines, hasLength(2));
        expect(
          userStoryLines.map((s) => s.id),
          containsAll(['story_a_1', 'story_b_1']),
        );
      });
    });

    group('Sync Conflict Resolution', () {
      test('should handle record updates from multiple devices', () async {
        const userId = 'user_1';
        const recordId = 'shared_record_1';

        final initialRecord = EncounterRecord(
          id: recordId,
          timestamp: DateTime.now(),
          location: Location(latitude: 39.9, longitude: 116.4),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userId,
          description: 'Initial',
        );

        await recordRepository.saveRecord(initialRecord);

        final deviceAUpdate = initialRecord.copyWith(
          description: () => 'Updated by Device A',
        );
        await recordRepository.updateRecord(deviceAUpdate);

        var record = recordRepository.getRecord(recordId);
        expect(record?.description, equals('Updated by Device A'));

        final deviceBUpdate = record!.copyWith(
          description: () => 'Updated by Device B',
        );
        await recordRepository.updateRecord(deviceBUpdate);

        record = recordRepository.getRecord(recordId);
        expect(record?.description, equals('Updated by Device B'));
      });

      test('should maintain user isolation during concurrent updates', () async {
        const userA = 'user_a';
        const userB = 'user_b';

        final recordA = EncounterRecord(
          id: 'record_a_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 39.9, longitude: 116.4),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userA,
          description: 'A Original',
        );

        final recordB = EncounterRecord(
          id: 'record_b_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 39.9, longitude: 116.4),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userB,
          description: 'B Original',
        );

        await recordRepository.saveRecord(recordA);
        await recordRepository.saveRecord(recordB);

        await Future.wait([
          recordRepository.updateRecord(
            recordA.copyWith(description: () => 'A Updated'),
          ),
          recordRepository.updateRecord(
            recordB.copyWith(description: () => 'B Updated'),
          ),
        ]);

        final updatedA = recordRepository.getRecord('record_a_1');
        final updatedB = recordRepository.getRecord('record_b_1');

        expect(updatedA?.description, equals('A Updated'));
        expect(updatedB?.description, equals('B Updated'));
        expect(updatedA?.ownerId, equals(userA));
        expect(updatedB?.ownerId, equals(userB));
      });
    });

    group('Offline to Online Sync', () {
      test('should handle offline records binding to user account', () async {
        const userId = 'user_1';

        final offlineRecord = EncounterRecord(
          id: 'offline_record_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 39.9, longitude: 116.4),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: null,
          description: 'Created offline',
        );

        await recordRepository.saveRecord(offlineRecord);

        final userRecords = recordRepository.getRecordsByUser(userId);
        expect(userRecords, isEmpty);

        final offlineRecords = recordRepository.getRecordsByUser(null);
        expect(offlineRecords, hasLength(1));

        final boundRecord = offlineRecord.copyWith(ownerId: () => userId);
        await recordRepository.updateRecord(boundRecord);

        final userRecordsAfterSync = recordRepository.getRecordsByUser(userId);
        expect(userRecordsAfterSync, hasLength(1));
        expect(userRecordsAfterSync[0].ownerId, equals(userId));

        final offlineRecordsAfterSync = recordRepository.getRecordsByUser(null);
        expect(offlineRecordsAfterSync, isEmpty);
      });

      test('should not leak offline records to other users', () async {
        const userA = 'user_a';

        final offlineRecord = EncounterRecord(
          id: 'offline_record_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 39.9, longitude: 116.4),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: null,
        );

        await recordRepository.saveRecord(offlineRecord);

        final userARecords = recordRepository.getRecordsByUser(userA);
        expect(userARecords, isEmpty);

        final offlineRecords = recordRepository.getRecordsByUser(null);
        expect(offlineRecords, hasLength(1));
      });
    });
  });
}
