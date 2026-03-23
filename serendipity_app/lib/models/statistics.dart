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
  String toString() =>
      'BasicStatistics(totalRecords: $totalRecords, successRate: $successRate)';

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
  int get hashCode =>
      totalRecords.hashCode ^
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

// ---------------------------------------------------------------------------
// 标签词云
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// 月度记录数
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// 情绪强度分布
// ---------------------------------------------------------------------------

/// 情绪强度分布数据项
/// 
/// intensity 与 EmotionIntensity.value 对应（1-5）
class EmotionIntensityItem {
  /// 情绪强度（1-5，对应 EmotionIntensity.value）
  final int intensity;

  /// 该强度的记录数
  final int count;

  const EmotionIntensityItem({
    required this.intensity,
    required this.count,
  });

  @override
  String toString() => 'EmotionIntensityItem($intensity: $count)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmotionIntensityItem &&
        other.intensity == intensity &&
        other.count == count;
  }

  @override
  int get hashCode => intensity.hashCode ^ count.hashCode;
}

// ---------------------------------------------------------------------------
// 天气分布
// ---------------------------------------------------------------------------

/// 天气分布数据项
class WeatherDistributionItem {
  /// 天气类型
  final Weather weather;

  /// 该天气的记录数
  final int count;

  const WeatherDistributionItem({
    required this.weather,
    required this.count,
  });

  @override
  String toString() => 'WeatherDistributionItem(${weather.label}: $count)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherDistributionItem &&
        other.weather == weather &&
        other.count == count;
  }

  @override
  int get hashCode => weather.hashCode ^ count.hashCode;
}

// ---------------------------------------------------------------------------
// 场所类型分布
// ---------------------------------------------------------------------------

/// 场所类型分布数据项
class PlaceTypeDistributionItem {
  /// 场所类型
  final PlaceType placeType;

  /// 该场所类型的记录数
  final int count;

  const PlaceTypeDistributionItem({
    required this.placeType,
    required this.count,
  });

  @override
  String toString() =>
      'PlaceTypeDistributionItem(${placeType.label}: $count)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceTypeDistributionItem &&
        other.placeType == placeType &&
        other.count == count;
  }

  @override
  int get hashCode => placeType.hashCode ^ count.hashCode;
}

// ---------------------------------------------------------------------------
// 成功率趋势
// ---------------------------------------------------------------------------

/// 月度成功率数据项
class MonthlySuccessRate {
  /// 年份
  final int year;

  /// 月份（1-12）
  final int month;

  /// 成功率（0.0 - 100.0）
  final double successRate;

  /// 成功记录数（邂逅 + 重逢）
  final int successCount;

  /// 当月总记录数
  final int totalCount;

  const MonthlySuccessRate({
    required this.year,
    required this.month,
    required this.successRate,
    required this.successCount,
    required this.totalCount,
  });

  @override
  String toString() =>
      'MonthlySuccessRate($year-$month: $successRate%, success: $successCount, total: $totalCount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlySuccessRate &&
        other.year == year &&
        other.month == month &&
        other.successRate == successRate &&
        other.successCount == successCount &&
        other.totalCount == totalCount;
  }

  @override
  int get hashCode =>
      year.hashCode ^
      month.hashCode ^
      successRate.hashCode ^
      successCount.hashCode ^
      totalCount.hashCode;
}

enum StatisticsChartRange {
  last12Months('近12个月'),
  all('全部');

  final String label;
  const StatisticsChartRange(this.label);
}

// ---------------------------------------------------------------------------
// 字段排名表格
// ---------------------------------------------------------------------------

/// 字段排名维度
enum FieldRankingDimension {
  weather('天气', '🌤️'),
  placeType('场所类型', '📍'),
  province('省份', '🗺️'),
  city('城市', '🏙️'),
  placeName('地点名称', '📌'),
  hour('时间段', '🕐'),
  tag('标签', '🏷️');

  final String label;
  final String icon;
  const FieldRankingDimension(this.label, this.icon);
}

/// 字段排名单行数据项
class FieldRankingItem {
  /// 显示名称（如 "☀️ 晴天"、"12:00-13:00"）
  final String label;

  /// 记录数
  final int count;

  const FieldRankingItem({required this.label, required this.count});

  @override
  String toString() => 'FieldRankingItem($label: $count)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldRankingItem &&
        other.label == label &&
        other.count == count;
  }

  @override
  int get hashCode => label.hashCode ^ count.hashCode;
}

/// 单个维度的完整排名表
class FieldRankingTable {
  /// 维度
  final FieldRankingDimension dimension;

  /// 按记录数降序排列的完整列表
  final List<FieldRankingItem> items;

  const FieldRankingTable({
    required this.dimension,
    required this.items,
  });

  @override
  String toString() =>
      'FieldRankingTable(${dimension.label}: ${items.length} items)';
}

// ---------------------------------------------------------------------------
// 高级统计（会员版）
// ---------------------------------------------------------------------------

/// 高级统计数据（会员版）
class AdvancedStatistics {
  /// 基础统计数据
  final BasicStatistics basic;

  /// 标签词云（按频率排序）
  final List<TagCloudItem> tagCloud;

  /// 月度记录数（按时间范围索引）
  /// key1: StatisticsChartRange，key2: null = 全部状态，非 null = 指定状态
  final Map<StatisticsChartRange, Map<EncounterStatus?, List<MonthlyRecord>>>
      monthlyDistributionByRange;

  /// 情绪强度分布（强度1-5，按强度正序，共5条）
  final List<EmotionIntensityItem> emotionIntensityDistribution;

  /// 天气分布（按记录数降序，只含有数据的天气）
  final List<WeatherDistributionItem> weatherDistribution;

  /// 场所类型分布（按记录数降序，前8个）
  final List<PlaceTypeDistributionItem> placeTypeDistribution;

  /// 月度成功率趋势（按时间范围索引，按时间正序）
  final Map<StatisticsChartRange, List<MonthlySuccessRate>>
      monthlySuccessRatesByRange;

  /// 字段排名表格（按维度索引，完整排名，含长尾数据）
  final Map<FieldRankingDimension, FieldRankingTable> fieldRankings;

  const AdvancedStatistics({
    required this.basic,
    required this.tagCloud,
    required this.monthlyDistributionByRange,
    required this.emotionIntensityDistribution,
    required this.weatherDistribution,
    required this.placeTypeDistribution,
    required this.monthlySuccessRatesByRange,
    required this.fieldRankings,
  });

  @override
  String toString() =>
      'AdvancedStatistics(basic: $basic, tagCloud: ${tagCloud.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvancedStatistics &&
        other.basic == basic &&
        other.tagCloud == tagCloud &&
        other.monthlyDistributionByRange == monthlyDistributionByRange &&
        other.emotionIntensityDistribution == emotionIntensityDistribution &&
        other.weatherDistribution == weatherDistribution &&
        other.placeTypeDistribution == placeTypeDistribution &&
        other.monthlySuccessRatesByRange == monthlySuccessRatesByRange &&
        other.fieldRankings == fieldRankings;
  }

  @override
  int get hashCode =>
      basic.hashCode ^
      tagCloud.hashCode ^
      monthlyDistributionByRange.hashCode ^
      emotionIntensityDistribution.hashCode ^
      weatherDistribution.hashCode ^
      placeTypeDistribution.hashCode ^
      monthlySuccessRatesByRange.hashCode ^
      fieldRankings.hashCode;
}
