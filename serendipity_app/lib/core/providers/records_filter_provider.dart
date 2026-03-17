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
  final TagMatchMode tagMatchMode;
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
    this.tagMatchMode = TagMatchMode.contains,
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
    TagMatchMode? tagMatchMode,
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
      tagMatchMode: tagMatchMode ?? this.tagMatchMode,
      descriptionKeyword: clearDescriptionKeyword ? null : (descriptionKeyword ?? this.descriptionKeyword),
      ifReencounterKeyword: clearIfReencounterKeyword ? null : (ifReencounterKeyword ?? this.ifReencounterKeyword),
      conversationStarterKeyword: clearConversationStarterKeyword ? null : (conversationStarterKeyword ?? this.conversationStarterKeyword),
      backgroundMusicKeyword: clearBackgroundMusicKeyword ? null : (backgroundMusicKeyword ?? this.backgroundMusicKeyword),
    );
  }
}

/// 记录筛选条件 Notifier
/// 
/// 职责：
/// - 管理筛选条件状态
/// - 提供统一的 updateFilter 和 clearFilter 方法
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责筛选条件管理
/// - 依赖倒置（DIP）：页面依赖此 Notifier，不依赖具体实现
/// 
/// 调用者：
/// - RecordFilterDialog（应用/清除筛选）
/// - RecordsNotifier（监听筛选条件变化）
class RecordsFilterNotifier extends Notifier<RecordsFilterCriteria> {
  @override
  RecordsFilterCriteria build() => const RecordsFilterCriteria();

  /// 更新筛选条件
  /// 
  /// 参数：
  /// - criteria: 新的筛选条件
  /// 
  /// Fail Fast：criteria 不能为 null（由类型系统保证）
  /// 
  /// 调用者：RecordFilterDialog._applyFilter()
  void updateFilter(RecordsFilterCriteria criteria) {
    state = criteria;
  }

  /// 清除所有筛选条件
  /// 
  /// 调用者：RecordFilterDialog._clearFilter()
  void clearFilter() {
    state = const RecordsFilterCriteria();
  }
}

/// 记录筛选条件 Provider
/// 
/// 职责：管理记录筛选条件状态
/// 
/// 使用示例：
/// ```dart
/// // 读取筛选条件
/// final filter = ref.watch(recordsFilterProvider);
/// 
/// // 更新筛选条件
/// ref.read(recordsFilterProvider.notifier).updateFilter(newCriteria);
/// 
/// // 清除筛选条件
/// ref.read(recordsFilterProvider.notifier).clearFilter();
/// ```
final recordsFilterProvider = NotifierProvider<RecordsFilterNotifier, RecordsFilterCriteria>(() {
  return RecordsFilterNotifier();
});

