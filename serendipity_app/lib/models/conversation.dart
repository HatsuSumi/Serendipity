/// 对话
class Conversation {
  final String id;
  final String matchId;
  final String userAId;
  final String userBId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool isActive;
  final DateTime? endedAt;
  final String? endedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.matchId,
    required this.userAId,
    required this.userBId,
    required this.startedAt,
    required this.expiresAt,
    required this.isActive,
    this.endedAt,
    this.endedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建 Conversation
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      userAId: json['userAId'] as String,
      userBId: json['userBId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isActive: json['isActive'] as bool,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      endedBy: json['endedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'userAId': userAId,
      'userBId': userBId,
      'startedAt': startedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
      'endedAt': endedAt?.toIso8601String(),
      'endedBy': endedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  Conversation copyWith({
    String? id,
    String? matchId,
    String? userAId,
    String? userBId,
    DateTime? startedAt,
    DateTime? expiresAt,
    bool? isActive,
    DateTime? endedAt,
    String? endedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      userAId: userAId ?? this.userAId,
      userBId: userBId ?? this.userBId,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      endedAt: endedAt ?? this.endedAt,
      endedBy: endedBy ?? this.endedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, matchId: $matchId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Conversation &&
        other.id == id &&
        other.matchId == matchId &&
        other.userAId == userAId &&
        other.userBId == userBId &&
        other.startedAt == startedAt &&
        other.expiresAt == expiresAt &&
        other.isActive == isActive &&
        other.endedAt == endedAt &&
        other.endedBy == endedBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        matchId.hashCode ^
        userAId.hashCode ^
        userBId.hashCode ^
        startedAt.hashCode ^
        expiresAt.hashCode ^
        isActive.hashCode ^
        endedAt.hashCode ^
        endedBy.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

/// 私信消息
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime? readAt;
  final DateTime sentAt;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    this.readAt,
    required this.sentAt,
    required this.createdAt,
  });

  /// 从 JSON 创建 Message
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      isRead: json['isRead'] as bool,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      sentAt: DateTime.parse(json['sentAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'sentAt': sentAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    bool? isRead,
    DateTime? readAt,
    DateTime? sentAt,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.id == id &&
        other.conversationId == conversationId &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.content == content &&
        other.isRead == isRead &&
        other.readAt == readAt &&
        other.sentAt == sentAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        conversationId.hashCode ^
        senderId.hashCode ^
        receiverId.hashCode ^
        content.hashCode ^
        isRead.hashCode ^
        readAt.hashCode ^
        sentAt.hashCode ^
        createdAt.hashCode;
  }
}

