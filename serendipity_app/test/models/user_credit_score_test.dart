import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/user_credit_score.dart';
import 'package:serendipity_app/models/enums.dart';

void main() {
  group('CreditChange', () {
    test('创建 CreditChange 对象', () {
      final now = DateTime.now();

      final change = CreditChange(
        reason: CreditChangeReason.verificationSuccess,
        delta: 10,
        scoreBefore: 90,
        scoreAfter: 100,
        relatedId: 'match123',
        changedAt: now,
      );

      expect(change.reason, CreditChangeReason.verificationSuccess);
      expect(change.delta, 10);
      expect(change.scoreBefore, 90);
      expect(change.scoreAfter, 100);
      expect(change.relatedId, 'match123');
      expect(change.changedAt, now);
    });

    test('创建 CreditChange 对象（负值变更）', () {
      final now = DateTime.now();

      final change = CreditChange(
        reason: CreditChangeReason.gpsAnomalyDetected,
        delta: -20,
        scoreBefore: 100,
        scoreAfter: 80,
        relatedId: 'record456',
        changedAt: now,
      );

      expect(change.delta, -20);
      expect(change.scoreBefore, 100);
      expect(change.scoreAfter, 80);
    });

    test('toJson 转换', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final change = CreditChange(
        reason: CreditChangeReason.goodBehavior,
        delta: 5,
        scoreBefore: 95,
        scoreAfter: 100,
        relatedId: 'action789',
        changedAt: now,
      );

      final json = change.toJson();

      expect(json['reason'], CreditChangeReason.goodBehavior.value);
      expect(json['delta'], 5);
      expect(json['scoreBefore'], 95);
      expect(json['scoreAfter'], 100);
      expect(json['relatedId'], 'action789');
    });

    test('fromJson 转换', () {
      final json = {
        'reason': 4,
        'delta': 10,
        'scoreBefore': 90,
        'scoreAfter': 100,
        'relatedId': 'match123',
        'changedAt': '2026-02-12T10:00:00.000',
      };

      final change = CreditChange.fromJson(json);

      expect(change.reason, CreditChangeReason.verificationSuccess);
      expect(change.delta, 10);
      expect(change.scoreBefore, 90);
      expect(change.scoreAfter, 100);
      expect(change.relatedId, 'match123');
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();

      final original = CreditChange(
        reason: CreditChangeReason.verificationSuccess,
        delta: 10,
        scoreBefore: 90,
        scoreAfter: 100,
        relatedId: 'match123',
        changedAt: now,
      );

      final json = original.toJson();
      final restored = CreditChange.fromJson(json);

      expect(restored.reason, original.reason);
      expect(restored.delta, original.delta);
      expect(restored.scoreBefore, original.scoreBefore);
      expect(restored.scoreAfter, original.scoreAfter);
      expect(restored.relatedId, original.relatedId);
    });

    test('toString 输出', () {
      final now = DateTime.now();

      final change = CreditChange(
        reason: CreditChangeReason.verificationSuccess,
        delta: 10,
        scoreBefore: 90,
        scoreAfter: 100,
        changedAt: now,
      );

      final str = change.toString();

      expect(str.contains('验证成功'), true);
      expect(str.contains('10'), true);
      expect(str.contains('100'), true);
    });
  });

  group('UserCreditScore', () {
    test('创建 UserCreditScore 对象（有历史记录）', () {
      final now = DateTime.now();
      final changes = [
        CreditChange(
          reason: CreditChangeReason.verificationSuccess,
          delta: 10,
          scoreBefore: 90,
          scoreAfter: 100,
          relatedId: 'match123',
          changedAt: now.subtract(Duration(days: 1)),
        ),
        CreditChange(
          reason: CreditChangeReason.gpsAnomalyDetected,
          delta: -5,
          scoreBefore: 100,
          scoreAfter: 95,
          relatedId: 'record456',
          changedAt: now,
        ),
      ];

      final creditScore = UserCreditScore(
        id: 'credit001',
        userId: 'user123',
        score: 95,
        history: changes,
        createdAt: now,
        updatedAt: now,
      );

      expect(creditScore.id, 'credit001');
      expect(creditScore.userId, 'user123');
      expect(creditScore.score, 95);
      expect(creditScore.history.length, 2);
    });

    test('创建 UserCreditScore 对象（无历史记录）', () {
      final now = DateTime.now();

      final creditScore = UserCreditScore(
        id: 'credit001',
        userId: 'user123',
        score: 100,
        history: [],
        createdAt: now,
        updatedAt: now,
      );

      expect(creditScore.score, 100);
      expect(creditScore.history.length, 0);
    });

    test('toJson 转换（有历史记录）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);
      final changes = [
        CreditChange(
          reason: CreditChangeReason.verificationSuccess,
          delta: 10,
          scoreBefore: 90,
          scoreAfter: 100,
          changedAt: now,
        ),
      ];

      final creditScore = UserCreditScore(
        id: 'credit001',
        userId: 'user123',
        score: 100,
        history: changes,
        createdAt: now,
        updatedAt: now,
      );

      final json = creditScore.toJson();

      expect(json['id'], 'credit001');
      expect(json['userId'], 'user123');
      expect(json['score'], 100);
      expect(json['history'], isList);
      expect(json['history'].length, 1);
    });

    test('toJson 转换（无历史记录）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final creditScore = UserCreditScore(
        id: 'credit001',
        userId: 'user123',
        score: 100,
        history: [],
        createdAt: now,
        updatedAt: now,
      );

      final json = creditScore.toJson();

      expect(json['history'], isEmpty);
    });

    test('fromJson 转换（有历史记录）', () {
      final json = {
        'id': 'credit001',
        'userId': 'user123',
        'score': 95,
        'history': [
          {
            'reason': 4,
            'delta': 10,
            'scoreBefore': 90,
            'scoreAfter': 100,
            'relatedId': 'match123',
            'changedAt': '2026-02-12T09:00:00.000',
          },
          {
            'reason': 1,
            'delta': -5,
            'scoreBefore': 100,
            'scoreAfter': 95,
            'relatedId': 'record456',
            'changedAt': '2026-02-12T10:00:00.000',
          },
        ],
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final creditScore = UserCreditScore.fromJson(json);

      expect(creditScore.id, 'credit001');
      expect(creditScore.userId, 'user123');
      expect(creditScore.score, 95);
      expect(creditScore.history.length, 2);
      expect(creditScore.history[0].reason, CreditChangeReason.verificationSuccess);
      expect(creditScore.history[1].reason, CreditChangeReason.gpsAnomalyDetected);
    });

    test('fromJson 转换（无历史记录）', () {
      final json = {
        'id': 'credit001',
        'userId': 'user123',
        'score': 100,
        'history': [],
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final creditScore = UserCreditScore.fromJson(json);

      expect(creditScore.history.length, 0);
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();
      final changes = [
        CreditChange(
          reason: CreditChangeReason.verificationSuccess,
          delta: 10,
          scoreBefore: 90,
          scoreAfter: 100,
          changedAt: now,
        ),
      ];

      final original = UserCreditScore(
        id: 'credit001',
        userId: 'user123',
        score: 100,
        history: changes,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = UserCreditScore.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.score, original.score);
      expect(restored.history.length, original.history.length);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();

      final original = UserCreditScore(
        id: 'credit001',
        userId: 'user123',
        score: 100,
        history: [],
        createdAt: now,
        updatedAt: now,
      );

      final newChange = CreditChange(
        reason: CreditChangeReason.goodBehavior,
        delta: 5,
        scoreBefore: 100,
        scoreAfter: 105,
        changedAt: now,
      );

      final updated = original.copyWith(
        score: 105,
        history: [newChange],
      );

      expect(updated.id, original.id);
      expect(updated.score, 105);
      expect(updated.history.length, 1);
    });

    test('相等性比较', () {
      final now = DateTime.now();

      final creditScore1 = UserCreditScore(
        id: 'credit001',
        userId: 'user123',
        score: 100,
        history: [],
        createdAt: now,
        updatedAt: now,
      );

      final creditScore2 = UserCreditScore(
        id: 'credit001',
        userId: 'user123',
        score: 100,
        history: [],
        createdAt: now,
        updatedAt: now,
      );

      final creditScore3 = UserCreditScore(
        id: 'credit002',
        userId: 'user123',
        score: 100,
        history: [],
        createdAt: now,
        updatedAt: now,
      );

      expect(creditScore1 == creditScore2, true);
      expect(creditScore1 == creditScore3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();
      final changes = [
        CreditChange(
          reason: CreditChangeReason.verificationSuccess,
          delta: 10,
          scoreBefore: 90,
          scoreAfter: 100,
          changedAt: now,
        ),
      ];

      final creditScore = UserCreditScore(
        id: 'credit001',
        userId: 'user123',
        score: 100,
        history: changes,
        createdAt: now,
        updatedAt: now,
      );

      final str = creditScore.toString();

      expect(str.contains('credit001'), true);
      expect(str.contains('100'), true);
      expect(str.contains('1'), true);
    });

    test('测试不同的变更原因', () {
      final now = DateTime.now();

      final reasons = [
        CreditChangeReason.gpsAnomalyDetected,
        CreditChangeReason.behaviorAnomalyDetected,
        CreditChangeReason.goodBehavior,
        CreditChangeReason.verificationSuccess,
      ];

      for (final reason in reasons) {
        final change = CreditChange(
          reason: reason,
          delta: 10,
          scoreBefore: 90,
          scoreAfter: 100,
          changedAt: now,
        );

        expect(change.reason, reason);

        final json = change.toJson();
        final restored = CreditChange.fromJson(json);
        expect(restored.reason, reason);
      }
    });
  });
}

