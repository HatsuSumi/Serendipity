import 'enums.dart';

/// 候选记录
class CandidateRecord {
  final String recordId;
  final String userId;
  final double score;

  CandidateRecord({
    required this.recordId,
    required this.userId,
    required this.score,
  });

  /// 从 JSON 创建 CandidateRecord
  factory CandidateRecord.fromJson(Map<String, dynamic> json) {
    return CandidateRecord(
      recordId: json['recordId'] as String,
      userId: json['userId'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'userId': userId,
      'score': score,
    };
  }

  /// 复制并修改部分字段
  CandidateRecord copyWith({
    String? recordId,
    String? userId,
    double? score,
  }) {
    return CandidateRecord(
      recordId: recordId ?? this.recordId,
      userId: userId ?? this.userId,
      score: score ?? this.score,
    );
  }

  @override
  String toString() {
    return 'CandidateRecord(recordId: $recordId, userId: $userId, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CandidateRecord &&
        other.recordId == recordId &&
        other.userId == userId &&
        other.score == score;
  }

  @override
  int get hashCode {
    return recordId.hashCode ^ userId.hashCode ^ score.hashCode;
  }
}

/// 匹配记录
class Match {
  final String id;
  final String userAId;
  final String recordAId;
  final List<CandidateRecord> candidateRecords;
  final String? userASelectedRecordId;
  final VerificationChoice? userAChoice;
  final String? otherUserId;
  final String? otherUserSelectedRecordId;
  final VerificationChoice? otherUserChoice;
  final MatchStatus status;
  final MatchConfidence confidence;
  final double matchScore;
  final DateTime matchedAt;
  final DateTime? notifiedAt;
  final bool isPermanentlyKeptInMemory;
  final DateTime? verifiedAt;
  final DateTime? expiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Match({
    required this.id,
    required this.userAId,
    required this.recordAId,
    required this.candidateRecords,
    this.userASelectedRecordId,
    this.userAChoice,
    this.otherUserId,
    this.otherUserSelectedRecordId,
    this.otherUserChoice,
    required this.status,
    required this.confidence,
    required this.matchScore,
    required this.matchedAt,
    this.notifiedAt,
    required this.isPermanentlyKeptInMemory,
    this.verifiedAt,
    this.expiredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建 Match
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      userAId: json['userAId'] as String,
      recordAId: json['recordAId'] as String,
      candidateRecords: (json['candidateRecords'] as List)
          .map((e) => CandidateRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      userASelectedRecordId: json['userASelectedRecordId'] as String?,
      userAChoice: json['userAChoice'] != null
          ? VerificationChoice.values.firstWhere(
              (e) => e.value == json['userAChoice'] as int)
          : null,
      otherUserId: json['otherUserId'] as String?,
      otherUserSelectedRecordId: json['otherUserSelectedRecordId'] as String?,
      otherUserChoice: json['otherUserChoice'] != null
          ? VerificationChoice.values.firstWhere(
              (e) => e.value == json['otherUserChoice'] as int)
          : null,
      status: MatchStatus.values
          .firstWhere((e) => e.value == json['status'] as int),
      confidence: MatchConfidence.values
          .firstWhere((e) => e.value == json['confidence'] as int),
      matchScore: (json['matchScore'] as num).toDouble(),
      matchedAt: DateTime.parse(json['matchedAt'] as String),
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.parse(json['notifiedAt'] as String)
          : null,
      isPermanentlyKeptInMemory:
          json['isPermanentlyKeptInMemory'] as bool,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      expiredAt: json['expiredAt'] != null
          ? DateTime.parse(json['expiredAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userAId': userAId,
      'recordAId': recordAId,
      'candidateRecords': candidateRecords.map((e) => e.toJson()).toList(),
      'userASelectedRecordId': userASelectedRecordId,
      'userAChoice': userAChoice?.value,
      'otherUserId': otherUserId,
      'otherUserSelectedRecordId': otherUserSelectedRecordId,
      'otherUserChoice': otherUserChoice?.value,
      'status': status.value,
      'confidence': confidence.value,
      'matchScore': matchScore,
      'matchedAt': matchedAt.toIso8601String(),
      'notifiedAt': notifiedAt?.toIso8601String(),
      'isPermanentlyKeptInMemory': isPermanentlyKeptInMemory,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'expiredAt': expiredAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  Match copyWith({
    String? id,
    String? userAId,
    String? recordAId,
    List<CandidateRecord>? candidateRecords,
    String? userASelectedRecordId,
    VerificationChoice? userAChoice,
    String? otherUserId,
    String? otherUserSelectedRecordId,
    VerificationChoice? otherUserChoice,
    MatchStatus? status,
    MatchConfidence? confidence,
    double? matchScore,
    DateTime? matchedAt,
    DateTime? notifiedAt,
    bool? isPermanentlyKeptInMemory,
    DateTime? verifiedAt,
    DateTime? expiredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      userAId: userAId ?? this.userAId,
      recordAId: recordAId ?? this.recordAId,
      candidateRecords: candidateRecords ?? this.candidateRecords,
      userASelectedRecordId:
          userASelectedRecordId ?? this.userASelectedRecordId,
      userAChoice: userAChoice ?? this.userAChoice,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserSelectedRecordId:
          otherUserSelectedRecordId ?? this.otherUserSelectedRecordId,
      otherUserChoice: otherUserChoice ?? this.otherUserChoice,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      matchScore: matchScore ?? this.matchScore,
      matchedAt: matchedAt ?? this.matchedAt,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      isPermanentlyKeptInMemory:
          isPermanentlyKeptInMemory ?? this.isPermanentlyKeptInMemory,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Match(id: $id, userAId: $userAId, status: $status, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Match &&
        other.id == id &&
        other.userAId == userAId &&
        other.recordAId == recordAId &&
        other.candidateRecords.length == candidateRecords.length &&
        other.userASelectedRecordId == userASelectedRecordId &&
        other.userAChoice == userAChoice &&
        other.otherUserId == otherUserId &&
        other.otherUserSelectedRecordId == otherUserSelectedRecordId &&
        other.otherUserChoice == otherUserChoice &&
        other.status == status &&
        other.confidence == confidence &&
        other.matchScore == matchScore &&
        other.matchedAt == matchedAt &&
        other.notifiedAt == notifiedAt &&
        other.isPermanentlyKeptInMemory == isPermanentlyKeptInMemory &&
        other.verifiedAt == verifiedAt &&
        other.expiredAt == expiredAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userAId.hashCode ^
        recordAId.hashCode ^
        candidateRecords.length.hashCode ^
        userASelectedRecordId.hashCode ^
        userAChoice.hashCode ^
        otherUserId.hashCode ^
        otherUserSelectedRecordId.hashCode ^
        otherUserChoice.hashCode ^
        status.hashCode ^
        confidence.hashCode ^
        matchScore.hashCode ^
        matchedAt.hashCode ^
        notifiedAt.hashCode ^
        isPermanentlyKeptInMemory.hashCode ^
        verifiedAt.hashCode ^
        expiredAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

