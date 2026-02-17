import 'package:hive/hive.dart';
import 'enums.dart';

part 'encounter_record.g.dart';

/// 标签 + 备注
@HiveType(typeId: 0)
class TagWithNote {
  @HiveField(0)
  final String tag;
  @HiveField(1)
  final String? note; // 可选，最多50字

  TagWithNote({
    required this.tag,
    this.note,
  }) : assert(tag.isNotEmpty, 'Tag cannot be empty'),
       assert(note == null || note.length <= 50, 
         'Note must be at most 50 characters, got ${note?.length}');

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'note': note,
    };
  }

  factory TagWithNote.fromJson(Map<String, dynamic> json) {
    return TagWithNote(
      tag: json['tag'] as String,
      note: json['note'] as String?,
    );
  }
}

/// 地点
@HiveType(typeId: 1)
class Location {
  @HiveField(0)
  final double? latitude;
  @HiveField(1)
  final double? longitude;
  @HiveField(2)
  final String? address;
  @HiveField(3)
  final String? placeName; // 用户手动输入，可选
  @HiveField(4)
  final PlaceType? placeType; // 场所类型，可选

  Location({
    this.latitude,
    this.longitude,
    this.address,
    this.placeName,
    this.placeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeName': placeName,
      'placeType': placeType?.value,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      address: json['address'] as String?,
      placeName: json['placeName'] as String?,
      placeType: json['placeType'] != null
          ? PlaceType.values.firstWhere(
              (e) => e.value == json['placeType'],
              orElse: () => throw StateError(
                'Invalid placeType value: ${json['placeType']}. '
                'Expected one of: ${PlaceType.values.map((e) => e.value).join(", ")}'
              ),
            )
          : null,
    );
  }

  /// 复制并修改部分字段
  /// 
  /// 对于可空字段，使用函数包装来区分"未传递"和"传递 null"
  Location copyWith({
    double? Function()? latitude,
    double? Function()? longitude,
    String? Function()? address,
    String? Function()? placeName,
    PlaceType? Function()? placeType,
  }) {
    return Location(
      latitude: latitude != null ? latitude() : this.latitude,
      longitude: longitude != null ? longitude() : this.longitude,
      address: address != null ? address() : this.address,
      placeName: placeName != null ? placeName() : this.placeName,
      placeType: placeType != null ? placeType() : this.placeType,
    );
  }
}

/// 记录
@HiveType(typeId: 2)
class EncounterRecord {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime timestamp;
  @HiveField(2)
  final Location location;
  @HiveField(3)
  final String? description; // 可选，最多500字
  @HiveField(4)
  final List<TagWithNote> tags;
  @HiveField(5)
  final EmotionIntensity? emotion; // 可选
  @HiveField(6)
  final EncounterStatus status;
  @HiveField(7)
  final String? storyLineId; // 所属故事线ID，可选
  @HiveField(8)
  final String? ifReencounter; // "如果再遇"备忘，可选
  @HiveField(9)
  final String? conversationStarter; // 对话契机（仅邂逅状态），可选，最多500字
  @HiveField(10)
  final String? backgroundMusic; // 背景音乐，可选
  @HiveField(11)
  final List<Weather> weather; // 天气信息，可选（支持多选）
  @HiveField(12)
  final DateTime createdAt;
  @HiveField(13)
  final DateTime updatedAt;
  @HiveField(14)
  final bool isPinned; // 是否置顶

  EncounterRecord({
    required this.id,
    required this.timestamp,
    required this.location,
    this.description,
    required this.tags,
    this.emotion,
    required this.status,
    this.storyLineId,
    this.ifReencounter,
    this.conversationStarter,
    this.backgroundMusic,
    this.weather = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  }) : assert(id.isNotEmpty, 'ID cannot be empty'),
       assert(description == null || description.length <= 500, 
         'Description must be at most 500 characters, got ${description?.length}'),
       assert(conversationStarter == null || conversationStarter.length <= 500, 
         'ConversationStarter must be at most 500 characters, got ${conversationStarter?.length}');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'location': location.toJson(),
      'description': description,
      'tags': tags.map((t) => t.toJson()).toList(),
      'emotion': emotion?.value,
      'status': status.value,
      'storyLineId': storyLineId,
      'ifReencounter': ifReencounter,
      'conversationStarter': conversationStarter,
      'backgroundMusic': backgroundMusic,
      'weather': weather.map((w) => w.value).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }

  factory EncounterRecord.fromJson(Map<String, dynamic> json) {
    return EncounterRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      description: json['description'] as String?,
      tags: (json['tags'] as List)
          .map((t) => TagWithNote.fromJson(t as Map<String, dynamic>))
          .toList(),
      emotion: json['emotion'] != null
          ? EmotionIntensity.values.firstWhere(
              (e) => e.value == json['emotion'],
              orElse: () => throw StateError(
                'Invalid emotion value: ${json['emotion']}. '
                'Expected one of: ${EmotionIntensity.values.map((e) => e.value).join(", ")}'
              ),
            )
          : null,
      status: EncounterStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => throw StateError(
          'Invalid status value: ${json['status']}. '
          'Expected one of: ${EncounterStatus.values.map((e) => e.value).join(", ")}'
        ),
      ),
      storyLineId: json['storyLineId'] as String?,
      ifReencounter: json['ifReencounter'] as String?,
      conversationStarter: json['conversationStarter'] as String?,
      backgroundMusic: json['backgroundMusic'] as String?,
      weather: json['weather'] != null
          ? (json['weather'] as List)
              .map((w) => Weather.values.firstWhere(
                (e) => e.value == w,
                orElse: () => throw StateError(
                  'Invalid weather value: $w. '
                  'Expected one of: ${Weather.values.map((e) => e.value).join(", ")}'
                ),
              ))
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  /// 复制并修改部分字段
  /// 
  /// 对于可空字段，使用函数包装来区分"未传递"和"传递 null"：
  /// - 不传参数：保持原值
  /// - 传递函数返回 null：清空字段
  /// - 传递函数返回新值：更新字段
  /// 
  /// 示例：
  /// ```dart
  /// // 清空描述
  /// record.copyWith(description: () => null)
  /// 
  /// // 修改描述
  /// record.copyWith(description: () => '新描述')
  /// 
  /// // 保持描述不变
  /// record.copyWith(status: EncounterStatus.met)
  /// ```
  EncounterRecord copyWith({
    String? id,
    DateTime? timestamp,
    Location? location,
    String? Function()? description,
    List<TagWithNote>? tags,
    EmotionIntensity? Function()? emotion,
    EncounterStatus? status,
    String? Function()? storyLineId,
    String? Function()? ifReencounter,
    String? Function()? conversationStarter,
    String? Function()? backgroundMusic,
    List<Weather>? weather,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return EncounterRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      description: description != null ? description() : this.description,
      tags: tags ?? this.tags,
      emotion: emotion != null ? emotion() : this.emotion,
      status: status ?? this.status,
      storyLineId: storyLineId != null ? storyLineId() : this.storyLineId,
      ifReencounter: ifReencounter != null ? ifReencounter() : this.ifReencounter,
      conversationStarter: conversationStarter != null ? conversationStarter() : this.conversationStarter,
      backgroundMusic: backgroundMusic != null ? backgroundMusic() : this.backgroundMusic,
      weather: weather ?? this.weather,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

