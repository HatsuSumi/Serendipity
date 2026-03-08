import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serendipity_app/core/providers/sync_status_provider.dart';
import 'package:serendipity_app/core/providers/auth_provider.dart';
import 'package:serendipity_app/core/services/sync_service.dart';
import 'package:serendipity_app/core/services/i_storage_service.dart';
import 'package:serendipity_app/models/encounter_record.dart';
import 'package:serendipity_app/models/story_line.dart';
import 'package:serendipity_app/models/achievement.dart';
import 'package:serendipity_app/models/check_in_record.dart';
import 'package:serendipity_app/models/user_settings.dart';
import 'package:serendipity_app/models/enums.dart';

/// Mock 存储服务
class MockStorageService implements IStorageService {
  final Map<String, dynamic> _storage = {};
  final Map<String, EncounterRecord> _records = {};
  final Map<String, StoryLine> _storyLines = {};
  final Map<String, Achievement> _achievements = {};
  final Map<String, CheckInRecord> _checkIns = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> set<T>(String key, T value) async {
    _storage[key] = value;
  }

  @override
  T? get<T>(String key) {
    return _storage[key] as T?;
  }

  @override
  Future<void> saveString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _storage[key] as String?;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

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
    final records = getAllRecords();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
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
    return getAllRecords()
        .where((record) => record.storyLineId == storyLineId)
        .toList();
  }

  @override
  List<EncounterRecord> getRecordsWithoutStoryLine() {
    return getAllRecords()
        .where((record) => record.storyLineId == null)
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
    final storyLines = getAllStoryLines();
    storyLines.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return storyLines;
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
    final checkIns = getAllCheckIns();
    checkIns.sort((a, b) => b.date.compareTo(a.date));
    return checkIns;
  }

  @override
  Future<void> deleteCheckIn(String id) async {
    _checkIns.remove(id);
  }

  @override
  UserSettings? getUserSettings() {
    return null;
  }

  @override
  Future<void> saveUserSettings(UserSettings settings) async {}
}

void main() {
  group('SyncStatusProvider', () {
    late MockStorageService mockStorage;
    late ProviderContainer container;

    setUp(() {
      mockStorage = MockStorageService();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('初始状态', () {
      test('初始状态应该是空闲', () {
        final state = container.read(syncStatusProvider);

        expect(state.status, SyncStatus.idle);
        expect(state.lastManualSyncTime, null);
        expect(state.syncResult, null);
        expect(state.errorMessage, null);
      });

      test('应该从存储加载上次同步时间', () async {
        final lastSyncTime = DateTime(2026, 3, 1, 10, 30);
        await mockStorage.set('last_manual_sync_time', lastSyncTime.toIso8601String());
        await mockStorage.set('last_full_sync_time', lastSyncTime.toIso8601String());

        // 重新创建 container 以触发初始化
        container.dispose();
        container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
        );

        final state = container.read(syncStatusProvider);

        expect(state.lastManualSyncTime, isNotNull);
        expect(state.lastManualSyncTime!.year, 2026);
        expect(state.lastManualSyncTime!.month, 3);
        expect(state.lastManualSyncTime!.day, 1);
        expect(state.lastFullSyncTime, isNotNull);
      });
    });

    group('startSync', () {
      test('应该将状态设置为同步中', () {
        container.read(syncStatusProvider.notifier).startSync();
        final state = container.read(syncStatusProvider);

        expect(state.status, SyncStatus.syncing);
        expect(state.syncResult, null);
        expect(state.errorMessage, null);
      });
    });

    group('syncSuccess', () {
      test('应该将状态设置为成功并保存同步结果', () {
        final result = SyncResult(
          uploadedRecords: 5,
          uploadedStoryLines: 2,
          uploadedCheckIns: 10,
          downloadedRecords: 3,
          downloadedStoryLines: 1,
          downloadedCheckIns: 8,
          mergedRecords: 1,
          mergedStoryLines: 0,
          mergedCheckIns: 2,
        );

        container.read(syncStatusProvider.notifier).syncSuccess(result);
        final state = container.read(syncStatusProvider);

        expect(state.status, SyncStatus.success);
        expect(state.syncResult, result);
        expect(state.errorMessage, null);
        expect(state.lastManualSyncTime, isNotNull);
      });

      test('应该保存上次同步时间到存储', () async {
        final result = SyncResult(
          uploadedRecords: 0,
          uploadedStoryLines: 0,
          uploadedCheckIns: 0,
          downloadedRecords: 0,
          downloadedStoryLines: 0,
          downloadedCheckIns: 0,
          mergedRecords: 0,
          mergedStoryLines: 0,
          mergedCheckIns: 0,
        );

        container.read(syncStatusProvider.notifier).syncSuccess(result);

        final savedManualTime = await mockStorage.get<String>('last_manual_sync_time');
        final savedFullTime = await mockStorage.get<String>('last_full_sync_time');
        expect(savedManualTime, isNotNull);
        expect(savedFullTime, isNotNull);
        
        final parsedTime = DateTime.parse(savedManualTime!);
        final now = DateTime.now();
        expect(parsedTime.difference(now).inSeconds.abs(), lessThan(2));
      });

      test('3秒后应该自动切换回空闲状态', () async {
        final result = SyncResult(
          uploadedRecords: 0,
          uploadedStoryLines: 0,
          uploadedCheckIns: 0,
          downloadedRecords: 0,
          downloadedStoryLines: 0,
          downloadedCheckIns: 0,
          mergedRecords: 0,
          mergedStoryLines: 0,
          mergedCheckIns: 0,
        );

        container.read(syncStatusProvider.notifier).syncSuccess(result);
        
        var state = container.read(syncStatusProvider);
        expect(state.status, SyncStatus.success);

        // 等待 3 秒
        await Future.delayed(const Duration(seconds: 3, milliseconds: 100));

        state = container.read(syncStatusProvider);
        expect(state.status, SyncStatus.idle);
      });
    });

    group('syncError', () {
      test('应该将状态设置为失败并保存错误信息', () {
        container.read(syncStatusProvider.notifier).syncError('网络连接失败');
        final state = container.read(syncStatusProvider);

        expect(state.status, SyncStatus.error);
        expect(state.errorMessage, '网络连接失败');
        expect(state.syncResult, null);
      });

      test('错误信息为空时应该抛出异常', () {
        expect(
          () => container.read(syncStatusProvider.notifier).syncError(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('5秒后应该自动切换回空闲状态', () async {
        container.read(syncStatusProvider.notifier).syncError('测试错误');
        
        var state = container.read(syncStatusProvider);
        expect(state.status, SyncStatus.error);

        // 等待 5 秒
        await Future.delayed(const Duration(seconds: 5, milliseconds: 100));

        state = container.read(syncStatusProvider);
        expect(state.status, SyncStatus.idle);
      });
    });

    group('reset', () {
      test('应该重置状态为空闲', () {
        // 先设置为错误状态
        container.read(syncStatusProvider.notifier).syncError('测试错误');
        
        var state = container.read(syncStatusProvider);
        expect(state.status, SyncStatus.error);
        expect(state.errorMessage, '测试错误');

        // 重置
        container.read(syncStatusProvider.notifier).reset();
        
        state = container.read(syncStatusProvider);
        expect(state.status, SyncStatus.idle);
        expect(state.errorMessage, null);
      });
    });

    group('SyncResult', () {
      test('hasChanges 应该正确判断是否有数据变化', () {
        // 无变化
        var result = const SyncResult(
          uploadedRecords: 0,
          uploadedStoryLines: 0,
          uploadedCheckIns: 0,
          downloadedRecords: 0,
          downloadedStoryLines: 0,
          downloadedCheckIns: 0,
          mergedRecords: 0,
          mergedStoryLines: 0,
          mergedCheckIns: 0,
        );
        expect(result.hasChanges, false);

        // 有上传
        result = const SyncResult(
          uploadedRecords: 1,
          uploadedStoryLines: 0,
          uploadedCheckIns: 0,
          downloadedRecords: 0,
          downloadedStoryLines: 0,
          downloadedCheckIns: 0,
          mergedRecords: 0,
          mergedStoryLines: 0,
          mergedCheckIns: 0,
        );
        expect(result.hasChanges, true);

        // 有下载
        result = const SyncResult(
          uploadedRecords: 0,
          uploadedStoryLines: 0,
          uploadedCheckIns: 0,
          downloadedRecords: 1,
          downloadedStoryLines: 0,
          downloadedCheckIns: 0,
          mergedRecords: 0,
          mergedStoryLines: 0,
          mergedCheckIns: 0,
        );
        expect(result.hasChanges, true);

        // 有合并
        result = const SyncResult(
          uploadedRecords: 0,
          uploadedStoryLines: 0,
          uploadedCheckIns: 0,
          downloadedRecords: 0,
          downloadedStoryLines: 0,
          downloadedCheckIns: 0,
          mergedRecords: 1,
          mergedStoryLines: 0,
          mergedCheckIns: 0,
        );
        expect(result.hasChanges, true);
      });
    });
  });
}

