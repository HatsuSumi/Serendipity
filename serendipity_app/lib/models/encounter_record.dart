import 'enums.dart';

/// 标签 + 备注
class TagWithNote {
  final String tag;
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
class Location {
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? placeName; // 用户手动输入，可选
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
class EncounterRecord {
  final String id;
  final DateTime timestamp;
  final Location location;
  final String? description; // 可选，最多500字
  final List<TagWithNote> tags;
  final EmotionIntensity? emotion; // 可选
  final EncounterStatus status;
  final String? storyLineId; // 所属故事线ID，可选
  final String? ifReencounter; // "如果再遇"备忘，可选
  final String? conversationStarter; // 对话契机（仅邂逅状态），可选，最多500字
  final String? backgroundMusic; // 背景音乐，可选
  final Weather? weather; // 天气信息，可选
  final DateTime createdAt;
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
    this.weather,
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
      'weather': weather?.value,
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
          ? Weather.values.firstWhere((e) => e.value == json['weather'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

