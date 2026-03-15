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
  final List<PlaceType>? placeTypes;
  final List<EncounterStatus>? statuses;
  final List<EmotionIntensity>? emotionIntensities;
  final List<Weather>? weathers;
  final List<String>? tags;

  const RecordsFilterCriteria({
    this.startDate,
    this.endDate,
    this.placeTypes,
    this.statuses,
    this.emotionIntensities,
    this.weathers,
    this.tags,
  });

  /// 是否有活跃的筛选条件
  bool get isActive {
    return startDate != null ||
        endDate != null ||
        (placeTypes?.isNotEmpty ?? false) ||
        (statuses?.isNotEmpty ?? false) ||
        (emotionIntensities?.isNotEmpty ?? false) ||
        (weathers?.isNotEmpty ?? false) ||
        (tags?.isNotEmpty ?? false);
  }

  /// 复制并修改
  RecordsFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<PlaceType>? placeTypes,
    List<EncounterStatus>? statuses,
    List<EmotionIntensity>? emotionIntensities,
    List<Weather>? weathers,
    List<String>? tags,
  }) {
    return RecordsFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      placeTypes: placeTypes ?? this.placeTypes,
      statuses: statuses ?? this.statuses,
      emotionIntensities: emotionIntensities ?? this.emotionIntensities,
      weathers: weathers ?? this.weathers,
      tags: tags ?? this.tags,
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

