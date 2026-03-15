import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';

/// 记录筛选条件模型
/// 
/// 职责：存储记录筛选条件
/// 
/// 调用者：RecordFilterDialog、RecordsNotifier
class RecordsFilterCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdStartDate;
  final DateTime? createdEndDate;
  final String? province;
  final String? city;
  final String? area;
  final List<PlaceType>? placeTypes;
  final List<EncounterStatus>? statuses;
  final List<EmotionIntensity>? emotionIntensities;
  final List<Weather>? weathers;
  final List<String>? tags;
  final String? descriptionKeyword;
  final String? ifReencounterKeyword;
  final String? conversationStarterKeyword;
  final String? backgroundMusicKeyword;

  const RecordsFilterCriteria({
    this.startDate,
    this.endDate,
    this.createdStartDate,
    this.createdEndDate,
    this.province,
    this.city,
    this.area,
    this.placeTypes,
    this.statuses,
    this.emotionIntensities,
    this.weathers,
    this.tags,
    this.descriptionKeyword,
    this.ifReencounterKeyword,
    this.conversationStarterKeyword,
    this.backgroundMusicKeyword,
  });

  /// 是否有活跃的筛选条件
  bool get isActive {
    return startDate != null ||
        endDate != null ||
        createdStartDate != null ||
        createdEndDate != null ||
        province != null ||
        city != null ||
        area != null ||
        (placeTypes?.isNotEmpty ?? false) ||
        (statuses?.isNotEmpty ?? false) ||
        (emotionIntensities?.isNotEmpty ?? false) ||
        (weathers?.isNotEmpty ?? false) ||
        (tags?.isNotEmpty ?? false) ||
        (descriptionKeyword?.isNotEmpty ?? false) ||
        (ifReencounterKeyword?.isNotEmpty ?? false) ||
        (conversationStarterKeyword?.isNotEmpty ?? false) ||
        (backgroundMusicKeyword?.isNotEmpty ?? false);
  }

  /// 复制并修改
  RecordsFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdStartDate,
    DateTime? createdEndDate,
    String? province,
    String? city,
    String? area,
    List<PlaceType>? placeTypes,
    List<EncounterStatus>? statuses,
    List<EmotionIntensity>? emotionIntensities,
    List<Weather>? weathers,
    List<String>? tags,
    String? descriptionKeyword,
    String? ifReencounterKeyword,
    String? conversationStarterKeyword,
    String? backgroundMusicKeyword,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearCreatedStartDate = false,
    bool clearCreatedEndDate = false,
    bool clearProvince = false,
    bool clearCity = false,
    bool clearArea = false,
    bool clearDescriptionKeyword = false,
    bool clearIfReencounterKeyword = false,
    bool clearConversationStarterKeyword = false,
    bool clearBackgroundMusicKeyword = false,
  }) {
    return RecordsFilterCriteria(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      createdStartDate: clearCreatedStartDate ? null : (createdStartDate ?? this.createdStartDate),
      createdEndDate: clearCreatedEndDate ? null : (createdEndDate ?? this.createdEndDate),
      province: clearProvince ? null : (province ?? this.province),
      city: clearCity ? null : (city ?? this.city),
      area: clearArea ? null : (area ?? this.area),
      placeTypes: placeTypes ?? this.placeTypes,
      statuses: statuses ?? this.statuses,
      emotionIntensities: emotionIntensities ?? this.emotionIntensities,
      weathers: weathers ?? this.weathers,
      tags: tags ?? this.tags,
      descriptionKeyword: clearDescriptionKeyword ? null : (descriptionKeyword ?? this.descriptionKeyword),
      ifReencounterKeyword: clearIfReencounterKeyword ? null : (ifReencounterKeyword ?? this.ifReencounterKeyword),
      conversationStarterKeyword: clearConversationStarterKeyword ? null : (conversationStarterKeyword ?? this.conversationStarterKeyword),
      backgroundMusicKeyword: clearBackgroundMusicKeyword ? null : (backgroundMusicKeyword ?? this.backgroundMusicKeyword),
    );
  }
}

/// 记录筛选条件 Provider
/// 
/// 职责：管理记录筛选条件状态
/// 
/// 调用者：RecordFilterDialog、RecordsNotifier
final recordsFilterProvider = StateProvider<RecordsFilterCriteria>((ref) {
  return const RecordsFilterCriteria();
});

