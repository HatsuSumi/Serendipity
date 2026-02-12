/// 留在记忆里列表
class KeepInMemoryList {
  final String id;
  final String userId;
  final String keptInMemoryUserId;
  final String matchId;
  final DateTime createdAt;

  KeepInMemoryList({
    required this.id,
    required this.userId,
    required this.keptInMemoryUserId,
    required this.matchId,
    required this.createdAt,
  });

  /// 从 JSON 创建 KeepInMemoryList
  factory KeepInMemoryList.fromJson(Map<String, dynamic> json) {
    return KeepInMemoryList(
      id: json['id'] as String,
      userId: json['userId'] as String,
      keptInMemoryUserId: json['keptInMemoryUserId'] as String,
      matchId: json['matchId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'keptInMemoryUserId': keptInMemoryUserId,
      'matchId': matchId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  KeepInMemoryList copyWith({
    String? id,
    String? userId,
    String? keptInMemoryUserId,
    String? matchId,
    DateTime? createdAt,
  }) {
    return KeepInMemoryList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      keptInMemoryUserId: keptInMemoryUserId ?? this.keptInMemoryUserId,
      matchId: matchId ?? this.matchId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'KeepInMemoryList(id: $id, userId: $userId, keptInMemoryUserId: $keptInMemoryUserId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KeepInMemoryList &&
        other.id == id &&
        other.userId == userId &&
        other.keptInMemoryUserId == keptInMemoryUserId &&
        other.matchId == matchId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        keptInMemoryUserId.hashCode ^
        matchId.hashCode ^
        createdAt.hashCode;
  }
}

