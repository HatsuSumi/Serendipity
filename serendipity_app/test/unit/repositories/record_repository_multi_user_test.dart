import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/core/repositories/record_repository.dart';
import 'package:serendipity_app/core/services/i_storage_service.dart';
import 'package:serendipity_app/models/encounter_record.dart';
import 'package:serendipity_app/models/enums.dart';
import 'package:serendipity_app/models/check_in_record.dart';
import 'package:serendipity_app/models/user_settings.dart';
import 'package:serendipity_app/models/achievement.dart';
import 'package:serendipity_app/models/story_line.dart';
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

  @override
  void validateDataConsistency() {}
}

void main() {
  group('RecordRepository - Multi-User Data Isolation', () {
    late RecordRepository repository;
    late InMemoryStorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
      repository = RecordRepository(storage);
    });

    group('User Data Isolation', () {
      test('should only return records for the specified user', () async {
        const userA = 'user_a';
        const userB = 'user_b';

        final recordA1 = EncounterRecord(
          id: 'record_a_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 0, longitude: 0),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userA,
        );

        final recordA2 = EncounterRecord(
          id: 'record_a_2',
          timestamp: DateTime.now(),
          location: Location(latitude: 0, longitude: 0),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userA,
        );

        final recordB1 = EncounterRecord(
          id: 'record_b_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 0, longitude: 0),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userB,
        );

        await repository.saveRecord(recordA1);
        await repository.saveRecord(recordA2);
        await repository.saveRecord(recordB1);

        final recordsA = repository.getRecordsByUser(userA);

        expect(recordsA, hasLength(2));
        expect(recordsA.every((r) => r.ownerId == userA), isTrue);
        expect(recordsA.map((r) => r.id), containsAll(['record_a_1', 'record_a_2']));
        expect(recordsA.map((r) => r.id), isNot(contains('record_b_1')));
      });

      test('should not leak user A data to user B', () async {
        const userA = 'user_a';
        const userB = 'user_b';

        for (int i = 0; i < 5; i++) {
          final record = EncounterRecord(
            id: 'record_a_$i',
            timestamp: DateTime.now(),
            location: Location(latitude: 0, longitude: 0),
            tags: [],
            status: EncounterStatus.missed,
            weather: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            ownerId: userA,
          );
          await repository.saveRecord(record);
        }

        final recordB = EncounterRecord(
          id: 'record_b_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 0, longitude: 0),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userB,
        );
        await repository.saveRecord(recordB);

        final recordsB = repository.getRecordsByUser(userB);

        expect(recordsB, hasLength(1));
        expect(recordsB[0].ownerId, equals(userB));
        expect(recordsB[0].id, equals('record_b_1'));

        for (int i = 0; i < 5; i++) {
          expect(recordsB.map((r) => r.id), isNot(contains('record_a_$i')));
        }
      });

      test('should return empty list for user with no records', () async {
        const userWithNoRecords = 'user_no_records';

        final records = repository.getRecordsByUser(userWithNoRecords);

        expect(records, isEmpty);
      });

      test('should handle null userId correctly', () async {
        final offlineRecord = EncounterRecord(
          id: 'offline_record',
          timestamp: DateTime.now(),
          location: Location(latitude: 0, longitude: 0),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: null,
        );

        await repository.saveRecord(offlineRecord);

        final records = repository.getRecordsByUser(null);

        expect(records, isNotEmpty);
        expect(records[0].ownerId, isNull);
      });
    });

    group('Record Deletion', () {
      test('should only delete records for the current user', () async {
        const userA = 'user_a';
        const userB = 'user_b';

        final recordA = EncounterRecord(
          id: 'record_a_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 0, longitude: 0),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userA,
        );

        final recordB = EncounterRecord(
          id: 'record_b_1',
          timestamp: DateTime.now(),
          location: Location(latitude: 0, longitude: 0),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: userB,
        );

        await repository.saveRecord(recordA);
        await repository.saveRecord(recordB);

        await repository.deleteRecord('record_a_1');

        expect(repository.getRecord('record_a_1'), isNull);
        expect(repository.getRecord('record_b_1'), isNotNull);
      });
    });

    group('Data Consistency', () {
      test('should maintain data consistency across multiple users', () async {
        const userA = 'user_a';
        const userB = 'user_b';

        final records = <EncounterRecord>[];
        for (int i = 0; i < 3; i++) {
          records.add(EncounterRecord(
            id: 'record_a_$i',
            timestamp: DateTime.now(),
            location: Location(latitude: 0, longitude: 0),
            tags: [],
            status: EncounterStatus.missed,
            weather: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            ownerId: userA,
          ));
        }

        for (int i = 0; i < 2; i++) {
          records.add(EncounterRecord(
            id: 'record_b_$i',
            timestamp: DateTime.now(),
            location: Location(latitude: 0, longitude: 0),
            tags: [],
            status: EncounterStatus.missed,
            weather: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            ownerId: userB,
          ));
        }

        for (final record in records) {
          await repository.saveRecord(record);
        }

        final allRecords = repository.getAllRecords();
        expect(allRecords, hasLength(5));

        final recordsA = repository.getRecordsByUser(userA);
        expect(recordsA, hasLength(3));
        expect(recordsA.every((r) => r.ownerId == userA), isTrue);

        final recordsB = repository.getRecordsByUser(userB);
        expect(recordsB, hasLength(2));
        expect(recordsB.every((r) => r.ownerId == userB), isTrue);

        final recordsAIds = recordsA.map((r) => r.id).toList();
        final recordsBIds = recordsB.map((r) => r.id).toList();
        for (final id in recordsBIds) {
          expect(recordsAIds, isNot(contains(id)));
        }
      });
    });
  });
}
