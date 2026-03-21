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
  /// - 地点聚类：GPS < 100米范围内算同一地点
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

  /// 计算高级统计数据（会员版）
  /// 
  /// 参数：
  /// - records：所有记录列表
  /// 
  /// 返回：
  /// - AdvancedStatistics：高级统计数据
  /// 
  /// 设计说明：
  /// - 包含基础统计 + 标签词云 + 月度分布 + 地点分布
  /// - 标签词云：统计所有标签的出现频率，按频率排序
  /// - 月度分布：按状态分组，统计最近12个月各月记录数
  /// - 地点分布：返回前5个最常错过的地点
  static AdvancedStatistics calculateAdvancedStatistics(List<EncounterRecord> records) {
    // 1. 计算基础统计
    final basic = calculateBasicStatistics(records);

    // 2. 计算标签词云
    final tagCloud = _calculateTagCloud(records);

    // 3. 计算月度分布（全部 + 各状态）
    final monthlyDistribution = _calculateMonthlyDistribution(records);

    // 4. 计算地点分布（前5个）
    final topPlaces = _calculateTopPlaces(records);

    return AdvancedStatistics(
      basic: basic,
      tagCloud: tagCloud,
      monthlyDistribution: monthlyDistribution,
      topPlaces: topPlaces,
    );
  }

  /// 计算月度记录数分布（最近12个月）
  /// 
  /// 设计说明：
  /// - 返回 Map(EncounterStatus?, List(MonthlyRecord))
  ///   - key = null：全部状态合计
  ///   - key = 某状态：仅该状态的记录数
  /// - 每个列表按时间正序排列，保证折线图从左到右
  /// - 只包含最近12个月，空月份补0保持连续性
  static Map<EncounterStatus?, List<MonthlyRecord>> _calculateMonthlyDistribution(
    List<EncounterRecord> records,
  ) {
    final now = DateTime.now();
    // 生成最近12个月的 (year, month) 列表，正序
    final months = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - 11 + i);
      return (dt.year, dt.month);
    });

    // 初始化所有 key 的计数 Map
    final allKeys = <EncounterStatus?>[null, ...EncounterStatus.values];
    final counts = <EncounterStatus?, Map<String, int>>{};
    for (final key in allKeys) {
      counts[key] = {};
      for (final (y, m) in months) {
        counts[key]!['$y-$m'] = 0;
      }
    }

    // 统计 — 只处理最近12个月内的记录
    final cutoff = DateTime(now.year, now.month - 11);
    for (final record in records) {
      final ts = record.timestamp;
      if (ts.isBefore(cutoff)) continue;
      final key = '${ts.year}-${ts.month}';
      counts[null]![key] = (counts[null]![key] ?? 0) + 1;
      counts[record.status]![key] = (counts[record.status]![key] ?? 0) + 1;
    }

    // 转换为有序 List<MonthlyRecord>
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

  /// 计算标签词云
  /// 
  /// 设计说明：
  /// - 统计所有标签的出现频率
  /// - 按频率从高到低排序
  /// - 计算相对大小（0.0 - 1.0）
  static List<TagCloudItem> _calculateTagCloud(List<EncounterRecord> records) {
    if (records.isEmpty) {
      return [];
    }

    // 统计标签频率
    final Map<String, int> tagFrequency = {};
    for (final record in records) {
      for (final tagWithNote in record.tags) {
        final tag = tagWithNote.tag;
        tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
      }
    }

    if (tagFrequency.isEmpty) {
      return [];
    }

    // 找出最大频率
    final maxFrequency = tagFrequency.values.reduce((a, b) => a > b ? a : b);

    // 转换为 TagCloudItem 并计算相对大小
    final items = tagFrequency.entries
        .map((entry) {
          final size = entry.value / maxFrequency; // 相对大小 0.0 - 1.0
          return TagCloudItem(
            tag: entry.key,
            count: entry.value,
            size: size,
          );
        })
        .toList();

    // 按频率从高到低排序
    items.sort((a, b) => b.count.compareTo(a.count));

    return items;
  }

  /// 计算地点分布（前5个最常错过的地点）
  /// 
  /// 设计说明：
  /// - 按记录数从高到低排序
  /// - 返回前5个地点
  /// - 地点名称优先级：address > placeName > placeType.label > "未知地点"
  static List<PlaceDistributionItem> _calculateTopPlaces(List<EncounterRecord> records) {
    if (records.isEmpty) {
      return [];
    }

    // 地点聚类：Map<地点标识, (地点名称, 场所类型, 记录数)>
    final Map<String, (String, PlaceType?, int)> placeCluster = {};

    for (final record in records) {
      // 生成地点标识（GPS坐标或地点名称）
      String placeKey;
      String placeName;
      PlaceType? placeType = record.location.placeType;

      if (record.location.latitude != null && record.location.longitude != null) {
        // 有 GPS 坐标，使用坐标作为标识
        final lat = (record.location.latitude! * 10).round() / 10;
        final lng = (record.location.longitude! * 10).round() / 10;
        placeKey = '$lat,$lng';
        
        // 地点名称优先级：address > placeName > placeType.label > "未知地点"
        if (record.location.address != null && record.location.address!.isNotEmpty) {
          placeName = record.location.address!;
        } else if (record.location.placeName != null && record.location.placeName!.isNotEmpty) {
          placeName = record.location.placeName!;
        } else if (placeType != null) {
          placeName = placeType.label;
        } else {
          placeName = '未知地点';
        }
      } else {
        // 无 GPS 坐标，使用地点名称或场所类型作为标识
        if (record.location.placeName != null && record.location.placeName!.isNotEmpty) {
          placeKey = record.location.placeName!;
          placeName = record.location.placeName!;
        } else if (placeType != null) {
          placeKey = placeType.label;
          placeName = placeType.label;
        } else {
          placeKey = '未知地点';
          placeName = '未知地点';
        }
      }

      // 聚类
      if (placeCluster.containsKey(placeKey)) {
        final (name, type, count) = placeCluster[placeKey]!;
        placeCluster[placeKey] = (name, type, count + 1);
      } else {
        placeCluster[placeKey] = (placeName, placeType, 1);
      }
    }

    // 转换为 PlaceDistributionItem 并排序
    final items = placeCluster.entries
        .map((entry) {
          final (placeName, placeType, count) = entry.value;
          return PlaceDistributionItem(
            placeName: placeName,
            count: count,
            placeType: placeType,
          );
        })
        .toList();

    // 按记录数从高到低排序
    items.sort((a, b) => b.count.compareTo(a.count));

    // 返回前5个
    return items.take(5).toList();
  }
}

