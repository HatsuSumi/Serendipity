import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/membership.dart';
import 'package:serendipity_app/models/enums.dart';

void main() {
  group('Membership', () {
    test('创建 Membership 对象（完整信息）', () {
      final now = DateTime.now();
      final startedAt = now.subtract(const Duration(days: 30));
      final expiresAt = now.add(const Duration(days: 335));

      final membership = Membership(
        id: 'membership001',
        userId: 'user123',
        tier: MembershipTier.premium,
        status: MembershipStatus.active,
        startedAt: startedAt,
        expiresAt: expiresAt,
        monthlyAmount: 88,
        autoRenew: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(membership.id, 'membership001');
      expect(membership.userId, 'user123');
      expect(membership.tier, MembershipTier.premium);
      expect(membership.status, MembershipStatus.active);
      expect(membership.monthlyAmount, 88);
      expect(membership.autoRenew, true);
      expect(membership.startedAt, startedAt);
      expect(membership.expiresAt, expiresAt);
    });

    test('创建 Membership 对象（免费版）', () {
      final now = DateTime.now();

      final membership = Membership(
        id: 'membership001',
        userId: 'user123',
        tier: MembershipTier.free,
        status: MembershipStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      expect(membership.tier, MembershipTier.free);
      expect(membership.startedAt, isNull);
      expect(membership.expiresAt, isNull);
    });

    test('toJson 转换（完整信息）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);
      final startedAt = DateTime(2026, 1, 12, 10, 0, 0);
      final expiresAt = DateTime(2027, 1, 12, 10, 0, 0);

      final membership = Membership(
        id: 'membership001',
        userId: 'user123',
        tier: MembershipTier.premium,
        status: MembershipStatus.active,
        startedAt: startedAt,
        expiresAt: expiresAt,
        monthlyAmount: 88,
        autoRenew: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = membership.toJson();

      expect(json['id'], 'membership001');
      expect(json['userId'], 'user123');
      expect(json['tier'], MembershipTier.premium.value);
      expect(json['status'], MembershipStatus.active.value);
      expect(json['monthlyAmount'], 88);
      expect(json['autoRenew'], true);
    });

    test('toJson 转换（免费版）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final membership = Membership(
        id: 'membership001',
        userId: 'user123',
        tier: MembershipTier.free,
        status: MembershipStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final json = membership.toJson();

      expect(json['tier'], MembershipTier.free.value);
      expect(json['startedAt'], isNull);
      expect(json['expiresAt'], isNull);
    });

    test('fromJson 转换（完整信息）', () {
      final json = {
        'id': 'membership001',
        'userId': 'user123',
        'tier': 2,
        'status': 2,
        'startedAt': '2026-01-12T10:00:00.000',
        'expiresAt': '2027-01-12T10:00:00.000',
        'monthlyAmount': 88,
        'autoRenew': true,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final membership = Membership.fromJson(json);

      expect(membership.id, 'membership001');
      expect(membership.userId, 'user123');
      expect(membership.tier, MembershipTier.premium);
      expect(membership.status, MembershipStatus.active);
    });

    test('fromJson 转换（免费版）', () {
      final json = {
        'id': 'membership001',
        'userId': 'user123',
        'tier': 1,
        'status': 2,
        'startedAt': null,
        'expiresAt': null,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final membership = Membership.fromJson(json);

      expect(membership.tier, MembershipTier.free);
      expect(membership.startedAt, isNull);
      expect(membership.expiresAt, isNull);
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();
      final startedAt = now.subtract(const Duration(days: 30));
      final expiresAt = now.add(const Duration(days: 335));

      final original = Membership(
        id: 'membership001',
        userId: 'user123',
        tier: MembershipTier.premium,
        status: MembershipStatus.active,
        startedAt: startedAt,
        expiresAt: expiresAt,
        monthlyAmount: 88,
        autoRenew: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = Membership.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.tier, original.tier);
      expect(restored.status, original.status);
      expect(restored.monthlyAmount, original.monthlyAmount);
      expect(restored.autoRenew, original.autoRenew);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();

      final original = Membership(
        id: 'membership001',
        userId: 'user123',
        tier: MembershipTier.free,
        status: MembershipStatus.inactive,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        tier: MembershipTier.premium,
        status: MembershipStatus.active,
        monthlyAmount: 88,
        autoRenew: true,
      );

      expect(updated.id, original.id);
      expect(updated.tier, MembershipTier.premium);
      expect(updated.status, MembershipStatus.active);
      expect(updated.monthlyAmount, 88);
      expect(updated.autoRenew, true);
    });

    test('相等性比较', () {
      final now = DateTime.now();

      final membership1 = Membership(
        id: 'membership001',
        userId: 'user123',
        tier: MembershipTier.premium,
        status: MembershipStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final membership2 = Membership(
        id: 'membership001',
        userId: 'user123',
        tier: MembershipTier.premium,
        status: MembershipStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final membership3 = Membership(
        id: 'membership002',
        userId: 'user123',
        tier: MembershipTier.premium,
        status: MembershipStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      expect(membership1 == membership2, true);
      expect(membership1 == membership3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();

      final membership = Membership(
        id: 'membership001',
        userId: 'user123',
        tier: MembershipTier.premium,
        status: MembershipStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final str = membership.toString();

      expect(str.contains('membership001'), true);
      expect(str.contains('会员版'), true);
      expect(str.contains('活跃'), true);
    });

    test('测试不同的会员状态', () {
      final now = DateTime.now();

      final statuses = [
        MembershipStatus.inactive,
        MembershipStatus.active,
        MembershipStatus.expired,
        MembershipStatus.cancelled,
      ];

      for (final status in statuses) {
        final membership = Membership(
          id: 'membership001',
          userId: 'user123',
          tier: MembershipTier.premium,
          status: status,
          createdAt: now,
          updatedAt: now,
        );

        expect(membership.status, status);

        final json = membership.toJson();
        final restored = Membership.fromJson(json);
        expect(restored.status, status);
      }
    });
  });
}
