import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serendipity_app/core/providers/auth_provider.dart';
import 'package:serendipity_app/core/providers/check_in_provider.dart';
import 'package:serendipity_app/core/providers/membership_provider.dart';
import 'package:serendipity_app/core/providers/message_provider.dart';
import 'package:serendipity_app/core/providers/records_provider.dart';
import 'package:serendipity_app/core/providers/user_settings_provider.dart';
import 'package:serendipity_app/core/repositories/check_in_repository.dart';
import 'package:serendipity_app/core/services/i_storage_service.dart';
import 'package:serendipity_app/core/services/notification_service.dart';
import 'package:serendipity_app/models/achievement.dart';
import 'package:serendipity_app/models/check_in_record.dart';
import 'package:serendipity_app/models/encounter_record.dart';
import 'package:serendipity_app/models/enums.dart';
import 'package:serendipity_app/models/membership.dart';
import 'package:serendipity_app/models/story_line.dart';
import 'package:serendipity_app/models/sync_history.dart';
import 'package:serendipity_app/models/user.dart';
import 'package:serendipity_app/models/user_settings.dart';

class InMemoryStorageService implements IStorageService {
  final Map<String, dynamic> _keyValues = {};
  final Map<String, CheckInRecord> _checkIns = {};
  UserSettings? _userSettings;

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
  UserSettings? getUserSettings() => _userSettings;

  @override
  Future<void> saveUserSettings(UserSettings settings) async {
    _userSettings = settings;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    _keyValues[key] = value;
  }

  @override
  T? get<T>(String key) => _keyValues[key] as T?;

  @override
  Future<void> saveString(String key, String value) async {
    _keyValues[key] = value;
  }

  @override
  Future<String?> getString(String key) async => _keyValues[key] as String?;

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

class RecordingNotificationService extends NotificationService {
  int scheduleCount = 0;
  int cancelCount = 0;
  int anniversaryCancelCount = 0;
  int permissionRequestCount = 0;
  TimeOfDay? lastScheduledTime;

  RecordingNotificationService(
    CheckInRepository repository, {
    IStorageService? storageService,
  }) : super(repository, storageService: storageService);

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequestCount++;
    return true;
  }

  @override
  Future<void> scheduleCheckInReminder(TimeOfDay time, {String? userId}) async {
    scheduleCount++;
    lastScheduledTime = time;
  }

  @override
  Future<void> cancelCheckInReminder() async {
    cancelCount++;
  }

  @override
  Future<void> cancelAnniversaryReminders() async {
    anniversaryCancelCount++;
  }
}

class TestAuthNotifier extends AuthNotifier {
  final User? current;

  TestAuthNotifier(this.current);

  @override
  Stream<User?> build() => Stream<User?>.value(current);
}

void main() {
  group('NotificationService', () {
    test('scheduleCheckInReminder 未初始化时快速失败', () async {
      final storage = InMemoryStorageService();
      final repository = CheckInRepository(storage);
      final service = NotificationService(repository, storageService: storage);

      await expectLater(
        service.scheduleCheckInReminder(const TimeOfDay(hour: 20, minute: 0)),
        throwsA(isA<StateError>()),
      );
    });

    test('未登录用户签到后会取消本地签到提醒', () async {
      final storage = InMemoryStorageService();
      final repository = CheckInRepository(storage);
      final notificationService = RecordingNotificationService(
        repository,
        storageService: storage,
      );
      final now = DateTime(2026, 4, 4, 10);
      final settings = UserSettings(
        id: 'settings-1',
        userId: 'guest',
        theme: ThemeOption.system,
        pageTransition: PageTransitionType.random,
        dialogAnimation: DialogAnimationType.random,
        achievementNotification: true,
        anniversaryReminder: false,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 30),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        hasSeenCommunityIntro: false,
        hasSeenFavoritesIntro: false,
        themeUpdatedAt: now,
        notificationsUpdatedAt: now,
        checkInUpdatedAt: now,
        communityUpdatedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await storage.saveUserSettings(settings);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          notificationServiceProvider.overrideWithValue(notificationService),
          authProvider.overrideWith(() => TestAuthNotifier(null)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(checkInProvider.notifier).checkIn();

      expect(notificationService.scheduleCount, 0);
      expect(notificationService.lastScheduledTime, isNull);
      expect(notificationService.cancelCount, 1);
    });

    test('用户设置初始化时会取消本地签到提醒', () async {
      final storage = InMemoryStorageService();
      final repository = CheckInRepository(storage);
      final notificationService = RecordingNotificationService(
        repository,
        storageService: storage,
      );
      final now = DateTime(2026, 4, 4, 10);
      final settings = UserSettings(
        id: 'settings-2',
        userId: 'guest',
        theme: ThemeOption.system,
        pageTransition: PageTransitionType.random,
        dialogAnimation: DialogAnimationType.random,
        achievementNotification: true,
        anniversaryReminder: false,
        checkInReminderEnabled: false,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        hasSeenCommunityIntro: false,
        hasSeenFavoritesIntro: false,
        themeUpdatedAt: now,
        notificationsUpdatedAt: now,
        checkInUpdatedAt: now,
        communityUpdatedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await storage.saveUserSettings(settings);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          notificationServiceProvider.overrideWithValue(notificationService),
          authProvider.overrideWith(() => TestAuthNotifier(null)),
        ],
      );
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notificationService.permissionRequestCount, 0);
      expect(notificationService.lastScheduledTime, isNull);
      expect(notificationService.cancelCount, greaterThanOrEqualTo(1));
    });
  });
}

