import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/match.dart';
import 'package:serendipity_app/models/enums.dart';

void main() {
  group('CandidateRecord', () {
    test('创建 CandidateRecord 对象', () {
      final candidate = CandidateRecord(
        recordId: 'record123',
        userId: 'user456',
        score: 85.5,
      );

      expect(candidate.recordId, 'record123');
      expect(candidate.userId, 'user456');
      expect(candidate.score, 85.5);
    });

    test('toJson 转换', () {
      final candidate = CandidateRecord(
        recordId: 'record123',
        userId: 'user456',
        score: 85.5,
      );

      final json = candidate.toJson();

      expect(json['recordId'], 'record123');
      expect(json['userId'], 'user456');
      expect(json['score'], 85.5);
    });

    test('fromJson 转换', () {
      final json = {
        'recordId': 'record123',
        'userId': 'user456',
        'score': 85.5,
      };

      final candidate = CandidateRecord.fromJson(json);

      expect(candidate.recordId, 'record123');
      expect(candidate.userId, 'user456');
      expect(candidate.score, 85.5);
    });

    test('copyWith 修改字段', () {
      final original = CandidateRecord(
        recordId: 'record123',
        userId: 'user456',
        score: 85.5,
      );

      final updated = original.copyWith(score: 90.0);

      expect(updated.recordId, original.recordId);
      expect(updated.userId, original.userId);
      expect(updated.score, 90.0);
    });

    test('相等性比较', () {
      final candidate1 = CandidateRecord(
        recordId: 'record123',
        userId: 'user456',
        score: 85.5,
      );

      final candidate2 = CandidateRecord(
        recordId: 'record123',
        userId: 'user456',
        score: 85.5,
      );

      final candidate3 = CandidateRecord(
        recordId: 'record789',
        userId: 'user456',
        score: 85.5,
      );

      expect(candidate1 == candidate2, true);
      expect(candidate1 == candidate3, false);
    });
  });

  group('Match', () {
    test('创建 Match 对象（pending 状态）', () {
      final now = DateTime.now();
      final candidates = [
        CandidateRecord(
          recordId: 'record123',
          userId: 'userB',
          score: 85.5,
        ),
      ];

      final match = Match(
        id: 'match001',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        status: MatchStatus.pending,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        isPermanentlyKeptInMemory: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(match.id, 'match001');
      expect(match.userAId, 'userA');
      expect(match.recordAId, 'recordA');
      expect(match.candidateRecords.length, 1);
      expect(match.status, MatchStatus.pending);
      expect(match.confidence, MatchConfidence.high);
      expect(match.matchScore, 85.5);
      expect(match.isPermanentlyKeptInMemory, false);
    });

    test('创建 Match 对象（verified 状态）', () {
      final now = DateTime.now();
      final candidates = [
        CandidateRecord(
          recordId: 'record123',
          userId: 'userB',
          score: 85.5,
        ),
      ];

      final match = Match(
        id: 'match001',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        userASelectedRecordId: 'record123',
        userAChoice: VerificationChoice.wantContact,
        otherUserId: 'userB',
        otherUserSelectedRecordId: 'recordA',
        otherUserChoice: VerificationChoice.wantContact,
        status: MatchStatus.verified,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        notifiedAt: now.add(Duration(hours: 6)),
        isPermanentlyKeptInMemory: false,
        verifiedAt: now.add(Duration(hours: 7)),
        expiredAt: now.add(Duration(days: 7)),
        createdAt: now,
        updatedAt: now,
      );

      expect(match.status, MatchStatus.verified);
      expect(match.userASelectedRecordId, 'record123');
      expect(match.userAChoice, VerificationChoice.wantContact);
      expect(match.otherUserId, 'userB');
      expect(match.otherUserSelectedRecordId, 'recordA');
      expect(match.otherUserChoice, VerificationChoice.wantContact);
      expect(match.verifiedAt, isNotNull);
      expect(match.expiredAt, isNotNull);
    });

    test('toJson 转换（pending 状态）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);
      final candidates = [
        CandidateRecord(
          recordId: 'record123',
          userId: 'userB',
          score: 85.5,
        ),
      ];

      final match = Match(
        id: 'match001',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        status: MatchStatus.pending,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        isPermanentlyKeptInMemory: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = match.toJson();

      expect(json['id'], 'match001');
      expect(json['userAId'], 'userA');
      expect(json['recordAId'], 'recordA');
      expect(json['candidateRecords'], isList);
      expect(json['candidateRecords'].length, 1);
      expect(json['status'], MatchStatus.pending.value);
      expect(json['confidence'], MatchConfidence.high.value);
      expect(json['matchScore'], 85.5);
      expect(json['isPermanentlyKeptInMemory'], false);
      expect(json['userASelectedRecordId'], isNull);
      expect(json['userAChoice'], isNull);
    });

    test('toJson 转换（verified 状态）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);
      final candidates = [
        CandidateRecord(
          recordId: 'record123',
          userId: 'userB',
          score: 85.5,
        ),
      ];

      final match = Match(
        id: 'match001',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        userASelectedRecordId: 'record123',
        userAChoice: VerificationChoice.wantContact,
        otherUserId: 'userB',
        otherUserSelectedRecordId: 'recordA',
        otherUserChoice: VerificationChoice.wantContact,
        status: MatchStatus.verified,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        notifiedAt: now.add(Duration(hours: 6)),
        isPermanentlyKeptInMemory: false,
        verifiedAt: now.add(Duration(hours: 7)),
        expiredAt: now.add(Duration(days: 7)),
        createdAt: now,
        updatedAt: now,
      );

      final json = match.toJson();

      expect(json['status'], MatchStatus.verified.value);
      expect(json['userASelectedRecordId'], 'record123');
      expect(json['userAChoice'], VerificationChoice.wantContact.value);
      expect(json['otherUserId'], 'userB');
      expect(json['otherUserSelectedRecordId'], 'recordA');
      expect(json['otherUserChoice'], VerificationChoice.wantContact.value);
      expect(json['verifiedAt'], isNotNull);
      expect(json['expiredAt'], isNotNull);
    });

    test('fromJson 转换（pending 状态）', () {
      final json = {
        'id': 'match001',
        'userAId': 'userA',
        'recordAId': 'recordA',
        'candidateRecords': [
          {
            'recordId': 'record123',
            'userId': 'userB',
            'score': 85.5,
          }
        ],
        'userASelectedRecordId': null,
        'userAChoice': null,
        'otherUserId': null,
        'otherUserSelectedRecordId': null,
        'otherUserChoice': null,
        'status': 1,
        'confidence': 1,
        'matchScore': 85.5,
        'matchedAt': '2026-02-12T10:00:00.000',
        'notifiedAt': null,
        'isPermanentlyKeptInMemory': false,
        'verifiedAt': null,
        'expiredAt': null,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final match = Match.fromJson(json);

      expect(match.id, 'match001');
      expect(match.userAId, 'userA');
      expect(match.recordAId, 'recordA');
      expect(match.candidateRecords.length, 1);
      expect(match.status, MatchStatus.pending);
      expect(match.confidence, MatchConfidence.high);
      expect(match.userASelectedRecordId, isNull);
      expect(match.userAChoice, isNull);
    });

    test('fromJson 转换（verified 状态）', () {
      final json = {
        'id': 'match001',
        'userAId': 'userA',
        'recordAId': 'recordA',
        'candidateRecords': [
          {
            'recordId': 'record123',
            'userId': 'userB',
            'score': 85.5,
          }
        ],
        'userASelectedRecordId': 'record123',
        'userAChoice': 1,
        'otherUserId': 'userB',
        'otherUserSelectedRecordId': 'recordA',
        'otherUserChoice': 1,
        'status': 4,
        'confidence': 1,
        'matchScore': 85.5,
        'matchedAt': '2026-02-12T10:00:00.000',
        'notifiedAt': '2026-02-12T16:00:00.000',
        'isPermanentlyKeptInMemory': false,
        'verifiedAt': '2026-02-12T17:00:00.000',
        'expiredAt': '2026-02-19T10:00:00.000',
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final match = Match.fromJson(json);

      expect(match.status, MatchStatus.verified);
      expect(match.userASelectedRecordId, 'record123');
      expect(match.userAChoice, VerificationChoice.wantContact);
      expect(match.otherUserId, 'userB');
      expect(match.otherUserSelectedRecordId, 'recordA');
      expect(match.otherUserChoice, VerificationChoice.wantContact);
      expect(match.verifiedAt, DateTime(2026, 2, 12, 17, 0, 0));
      expect(match.expiredAt, DateTime(2026, 2, 19, 10, 0, 0));
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();
      final candidates = [
        CandidateRecord(
          recordId: 'record123',
          userId: 'userB',
          score: 85.5,
        ),
      ];

      final original = Match(
        id: 'match001',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        userASelectedRecordId: 'record123',
        userAChoice: VerificationChoice.wantContact,
        otherUserId: 'userB',
        otherUserSelectedRecordId: 'recordA',
        otherUserChoice: VerificationChoice.wantContact,
        status: MatchStatus.verified,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        notifiedAt: now.add(Duration(hours: 6)),
        isPermanentlyKeptInMemory: false,
        verifiedAt: now.add(Duration(hours: 7)),
        expiredAt: now.add(Duration(days: 7)),
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = Match.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userAId, original.userAId);
      expect(restored.recordAId, original.recordAId);
      expect(restored.candidateRecords.length, original.candidateRecords.length);
      expect(restored.status, original.status);
      expect(restored.confidence, original.confidence);
      expect(restored.userAChoice, original.userAChoice);
      expect(restored.otherUserChoice, original.otherUserChoice);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();
      final candidates = [
        CandidateRecord(
          recordId: 'record123',
          userId: 'userB',
          score: 85.5,
        ),
      ];

      final original = Match(
        id: 'match001',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        status: MatchStatus.pending,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        isPermanentlyKeptInMemory: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        status: MatchStatus.notified,
        notifiedAt: now.add(Duration(hours: 6)),
      );

      expect(updated.id, original.id);
      expect(updated.status, MatchStatus.notified);
      expect(updated.notifiedAt, isNotNull);
    });

    test('相等性比较', () {
      final now = DateTime.now();
      final candidates = [
        CandidateRecord(
          recordId: 'record123',
          userId: 'userB',
          score: 85.5,
        ),
      ];

      final match1 = Match(
        id: 'match001',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        status: MatchStatus.pending,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        isPermanentlyKeptInMemory: false,
        createdAt: now,
        updatedAt: now,
      );

      final match2 = Match(
        id: 'match001',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        status: MatchStatus.pending,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        isPermanentlyKeptInMemory: false,
        createdAt: now,
        updatedAt: now,
      );

      final match3 = Match(
        id: 'match002',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        status: MatchStatus.pending,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        isPermanentlyKeptInMemory: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(match1 == match2, true);
      expect(match1 == match3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();
      final candidates = [
        CandidateRecord(
          recordId: 'record123',
          userId: 'userB',
          score: 85.5,
        ),
      ];

      final match = Match(
        id: 'match001',
        userAId: 'userA',
        recordAId: 'recordA',
        candidateRecords: candidates,
        status: MatchStatus.pending,
        confidence: MatchConfidence.high,
        matchScore: 85.5,
        matchedAt: now,
        isPermanentlyKeptInMemory: false,
        createdAt: now,
        updatedAt: now,
      );

      final str = match.toString();

      expect(str.contains('match001'), true);
      expect(str.contains('userA'), true);
      expect(str.contains('pending'), true);
      expect(str.contains('high'), true);
    });
  });
}

