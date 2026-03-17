import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';

/// 我的帖子筛选条件
/// 
/// 职责：
/// - 存储筛选条件
/// - 判断是否有筛选条件
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责筛选条件管理
/// - 不可变对象：使用 copyWith 模式
class MyPostsFilterCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? publishStartDate;
  final DateTime? publishEndDate;
  final String? province;
  final String? city;
  final String? area;
  final List<PlaceType>? placeTypes;
  final List<EncounterStatus>? statuses;
  final List<String>? tags;
  final TagMatchMode tagMatchMode;

  const MyPostsFilterCriteria({
    this.startDate,
    this.endDate,
    this.publishStartDate,
    this.publishEndDate,
    this.province,
    this.city,
    this.area,
    this.placeTypes,
    this.statuses,
    this.tags,
    this.tagMatchMode = TagMatchMode.contains,
  });

  /// 判断是否有活跃的筛选条件
  bool get isActive {
    return startDate != null ||
        endDate != null ||
        publishStartDate != null ||
        publishEndDate != null ||
        province != null ||
        city != null ||
        area != null ||
        (placeTypes != null && placeTypes!.isNotEmpty) ||
        (statuses != null && statuses!.isNotEmpty) ||
        (tags != null && tags!.isNotEmpty);
  }

  /// 复制并修改筛选条件
  MyPostsFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? publishStartDate,
    DateTime? publishEndDate,
    String? province,
    String? city,
    String? area,
    List<PlaceType>? placeTypes,
    List<EncounterStatus>? statuses,
    List<String>? tags,
    TagMatchMode? tagMatchMode,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearPublishStartDate = false,
    bool clearPublishEndDate = false,
    bool clearProvince = false,
    bool clearCity = false,
    bool clearArea = false,
    bool clearPlaceTypes = false,
    bool clearStatuses = false,
    bool clearTags = false,
  }) {
    return MyPostsFilterCriteria(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      publishStartDate: clearPublishStartDate ? null : (publishStartDate ?? this.publishStartDate),
      publishEndDate: clearPublishEndDate ? null : (publishEndDate ?? this.publishEndDate),
      province: clearProvince ? null : (province ?? this.province),
      city: clearCity ? null : (city ?? this.city),
      area: clearArea ? null : (area ?? this.area),
      placeTypes: clearPlaceTypes ? null : (placeTypes ?? this.placeTypes),
      statuses: clearStatuses ? null : (statuses ?? this.statuses),
      tags: clearTags ? null : (tags ?? this.tags),
      tagMatchMode: tagMatchMode ?? this.tagMatchMode,
    );
  }

  /// 清空所有筛选条件
  static const empty = MyPostsFilterCriteria();
}

/// 我的帖子筛选条件 Notifier
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
/// - MyPostsFilterDialog（应用/清除筛选）
/// - MyPostsNotifier（监听筛选条件变化）
class MyPostsFilterNotifier extends Notifier<MyPostsFilterCriteria> {
  @override
  MyPostsFilterCriteria build() => MyPostsFilterCriteria.empty;

  /// 更新筛选条件
  /// 
  /// 参数：
  /// - criteria: 新的筛选条件
  /// 
  /// Fail Fast：criteria 不能为 null（由类型系统保证）
  /// 
  /// 调用者：MyPostsFilterDialog._applyFilter()
  void updateFilter(MyPostsFilterCriteria criteria) {
    state = criteria;
  }

  /// 清除所有筛选条件
  /// 
  /// 调用者：MyPostsFilterDialog._clearFilter()
  void clearFilter() {
    state = MyPostsFilterCriteria.empty;
  }
}

/// 我的帖子筛选条件 Provider
/// 
/// 职责：管理我的帖子筛选条件状态
/// 
/// 使用示例：
/// ```dart
/// // 读取筛选条件
/// final filter = ref.watch(myPostsFilterProvider);
/// 
/// // 更新筛选条件
/// ref.read(myPostsFilterProvider.notifier).updateFilter(newCriteria);
/// 
/// // 清除筛选条件
/// ref.read(myPostsFilterProvider.notifier).clearFilter();
/// ```
final myPostsFilterProvider = NotifierProvider<MyPostsFilterNotifier, MyPostsFilterCriteria>(() {
  return MyPostsFilterNotifier();
});
