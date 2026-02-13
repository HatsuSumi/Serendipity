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
  });

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
          ? PlaceType.values.firstWhere((e) => e.value == json['placeType'])
          : null,
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
  });

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
          ? EmotionIntensity.values.firstWhere((e) => e.value == json['emotion'])
          : null,
      status: EncounterStatus.values.firstWhere((e) => e.value == json['status']),
      storyLineId: json['storyLineId'] as String?,
      ifReencounter: json['ifReencounter'] as String?,
      conversationStarter: json['conversationStarter'] as String?,
      backgroundMusic: json['backgroundMusic'] as String?,
      weather: json['weather'] != null
          ? (json['weather'] as List)
              .map((w) => Weather.values.firstWhere((e) => e.value == w))
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

