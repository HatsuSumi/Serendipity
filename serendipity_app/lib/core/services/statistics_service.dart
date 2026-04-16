import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../../models/statistics.dart';

part 'statistics/statistics_distribution_calculator.dart';
part 'statistics/statistics_overview_calculator.dart';
part 'statistics/statistics_ranking_calculator.dart';
part 'statistics/statistics_trend_calculator.dart';
 
/// 统计服务
/// 
/// 职责：
/// - 聚合记录数据，计算各类统计指标
/// - 不涉及 UI 逻辑，纯数据计算
/// - 支持基础统计和高级统计
/// 
/// 调用者：
/// - StatisticsProvider：状态管理层
/// 
/// 设计原则：
/// - 单一职责：只负责数据聚合和计算
/// - Fail Fast：参数非法立即返回默认值或抛异常
/// - 不修改输入：所有计算都基于输入数据，不修改原列表
/// - 性能优化：循环不变量前置，避免重复计算
class StatisticsService {
  StatisticsService._(); // 私有构造函数，防止实例化

  /// 计算基础统计数据
  /// 
  /// 参数：
  /// - records：所有记录列表
  /// 
  /// 返回：
  /// - BasicStatistics：基础统计数据
  static BasicStatistics calculateBasicStatistics(List<EncounterRecord> records) {
    return _calculateBasicStatistics(records);
  }

  /// 计算标签词云。
  ///
  /// 调用者：
  /// - `calculateAdvancedStatistics`：全局高级统计
  /// - 故事线局部词云 Provider
  static List<TagCloudItem> calculateTagCloud(List<EncounterRecord> records) {
    return _calculateTagCloud(records);
  }

  /// 计算高级统计数据（会员版）
  ///
  /// 包含：基础统计 + 标签词云 + 月度分布
  ///      + 情绪强度分布 + 天气分布 + 场所类型分布 + 月度成功率
  static AdvancedStatistics calculateAdvancedStatistics(List<EncounterRecord> records) {
    final basic = _calculateBasicStatistics(records);
    final tagCloud = _calculateTagCloud(records);

    final monthlyDistributionByRange = {
      for (final range in StatisticsChartRange.values)
        range: _calculateMonthlyDistribution(records, chartRange: range),
    };

    final emotionIntensityDistribution = _calculateEmotionIntensityDistribution(records);
    final weatherDistribution = _calculateWeatherDistribution(records);
    final placeTypeDistribution = _calculatePlaceTypeDistribution(records);

    final monthlySuccessRatesByRange = {
      for (final range in StatisticsChartRange.values)
        range: _calculateMonthlySuccessRates(records, chartRange: range),
    };

    final fieldRankings = _calculateFieldRankings(records, tagCloud);

    return AdvancedStatistics(
      basic: basic,
      tagCloud: tagCloud,
      monthlyDistributionByRange: monthlyDistributionByRange,
      emotionIntensityDistribution: emotionIntensityDistribution,
      weatherDistribution: weatherDistribution,
      placeTypeDistribution: placeTypeDistribution,
      monthlySuccessRatesByRange: monthlySuccessRatesByRange,
      fieldRankings: fieldRankings,
    );
  }
}
