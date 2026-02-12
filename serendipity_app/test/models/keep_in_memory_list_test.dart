import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/keep_in_memory_list.dart';

void main() {
  group('KeepInMemoryList', () {
    test('创建 KeepInMemoryList 对象', () {
      final now = DateTime.now();

      final keepInMemory = KeepInMemoryList(
        id: 'keep001',
        userId: 'user123',
        keptInMemoryUserId: 'user456',
        matchId: 'match789',
        createdAt: now,
      );

      expect(keepInMemory.id, 'keep001');
      expect(keepInMemory.userId, 'user123');
      expect(keepInMemory.keptInMemoryUserId, 'user456');
      expect(keepInMemory.matchId, 'match789');
      expect(keepInMemory.createdAt, now);
    });

    test('toJson 转换', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final keepInMemory = KeepInMemoryList(
        id: 'keep001',
        userId: 'user123',
        keptInMemoryUserId: 'user456',
        matchId: 'match789',
        createdAt: now,
      );

      final json = keepInMemory.toJson();

      expect(json['id'], 'keep001');
      expect(json['userId'], 'user123');
      expect(json['keptInMemoryUserId'], 'user456');
      expect(json['matchId'], 'match789');
      expect(json['createdAt'], '2026-02-12T10:00:00.000');
    });

    test('fromJson 转换', () {
      final json = {
        'id': 'keep001',
        'userId': 'user123',
        'keptInMemoryUserId': 'user456',
        'matchId': 'match789',
        'createdAt': '2026-02-12T10:00:00.000',
      };

      final keepInMemory = KeepInMemoryList.fromJson(json);

      expect(keepInMemory.id, 'keep001');
      expect(keepInMemory.userId, 'user123');
      expect(keepInMemory.keptInMemoryUserId, 'user456');
      expect(keepInMemory.matchId, 'match789');
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();

      final original = KeepInMemoryList(
        id: 'keep001',
        userId: 'user123',
        keptInMemoryUserId: 'user456',
        matchId: 'match789',
        createdAt: now,
      );

      final json = original.toJson();
      final restored = KeepInMemoryList.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.keptInMemoryUserId, original.keptInMemoryUserId);
      expect(restored.matchId, original.matchId);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();

      final original = KeepInMemoryList(
        id: 'keep001',
        userId: 'user123',
        keptInMemoryUserId: 'user456',
        matchId: 'match789',
        createdAt: now,
      );

      final updated = original.copyWith(
        keptInMemoryUserId: 'user999',
        matchId: 'match888',
      );

      expect(updated.id, original.id);
      expect(updated.userId, original.userId);
      expect(updated.keptInMemoryUserId, 'user999');
      expect(updated.matchId, 'match888');
      expect(updated.createdAt, original.createdAt);
    });

    test('相等性比较', () {
      final now = DateTime.now();

      final keepInMemory1 = KeepInMemoryList(
        id: 'keep001',
        userId: 'user123',
        keptInMemoryUserId: 'user456',
        matchId: 'match789',
        createdAt: now,
      );

      final keepInMemory2 = KeepInMemoryList(
        id: 'keep001',
        userId: 'user123',
        keptInMemoryUserId: 'user456',
        matchId: 'match789',
        createdAt: now,
      );

      final keepInMemory3 = KeepInMemoryList(
        id: 'keep002',
        userId: 'user123',
        keptInMemoryUserId: 'user456',
        matchId: 'match789',
        createdAt: now,
      );

      expect(keepInMemory1 == keepInMemory2, true);
      expect(keepInMemory1 == keepInMemory3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();

      final keepInMemory = KeepInMemoryList(
        id: 'keep001',
        userId: 'user123',
        keptInMemoryUserId: 'user456',
        matchId: 'match789',
        createdAt: now,
      );

      final str = keepInMemory.toString();

      expect(str.contains('keep001'), true);
      expect(str.contains('user123'), true);
      expect(str.contains('user456'), true);
    });

    test('测试多个用户的留在记忆里记录', () {
      final now = DateTime.now();

      final records = [
        KeepInMemoryList(
          id: 'keep001',
          userId: 'user123',
          keptInMemoryUserId: 'user456',
          matchId: 'match001',
          createdAt: now.subtract(Duration(days: 2)),
        ),
        KeepInMemoryList(
          id: 'keep002',
          userId: 'user123',
          keptInMemoryUserId: 'user789',
          matchId: 'match002',
          createdAt: now.subtract(Duration(days: 1)),
        ),
        KeepInMemoryList(
          id: 'keep003',
          userId: 'user123',
          keptInMemoryUserId: 'user999',
          matchId: 'match003',
          createdAt: now,
        ),
      ];

      expect(records.length, 3);
      expect(records[0].keptInMemoryUserId, 'user456');
      expect(records[1].keptInMemoryUserId, 'user789');
      expect(records[2].keptInMemoryUserId, 'user999');
    });
  });
}

