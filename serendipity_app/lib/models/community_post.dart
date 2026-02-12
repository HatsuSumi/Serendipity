import 'enums.dart';
import 'encounter_record.dart';

/// 社区帖子/树洞
class CommunityPost {
  final String id;
  final String userId;
  final String recordId;
  final DateTime timestamp;
  final String? address;
  final String? placeName;
  final PlaceType? placeType;
  final String? cityName;
  final String description;
  final List<TagWithNote> tags;
  final EncounterStatus status;
  final bool isAnonymous;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.recordId,
    required this.timestamp,
    this.address,
    this.placeName,
    this.placeType,
    this.cityName,
    required this.description,
    required this.tags,
    required this.status,
    required this.isAnonymous,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建 CommunityPost
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      userId: json['userId'] as String,
      recordId: json['recordId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String?,
      placeName: json['placeName'] as String?,
      placeType: json['placeType'] != null
          ? PlaceType.values.firstWhere(
              (e) => e.value == json['placeType'] as String)
          : null,
      cityName: json['cityName'] as String?,
      description: json['description'] as String,
      tags: (json['tags'] as List)
          .map((e) => TagWithNote.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: EncounterStatus.values
          .firstWhere((e) => e.value == json['status'] as int),
      isAnonymous: json['isAnonymous'] as bool,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recordId': recordId,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'placeName': placeName,
      'placeType': placeType?.value,
      'cityName': cityName,
      'description': description,
      'tags': tags.map((e) => e.toJson()).toList(),
      'status': status.value,
      'isAnonymous': isAnonymous,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  CommunityPost copyWith({
    String? id,
    String? userId,
    String? recordId,
    DateTime? timestamp,
    String? address,
    String? placeName,
    PlaceType? placeType,
    String? cityName,
    String? description,
    List<TagWithNote>? tags,
    EncounterStatus? status,
    bool? isAnonymous,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recordId: recordId ?? this.recordId,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      placeName: placeName ?? this.placeName,
      placeType: placeType ?? this.placeType,
      cityName: cityName ?? this.cityName,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CommunityPost(id: $id, status: $status, isAnonymous: $isAnonymous)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CommunityPost &&
        other.id == id &&
        other.userId == userId &&
        other.recordId == recordId &&
        other.timestamp == timestamp &&
        other.address == address &&
        other.placeName == placeName &&
        other.placeType == placeType &&
        other.cityName == cityName &&
        other.description == description &&
        other.tags.length == tags.length &&
        other.status == status &&
        other.isAnonymous == isAnonymous &&
        other.publishedAt == publishedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        recordId.hashCode ^
        timestamp.hashCode ^
        address.hashCode ^
        placeName.hashCode ^
        placeType.hashCode ^
        cityName.hashCode ^
        description.hashCode ^
        tags.length.hashCode ^
        status.hashCode ^
        isAnonymous.hashCode ^
        publishedAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

