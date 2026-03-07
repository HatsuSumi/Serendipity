import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';

/// 社区筛选条件
/// 
/// 职责：
/// - 存储筛选条件
/// - 判断是否有筛选条件
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责筛选条件管理
/// - 不可变对象：使用 copyWith 模式
class CommunityFilterCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? publishStartDate;
  final DateTime? publishEndDate;
  final String? province;
  final String? city;
  final String? area;
  final List<PlaceType>? placeTypes;
  final List<String>? tags;
  final List<EncounterStatus>? statuses;

  const CommunityFilterCriteria({
    this.startDate,
    this.endDate,
    this.publishStartDate,
    this.publishEndDate,
    this.province,
    this.city,
    this.area,
    this.placeTypes,
    this.tags,
    this.statuses,
  });

  /// 判断是否有任何筛选条件
  bool get hasAnyFilter {
    return startDate != null ||
        endDate != null ||
        publishStartDate != null ||
        publishEndDate != null ||
        province != null ||
        city != null ||
        area != null ||
        (placeTypes != null && placeTypes!.isNotEmpty) ||
        (tags != null && tags!.isNotEmpty) ||
        (statuses != null && statuses!.isNotEmpty);
  }

  /// 复制并修改筛选条件
  CommunityFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? publishStartDate,
    DateTime? publishEndDate,
    String? province,
    String? city,
    String? area,
    List<PlaceType>? placeTypes,
    List<String>? tags,
    List<EncounterStatus>? statuses,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearPublishStartDate = false,
    bool clearPublishEndDate = false,
    bool clearProvince = false,
    bool clearCity = false,
    bool clearArea = false,
    bool clearPlaceTypes = false,
    bool clearTags = false,
    bool clearStatuses = false,
  }) {
    return CommunityFilterCriteria(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      publishStartDate: clearPublishStartDate ? null : (publishStartDate ?? this.publishStartDate),
      publishEndDate: clearPublishEndDate ? null : (publishEndDate ?? this.publishEndDate),
      province: clearProvince ? null : (province ?? this.province),
      city: clearCity ? null : (city ?? this.city),
      area: clearArea ? null : (area ?? this.area),
      placeTypes: clearPlaceTypes ? null : (placeTypes ?? this.placeTypes),
      tags: clearTags ? null : (tags ?? this.tags),
      statuses: clearStatuses ? null : (statuses ?? this.statuses),
    );
  }

  /// 清空所有筛选条件
  static const empty = CommunityFilterCriteria();
}

/// 社区筛选条件状态管理
/// 
/// 职责：
/// - 管理筛选条件状态
/// - 提供更新筛选条件的方法
/// 
/// 调用者：
/// - CommunityFilterDialog（筛选对话框）
/// - CommunityNotifier（监听筛选条件变化）
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责筛选条件管理
/// - 状态独立：不依赖其他 Provider
class CommunityFilterNotifier extends Notifier<CommunityFilterCriteria> {
  @override
  CommunityFilterCriteria build() {
    return CommunityFilterCriteria.empty;
  }

  /// 更新筛选条件
  /// 
  /// 参数：
  /// - criteria: 新的筛选条件
  /// 
  /// 调用者：CommunityFilterDialog（确认按钮）
  void updateFilter(CommunityFilterCriteria criteria) {
    state = criteria;
  }

  /// 清空筛选条件
  /// 
  /// 调用者：CommunityPage（清除筛选按钮）
  void clearFilter() {
    state = CommunityFilterCriteria.empty;
  }

  /// 判断是否有筛选条件
  bool get hasFilter => state.hasAnyFilter;
}

/// 社区筛选条件 Provider
/// 
/// 职责：管理社区筛选条件状态
/// 
/// 使用示例：
/// ```dart
/// // 读取筛选条件
/// final filter = ref.watch(communityFilterProvider);
/// 
/// // 更新筛选条件
/// ref.read(communityFilterProvider.notifier).updateFilter(newCriteria);
/// 
/// // 清空筛选条件
/// ref.read(communityFilterProvider.notifier).clearFilter();
/// 
/// // 判断是否有筛选条件
/// final hasFilter = ref.read(communityFilterProvider.notifier).hasFilter;
/// ```
final communityFilterProvider = NotifierProvider<CommunityFilterNotifier, CommunityFilterCriteria>(() {
  return CommunityFilterNotifier();
});

