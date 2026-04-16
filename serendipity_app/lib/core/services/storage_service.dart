import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/achievement.dart';
import '../../models/check_in_record.dart';
import '../../models/encounter_record.dart';
import '../../models/membership.dart';
import '../../models/story_line.dart';
import '../../models/sync_history.dart';
import '../../models/user_settings.dart';
import 'i_storage_service.dart';

part 'storage/storage_service_achievements.dart';
part 'storage/storage_service_auxiliary_data.dart';
part 'storage/storage_service_check_ins.dart';
part 'storage/storage_service_records.dart';
part 'storage/storage_service_settings.dart';
part 'storage/storage_service_story_lines.dart';
part 'storage/storage_service_sync_history.dart';
part 'storage/storage_service_user_data.dart';

abstract class _StorageServiceCore implements IStorageService {
  Box<EncounterRecord> get recordsBoxOrThrow;
  Box get settingsBoxOrThrow;
  Box<StoryLine> get storyLinesBoxOrThrow;
  Box<Achievement> get achievementsBoxOrThrow;
  Box<CheckInRecord> get checkInsBoxOrThrow;
  Box<SyncHistory> get syncHistoriesBoxOrThrow;
  Box<EncounterRecord> get favoritedRecordSnapshotsBoxOrThrow;
  Box<String> get favoritedPostSnapshotsBoxOrThrow;
  Box<String> get membershipsBoxOrThrow;
}

/// 本地存储服务（Hive 实现）
/// 使用 Hive 进行数据持久化
class StorageService extends _StorageServiceCore
    with
        _StorageServiceRecords,
        _StorageServiceStoryLines,
        _StorageServiceAchievements,
        _StorageServiceCheckIns,
        _StorageServiceSettings,
        _StorageServiceSyncHistory,
        _StorageServiceAuxiliaryData,
        _StorageServiceUserData {
  static const String _recordsBoxName = 'records';
  static const String _settingsBoxName = 'settings';
  static const String _storyLinesBoxName = 'story_lines';
  static const String _achievementsBoxName = 'achievements';
  static const String _checkInsBoxName = 'check_ins';
  static const String _syncHistoriesBoxName = 'sync_histories';
  static const String _favoritedRecordSnapshotsBoxName =
      'favorited_record_snapshots';
  static const String _favoritedPostSnapshotsBoxName =
      'favorited_post_snapshots';
  static const String _membershipsBoxName = 'memberships';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Box<EncounterRecord>? _recordsBox;
  Box? _settingsBox;
  Box<StoryLine>? _storyLinesBox;
  Box<Achievement>? _achievementsBox;
  Box<CheckInRecord>? _checkInsBox;
  Box<SyncHistory>? _syncHistoriesBox;
  Box<EncounterRecord>? _favoritedRecordSnapshotsBox;
  Box<String>? _favoritedPostSnapshotsBox;
  Box<String>? _membershipsBox;

  @override
  Box<EncounterRecord> get recordsBoxOrThrow {
    if (_recordsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _recordsBox!;
  }

  @override
  Box get settingsBoxOrThrow {
    if (_settingsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _settingsBox!;
  }

  @override
  Box<StoryLine> get storyLinesBoxOrThrow {
    if (_storyLinesBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _storyLinesBox!;
  }

  @override
  Box<Achievement> get achievementsBoxOrThrow {
    if (_achievementsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _achievementsBox!;
  }

  @override
  Box<CheckInRecord> get checkInsBoxOrThrow {
    if (_checkInsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _checkInsBox!;
  }

  @override
  Box<SyncHistory> get syncHistoriesBoxOrThrow {
    if (_syncHistoriesBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _syncHistoriesBox!;
  }

  @override
  Box<EncounterRecord> get favoritedRecordSnapshotsBoxOrThrow {
    if (_favoritedRecordSnapshotsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _favoritedRecordSnapshotsBox!;
  }

  @override
  Box<String> get favoritedPostSnapshotsBoxOrThrow {
    if (_favoritedPostSnapshotsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _favoritedPostSnapshotsBox!;
  }

  @override
  Box<String> get membershipsBoxOrThrow {
    if (_membershipsBox == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _membershipsBox!;
  }

  @override
  Future<void> init() async {
    _recordsBox = await Hive.openBox<EncounterRecord>(_recordsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _storyLinesBox = await Hive.openBox<StoryLine>(_storyLinesBoxName);
    _achievementsBox = await Hive.openBox<Achievement>(_achievementsBoxName);
    _checkInsBox = await Hive.openBox<CheckInRecord>(_checkInsBoxName);
    _syncHistoriesBox = await Hive.openBox<SyncHistory>(_syncHistoriesBoxName);
    _favoritedRecordSnapshotsBox =
        await Hive.openBox<EncounterRecord>(_favoritedRecordSnapshotsBoxName);
    _favoritedPostSnapshotsBox =
        await Hive.openBox<String>(_favoritedPostSnapshotsBoxName);
    _membershipsBox = await Hive.openBox<String>(_membershipsBoxName);
  }

  @override
  Future<void> close() async {
    await _recordsBox?.close();
    await _settingsBox?.close();
    await _storyLinesBox?.close();
    await _achievementsBox?.close();
    await _checkInsBox?.close();
    await _syncHistoriesBox?.close();
    await _favoritedRecordSnapshotsBox?.close();
    await _favoritedPostSnapshotsBox?.close();
    await _membershipsBox?.close();
  }
}
