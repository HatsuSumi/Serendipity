import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/user_settings.dart';
import 'package:serendipity_app/models/enums.dart';

void main() {
  group('UserSettings', () {
    test('创建 UserSettings 对象（完整信息）', () {
      final now = DateTime.now();

      final settings = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: ThemeOption.dark,
        accentColor: '#FF5722',
        pageTransition: PageTransitionType.slideFromRight,
        dialogAnimation: DialogAnimationType.fadeScale,
        cloudSyncEnabled: true,
        biometricLockEnabled: true,
        passwordLockEnabled: false,
        passwordHash: 'hashed_password_123',
        hiddenRecordIds: ['record001', 'record002'],
        achievementNotification: true,
        anniversaryReminder: true,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.id, 'settings001');
      expect(settings.userId, 'user123');
      expect(settings.theme, ThemeOption.dark);
      expect(settings.accentColor, '#FF5722');
      expect(settings.pageTransition, PageTransitionType.slideFromRight);
      expect(settings.dialogAnimation, DialogAnimationType.fadeScale);
      expect(settings.cloudSyncEnabled, true);
      expect(settings.biometricLockEnabled, true);
      expect(settings.hiddenRecordIds.length, 2);
      expect(settings.checkInReminderEnabled, true);
      expect(settings.checkInVibrationEnabled, true);
      expect(settings.checkInConfettiEnabled, true);
    });

    test('创建 UserSettings 对象（默认设置）', () {
      final now = DateTime.now();

      final settings = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: ThemeOption.system,
        pageTransition: PageTransitionType.random,
        dialogAnimation: DialogAnimationType.random,
        cloudSyncEnabled: false,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.theme, ThemeOption.system);
      expect(settings.accentColor, isNull);
      expect(settings.passwordHash, isNull);
      expect(settings.cloudSyncEnabled, false);
      expect(settings.hiddenRecordIds.length, 0);
      expect(settings.pageTransition, PageTransitionType.random);
      expect(settings.dialogAnimation, DialogAnimationType.random);
    });

    test('toJson 转换（完整信息）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final settings = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: ThemeOption.dark,
        accentColor: '#FF5722',
        pageTransition: PageTransitionType.slideFromRight,
        dialogAnimation: DialogAnimationType.fadeScale,
        cloudSyncEnabled: true,
        biometricLockEnabled: true,
        passwordLockEnabled: false,
        passwordHash: 'hashed_password_123',
        hiddenRecordIds: ['record001', 'record002'],
        achievementNotification: true,
        anniversaryReminder: true,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = settings.toJson();

      expect(json['id'], 'settings001');
      expect(json['userId'], 'user123');
      expect(json['theme'], 'dark');
      expect(json['accentColor'], '#FF5722');
      expect(json['pageTransition'], 'slide_from_right');
      expect(json['dialogAnimation'], 'fade_scale');
      expect(json['cloudSyncEnabled'], true);
      expect(json['hiddenRecordIds'], isList);
      expect(json['hiddenRecordIds'].length, 2);
      expect(json['checkInReminderEnabled'], true);
      expect(json['checkInReminderTime'], isMap);
      expect(json['checkInReminderTime']['hour'], 20);
      expect(json['checkInReminderTime']['minute'], 0);
      expect(json['checkInVibrationEnabled'], true);
      expect(json['checkInConfettiEnabled'], true);
    });

    test('toJson 转换（默认设置）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final settings = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: ThemeOption.system,
        pageTransition: PageTransitionType.random,
        dialogAnimation: DialogAnimationType.random,
        cloudSyncEnabled: false,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = settings.toJson();

      expect(json['theme'], 'system');
      expect(json['accentColor'], isNull);
      expect(json['passwordHash'], isNull);
      expect(json['hiddenRecordIds'], isEmpty);
      expect(json['pageTransition'], 'random');
      expect(json['dialogAnimation'], 'random');
    });

    test('fromJson 转换（完整信息）', () {
      final json = {
        'id': 'settings001',
        'userId': 'user123',
        'theme': 'dark',
        'accentColor': '#FF5722',
        'pageTransition': 'slide_from_right',
        'dialogAnimation': 'fade_scale',
        'cloudSyncEnabled': true,
        'biometricLockEnabled': true,
        'passwordLockEnabled': false,
        'passwordHash': 'hashed_password_123',
        'hiddenRecordIds': ['record001', 'record002'],
        'achievementNotification': true,
        'anniversaryReminder': true,
        'checkInReminderEnabled': true,
        'checkInReminderTime': {
          'hour': 20,
          'minute': 0,
        },
        'checkInVibrationEnabled': true,
        'checkInConfettiEnabled': true,
        'autoPublishToCommunity': false,
        'hidePublishWarning': false,
        'hasSeenPublishWarning': false,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.id, 'settings001');
      expect(settings.userId, 'user123');
      expect(settings.theme, ThemeOption.dark);
      expect(settings.accentColor, '#FF5722');
      expect(settings.pageTransition, PageTransitionType.slideFromRight);
      expect(settings.dialogAnimation, DialogAnimationType.fadeScale);
      expect(settings.cloudSyncEnabled, true);
      expect(settings.hiddenRecordIds.length, 2);
      expect(settings.checkInReminderEnabled, true);
      expect(settings.checkInReminderTime.hour, 20);
      expect(settings.checkInReminderTime.minute, 0);
      expect(settings.checkInVibrationEnabled, true);
      expect(settings.checkInConfettiEnabled, true);
    });

    test('fromJson 转换（默认设置）', () {
      final json = {
        'id': 'settings001',
        'userId': 'user123',
        'theme': 'system',
        'accentColor': null,
        'pageTransition': 'random',
        'dialogAnimation': 'random',
        'cloudSyncEnabled': false,
        'biometricLockEnabled': false,
        'passwordLockEnabled': false,
        'passwordHash': null,
        'hiddenRecordIds': [],
        'achievementNotification': true,
        'anniversaryReminder': false,
        'checkInReminderEnabled': true,
        'checkInReminderTime': {
          'hour': 20,
          'minute': 0,
        },
        'checkInVibrationEnabled': true,
        'checkInConfettiEnabled': true,
        'autoPublishToCommunity': false,
        'hidePublishWarning': false,
        'hasSeenPublishWarning': false,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.theme, ThemeOption.system);
      expect(settings.accentColor, isNull);
      expect(settings.passwordHash, isNull);
      expect(settings.hiddenRecordIds.length, 0);
      expect(settings.pageTransition, PageTransitionType.random);
      expect(settings.dialogAnimation, DialogAnimationType.random);
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();

      final original = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: ThemeOption.dark,
        accentColor: '#FF5722',
        pageTransition: PageTransitionType.slideFromRight,
        dialogAnimation: DialogAnimationType.fadeScale,
        cloudSyncEnabled: true,
        biometricLockEnabled: true,
        passwordLockEnabled: false,
        hiddenRecordIds: ['record001'],
        achievementNotification: true,
        anniversaryReminder: true,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = UserSettings.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.theme, original.theme);
      expect(restored.accentColor, original.accentColor);
      expect(restored.pageTransition, original.pageTransition);
      expect(restored.dialogAnimation, original.dialogAnimation);
      expect(restored.cloudSyncEnabled, original.cloudSyncEnabled);
      expect(restored.checkInReminderEnabled, original.checkInReminderEnabled);
      expect(restored.checkInVibrationEnabled, original.checkInVibrationEnabled);
      expect(restored.checkInConfettiEnabled, original.checkInConfettiEnabled);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();

      final original = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: ThemeOption.system,
        pageTransition: PageTransitionType.random,
        dialogAnimation: DialogAnimationType.random,
        cloudSyncEnabled: false,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        theme: ThemeOption.dark,
        cloudSyncEnabled: true,
        biometricLockEnabled: true,
        pageTransition: PageTransitionType.slideFromRight,
        dialogAnimation: DialogAnimationType.fadeScale,
        checkInReminderEnabled: false,
        checkInVibrationEnabled: false,
      );

      expect(updated.id, original.id);
      expect(updated.theme, ThemeOption.dark);
      expect(updated.cloudSyncEnabled, true);
      expect(updated.biometricLockEnabled, true);
      expect(updated.pageTransition, PageTransitionType.slideFromRight);
      expect(updated.dialogAnimation, DialogAnimationType.fadeScale);
      expect(updated.checkInReminderEnabled, false);
      expect(updated.checkInVibrationEnabled, false);
    });

    test('相等性比较', () {
      final now = DateTime.now();

      final settings1 = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: ThemeOption.dark,
        pageTransition: PageTransitionType.random,
        dialogAnimation: DialogAnimationType.random,
        cloudSyncEnabled: true,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      final settings2 = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: ThemeOption.dark,
        pageTransition: PageTransitionType.random,
        dialogAnimation: DialogAnimationType.random,
        cloudSyncEnabled: true,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      final settings3 = UserSettings(
        id: 'settings002',
        userId: 'user123',
        theme: ThemeOption.dark,
        pageTransition: PageTransitionType.random,
        dialogAnimation: DialogAnimationType.random,
        cloudSyncEnabled: true,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(settings1 == settings2, true);
      expect(settings1 == settings3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();

      final settings = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: ThemeOption.dark,
        pageTransition: PageTransitionType.random,
        dialogAnimation: DialogAnimationType.random,
        cloudSyncEnabled: true,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        checkInReminderEnabled: true,
        checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
        checkInVibrationEnabled: true,
        checkInConfettiEnabled: true,
        autoPublishToCommunity: false,
        hidePublishWarning: false,
        hasSeenPublishWarning: false,
        createdAt: now,
        updatedAt: now,
      );

      final str = settings.toString();

      expect(str.contains('settings001'), true);
      expect(str.contains('深色'), true);
      expect(str.contains('true'), true);
    });

    test('测试不同的主题', () {
      final now = DateTime.now();

      final themes = [
        ThemeOption.light,
        ThemeOption.dark,
        ThemeOption.system,
        ThemeOption.misty,
        ThemeOption.midnight,
        ThemeOption.warm,
        ThemeOption.autumn,
      ];

      for (final theme in themes) {
        final settings = UserSettings(
          id: 'settings001',
          userId: 'user123',
          theme: theme,
          pageTransition: PageTransitionType.random,
          dialogAnimation: DialogAnimationType.random,
          cloudSyncEnabled: false,
          biometricLockEnabled: false,
          passwordLockEnabled: false,
          hiddenRecordIds: [],
          achievementNotification: true,
          anniversaryReminder: false,
          checkInReminderEnabled: true,
          checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
          checkInVibrationEnabled: true,
          checkInConfettiEnabled: true,
          autoPublishToCommunity: false,
          hidePublishWarning: false,
          hasSeenPublishWarning: false,
          createdAt: now,
          updatedAt: now,
        );

        expect(settings.theme, theme);

        final json = settings.toJson();
        final restored = UserSettings.fromJson(json);
        expect(restored.theme, theme);
      }
    });

    test('测试会员专属主题标记', () {
      expect(ThemeOption.light.isPremium, false);
      expect(ThemeOption.dark.isPremium, false);
      expect(ThemeOption.system.isPremium, false);
      expect(ThemeOption.misty.isPremium, true);
      expect(ThemeOption.midnight.isPremium, true);
      expect(ThemeOption.warm.isPremium, true);
      expect(ThemeOption.autumn.isPremium, true);
    });
  });
}

