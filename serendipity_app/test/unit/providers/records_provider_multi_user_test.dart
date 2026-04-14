import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serendipity_app/core/providers/records_provider.dart';
import 'package:serendipity_app/core/repositories/record_repository.dart';
import 'package:serendipity_app/core/services/i_storage_service.dart';
import 'package:serendipity_app/models/encounter_record.dart';
import 'package:serendipity_app/models/enums.dart';
import 'package:serendipity_app/models/check_in_record.dart';
import 'package:serendipity_app/models/user_settings.dart';
import 'package:serendipity_app/models/achievement.dart';
import 'package:serendipity_app/models/story_line.dart';
import 'package:serendipity_app/models/sync_history.dart';
import 'package:serendipity_app/models/membership.dart';

/// 简单的内存存储实现，用于测试
class InMemoryStorageService implements IStorageService {
  final Map<String, EncounterRecord> _records = {};
  final Map<String, StoryLine> _storyLines = {};
  final Map<String, Achievement> _achievements = {};
  final Map<String, CheckInRecord> _checkIns = {};
  final Map<String, dynamic> _keyValues = {};
  final Map<String, Membership> _memberships = {};
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
        .where((s) => s.userId == userId)
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
      if (storyLine.userId == null) {
        _storyLines[storyLine.id] = storyLine.copyWith(userId: () => userId);
      }
    }
  }

  @override
  Future<void> deleteOfflineData() async {
    _records.removeWhere((_, r) => r.ownerId == null);
    _storyLines.removeWhere((_, s) => s.userId == null);
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

  // ==================== 会员相关操作 ====================

  @override
  Future<Membership?> getMembership(String userId) async {
    return _memberships[userId];
  }

  @override
  Future<void> saveMembership(Membership membership) async {
    _memberships[membership.userId] = membership;
  }

  @override
  Future<void> deleteMembership(String userId) async {
    _memberships.remove(userId);
  }

  @override
  Future<void> deleteUserData(String userId) async {
    if (userId.isEmpty) throw ArgumentError('userId cannot be empty');
    _records.removeWhere((_, r) => r.ownerId == userId);
    _storyLines.removeWhere((_, s) => s.userId == userId);
    _checkIns.removeWhere((_, c) => c.userId == userId);
    _achievements.clear();
    _memberships.remove(userId);
    _userSettings = null;
  }

  void validateDataConsistency() {}
}

void main() {
  group('RecordsProvider - Multi-User Data Isolation', () {
    late ProviderContainer container;
    late RecordRepository recordRepository;
    late InMemoryStorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
      recordRepository = RecordRepository(storage);

      container = ProviderContainer(
        overrides: [
          recordRepositoryProvider.overrideWithValue(recordRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('User-Specific Record Queries', () {
      test('should only return records for the current user', () async {
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
        sourceDeviceId: 'device-test',
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
        sourceDeviceId: 'device-test',
          ownerId: userB,
        );

        await recordRepository.saveRecord(recordA);
        await recordRepository.saveRecord(recordB);

        final recordsA = storage.getRecordsByUser(userA);

        expect(recordsA, hasLength(1));
        expect(recordsA[0].ownerId, equals(userA));
        expect(recordsA[0].id, equals('record_a_1'));
      });

      test('should not leak data between users during concurrent access', () async {
        const userA = 'user_a';
        const userB = 'user_b';

        final futures = <Future<void>>[];

        for (int i = 0; i < 10; i++) {
          futures.add(
            recordRepository.saveRecord(
              EncounterRecord(
                id: 'record_a_$i',
                timestamp: DateTime.now(),
                location: Location(latitude: 0, longitude: 0),
                tags: [],
                status: EncounterStatus.missed,
                weather: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
        sourceDeviceId: 'device-test',
                ownerId: userA,
              ),
            ),
          );
        }

        for (int i = 0; i < 5; i++) {
          futures.add(
            recordRepository.saveRecord(
              EncounterRecord(
                id: 'record_b_$i',
                timestamp: DateTime.now(),
                location: Location(latitude: 0, longitude: 0),
                tags: [],
                status: EncounterStatus.missed,
                weather: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
        sourceDeviceId: 'device-test',
                ownerId: userB,
              ),
            ),
          );
        }

        await Future.wait(futures);

        final recordsA = storage.getRecordsByUser(userA);
        expect(recordsA, hasLength(10));
        expect(recordsA.every((r) => r.ownerId == userA), isTrue);

        final recordsB = storage.getRecordsByUser(userB);
        expect(recordsB, hasLength(5));
        expect(recordsB.every((r) => r.ownerId == userB), isTrue);

        final recordsAIds = recordsA.map((r) => r.id).toSet();
        final recordsBIds = recordsB.map((r) => r.id).toSet();
        expect(recordsAIds.intersection(recordsBIds), isEmpty);
      });
    });

    group('Record Update Isolation', () {
      test('should only update records for the current user', () async {
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
        sourceDeviceId: 'device-test',
          ownerId: userA,
          description: 'Original A',
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
        sourceDeviceId: 'device-test',
          ownerId: userB,
          description: 'Original B',
        );

        await recordRepository.saveRecord(recordA);
        await recordRepository.saveRecord(recordB);

        final updatedRecordA = recordA.copyWith(
          description: () => 'Updated A',
        );
        await recordRepository.updateRecord(updatedRecordA);

        final fetchedRecordA = storage.getRecord('record_a_1');
        expect(fetchedRecordA?.description, equals('Updated A'));

        final fetchedRecordB = storage.getRecord('record_b_1');
        expect(fetchedRecordB?.description, equals('Original B'));
      });
    });

    group('Offline Records Handling', () {
      test('should handle offline records (null ownerId) separately', () async {
        const userA = 'user_a';

        final onlineRecord = EncounterRecord(
          id: 'online_record',
          timestamp: DateTime.now(),
          location: Location(latitude: 0, longitude: 0),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        sourceDeviceId: 'device-test',
          ownerId: userA,
        );

        final offlineRecord = EncounterRecord(
          id: 'offline_record',
          timestamp: DateTime.now(),
          location: Location(latitude: 0, longitude: 0),
          tags: [],
          status: EncounterStatus.missed,
          weather: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        sourceDeviceId: 'device-test',
          ownerId: null,
        );

        await recordRepository.saveRecord(onlineRecord);
        await recordRepository.saveRecord(offlineRecord);

        final onlineRecords = storage.getRecordsByUser(userA);
        expect(onlineRecords, hasLength(1));
        expect(onlineRecords[0].ownerId, equals(userA));

        final offlineRecords = storage.getRecordsByUser(null);
        expect(offlineRecords, hasLength(1));
        expect(offlineRecords[0].ownerId, isNull);

        final onlineIds = onlineRecords.map((r) => r.id).toSet();
        final offlineIds = offlineRecords.map((r) => r.id).toSet();
        expect(onlineIds.intersection(offlineIds), isEmpty);
      });
    });

    group('Data Consistency Checks', () {
      test('should maintain consistency when validating data', () async {
        const userA = 'user_a';
        const userB = 'user_b';

        for (int i = 0; i < 3; i++) {
          await recordRepository.saveRecord(
            EncounterRecord(
              id: 'record_a_$i',
              timestamp: DateTime.now(),
              location: Location(latitude: 0, longitude: 0),
              tags: [],
              status: EncounterStatus.missed,
              weather: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
        sourceDeviceId: 'device-test',
              ownerId: userA,
            ),
          );
        }

        for (int i = 0; i < 2; i++) {
          await recordRepository.saveRecord(
            EncounterRecord(
              id: 'record_b_$i',
              timestamp: DateTime.now(),
              location: Location(latitude: 0, longitude: 0),
              tags: [],
              status: EncounterStatus.missed,
              weather: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
        sourceDeviceId: 'device-test',
              ownerId: userB,
            ),
          );
        }

        storage.validateDataConsistency();

        final allRecords = storage.getAllRecords();
        expect(allRecords, hasLength(5));

        final recordsA = storage.getRecordsByUser(userA);
        final recordsB = storage.getRecordsByUser(userB);

        expect(recordsA.length + recordsB.length, equals(5));
      });
    });
  });
}
