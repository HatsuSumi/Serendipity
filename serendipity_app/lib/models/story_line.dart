import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'story_line.g.dart';

/// StoryLine（故事线）数据模型
///
/// 用于将多条记录组合成一个完整的故事线
/// 一个故事线 = 同一个人的多次记录
@HiveType(typeId: 3)
class StoryLine {
  /// 故事线ID（唯一标识）
  @HiveField(0)
  final String id;

  /// 故事线名称（用户自定义）
  /// 例如："地铁上的她"、"咖啡馆的他"
  @HiveField(1)
  final String name;

  /// 包含的记录ID列表（按时间排序）
  @HiveField(2)
  final List<String> recordIds;

  /// 创建时间
  @HiveField(3)
  final DateTime createdAt;

  /// 最后更新时间
  @HiveField(4)
  final DateTime updatedAt;

  /// 是否置顶
  @HiveField(5)
  final bool isPinned;

  /// 数据归属用户ID，null 表示离线创建未绑定账号
  @HiveField(6)
  final String? userId;

  @HiveField(7)
  final String? sourceDeviceId;

  @HiveField(8)
  final DateTime? deletedAt;

  const StoryLine({
    required this.id,
    required this.name,
    required this.recordIds,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.userId,
    this.sourceDeviceId,
    this.deletedAt,
  }) : assert(id != '', 'ID cannot be empty'),
       assert(name != '', 'Name cannot be empty');

  /// 从 JSON 创建 StoryLine 对象
  factory StoryLine.fromJson(Map<String, dynamic> json) {
    return StoryLine(
      id: json['id'] as String,
      name: json['name'] as String,
      recordIds: (json['recordIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      userId: json['userId'] as String?,
      sourceDeviceId: json['sourceDeviceId'] as String?,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'recordIds': recordIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'userId': userId,
      'sourceDeviceId': sourceDeviceId,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  StoryLine copyWith({
    String? id,
    String? name,
    List<String>? recordIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    String? Function()? userId,
    String? sourceDeviceId,
    DateTime? Function()? deletedAt,
  }) {
    return StoryLine(
      id: id ?? this.id,
      name: name ?? this.name,
      recordIds: recordIds ?? this.recordIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      userId: userId != null ? userId() : this.userId,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'StoryLine(id: $id, name: $name, recordCount: ${recordIds.length}, '
        'createdAt: $createdAt, updatedAt: $updatedAt, sourceDeviceId: $sourceDeviceId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StoryLine &&
        other.id == id &&
        other.name == name &&
        listEquals(other.recordIds, recordIds) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isPinned == isPinned &&
        other.userId == userId &&
        other.sourceDeviceId == sourceDeviceId &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        recordIds.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isPinned.hashCode ^
        userId.hashCode ^
        sourceDeviceId.hashCode ^
        deletedAt.hashCode;
  }
}

