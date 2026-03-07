import 'enums.dart';
import '../core/utils/iterable_extensions.dart';

/// 会员状态
class Membership {
  final String id;
  final String userId;
  final MembershipTier tier;
  final MembershipStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Membership({
    required this.id,
    required this.userId,
    required this.tier,
    required this.status,
    this.startedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建 Membership
  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tier: MembershipTier.values.firstWhereOrThrow(
        (e) => e.value == json['tier'] as int,
        message: 'Membership.fromJson: MembershipTier with value=${json['tier']} not found. '
            'Available values: ${MembershipTier.values.map((e) => e.value).join(", ")}',
      ),
      status: MembershipStatus.values.firstWhereOrThrow(
        (e) => e.value == json['status'] as int,
        message: 'Membership.fromJson: MembershipStatus with value=${json['status']} not found. '
            'Available values: ${MembershipStatus.values.map((e) => e.value).join(", ")}',
      ),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tier': tier.value,
      'status': status.value,
      'startedAt': startedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  Membership copyWith({
    String? id,
    String? userId,
    MembershipTier? tier,
    MembershipStatus? status,
    DateTime? startedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Membership(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Membership(id: $id, tier: ${tier.label}, status: ${status.label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Membership &&
        other.id == id &&
        other.userId == userId &&
        other.tier == tier &&
        other.status == status &&
        other.startedAt == startedAt &&
        other.expiresAt == expiresAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        tier.hashCode ^
        status.hashCode ^
        startedAt.hashCode ^
        expiresAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

