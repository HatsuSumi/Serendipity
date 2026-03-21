import 'enums.dart';

/// 基础统计数据（免费版）
class BasicStatistics {
  /// 总记录数
  final int totalRecords;
  
  /// 各状态的记录数
  final int missedCount;
  final int avoidCount;
  final int reencounterCount;
  final int metCount;
  final int reunionCount;
  final int farewellCount;
  final int lostCount;
  
  /// 成功率（邂逅 + 重逢）/ 总数 * 100
  final double successRate;
  
  /// 最常见的地点（仅显示用户手动输入的 placeName）
  final String? mostCommonPlace;
  
  /// 最常见的场所类型
  final PlaceType? mostCommonPlaceType;
  
  /// 最常见的省份
  final String? mostCommonProvince;
  
  /// 最常见的城市
  final String? mostCommonCity;
  
  /// 最常见的区县
  final String? mostCommonArea;
  
  /// 最常见的时间段（小时，0-23）
  final int? mostCommonHour;
  
  /// 最常见的天气
  final Weather? mostCommonWeather;

  const BasicStatistics({
    required this.totalRecords,
    required this.missedCount,
    required this.avoidCount,
    required this.reencounterCount,
    required this.metCount,
    required this.reunionCount,
    required this.farewellCount,
    required this.lostCount,
    required this.successRate,
    this.mostCommonPlace,
    this.mostCommonPlaceType,
    this.mostCommonProvince,
    this.mostCommonCity,
    this.mostCommonArea,
    this.mostCommonHour,
    this.mostCommonWeather,
  });

  @override
  String toString() {
    return 'BasicStatistics(totalRecords: $totalRecords, successRate: $successRate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BasicStatistics &&
        other.totalRecords == totalRecords &&
        other.missedCount == missedCount &&
        other.avoidCount == avoidCount &&
        other.reencounterCount == reencounterCount &&
        other.metCount == metCount &&
        other.reunionCount == reunionCount &&
        other.farewellCount == farewellCount &&
        other.lostCount == lostCount &&
        other.successRate == successRate &&
        other.mostCommonPlace == mostCommonPlace &&
        other.mostCommonPlaceType == mostCommonPlaceType &&
        other.mostCommonProvince == mostCommonProvince &&
        other.mostCommonCity == mostCommonCity &&
        other.mostCommonArea == mostCommonArea &&
        other.mostCommonHour == mostCommonHour &&
        other.mostCommonWeather == mostCommonWeather;
  }

  @override
  int get hashCode {
    return totalRecords.hashCode ^
        missedCount.hashCode ^
        avoidCount.hashCode ^
        reencounterCount.hashCode ^
        metCount.hashCode ^
        reunionCount.hashCode ^
        farewellCount.hashCode ^
        lostCount.hashCode ^
        successRate.hashCode ^
        mostCommonPlace.hashCode ^
        mostCommonPlaceType.hashCode ^
        mostCommonProvince.hashCode ^
        mostCommonCity.hashCode ^
        mostCommonArea.hashCode ^
        mostCommonHour.hashCode ^
        mostCommonWeather.hashCode;
  }
}

/// 标签词云数据项
class TagCloudItem {
  /// 标签名称
  final String tag;
  
  /// 出现次数
  final int count;
  
  /// 相对大小（0.0 - 1.0）
  final double size;

  const TagCloudItem({
    required this.tag,
    required this.count,
    required this.size,
  });

  @override
  String toString() => 'TagCloudItem(tag: $tag, count: $count, size: $size)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TagCloudItem &&
        other.tag == tag &&
        other.count == count &&
        other.size == size;
  }

  @override
  int get hashCode => tag.hashCode ^ count.hashCode ^ size.hashCode;
}

/// 月度记录数据项
class MonthlyRecord {
  /// 年份
  final int year;

  /// 月份（1-12）
  final int month;

  /// 该月记录数
  final int count;

  const MonthlyRecord({
    required this.year,
    required this.month,
    required this.count,
  });

  @override
  String toString() => 'MonthlyRecord($year-$month: $count)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlyRecord &&
        other.year == year &&
        other.month == month &&
        other.count == count;
  }

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ count.hashCode;
}

/// 高级统计数据（会员版）
class AdvancedStatistics {
  /// 基础统计数据
  final BasicStatistics basic;
  
  /// 标签词云（按频率排序）
  final List<TagCloudItem> tagCloud;

  /// 月度记录数（最近12个月，按时间正序）
  /// key: null = 全部状态，非 null = 指定状态
  final Map<EncounterStatus?, List<MonthlyRecord>> monthlyDistribution;
  
  /// 地点分布（前5个最常错过的地点）
  final List<PlaceDistributionItem> topPlaces;

  const AdvancedStatistics({
    required this.basic,
    required this.tagCloud,
    required this.monthlyDistribution,
    required this.topPlaces,
  });

  @override
  String toString() {
    return 'AdvancedStatistics(basic: $basic, tagCloud: ${tagCloud.length}, topPlaces: ${topPlaces.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AdvancedStatistics &&
        other.basic == basic &&
        other.tagCloud == tagCloud &&
        other.monthlyDistribution == monthlyDistribution &&
        other.topPlaces == topPlaces;
  }

  @override
  int get hashCode {
    return basic.hashCode ^
        tagCloud.hashCode ^
        monthlyDistribution.hashCode ^
        topPlaces.hashCode;
  }
}

/// 地点分布数据项
class PlaceDistributionItem {
  /// 地点名称
  final String placeName;
  
  /// 该地点的记录数
  final int count;
  
  /// 场所类型（如果有）
  final PlaceType? placeType;

  const PlaceDistributionItem({
    required this.placeName,
    required this.count,
    this.placeType,
  });

  @override
  String toString() => 'PlaceDistributionItem(placeName: $placeName, count: $count)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaceDistributionItem &&
        other.placeName == placeName &&
        other.count == count &&
        other.placeType == placeType;
  }

  @override
  int get hashCode => placeName.hashCode ^ count.hashCode ^ placeType.hashCode;
}
