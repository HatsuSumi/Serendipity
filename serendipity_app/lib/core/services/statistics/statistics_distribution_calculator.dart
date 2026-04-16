part of '../statistics_service.dart';

/// 分布类统计计算。
List<EmotionIntensityItem> _calculateEmotionIntensityDistribution(
  List<EncounterRecord> records,
) {
  final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  for (final record in records) {
    if (record.emotion == null) continue;
    final value = record.emotion!.value;
    counts[value] = (counts[value] ?? 0) + 1;
  }

  return counts.entries
      .map((entry) => EmotionIntensityItem(intensity: entry.key, count: entry.value))
      .toList()
    ..sort((a, b) => a.intensity.compareTo(b.intensity));
}

List<WeatherDistributionItem> _calculateWeatherDistribution(
  List<EncounterRecord> records,
) {
  final counts = <Weather, int>{};

  for (final record in records) {
    for (final weather in record.weather) {
      counts[weather] = (counts[weather] ?? 0) + 1;
    }
  }

  if (counts.isEmpty) return [];

  return counts.entries
      .map((entry) => WeatherDistributionItem(weather: entry.key, count: entry.value))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
}

List<PlaceTypeDistributionItem> _calculatePlaceTypeDistribution(
  List<EncounterRecord> records,
) {
  final counts = <PlaceType, int>{};

  for (final record in records) {
    final placeType = record.location.placeType;
    if (placeType == null) continue;
    counts[placeType] = (counts[placeType] ?? 0) + 1;
  }

  if (counts.isEmpty) return [];

  return (counts.entries
          .map(
            (entry) => PlaceTypeDistributionItem(
              placeType: entry.key,
              count: entry.value,
            ),
          )
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count)))
      .take(8)
      .toList();
}

