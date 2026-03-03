import 'enums.dart';
import 'encounter_record.dart';
import '../core/utils/iterable_extensions.dart';

/// 社区帖子/树洞
/// 
/// 注意：后端不返回 userId 字段（隐私保护）
/// - 使用 isOwner 字段判断是否可以删除
/// - 所有帖子都是匿名的
class CommunityPost {
  final String id;
  final String recordId;
  final DateTime timestamp;
  final String? address;
  final String? placeName;
  final PlaceType? placeType;
  final String? province;  // 省份（如"广东省"）
  final String? city;      // 城市（如"深圳市"）
  final String? area;      // 区县（如"南山区"）
  final String? description;
  final List<TagWithNote> tags;
  final EncounterStatus status;
  final bool isOwner;      // 是否是当前用户的帖子
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPost({
    required this.id,
    required this.recordId,
    required this.timestamp,
    this.address,
    this.placeName,
    this.placeType,
    this.province,
    this.city,
    this.area,
    this.description,
    required this.tags,
    required this.status,
    this.isOwner = false,  // 默认不是自己的
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建 CommunityPost
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      recordId: json['recordId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String?,
      placeName: json['placeName'] as String?,
      placeType: json['placeType'] != null
          ? PlaceType.values.firstWhereOrThrow(
              (e) => e.value == json['placeType'] as String,
              message: 'CommunityPost.fromJson: PlaceType with value="${json['placeType']}" not found. '
                  'Available values: ${PlaceType.values.map((e) => e.value).join(", ")}',
            )
          : null,
      province: json['province'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      description: json['description'] as String?,
      tags: (json['tags'] as List)
          .map((e) => TagWithNote.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: EncounterStatus.values.firstWhereOrThrow(
        (e) => e.name == json['status'] as String,
        message: 'CommunityPost.fromJson: EncounterStatus with name="${json['status']}" not found. '
            'Available names: ${EncounterStatus.values.map((e) => e.name).join(", ")}',
      ),
      isOwner: json['isOwner'] as bool? ?? false,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recordId': recordId,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'placeName': placeName,
      'placeType': placeType?.value,
      'province': province,
      'city': city,
      'area': area,
      'description': description,
      'tags': tags.map((e) => e.toJson()).toList(),
      'status': status.name,
      'isOwner': isOwner,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  CommunityPost copyWith({
    String? id,
    String? recordId,
    DateTime? timestamp,
    String? address,
    String? placeName,
    PlaceType? placeType,
    String? province,
    String? city,
    String? area,
    String? description,
    List<TagWithNote>? tags,
    EncounterStatus? status,
    bool? isOwner,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      placeName: placeName ?? this.placeName,
      placeType: placeType ?? this.placeType,
      province: province ?? this.province,
      city: city ?? this.city,
      area: area ?? this.area,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      isOwner: isOwner ?? this.isOwner,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CommunityPost(id: $id, status: $status, isOwner: $isOwner)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CommunityPost &&
        other.id == id &&
        other.recordId == recordId &&
        other.timestamp == timestamp &&
        other.address == address &&
        other.placeName == placeName &&
        other.placeType == placeType &&
        other.province == province &&
        other.city == city &&
        other.area == area &&
        other.description == description &&
        other.tags.length == tags.length &&
        other.status == status &&
        other.isOwner == isOwner &&
        other.publishedAt == publishedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        recordId.hashCode ^
        timestamp.hashCode ^
        address.hashCode ^
        placeName.hashCode ^
        placeType.hashCode ^
        province.hashCode ^
        city.hashCode ^
        area.hashCode ^
        description.hashCode ^
        tags.length.hashCode ^
        status.hashCode ^
        isOwner.hashCode ^
        publishedAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

