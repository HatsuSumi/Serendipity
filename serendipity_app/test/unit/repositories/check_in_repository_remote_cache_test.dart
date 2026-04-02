import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/core/repositories/check_in_repository.dart';
import 'package:serendipity_app/core/services/i_storage_service.dart';
import 'package:serendipity_app/models/achievement.dart';
import 'package:serendipity_app/models/check_in_record.dart';
import 'package:serendipity_app/models/membership.dart';
import 'package:serendipity_app/models/remote_check_in_status.dart';
import 'package:serendipity_app/models/story_line.dart';
import 'package:serendipity_app/models/sync_history.dart';
import 'package:serendipity_app/models/user_settings.dart';
import 'package:serendipity_app/models/encounter_record.dart';

class InMemoryStorageService implements IStorageService {
  final Map<String, dynamic> _values = {};
  final Map<String, CheckInRecord> _checkIns = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> saveCheckIn(CheckInRecord checkIn) async {
    _checkIns[checkIn.id] = checkIn;
  }

  @override
  CheckInRecord? getCheckIn(String id) => _checkIns[id];

  @override
  List<CheckInRecord> getAllCheckIns() => _checkIns.values.toList();

  @override
  List<CheckInRecord> getCheckInsSortedByDate() => _checkIns.values.toList();

  @override
  List<CheckInRecord> getCheckInsByUser(String? userId) =>
      _checkIns.values.where((item) => item.userId == userId).toList();

  @override
  Future<void> deleteCheckIn(String id) async {
    _checkIns.remove(id);
  }

  @override
  Future<void> set<T>(String key, T value) async {
    _values[key] = value;
  }

  @override
  T? get<T>(String key) {
    return _values[key] as T?;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CheckInRepository remote status cache', () {
    late InMemoryStorageService storageService;
    late CheckInRepository repository;

    setUp(() {
      storageService = InMemoryStorageService();
      repository = CheckInRepository(storageService);
    });

    test('保存后可以按用户与月份读取远端签到状态缓存', () async {
      const userId = 'user-1';
      final month = DateTime(2026, 4);
      final status = RemoteCheckInStatus(
        hasCheckedInToday: true,
        consecutiveDays: 7,
        totalDays: 20,
        currentMonthDays: 2,
        recentCheckIns: [
          CheckInRecord(
            id: 'check-in-1',
            date: DateTime(2026, 4, 2),
            checkedAt: DateTime(2026, 4, 2, 8),
            userId: userId,
            createdAt: DateTime(2026, 4, 2, 8),
            updatedAt: DateTime(2026, 4, 2, 8),
          ),
        ],
        checkedInDatesInMonth: [
          DateTime(2026, 4, 1),
          DateTime(2026, 4, 2),
        ],
      );

      await repository.saveRemoteStatusCache(
        userId: userId,
        month: month,
        status: status,
      );

      final cached = repository.getRemoteStatusCache(userId: userId, month: month);

      expect(cached, isNotNull);
      expect(cached!.hasCheckedInToday, isTrue);
      expect(cached.consecutiveDays, 7);
      expect(cached.recentCheckIns.single.id, 'check-in-1');
      expect(cached.checkedInDatesInMonth.length, 2);
    });

    test('不同月份缓存键隔离', () async {
      const userId = 'user-1';
      await repository.saveRemoteStatusCache(
        userId: userId,
        month: DateTime(2026, 4),
        status: const RemoteCheckInStatus(
          hasCheckedInToday: false,
          consecutiveDays: 1,
          totalDays: 1,
          currentMonthDays: 1,
          recentCheckIns: [],
          checkedInDatesInMonth: [],
        ),
      );

      final mayCache = repository.getRemoteStatusCache(
        userId: userId,
        month: DateTime(2026, 5),
      );

      expect(mayCache, isNull);
    });
  });
}

