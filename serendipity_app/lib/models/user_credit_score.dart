import 'enums.dart';

/// 信用分变更记录
class CreditChange {
  final CreditChangeReason reason;
  final int delta;
  final int scoreBefore;
  final int scoreAfter;
  final String? relatedId;
  final DateTime changedAt;

  CreditChange({
    required this.reason,
    required this.delta,
    required this.scoreBefore,
    required this.scoreAfter,
    this.relatedId,
    required this.changedAt,
  });

  /// 从 JSON 创建 CreditChange
  factory CreditChange.fromJson(Map<String, dynamic> json) {
    return CreditChange(
      reason: CreditChangeReason.values
          .firstWhere((e) => e.value == json['reason'] as int),
      delta: json['delta'] as int,
      scoreBefore: json['scoreBefore'] as int,
      scoreAfter: json['scoreAfter'] as int,
      relatedId: json['relatedId'] as String?,
      changedAt: DateTime.parse(json['changedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'reason': reason.value,
      'delta': delta,
      'scoreBefore': scoreBefore,
      'scoreAfter': scoreAfter,
      'relatedId': relatedId,
      'changedAt': changedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  CreditChange copyWith({
    CreditChangeReason? reason,
    int? delta,
    int? scoreBefore,
    int? scoreAfter,
    String? relatedId,
    DateTime? changedAt,
  }) {
    return CreditChange(
      reason: reason ?? this.reason,
      delta: delta ?? this.delta,
      scoreBefore: scoreBefore ?? this.scoreBefore,
      scoreAfter: scoreAfter ?? this.scoreAfter,
      relatedId: relatedId ?? this.relatedId,
      changedAt: changedAt ?? this.changedAt,
    );
  }

  @override
  String toString() {
    return 'CreditChange(reason: ${reason.label}, delta: $delta, scoreAfter: $scoreAfter)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CreditChange &&
        other.reason == reason &&
        other.delta == delta &&
        other.scoreBefore == scoreBefore &&
        other.scoreAfter == scoreAfter &&
        other.relatedId == relatedId &&
        other.changedAt == changedAt;
  }

  @override
  int get hashCode {
    return reason.hashCode ^
        delta.hashCode ^
        scoreBefore.hashCode ^
        scoreAfter.hashCode ^
        relatedId.hashCode ^
        changedAt.hashCode;
  }
}

/// 用户信用分
class UserCreditScore {
  final String id;
  final String userId;
  final int score;
  final List<CreditChange> history;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserCreditScore({
    required this.id,
    required this.userId,
    required this.score,
    required this.history,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建 UserCreditScore
  factory UserCreditScore.fromJson(Map<String, dynamic> json) {
    return UserCreditScore(
      id: json['id'] as String,
      userId: json['userId'] as String,
      score: json['score'] as int,
      history: (json['history'] as List)
          .map((e) => CreditChange.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'score': score,
      'history': history.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  UserCreditScore copyWith({
    String? id,
    String? userId,
    int? score,
    List<CreditChange>? history,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserCreditScore(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserCreditScore(id: $id, score: $score, historyCount: ${history.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserCreditScore &&
        other.id == id &&
        other.userId == userId &&
        other.score == score &&
        other.history.length == history.length &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        score.hashCode ^
        history.length.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

