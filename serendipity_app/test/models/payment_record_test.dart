import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/payment_record.dart';
import 'package:serendipity_app/models/enums.dart';

void main() {
  group('PaymentRecord', () {
    test('创建 PaymentRecord 对象（完整信息）', () {
      final now = DateTime.now();
      final paidAt = now.subtract(Duration(minutes: 5));

      final payment = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.applePay,
        status: PaymentStatus.success,
        transactionId: 'txn_123456789',
        receiptData: 'base64_encoded_receipt_data',
        paidAt: paidAt,
        createdAt: now,
        updatedAt: now,
      );

      expect(payment.id, 'payment001');
      expect(payment.userId, 'user123');
      expect(payment.membershipId, 'membership001');
      expect(payment.amount, 19.9);
      expect(payment.method, PaymentMethod.applePay);
      expect(payment.status, PaymentStatus.success);
      expect(payment.transactionId, 'txn_123456789');
      expect(payment.receiptData, 'base64_encoded_receipt_data');
      expect(payment.paidAt, paidAt);
    });

    test('创建 PaymentRecord 对象（待支付）', () {
      final now = DateTime.now();

      final payment = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.alipay,
        status: PaymentStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      expect(payment.status, PaymentStatus.pending);
      expect(payment.transactionId, isNull);
      expect(payment.receiptData, isNull);
      expect(payment.paidAt, isNull);
    });

    test('创建 PaymentRecord 对象（免费解锁）', () {
      final now = DateTime.now();

      final payment = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 0.0,
        method: PaymentMethod.free,
        status: PaymentStatus.success,
        paidAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(payment.amount, 0.0);
      expect(payment.method, PaymentMethod.free);
      expect(payment.status, PaymentStatus.success);
    });

    test('toJson 转换（完整信息）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);
      final paidAt = DateTime(2026, 2, 12, 9, 55, 0);

      final payment = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.applePay,
        status: PaymentStatus.success,
        transactionId: 'txn_123456789',
        receiptData: 'base64_encoded_receipt_data',
        paidAt: paidAt,
        createdAt: now,
        updatedAt: now,
      );

      final json = payment.toJson();

      expect(json['id'], 'payment001');
      expect(json['userId'], 'user123');
      expect(json['membershipId'], 'membership001');
      expect(json['amount'], 19.9);
      expect(json['method'], 'apple_pay');
      expect(json['status'], PaymentStatus.success.value);
      expect(json['transactionId'], 'txn_123456789');
      expect(json['receiptData'], 'base64_encoded_receipt_data');
      expect(json['paidAt'], isNotNull);
    });

    test('toJson 转换（待支付）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final payment = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.alipay,
        status: PaymentStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final json = payment.toJson();

      expect(json['status'], PaymentStatus.pending.value);
      expect(json['transactionId'], isNull);
      expect(json['receiptData'], isNull);
      expect(json['paidAt'], isNull);
    });

    test('fromJson 转换（完整信息）', () {
      final json = {
        'id': 'payment001',
        'userId': 'user123',
        'membershipId': 'membership001',
        'amount': 19.9,
        'method': 'apple_pay',
        'status': 3,
        'transactionId': 'txn_123456789',
        'receiptData': 'base64_encoded_receipt_data',
        'paidAt': '2026-02-12T09:55:00.000',
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final payment = PaymentRecord.fromJson(json);

      expect(payment.id, 'payment001');
      expect(payment.userId, 'user123');
      expect(payment.membershipId, 'membership001');
      expect(payment.amount, 19.9);
      expect(payment.method, PaymentMethod.applePay);
      expect(payment.status, PaymentStatus.success);
      expect(payment.transactionId, 'txn_123456789');
      expect(payment.receiptData, 'base64_encoded_receipt_data');
      expect(payment.paidAt, isNotNull);
    });

    test('fromJson 转换（待支付）', () {
      final json = {
        'id': 'payment001',
        'userId': 'user123',
        'membershipId': 'membership001',
        'amount': 19.9,
        'method': 'alipay',
        'status': 1,
        'transactionId': null,
        'receiptData': null,
        'paidAt': null,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final payment = PaymentRecord.fromJson(json);

      expect(payment.status, PaymentStatus.pending);
      expect(payment.transactionId, isNull);
      expect(payment.receiptData, isNull);
      expect(payment.paidAt, isNull);
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();
      final paidAt = now.subtract(Duration(minutes: 5));

      final original = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.applePay,
        status: PaymentStatus.success,
        transactionId: 'txn_123456789',
        paidAt: paidAt,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = PaymentRecord.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.membershipId, original.membershipId);
      expect(restored.amount, original.amount);
      expect(restored.method, original.method);
      expect(restored.status, original.status);
      expect(restored.transactionId, original.transactionId);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();

      final original = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.alipay,
        status: PaymentStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        status: PaymentStatus.success,
        transactionId: 'txn_123456789',
        paidAt: now,
      );

      expect(updated.id, original.id);
      expect(updated.status, PaymentStatus.success);
      expect(updated.transactionId, 'txn_123456789');
      expect(updated.paidAt, now);
      expect(updated.amount, original.amount);
    });

    test('相等性比较', () {
      final now = DateTime.now();

      final payment1 = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.applePay,
        status: PaymentStatus.success,
        createdAt: now,
        updatedAt: now,
      );

      final payment2 = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.applePay,
        status: PaymentStatus.success,
        createdAt: now,
        updatedAt: now,
      );

      final payment3 = PaymentRecord(
        id: 'payment002',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.applePay,
        status: PaymentStatus.success,
        createdAt: now,
        updatedAt: now,
      );

      expect(payment1 == payment2, true);
      expect(payment1 == payment3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();

      final payment = PaymentRecord(
        id: 'payment001',
        userId: 'user123',
        membershipId: 'membership001',
        amount: 19.9,
        method: PaymentMethod.applePay,
        status: PaymentStatus.success,
        createdAt: now,
        updatedAt: now,
      );

      final str = payment.toString();

      expect(str.contains('payment001'), true);
      expect(str.contains('19.9'), true);
      expect(str.contains('Apple Pay'), true);
      expect(str.contains('支付成功'), true);
    });

    test('测试不同的支付方式', () {
      final now = DateTime.now();

      final methods = [
        PaymentMethod.free,
        PaymentMethod.applePay,
        PaymentMethod.googlePay,
        PaymentMethod.alipay,
        PaymentMethod.wechatPay,
      ];

      for (final method in methods) {
        final payment = PaymentRecord(
          id: 'payment001',
          userId: 'user123',
          membershipId: 'membership001',
          amount: method == PaymentMethod.free ? 0.0 : 19.9,
          method: method,
          status: PaymentStatus.success,
          createdAt: now,
          updatedAt: now,
        );

        expect(payment.method, method);

        final json = payment.toJson();
        final restored = PaymentRecord.fromJson(json);
        expect(restored.method, method);
      }
    });

    test('测试不同的支付状态', () {
      final now = DateTime.now();

      final statuses = [
        PaymentStatus.pending,
        PaymentStatus.processing,
        PaymentStatus.success,
        PaymentStatus.failed,
        PaymentStatus.refunded,
      ];

      for (final status in statuses) {
        final payment = PaymentRecord(
          id: 'payment001',
          userId: 'user123',
          membershipId: 'membership001',
          amount: 19.9,
          method: PaymentMethod.applePay,
          status: status,
          createdAt: now,
          updatedAt: now,
        );

        expect(payment.status, status);

        final json = payment.toJson();
        final restored = PaymentRecord.fromJson(json);
        expect(restored.status, status);
      }
    });
  });
}

