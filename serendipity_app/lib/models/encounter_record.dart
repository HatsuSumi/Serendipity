import 'package:hive/hive.dart';
import 'enums.dart';
import '../core/utils/json_helper.dart';

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
       assert(tag is String, 'Field "tag.tag" expected String but got ${tag.runtimeType} ($tag)'),
       assert(note == null || note is String,
         'Field "tag.note" expected String? but got ${note.runtimeType} ($note)'),
       assert(note == null || note.length <= 50, 
         'Note must be at most 50 characters, got ${note.length}');

  Map<String, dynamic> toJson() {
    try {
      final json = <String, dynamic>{
        'tag': JsonHelper.validateField('tag.tag', tag, String),
      };
      
      // 只添加非空的 note
      if (note != null && note!.isNotEmpty) {
        json['note'] = JsonHelper.validateField('tag.note', note, String);
      }
      
      return json;
    } catch (e) {
      throw FormatException('TagWithNote.toJson() failed: $e');
    }
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
  }) : assert(address == null || address is String,
         'Field "location.address" expected String? but got ${address.runtimeType} ($address)'),
       assert(placeName == null || placeName is String,
         'Field "location.placeName" expected String? but got ${placeName.runtimeType} ($placeName)');

  Map<String, dynamic> toJson() {
    try {
      final json = <String, dynamic>{};
      
      // 只添加非空字段（带类型验证）
      if (latitude != null) {
        json['latitude'] = latitude;
      }
      if (longitude != null) {
        json['longitude'] = longitude;
      }
      if (address != null && address!.isNotEmpty) {
        json['address'] = JsonHelper.validateField('location.address', address, String);
      }
      if (placeName != null && placeName!.isNotEmpty) {
        json['placeName'] = JsonHelper.validateField('location.placeName', placeName, String);
      }
      if (placeType != null) {
        final placeTypeValue = placeType!.value;
        json['placeType'] = JsonHelper.validateField('location.placeType', placeTypeValue, String);
      }
      
      return json;
    } catch (e) {
      throw FormatException('Location.toJson() failed: $e');
    }
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
  @HiveField(15)
  final String? ownerId; // 数据归属用户ID，null 表示离线创建未绑定账号

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
    this.ownerId,
  }) : assert(id.isNotEmpty, 'ID cannot be empty'),
       assert(id is String, 'Field "id" expected String but got ${id.runtimeType} ($id)'),
       assert(description == null || description is String, 
         'Field "description" expected String? but got ${description.runtimeType} ($description)'),
       assert(description == null || description.length <= 500, 
         'Description must be at most 500 characters, got ${description.length}'),
       assert(storyLineId == null || storyLineId is String,
         'Field "storyLineId" expected String? but got ${storyLineId.runtimeType} ($storyLineId)'),
       assert(ifReencounter == null || ifReencounter is String,
         'Field "ifReencounter" expected String? but got ${ifReencounter.runtimeType} ($ifReencounter)'),
       assert(conversationStarter == null || conversationStarter is String,
         'Field "conversationStarter" expected String? but got ${conversationStarter.runtimeType} ($conversationStarter)'),
       assert(conversationStarter == null || conversationStarter.length <= 500, 
         'ConversationStarter must be at most 500 characters, got ${conversationStarter.length}'),
       assert(backgroundMusic == null || backgroundMusic is String,
         'Field "backgroundMusic" expected String? but got ${backgroundMusic.runtimeType} ($backgroundMusic)'),
       assert(ownerId == null || ownerId is String,
         'Field "ownerId" expected String? but got ${ownerId.runtimeType} ($ownerId)');

  Map<String, dynamic> toJson() {
    try {
      // 构建基础 JSON（带类型验证）
      final json = <String, dynamic>{
        'id': JsonHelper.validateField('id', id, String),
        'timestamp': JsonHelper.validateField('timestamp', timestamp.toIso8601String(), String),
        'location': location.toJson(),
        'tags': tags.map((t) => t.toJson()).toList(),
        'status': JsonHelper.validateField('status', status.name, String),
        'weather': weather.map((w) => w.value.toString()).toList(),
        'createdAt': JsonHelper.validateField('createdAt', createdAt.toIso8601String(), String),
        'updatedAt': JsonHelper.validateField('updatedAt', updatedAt.toIso8601String(), String),
        'isPinned': JsonHelper.validateField('isPinned', isPinned, bool),
      };
      
      // 只添加非空的可选字段（带类型验证）
      if (description != null && description!.isNotEmpty) {
        json['description'] = JsonHelper.validateField('description', description, String);
      }
      if (emotion != null) {
        json['emotion'] = JsonHelper.validateField('emotion', emotion!.name, String);
      }
      if (storyLineId != null && storyLineId!.isNotEmpty) {
        json['storyLineId'] = JsonHelper.validateField('storyLineId', storyLineId, String);
      }
      if (ifReencounter != null && ifReencounter!.isNotEmpty) {
        json['ifReencounter'] = JsonHelper.validateField('ifReencounter', ifReencounter, String);
      }
      if (conversationStarter != null && conversationStarter!.isNotEmpty) {
        json['conversationStarter'] = JsonHelper.validateField('conversationStarter', conversationStarter, String);
      }
      if (backgroundMusic != null && backgroundMusic!.isNotEmpty) {
        json['backgroundMusic'] = JsonHelper.validateField('backgroundMusic', backgroundMusic, String);
      }
      if (ownerId != null) {
        json['ownerId'] = JsonHelper.validateField('ownerId', ownerId, String);
      }
      
      return json;
    } catch (e) {
      // 重新抛出，带上更多上下文信息
      throw FormatException('EncounterRecord.toJson() failed: $e');
    }
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
              (e) => e.name == json['emotion'],
              orElse: () => throw StateError(
                'Invalid emotion value: ${json['emotion']}. '
                'Expected one of: ${EmotionIntensity.values.map((e) => e.name).join(", ")}'
              ),
            )
          : null,
      status: EncounterStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => throw StateError(
          'Invalid status value: ${json['status']}. '
          'Expected one of: ${EncounterStatus.values.map((e) => e.name).join(", ")}'
        ),
      ),
      storyLineId: json['storyLineId'] as String?,
      ifReencounter: json['ifReencounter'] as String?,
      conversationStarter: json['conversationStarter'] as String?,
      backgroundMusic: json['backgroundMusic'] as String?,
      weather: json['weather'] != null
          ? (json['weather'] as List)
              .map((w) {
                // 处理字符串和整数两种格式
                final value = w is String ? int.parse(w) : w as int;
                return Weather.values.firstWhere(
                  (e) => e.value == value,
                  orElse: () => throw StateError(
                    'Invalid weather value: $w. '
                    'Expected one of: ${Weather.values.map((e) => e.value).join(", ")}'
                  ),
                );
              })
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      ownerId: json['ownerId'] as String?,
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
    String? Function()? ownerId,
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
      ownerId: ownerId != null ? ownerId() : this.ownerId,
    );
  }
}

