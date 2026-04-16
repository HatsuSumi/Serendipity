part of '../statistics_service.dart';

/// 基础统计与总览计算。
BasicStatistics _calculateBasicStatistics(List<EncounterRecord> records) {
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

  int missedCount = 0;
  int avoidCount = 0;
  int reencounterCount = 0;
  int metCount = 0;
  int reunionCount = 0;
  int farewellCount = 0;
  int lostCount = 0;

  final Map<String, int> placeNameCluster = {};
  final Map<PlaceType, int> placeTypeCluster = {};
  final Map<String, int> provinceCluster = {};
  final Map<String, int> cityCluster = {};
  final Map<String, int> areaCluster = {};
  final Map<Weather, int> weatherCluster = {};
  final Map<int, int> hourDistribution = {};

  for (final record in records) {
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

    final placeName = record.location.placeName;
    if (placeName != null && placeName.isNotEmpty) {
      placeNameCluster[placeName] = (placeNameCluster[placeName] ?? 0) + 1;
    }

    final placeType = record.location.placeType;
    if (placeType != null) {
      placeTypeCluster[placeType] = (placeTypeCluster[placeType] ?? 0) + 1;
    }

    final province = record.location.province;
    if (province != null && province.isNotEmpty) {
      provinceCluster[province] = (provinceCluster[province] ?? 0) + 1;
    }

    final city = record.location.city;
    if (city != null && city.isNotEmpty) {
      cityCluster[city] = (cityCluster[city] ?? 0) + 1;
    }

    final area = record.location.area;
    if (area != null && area.isNotEmpty) {
      areaCluster[area] = (areaCluster[area] ?? 0) + 1;
    }

    for (final weather in record.weather) {
      weatherCluster[weather] = (weatherCluster[weather] ?? 0) + 1;
    }

    final hour = record.timestamp.hour;
    hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;
  }

  final successCount = metCount + reunionCount;
  final successRate = (successCount / records.length) * 100;

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
    mostCommonPlace: _mostCommonKey(placeNameCluster),
    mostCommonPlaceType: _mostCommonKey(placeTypeCluster),
    mostCommonProvince: _mostCommonKey(provinceCluster),
    mostCommonCity: _mostCommonKey(cityCluster),
    mostCommonArea: _mostCommonKey(areaCluster),
    mostCommonHour: _mostCommonKey(hourDistribution),
    mostCommonWeather: _mostCommonKey(weatherCluster),
  );
}

List<TagCloudItem> _calculateTagCloud(List<EncounterRecord> records) {
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

  return tagFrequency.entries
      .map(
        (entry) => TagCloudItem(
          tag: entry.key,
          count: entry.value,
          size: entry.value / maxFrequency,
        ),
      )
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
}

T? _mostCommonKey<T>(Map<T, int> counts) {
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
}

