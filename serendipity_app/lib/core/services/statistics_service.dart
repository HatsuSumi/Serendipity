import '../../models/encounter_record.dart';
import '../../models/statistics.dart';
import '../../models/enums.dart';
 
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
  /// 
  /// 设计说明：
  /// - 循环不变量前置：所有与单条记录无关的计算在循环外完成
  /// - 一次遍历：只遍历一次记录列表，计算所有统计指标
  /// - 时间统计：按小时统计，找出频率最高的时间段
  static BasicStatistics calculateBasicStatistics(List<EncounterRecord> records) {
    // Fail Fast：空列表直接返回默认值
    if (records.isEmpty) {
      return const BasicStatistics(
        totalRecords: 0,
        missedCount: 0,
        avoidCount: 0,
        reencounterCount: 0,
        metCount: 0,
        reunionCount: 0,
        farewellCount: 0,
        lostCount: 0,
        successRate: 0.0,
        mostCommonPlace: null,
        mostCommonPlaceType: null,
        mostCommonProvince: null,
        mostCommonCity: null,
        mostCommonArea: null,
        mostCommonHour: null,
        mostCommonWeather: null,
      );
    }

    // 初始化计数器
    int missedCount = 0;
    int avoidCount = 0;
    int reencounterCount = 0;
    int metCount = 0;
    int reunionCount = 0;
    int farewellCount = 0;
    int lostCount = 0;

    // 地点聚类：仅统计用户手动输入的 placeName
    final Map<String, int> placeNameCluster = {};
    
    // 场所类型统计
    final Map<PlaceType, int> placeTypeCluster = {};
    
    // 省份统计
    final Map<String, int> provinceCluster = {};
    
    // 城市统计
    final Map<String, int> cityCluster = {};
    
    // 区县统计
    final Map<String, int> areaCluster = {};
    
    // 天气统计
    final Map<Weather, int> weatherCluster = {};
    
    // 时间分布：Map<小时, 记录数>
    final Map<int, int> hourDistribution = {};

    // 一次遍历，计算所有统计指标
    for (final record in records) {
      // 1. 状态统计
      switch (record.status) {
        case EncounterStatus.missed:
          missedCount++;
        case EncounterStatus.avoid:
          avoidCount++;
        case EncounterStatus.reencounter:
          reencounterCount++;
        case EncounterStatus.met:
          metCount++;
        case EncounterStatus.reunion:
          reunionCount++;
        case EncounterStatus.farewell:
          farewellCount++;
        case EncounterStatus.lost:
          lostCount++;
      }

      // 2. 地点聚类（仅统计用户手动输入的 placeName）
      if (record.location.placeName != null && record.location.placeName!.isNotEmpty) {
        placeNameCluster[record.location.placeName!] = 
          (placeNameCluster[record.location.placeName!] ?? 0) + 1;
      }
      
      // 3. 场所类型统计
      if (record.location.placeType != null) {
        placeTypeCluster[record.location.placeType!] = 
          (placeTypeCluster[record.location.placeType!] ?? 0) + 1;
      }
      
      // 4. 省份统计
      if (record.location.province != null && record.location.province!.isNotEmpty) {
        provinceCluster[record.location.province!] = 
          (provinceCluster[record.location.province!] ?? 0) + 1;
      }
      
      // 5. 城市统计
      if (record.location.city != null && record.location.city!.isNotEmpty) {
        cityCluster[record.location.city!] = 
          (cityCluster[record.location.city!] ?? 0) + 1;
      }
      
      // 6. 区县统计
      if (record.location.area != null && record.location.area!.isNotEmpty) {
        areaCluster[record.location.area!] = 
          (areaCluster[record.location.area!] ?? 0) + 1;
      }

      // 7. 天气统计
      for (final w in record.weather) {
        weatherCluster[w] = (weatherCluster[w] ?? 0) + 1;
      }

      // 8. 时间分布
      final hour = record.timestamp.hour;
      hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;
    }

    // 计算成功率
    final successCount = metCount + reunionCount;
    final successRate = records.isNotEmpty
        ? (successCount / records.length) * 100
        : 0.0;

    // 找出最常见的地点（仅 placeName）
    String? mostCommonPlace;
    if (placeNameCluster.isNotEmpty) {
      final maxEntry = placeNameCluster.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostCommonPlace = maxEntry.key;
    }
    
    // 找出最常见的场所类型
    PlaceType? mostCommonPlaceType;
    if (placeTypeCluster.isNotEmpty) {
      final maxEntry = placeTypeCluster.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostCommonPlaceType = maxEntry.key;
    }
    
    // 找出最常见的省份
    String? mostCommonProvince;
    if (provinceCluster.isNotEmpty) {
      final maxEntry = provinceCluster.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostCommonProvince = maxEntry.key;
    }
    
    // 找出最常错过的城市
    String? mostCommonCity;
    if (cityCluster.isNotEmpty) {
      final maxEntry = cityCluster.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostCommonCity = maxEntry.key;
    }
    
    // 找出最常错过的区县
    String? mostCommonArea;
    if (areaCluster.isNotEmpty) {
      final maxEntry = areaCluster.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostCommonArea = maxEntry.key;
    }

    // 找出最常见的天气
    Weather? mostCommonWeather;
    if (weatherCluster.isNotEmpty) {
      final maxEntry = weatherCluster.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostCommonWeather = maxEntry.key;
    }

    // 找出最常见的时间段
    int? mostCommonHour;
    if (hourDistribution.isNotEmpty) {
      final maxEntry = hourDistribution.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostCommonHour = maxEntry.key;
    }

    return BasicStatistics(
      totalRecords: records.length,
      missedCount: missedCount,
      avoidCount: avoidCount,
      reencounterCount: reencounterCount,
      metCount: metCount,
      reunionCount: reunionCount,
      farewellCount: farewellCount,
      lostCount: lostCount,
      successRate: successRate,
      mostCommonPlace: mostCommonPlace,
      mostCommonPlaceType: mostCommonPlaceType,
      mostCommonProvince: mostCommonProvince,
      mostCommonCity: mostCommonCity,
      mostCommonArea: mostCommonArea,
      mostCommonHour: mostCommonHour,
      mostCommonWeather: mostCommonWeather,
    );
  }

  /// 计算标签词云。
  ///
  /// 调用者：
  /// - `calculateAdvancedStatistics`：全局高级统计
  /// - 故事线局部词云 Provider
  static List<TagCloudItem> calculateTagCloud(List<EncounterRecord> records) {
    if (records.isEmpty) {
      return const [];
    }

    final Map<String, int> tagFrequency = {};
    for (final record in records) {
      for (final tagWithNote in record.tags) {
        final tag = tagWithNote.tag;
        tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
      }
    }

    if (tagFrequency.isEmpty) {
      return const [];
    }

    final maxFrequency = tagFrequency.values.reduce((a, b) => a > b ? a : b);

    final items = tagFrequency.entries
        .map((entry) => TagCloudItem(
              tag: entry.key,
              count: entry.value,
              size: entry.value / maxFrequency,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return items;
  }

  /// 计算高级统计数据（会员版）
  ///
  /// 包含：基础统计 + 标签词云 + 月度分布
  ///      + 情绪强度分布 + 天气分布 + 场所类型分布 + 月度成功率
  static AdvancedStatistics calculateAdvancedStatistics(List<EncounterRecord> records) {
    // 1. 计算基础统计
    final basic = calculateBasicStatistics(records);

    // 2. 计算标签词云
    final tagCloud = calculateTagCloud(records);

    // 3. 计算月度分布（按时间范围缓存）
    final monthlyDistributionByRange = {
      for (final range in StatisticsChartRange.values)
        range: _calculateMonthlyDistribution(records, chartRange: range),
    };

    // 4. 情绪强度分布
    final emotionIntensityDistribution = _calculateEmotionIntensityDistribution(records);

    // 5. 天气分布
    final weatherDistribution = _calculateWeatherDistribution(records);

    // 6. 场所类型分布（前8）
    final placeTypeDistribution = _calculatePlaceTypeDistribution(records);

    // 7. 月度成功率趋势（按时间范围缓存）
    final monthlySuccessRatesByRange = {
      for (final range in StatisticsChartRange.values)
        range: _calculateMonthlySuccessRates(records, chartRange: range),
    };

    // 8. 字段完整排名表格
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

  /// 计算月度记录数分布
  /// 
  /// 设计说明：
  /// - 返回 Map(EncounterStatus?, List(MonthlyRecord))
  ///   - key = null：全部状态合计
  ///   - key = 某状态：仅该状态的记录数
  /// - 每个列表按时间正序排列，保证折线图从左到右
  /// - 空月份补0保持连续性
  static Map<EncounterStatus?, List<MonthlyRecord>> _calculateMonthlyDistribution(
    List<EncounterRecord> records, {
    required StatisticsChartRange chartRange,
  }) {
    final months = _buildMonthlyWindow(records, chartRange);
    final allKeys = <EncounterStatus?>[null, ...EncounterStatus.values];

    if (months.isEmpty) {
      return {
        for (final key in allKeys) key: const <MonthlyRecord>[],
      };
    }

    final counts = <EncounterStatus?, Map<String, int>>{};
    for (final key in allKeys) {
      counts[key] = {};
      for (final (y, m) in months) {
        counts[key]!['$y-$m'] = 0;
      }
    }

    for (final record in records) {
      final ts = record.timestamp;
      final key = '${ts.year}-${ts.month}';
      if (!counts[null]!.containsKey(key)) continue;
      counts[null]![key] = (counts[null]![key] ?? 0) + 1;
      counts[record.status]![key] = (counts[record.status]![key] ?? 0) + 1;
    }

    final result = <EncounterStatus?, List<MonthlyRecord>>{};
    for (final statusKey in allKeys) {
      result[statusKey] = months
          .map((ym) => MonthlyRecord(
                year: ym.$1,
                month: ym.$2,
                count: counts[statusKey]!['${ym.$1}-${ym.$2}'] ?? 0,
              ))
          .toList();
    }
    return result;
  }

  /// 计算情绪强度分布
  ///
  /// 设计说明：
  /// - 按强度 1-5 分组，每组统计记录数
  /// - emotion 为 null 的记录不计入
  /// - 结果按强度正序排列（方便柱状图左→右展示）
  static List<EmotionIntensityItem> _calculateEmotionIntensityDistribution(
    List<EncounterRecord> records,
  ) {
    // 初始化 1-5 的计数
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final record in records) {
      if (record.emotion == null) continue;
      final v = record.emotion!.value; // EmotionIntensity.value 为 1-5
      counts[v] = (counts[v] ?? 0) + 1;
    }

    return counts.entries
        .map((e) => EmotionIntensityItem(intensity: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.intensity.compareTo(b.intensity));
  }

  /// 计算天气分布
  ///
  /// 设计说明：
  /// - 统计所有天气类型的出现频率
  /// - 只返回出现过的天气（count > 0）
  /// - 按记录数降序排列
  static List<WeatherDistributionItem> _calculateWeatherDistribution(
    List<EncounterRecord> records,
  ) {
    final counts = <Weather, int>{};

    for (final record in records) {
      for (final w in record.weather) {
        counts[w] = (counts[w] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return [];

    return counts.entries
        .map((e) => WeatherDistributionItem(weather: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  /// 计算场所类型分布（前8个）
  ///
  /// 设计说明：
  /// - 按场所类型分组统计记录数
  /// - 只统计有明确 placeType 的记录
  /// - 按记录数降序排列，返回前8
  static List<PlaceTypeDistributionItem> _calculatePlaceTypeDistribution(
    List<EncounterRecord> records,
  ) {
    final counts = <PlaceType, int>{};

    for (final record in records) {
      final pt = record.location.placeType;
      if (pt == null) continue;
      counts[pt] = (counts[pt] ?? 0) + 1;
    }

    if (counts.isEmpty) return [];

    return (counts.entries
            .map((e) =>
                PlaceTypeDistributionItem(placeType: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(8)
        .toList();
  }

  /// 计算所有维度的字段完整排名表格
  ///
  /// 设计说明：
  /// - 7个维度：天气、场所类型、省份、城市、地点名称、时间段、标签
  /// - 天气/场所类型：全量枚举（含长尾），按记录数降序
  /// - 省份/城市/地点名称：自由文本聚合，按记录数降序
  /// - 时间段：0-23小时，展示为 "HH:00-HH:00"，按记录数降序
  /// - 标签：复用 tagCloud 计算结果，转换格式
  /// - 无数据的维度返回空列表
  static Map<FieldRankingDimension, FieldRankingTable> _calculateFieldRankings(
    List<EncounterRecord> records,
    List<TagCloudItem> tagCloud,
  ) {
    final weatherCounts = <Weather, int>{};
    final placeTypeCounts = <PlaceType, int>{};
    final provinceCounts = <String, int>{};
    final cityCounts = <String, int>{};
    final placeNameCounts = <String, int>{};
    final hourCounts = <int, int>{};

    for (final record in records) {
      for (final weather in record.weather) {
        weatherCounts[weather] = (weatherCounts[weather] ?? 0) + 1;
      }

      final placeType = record.location.placeType;
      if (placeType != null) {
        placeTypeCounts[placeType] = (placeTypeCounts[placeType] ?? 0) + 1;
      }

      final province = record.location.province;
      if (province != null && province.isNotEmpty) {
        provinceCounts[province] = (provinceCounts[province] ?? 0) + 1;
      }

      final city = record.location.city;
      if (city != null && city.isNotEmpty) {
        cityCounts[city] = (cityCounts[city] ?? 0) + 1;
      }

      final placeName = record.location.placeName;
      if (placeName != null && placeName.isNotEmpty) {
        placeNameCounts[placeName] = (placeNameCounts[placeName] ?? 0) + 1;
      }

      final hour = record.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    return {
      FieldRankingDimension.weather: FieldRankingTable(
        dimension: FieldRankingDimension.weather,
        items: _buildFieldRankingItems(
          weatherCounts.entries.map(
            (entry) => FieldRankingItem(
              label: entry.key.label,
              count: entry.value,
            ),
          ),
        ),
      ),
      FieldRankingDimension.placeType: FieldRankingTable(
        dimension: FieldRankingDimension.placeType,
        items: _buildFieldRankingItems(
          placeTypeCounts.entries.map(
            (entry) => FieldRankingItem(
              label: entry.key.label,
              count: entry.value,
            ),
          ),
        ),
      ),
      FieldRankingDimension.province: FieldRankingTable(
        dimension: FieldRankingDimension.province,
        items: _buildFieldRankingItems(
          provinceCounts.entries.map(
            (entry) => FieldRankingItem(
              label: entry.key,
              count: entry.value,
            ),
          ),
        ),
      ),
      FieldRankingDimension.city: FieldRankingTable(
        dimension: FieldRankingDimension.city,
        items: _buildFieldRankingItems(
          cityCounts.entries.map(
            (entry) => FieldRankingItem(
              label: entry.key,
              count: entry.value,
            ),
          ),
        ),
      ),
      FieldRankingDimension.placeName: FieldRankingTable(
        dimension: FieldRankingDimension.placeName,
        items: _buildFieldRankingItems(
          placeNameCounts.entries.map(
            (entry) => FieldRankingItem(
              label: entry.key,
              count: entry.value,
            ),
          ),
        ),
      ),
      FieldRankingDimension.hour: FieldRankingTable(
        dimension: FieldRankingDimension.hour,
        items: _buildFieldRankingItems(
          hourCounts.entries.map(
            (entry) => FieldRankingItem(
              label: _formatHourRange(entry.key),
              count: entry.value,
            ),
          ),
        ),
      ),
      FieldRankingDimension.tag: FieldRankingTable(
        dimension: FieldRankingDimension.tag,
        items: _buildFieldRankingItems(
          tagCloud.map(
            (item) => FieldRankingItem(
              label: item.tag,
              count: item.count,
            ),
          ),
        ),
      ),
    };
  }

  static List<FieldRankingItem> _buildFieldRankingItems(
    Iterable<FieldRankingItem> items,
  ) {
    return items.toList()..sort((a, b) => b.count.compareTo(a.count));
  }

  /// 计算月度成功率趋势
  ///
  /// 设计说明：
  /// - 成功定义：状态为 met 或 reunion
  /// - 成功率 = 成功记录数 / 当月总记录数 * 100
  /// - 月份窗口与 monthlyDistribution 保持一致
  /// - 空月份成功率为 0
  static List<MonthlySuccessRate> _calculateMonthlySuccessRates(
    List<EncounterRecord> records, {
    required StatisticsChartRange chartRange,
  }) {
    final months = _buildMonthlyWindow(records, chartRange);
    if (months.isEmpty) return const [];

    final totalCounts = <String, int>{};
    final successCounts = <String, int>{};

    for (final (year, month) in months) {
      final key = '$year-$month';
      totalCounts[key] = 0;
      successCounts[key] = 0;
    }

    for (final record in records) {
      final timestamp = record.timestamp;
      final key = '${timestamp.year}-${timestamp.month}';
      if (!totalCounts.containsKey(key)) continue;

      totalCounts[key] = (totalCounts[key] ?? 0) + 1;
      final isSuccess = record.status == EncounterStatus.met ||
          record.status == EncounterStatus.reunion;
      if (isSuccess) {
        successCounts[key] = (successCounts[key] ?? 0) + 1;
      }
    }

    return months.map((yearMonth) {
      final key = '${yearMonth.$1}-${yearMonth.$2}';
      final totalCount = totalCounts[key] ?? 0;
      final successCount = successCounts[key] ?? 0;
      final successRate = totalCount == 0
          ? 0.0
          : (successCount / totalCount) * 100;

      return MonthlySuccessRate(
        year: yearMonth.$1,
        month: yearMonth.$2,
        successRate: successRate,
        successCount: successCount,
        totalCount: totalCount,
      );
    }).toList();
  }

  /// 构建月度窗口
  ///
  /// 设计说明：
  /// - last12Months：以当前月份为终点，向前取连续12个月
  /// - all：以数据中最早月份到最晚月份为范围
  /// - 返回按时间正序排列的 (year, month)
  static List<(int, int)> _buildMonthlyWindow(
    List<EncounterRecord> records,
    StatisticsChartRange chartRange,
  ) {
    if (records.isEmpty) return const [];

    DateTime start;
    DateTime end;

    if (chartRange == StatisticsChartRange.last12Months) {
      final now = DateTime.now();
      end = DateTime(now.year, now.month);
      start = DateTime(end.year, end.month - 11);
    } else {
      final sorted = [...records]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final first = sorted.first.timestamp;
      final last = sorted.last.timestamp;
      start = DateTime(first.year, first.month);
      end = DateTime(last.year, last.month);
    }

    final result = <(int, int)>[];
    var current = start;
    while (!current.isAfter(end)) {
      result.add((current.year, current.month));
      current = DateTime(current.year, current.month + 1);
    }
    return result;
  }

  static String _formatHourRange(int hour) {
    final endHour = (hour + 1) % 24;
    final startText = hour.toString().padLeft(2, '0');
    final endText = endHour.toString().padLeft(2, '0');
    return '$startText:00-$endText:00';
  }
}
