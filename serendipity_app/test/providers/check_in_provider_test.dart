import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:serendipity_app/core/providers/auth_provider.dart';
import 'package:serendipity_app/core/providers/check_in_provider.dart';
import 'package:serendipity_app/core/repositories/achievement_repository.dart';
import 'package:serendipity_app/core/repositories/i_auth_repository.dart';
import 'package:serendipity_app/core/repositories/i_remote_data_repository.dart';
import 'package:serendipity_app/core/services/http_client_service.dart';
import 'package:serendipity_app/core/services/i_storage_service.dart';
import 'package:serendipity_app/core/services/sync_service.dart';
import 'package:serendipity_app/models/achievement.dart';
import 'package:serendipity_app/models/check_in_record.dart';
import 'package:serendipity_app/models/enums.dart';
import 'package:serendipity_app/models/remote_check_in_status.dart';
import 'package:serendipity_app/models/user.dart';

class InMemoryStorageService implements IStorageService {
  final Map<String, dynamic> _keyValues = {};
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
  List<CheckInRecord> getCheckInsSortedByDate() {
    final checkIns = _checkIns.values.toList();
    checkIns.sort((a, b) => b.date.compareTo(a.date));
    return checkIns;
  }

  @override
  List<CheckInRecord> getCheckInsByUser(String? userId) {
    final checkIns = _checkIns.values.where((item) => item.userId == userId).toList();
    checkIns.sort((a, b) => b.date.compareTo(a.date));
    return checkIns;
  }

  @override
  Future<void> deleteCheckIn(String id) async {
    _checkIns.remove(id);
  }

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
  Future<void> saveAchievement(Achievement achievement) async {}

  @override
  Achievement? getAchievement(String id) => null;

  @override
  List<Achievement> getAllAchievements() => [];

  @override
  Future<void> updateAchievement(Achievement achievement) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements IAuthRepository {
  FakeAuthRepository(this._user);

  final User? _user;

  @override
  Future<User?> get currentUser async => _user;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(_user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRemoteDataRepository implements IRemoteDataRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FailingCheckInSyncService extends SyncService {
  FailingCheckInSyncService({required super.storageService})
      : super(
          remoteRepository: FakeRemoteDataRepository(),
          achievementRepository: AchievementRepository(storageService),
        );

  @override
  Future<RemoteCheckInStatus> getCheckInStatus(User user, int year, int month) async {
    throw Exception('remote unavailable');
  }
}

void main() {
  group('CheckInProvider', () {
    late InMemoryStorageService storageService;
    late ProviderContainer container;
    late User user;

    setUp(() async {
      storageService = InMemoryStorageService();
      user = User(
        id: 'user-1',
        email: 'user@example.com',
        authProvider: AuthProvider.email,
        isEmailVerified: true,
        isPhoneVerified: false,
        createdAt: DateTime(2026, 4, 1),
      );

      final cachedStatus = RemoteCheckInStatus(
        hasCheckedInToday: true,
        consecutiveDays: 5,
        totalDays: 12,
        currentMonthDays: 3,
        recentCheckIns: [
          CheckInRecord(
            id: 'remote-check-in-1',
            date: DateTime(2026, 4, 3),
            checkedAt: DateTime(2026, 4, 3, 8),
            userId: user.id,
            createdAt: DateTime(2026, 4, 3, 8),
            updatedAt: DateTime(2026, 4, 3, 8),
          ),
        ],
        checkedInDatesInMonth: [
          DateTime(2026, 4, 1),
          DateTime(2026, 4, 2),
          DateTime(2026, 4, 3),
        ],
      );

      final month = DateTime.now();
      final normalizedMonth = DateTime(month.year, month.month);
      final monthKey = '${normalizedMonth.year.toString().padLeft(4, '0')}-${normalizedMonth.month.toString().padLeft(2, '0')}';
      await storageService.set(
        'remote_check_in_status_${user.id}_$monthKey',
        cachedStatus.toJson(),
      );

      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          httpClientServiceProvider.overrideWithValue(
            HttpClientService(storage: storageService, client: http.Client()),
          ),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository(user)),
          syncServiceProvider.overrideWithValue(
            FailingCheckInSyncService(storageService: storageService),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('远端失败时应回退到按用户和月份缓存的远端签到状态', () async {
      final state = await container.read(checkInProvider.future);

      expect(state.isRemoteAuthoritative, isTrue);
      expect(state.hasCheckedInToday, isTrue);
      expect(state.consecutiveDays, 5);
      expect(state.totalDays, 12);
      expect(state.currentMonthDays, 3);
      expect(state.recentCheckIns.single.id, 'remote-check-in-1');
      expect(
        state.checkedInDatesInCurrentMonth.map((item) => item.toIso8601String()),
        [
          DateTime(2026, 4, 1).toIso8601String(),
          DateTime(2026, 4, 2).toIso8601String(),
          DateTime(2026, 4, 3).toIso8601String(),
        ],
      );
    });
  });
}

