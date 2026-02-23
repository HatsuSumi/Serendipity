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
        theme: AppTheme.dark,
        accentColor: '#FF5722',
        cloudSyncEnabled: true,
        biometricLockEnabled: true,
        passwordLockEnabled: false,
        passwordHash: 'hashed_password_123',
        hiddenRecordIds: ['record001', 'record002'],
        achievementNotification: true,
        anniversaryReminder: true,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.id, 'settings001');
      expect(settings.userId, 'user123');
      expect(settings.theme, AppTheme.dark);
      expect(settings.accentColor, '#FF5722');
      expect(settings.cloudSyncEnabled, true);
      expect(settings.biometricLockEnabled, true);
      expect(settings.hiddenRecordIds.length, 2);
      expect(settings.matchingEnabled, true);
    });

    test('创建 UserSettings 对象（默认设置）', () {
      final now = DateTime.now();

      final settings = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: AppTheme.system,
        cloudSyncEnabled: false,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.theme, AppTheme.system);
      expect(settings.accentColor, isNull);
      expect(settings.passwordHash, isNull);
      expect(settings.cloudSyncEnabled, false);
      expect(settings.hiddenRecordIds.length, 0);
    });

    test('toJson 转换（完整信息）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final settings = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: AppTheme.dark,
        accentColor: '#FF5722',
        cloudSyncEnabled: true,
        biometricLockEnabled: true,
        passwordLockEnabled: false,
        passwordHash: 'hashed_password_123',
        hiddenRecordIds: ['record001', 'record002'],
        achievementNotification: true,
        anniversaryReminder: true,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = settings.toJson();

      expect(json['id'], 'settings001');
      expect(json['userId'], 'user123');
      expect(json['theme'], 'dark');
      expect(json['accentColor'], '#FF5722');
      expect(json['cloudSyncEnabled'], true);
      expect(json['hiddenRecordIds'], isList);
      expect(json['hiddenRecordIds'].length, 2);
      expect(json['matchingEnabled'], true);
    });

    test('toJson 转换（默认设置）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final settings = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: AppTheme.system,
        cloudSyncEnabled: false,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = settings.toJson();

      expect(json['theme'], 'system');
      expect(json['accentColor'], isNull);
      expect(json['passwordHash'], isNull);
      expect(json['hiddenRecordIds'], isEmpty);
    });

    test('fromJson 转换（完整信息）', () {
      final json = {
        'id': 'settings001',
        'userId': 'user123',
        'theme': 'dark',
        'accentColor': '#FF5722',
        'cloudSyncEnabled': true,
        'biometricLockEnabled': true,
        'passwordLockEnabled': false,
        'passwordHash': 'hashed_password_123',
        'hiddenRecordIds': ['record001', 'record002'],
        'achievementNotification': true,
        'anniversaryReminder': true,
        'matchNotification': true,
        'messageNotification': true,
        'matchingEnabled': true,
        'gpsVerificationEnabled': true,
        'autoPublishToCommunity': false,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.id, 'settings001');
      expect(settings.userId, 'user123');
      expect(settings.theme, AppTheme.dark);
      expect(settings.accentColor, '#FF5722');
      expect(settings.cloudSyncEnabled, true);
      expect(settings.hiddenRecordIds.length, 2);
      expect(settings.matchingEnabled, true);
    });

    test('fromJson 转换（默认设置）', () {
      final json = {
        'id': 'settings001',
        'userId': 'user123',
        'theme': 'system',
        'accentColor': null,
        'cloudSyncEnabled': false,
        'biometricLockEnabled': false,
        'passwordLockEnabled': false,
        'passwordHash': null,
        'hiddenRecordIds': [],
        'achievementNotification': true,
        'anniversaryReminder': false,
        'matchNotification': true,
        'messageNotification': true,
        'matchingEnabled': true,
        'gpsVerificationEnabled': true,
        'autoPublishToCommunity': false,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.theme, AppTheme.system);
      expect(settings.accentColor, isNull);
      expect(settings.passwordHash, isNull);
      expect(settings.hiddenRecordIds.length, 0);
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();

      final original = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: AppTheme.dark,
        accentColor: '#FF5722',
        cloudSyncEnabled: true,
        biometricLockEnabled: true,
        passwordLockEnabled: false,
        hiddenRecordIds: ['record001'],
        achievementNotification: true,
        anniversaryReminder: true,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = UserSettings.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.theme, original.theme);
      expect(restored.accentColor, original.accentColor);
      expect(restored.cloudSyncEnabled, original.cloudSyncEnabled);
      expect(restored.matchingEnabled, original.matchingEnabled);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();

      final original = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: AppTheme.system,
        cloudSyncEnabled: false,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        theme: AppTheme.dark,
        cloudSyncEnabled: true,
        biometricLockEnabled: true,
        matchingEnabled: false,
      );

      expect(updated.id, original.id);
      expect(updated.theme, AppTheme.dark);
      expect(updated.cloudSyncEnabled, true);
      expect(updated.biometricLockEnabled, true);
      expect(updated.matchingEnabled, false);
    });

    test('相等性比较', () {
      final now = DateTime.now();

      final settings1 = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: AppTheme.dark,
        cloudSyncEnabled: true,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
        createdAt: now,
        updatedAt: now,
      );

      final settings2 = UserSettings(
        id: 'settings001',
        userId: 'user123',
        theme: AppTheme.dark,
        cloudSyncEnabled: true,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
        createdAt: now,
        updatedAt: now,
      );

      final settings3 = UserSettings(
        id: 'settings002',
        userId: 'user123',
        theme: AppTheme.dark,
        cloudSyncEnabled: true,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
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
        theme: AppTheme.dark,
        cloudSyncEnabled: true,
        biometricLockEnabled: false,
        passwordLockEnabled: false,
        hiddenRecordIds: [],
        achievementNotification: true,
        anniversaryReminder: false,
        matchNotification: true,
        messageNotification: true,
        matchingEnabled: true,
        gpsVerificationEnabled: true,
        autoPublishToCommunity: false,
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
        AppTheme.light,
        AppTheme.dark,
        AppTheme.system,
        AppTheme.misty,
        AppTheme.midnight,
        AppTheme.warm,
        AppTheme.autumn,
      ];

      for (final theme in themes) {
        final settings = UserSettings(
          id: 'settings001',
          userId: 'user123',
          theme: theme,
          cloudSyncEnabled: false,
          biometricLockEnabled: false,
          passwordLockEnabled: false,
          hiddenRecordIds: [],
          achievementNotification: true,
          anniversaryReminder: false,
          matchNotification: true,
          messageNotification: true,
          matchingEnabled: true,
          gpsVerificationEnabled: true,
          autoPublishToCommunity: false,
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
      expect(AppTheme.light.isPremium, false);
      expect(AppTheme.dark.isPremium, false);
      expect(AppTheme.system.isPremium, false);
      expect(AppTheme.misty.isPremium, true);
      expect(AppTheme.midnight.isPremium, true);
      expect(AppTheme.warm.isPremium, true);
      expect(AppTheme.autumn.isPremium, true);
    });
  });
}

