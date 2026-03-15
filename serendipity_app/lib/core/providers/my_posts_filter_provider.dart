import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';

/// 我的帖子筛选条件模型
/// 
/// 职责：存储我的帖子筛选条件
/// 
/// 调用者：MyPostsFilterDialog、MyPostsNotifier
class MyPostsFilterCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? publishStartDate;
  final DateTime? publishEndDate;
  final List<PlaceType>? placeTypes;
  final List<EncounterStatus>? statuses;
  final List<String>? tags;
  final String? province;
  final String? city;
  final String? area;

  const MyPostsFilterCriteria({
    this.startDate,
    this.endDate,
    this.publishStartDate,
    this.publishEndDate,
    this.placeTypes,
    this.statuses,
    this.tags,
    this.province,
    this.city,
    this.area,
  });

  /// 是否有活跃的筛选条件
  bool get isActive {
    return startDate != null ||
        endDate != null ||
        publishStartDate != null ||
        publishEndDate != null ||
        (placeTypes?.isNotEmpty ?? false) ||
        (statuses?.isNotEmpty ?? false) ||
        (tags?.isNotEmpty ?? false) ||
        province != null ||
        city != null ||
        area != null;
  }

  /// 复制并修改
  MyPostsFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? publishStartDate,
    DateTime? publishEndDate,
    List<PlaceType>? placeTypes,
    List<EncounterStatus>? statuses,
    List<String>? tags,
    String? province,
    String? city,
    String? area,
  }) {
    return MyPostsFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      publishStartDate: publishStartDate ?? this.publishStartDate,
      publishEndDate: publishEndDate ?? this.publishEndDate,
      placeTypes: placeTypes ?? this.placeTypes,
      statuses: statuses ?? this.statuses,
      tags: tags ?? this.tags,
      province: province ?? this.province,
      city: city ?? this.city,
      area: area ?? this.area,
    );
  }
}

/// 我的帖子筛选条件 Provider
/// 
/// 职责：管理我的帖子筛选条件状态
/// 
/// 调用者：MyPostsFilterDialog、MyPostsNotifier
final myPostsFilterProvider = StateProvider<MyPostsFilterCriteria>((ref) {
  return const MyPostsFilterCriteria();
});

