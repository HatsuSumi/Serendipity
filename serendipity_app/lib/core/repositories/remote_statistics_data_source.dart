import '../../models/statistics.dart';
import '../services/http_client_service.dart';
import 'i_statistics_data_source.dart';

/// 远端统计数据源
///
/// 职责：
/// - 调用后端 GET /statistics/overview 获取账号全局统计总览
/// - 图表类统计（高级统计）继续由本地聚合，此类始终抛出 UnsupportedError 触发降级
///
/// 字段说明：
/// - mostCommonPlace / mostCommonPlaceType / province / city / area / hour / weather：
///   服务端 overview 接口不返回这些图表级字段，统一置为 null
///   （这些字段属于本地聚合域，只在 LocalStatisticsDataSource 填充）
/// - pinnedStoryLineCount：服务端 StoryLine 表无 isPinned 字段，固定返回 0
///
/// 设计原则：
/// - 依赖倒置：依赖 HttpClientService，不依赖具体 HTTP 库
/// - Fail Fast：接口未就绪时明确抛出，不返回假数据
/// - 不持有状态：无成员变量缓存，每次调用均为新的网络请求
final class RemoteStatisticsDataSource implements IStatisticsDataSource {
  final HttpClientService _httpClient;

  const RemoteStatisticsDataSource({required HttpClientService httpClient})
      : _httpClient = httpClient;

  // ---------------------------------------------------------------------------
  // Overview
  // ---------------------------------------------------------------------------

  /// 获取账号全局统计总览
  ///
  /// 对应服务端：GET /statistics/overview
  /// 响应格式见 docs/Statistics_Refactoring_Plan.md
  @override
  Future<StatisticsOverview> getOverview({required String? userId}) async {
    final response = await _httpClient.get('/statistics/overview');
    final data = response['data'] as Map<String, dynamic>;
    return _mapOverviewDto(data);
  }

  // ---------------------------------------------------------------------------
  // Advanced Statistics
  // ---------------------------------------------------------------------------

  /// 高级图表数据不走远端，始终降级到本地
  ///
  /// 图表类统计交互频繁，短期内继续由本地聚合；
  /// 此方法抛出 UnsupportedError 确保 StatisticsRepository 降级到本地。
  @override
  Future<AdvancedStatistics> getAdvancedStatistics({
    required String? userId,
  }) async {
    throw UnsupportedError(
      'Remote advanced statistics is not implemented. '
      'Falling back to local data source.',
    );
  }

  // ---------------------------------------------------------------------------
  // DTO 映射
  // ---------------------------------------------------------------------------

  StatisticsOverview _mapOverviewDto(Map<String, dynamic> data) {
    final statusCounts = data['statusCounts'] as Map<String, dynamic>;

    // BasicStatistics：状态计数与成功率来自服务端
    // 图表级字段（mostCommon*）服务端不返回，置 null 由本地后续使用
    final basic = BasicStatistics(
      totalRecords:     _int(data['totalRecords']),
      missedCount:      _int(statusCounts['missed']),
      avoidCount:       _int(statusCounts['avoid']),
      reencounterCount: _int(statusCounts['reencounter']),
      metCount:         _int(statusCounts['met']),
      reunionCount:     _int(statusCounts['reunion']),
      farewellCount:    _int(statusCounts['farewell']),
      lostCount:        _int(statusCounts['lost']),
      successRate:      _double(data['successRate']),
      // 以下为图表级字段，服务端 overview 不提供，保持 null
      mostCommonPlace:     null,
      mostCommonPlaceType: null,
      mostCommonProvince:  null,
      mostCommonCity:      null,
      mostCommonArea:      null,
      mostCommonHour:      null,
      mostCommonWeather:   null,
    );

    return StatisticsOverview(
      basic:                          basic,
      storyLineCount:                 _int(data['storyLineCount']),
      linkedRecordCount:              _int(data['linkedRecordCount']),
      unlinkedRecordCount:            _int(data['unlinkedRecordCount']),
      linkedRecordPercentage:         _double(data['linkedRecordPercentage']),
      unlinkedRecordPercentage:       _double(data['unlinkedRecordPercentage']),
      registeredAt:                   _parseDate(data['registeredAt'] as String?),
      totalCheckInDays:               _int(data['totalCheckInDays']),
      totalCheckInStartDate:          _parseDate(data['totalCheckInStartDate'] as String?),
      totalCheckInEndDate:            _parseDate(data['totalCheckInEndDate'] as String?),
      longestCheckInStreakDays:        _int(data['longestCheckInStreakDays']),
      longestCheckInStreakStartDate:   _parseDate(data['longestCheckInStreakStartDate'] as String?),
      longestCheckInStreakEndDate:     _parseDate(data['longestCheckInStreakEndDate'] as String?),
      // 收藏与置顶：服务端直接返回账号全局值
      favoritesAvailable:             true,
      favoritedRecordCount:           _int(data['favoritedRecordCount']),
      favoritedPostCount:             _int(data['favoritedPostCount']),
      pinnedRecordCount:              _int(data['pinnedRecordCount']),
      pinnedStoryLineCount:           _int(data['pinnedStoryLineCount']),
    );
  }

  // ---------------------------------------------------------------------------
  // 类型转换辅助
  // ---------------------------------------------------------------------------

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

  static double _double(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  static DateTime? _parseDate(String? s) =>
      s != null ? DateTime.parse(s) : null;
}
