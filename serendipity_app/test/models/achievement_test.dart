import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/achievement.dart';

void main() {
  group('Achievement', () {
    test('创建 Achievement 对象（已解锁）', () {
      final now = DateTime.now();
      final achievement = Achievement(
        id: 'first_missed',
        name: '第一次错过',
        description: '你记录了第一次错过',
        icon: '🌫️',
        unlocked: true,
        unlockedAt: now,
      );

      expect(achievement.id, 'first_missed');
      expect(achievement.name, '第一次错过');
      expect(achievement.description, '你记录了第一次错过');
      expect(achievement.icon, '🌫️');
      expect(achievement.unlocked, true);
      expect(achievement.unlockedAt, now);
    });

    test('创建 Achievement 对象（未解锁）', () {
      final achievement = Achievement(
        id: 'first_met',
        name: '第一次邂逅',
        description: '你第一次标记"邂逅"状态',
        icon: '💫',
        unlocked: false,
        unlockedAt: null,
      );

      expect(achievement.id, 'first_met');
      expect(achievement.name, '第一次邂逅');
      expect(achievement.unlocked, false);
      expect(achievement.unlockedAt, isNull);
    });

    test('toJson 转换（已解锁）', () {
      final now = DateTime(2026, 2, 11, 20, 0, 0);
      final achievement = Achievement(
        id: 'first_missed',
        name: '第一次错过',
        description: '你记录了第一次错过',
        icon: '🌫️',
        unlocked: true,
        unlockedAt: now,
      );

      final json = achievement.toJson();

      expect(json['id'], 'first_missed');
      expect(json['name'], '第一次错过');
      expect(json['description'], '你记录了第一次错过');
      expect(json['icon'], '🌫️');
      expect(json['unlocked'], true);
      expect(json['unlockedAt'], now.toIso8601String());
    });

    test('toJson 转换（未解锁）', () {
      final achievement = Achievement(
        id: 'first_met',
        name: '第一次邂逅',
        description: '你第一次标记"邂逅"状态',
        icon: '💫',
        unlocked: false,
        unlockedAt: null,
      );

      final json = achievement.toJson();

      expect(json['id'], 'first_met');
      expect(json['unlocked'], false);
      expect(json['unlockedAt'], isNull);
    });

    test('fromJson 转换（已解锁）', () {
      final json = {
        'id': 'first_missed',
        'name': '第一次错过',
        'description': '你记录了第一次错过',
        'icon': '🌫️',
        'unlocked': true,
        'unlockedAt': '2026-02-11T20:00:00.000',
      };

      final achievement = Achievement.fromJson(json);

      expect(achievement.id, 'first_missed');
      expect(achievement.name, '第一次错过');
      expect(achievement.description, '你记录了第一次错过');
      expect(achievement.icon, '🌫️');
      expect(achievement.unlocked, true);
      expect(achievement.unlockedAt, DateTime(2026, 2, 11, 20, 0, 0));
    });

    test('fromJson 转换（未解锁）', () {
      final json = {
        'id': 'first_met',
        'name': '第一次邂逅',
        'description': '你第一次标记"邂逅"状态',
        'icon': '💫',
        'unlocked': false,
        'unlockedAt': null,
      };

      final achievement = Achievement.fromJson(json);

      expect(achievement.id, 'first_met');
      expect(achievement.unlocked, false);
      expect(achievement.unlockedAt, isNull);
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();
      final original = Achievement(
        id: 'first_missed',
        name: '第一次错过',
        description: '你记录了第一次错过',
        icon: '🌫️',
        unlocked: true,
        unlockedAt: now,
      );

      final json = original.toJson();
      final restored = Achievement.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.icon, original.icon);
      expect(restored.unlocked, original.unlocked);
      expect(
        restored.unlockedAt?.millisecondsSinceEpoch,
        original.unlockedAt?.millisecondsSinceEpoch,
      );
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();
      final original = Achievement(
        id: 'first_missed',
        name: '第一次错过',
        description: '你记录了第一次错过',
        icon: '🌫️',
        unlocked: false,
        unlockedAt: null,
      );

      final updated = original.copyWith(
        unlocked: true,
        unlockedAt: now,
      );

      expect(updated.id, original.id);
      expect(updated.name, original.name);
      expect(updated.unlocked, true);
      expect(updated.unlockedAt, now);
    });

    test('相等性比较', () {
      final now = DateTime.now();
      final achievement1 = Achievement(
        id: 'first_missed',
        name: '第一次错过',
        description: '你记录了第一次错过',
        icon: '🌫️',
        unlocked: true,
        unlockedAt: now,
      );

      final achievement2 = Achievement(
        id: 'first_missed',
        name: '第一次错过',
        description: '你记录了第一次错过',
        icon: '🌫️',
        unlocked: true,
        unlockedAt: now,
      );

      final achievement3 = Achievement(
        id: 'first_met',
        name: '第一次邂逅',
        description: '你第一次标记"邂逅"状态',
        icon: '💫',
        unlocked: false,
        unlockedAt: null,
      );

      expect(achievement1 == achievement2, true);
      expect(achievement1 == achievement3, false);
    });

    test('toString 输出', () {
      final achievement = Achievement(
        id: 'first_missed',
        name: '第一次错过',
        description: '你记录了第一次错过',
        icon: '🌫️',
        unlocked: true,
        unlockedAt: DateTime.now(),
      );

      final str = achievement.toString();

      expect(str.contains('first_missed'), true);
      expect(str.contains('第一次错过'), true);
      expect(str.contains('unlocked: true'), true);
    });
  });
}

