import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/user.dart';
import 'package:serendipity_app/models/enums.dart';

void main() {
  group('User', () {
    test('创建 User 对象（完整信息）', () {
      final now = DateTime.now();

      final user = User(
        id: 'user123',
        email: 'test@example.com',
        phoneNumber: '+86 138 0000 0000',
        displayName: '张三',
        avatarUrl: 'https://example.com/avatar.jpg',
        authProvider: AuthProvider.email,
        isEmailVerified: true,
        isPhoneVerified: false,
        lastLoginAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(user.id, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.phoneNumber, '+86 138 0000 0000');
      expect(user.displayName, '张三');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.authProvider, AuthProvider.email);
      expect(user.isEmailVerified, true);
      expect(user.isPhoneVerified, false);
      expect(user.lastLoginAt, now);
    });

    test('创建 User 对象（最小信息）', () {
      final now = DateTime.now();

      final user = User(
        id: 'user123',
        email: 'test@example.com',
        authProvider: AuthProvider.email,
        isEmailVerified: false,
        isPhoneVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(user.email, 'test@example.com');
      expect(user.phoneNumber, isNull);
      expect(user.displayName, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.lastLoginAt, isNull);
      expect(user.authProvider, AuthProvider.email);
    });

    test('toJson 转换（完整信息）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final user = User(
        id: 'user123',
        email: 'test@example.com',
        phoneNumber: '+86 138 0000 0000',
        displayName: '张三',
        avatarUrl: 'https://example.com/avatar.jpg',
        authProvider: AuthProvider.email,
        isEmailVerified: true,
        isPhoneVerified: false,
        lastLoginAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = user.toJson();

      expect(json['id'], 'user123');
      expect(json['email'], 'test@example.com');
      expect(json['phoneNumber'], '+86 138 0000 0000');
      expect(json['displayName'], '张三');
      expect(json['avatarUrl'], 'https://example.com/avatar.jpg');
      expect(json['authProvider'], 'email');
      expect(json['isEmailVerified'], true);
      expect(json['isPhoneVerified'], false);
      expect(json['lastLoginAt'], isNotNull);
    });

    test('toJson 转换（最小信息）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final user = User(
        id: 'user123',
        phoneNumber: '+86 138 0000 0000',
        authProvider: AuthProvider.phone,
        isEmailVerified: false,
        isPhoneVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = user.toJson();

      expect(json['email'], isNull);
      expect(json['phoneNumber'], '+86 138 0000 0000');
      expect(json['displayName'], isNull);
      expect(json['avatarUrl'], isNull);
      expect(json['lastLoginAt'], isNull);
      expect(json['authProvider'], 'phone');
    });

    test('fromJson 转换（完整信息）', () {
      final json = {
        'id': 'user123',
        'email': 'test@example.com',
        'phoneNumber': '+86 138 0000 0000',
        'displayName': '张三',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'authProvider': 'email',
        'isEmailVerified': true,
        'isPhoneVerified': false,
        'lastLoginAt': '2026-02-12T10:00:00.000',
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final user = User.fromJson(json);

      expect(user.id, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.phoneNumber, '+86 138 0000 0000');
      expect(user.displayName, '张三');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.authProvider, AuthProvider.email);
      expect(user.isEmailVerified, true);
      expect(user.isPhoneVerified, false);
      expect(user.lastLoginAt, isNotNull);
    });

    test('fromJson 转换（最小信息）', () {
      final json = {
        'id': 'user123',
        'email': 'test@example.com',
        'phoneNumber': null,
        'displayName': null,
        'avatarUrl': null,
        'authProvider': 'email',
        'isEmailVerified': false,
        'isPhoneVerified': false,
        'lastLoginAt': null,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final user = User.fromJson(json);

      expect(user.email, 'test@example.com');
      expect(user.phoneNumber, isNull);
      expect(user.displayName, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.lastLoginAt, isNull);
      expect(user.authProvider, AuthProvider.email);
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();

      final original = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: '张三',
        authProvider: AuthProvider.email,
        isEmailVerified: true,
        isPhoneVerified: false,
        lastLoginAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = User.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.authProvider, original.authProvider);
      expect(restored.isEmailVerified, original.isEmailVerified);
      expect(restored.isPhoneVerified, original.isPhoneVerified);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();

      final original = User(
        id: 'user123',
        email: 'old@example.com', // 需要提供邮箱或手机号
        authProvider: AuthProvider.email,
        isEmailVerified: false,
        isPhoneVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        email: () => 'test@example.com',
        displayName: () => '张三',
        isEmailVerified: true,
      );

      expect(updated.id, original.id);
      expect(updated.email, 'test@example.com');
      expect(updated.displayName, '张三');
      expect(updated.isEmailVerified, true);
      expect(updated.authProvider, original.authProvider);
    });

    test('相等性比较', () {
      final now = DateTime.now();

      final user1 = User(
        id: 'user123',
        email: 'test@example.com',
        authProvider: AuthProvider.email,
        isEmailVerified: true,
        isPhoneVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      final user2 = User(
        id: 'user123',
        email: 'test@example.com',
        authProvider: AuthProvider.email,
        isEmailVerified: true,
        isPhoneVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      final user3 = User(
        id: 'user456',
        email: 'test@example.com',
        authProvider: AuthProvider.email,
        isEmailVerified: true,
        isPhoneVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(user1 == user2, true);
      expect(user1 == user3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();

      final user = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: '张三',
        authProvider: AuthProvider.email,
        isEmailVerified: true,
        isPhoneVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      final str = user.toString();

      expect(str.contains('user123'), true);
      expect(str.contains('邮箱'), true);
      expect(str.contains('张三'), true);
    });

    test('测试不同的 AuthProvider', () {
      final now = DateTime.now();

      final providers = [
        (AuthProvider.email, 'test@example.com', null),
        (AuthProvider.phone, null, '+86 138 0000 0000'),
      ];

      for (final provider in providers) {
        final user = User(
          id: 'user123',
          email: provider.$2,
          phoneNumber: provider.$3,
          authProvider: provider.$1,
          isEmailVerified: false,
          isPhoneVerified: false,
          createdAt: now,
          updatedAt: now,
        );

        expect(user.authProvider, provider.$1);

        final json = user.toJson();
        final restored = User.fromJson(json);
        expect(restored.authProvider, provider.$1);
      }
    });
  });
}

