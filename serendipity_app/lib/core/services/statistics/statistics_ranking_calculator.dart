part of '../statistics_service.dart';

/// 排名类统计计算。
Map<FieldRankingDimension, FieldRankingTable> _calculateFieldRankings(
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
          (entry) => FieldRankingItem(label: entry.key.label, count: entry.value),
        ),
      ),
    ),
    FieldRankingDimension.placeType: FieldRankingTable(
      dimension: FieldRankingDimension.placeType,
      items: _buildFieldRankingItems(
        placeTypeCounts.entries.map(
          (entry) => FieldRankingItem(label: entry.key.label, count: entry.value),
        ),
      ),
    ),
    FieldRankingDimension.province: FieldRankingTable(
      dimension: FieldRankingDimension.province,
      items: _buildFieldRankingItems(
        provinceCounts.entries.map(
          (entry) => FieldRankingItem(label: entry.key, count: entry.value),
        ),
      ),
    ),
    FieldRankingDimension.city: FieldRankingTable(
      dimension: FieldRankingDimension.city,
      items: _buildFieldRankingItems(
        cityCounts.entries.map(
          (entry) => FieldRankingItem(label: entry.key, count: entry.value),
        ),
      ),
    ),
    FieldRankingDimension.placeName: FieldRankingTable(
      dimension: FieldRankingDimension.placeName,
      items: _buildFieldRankingItems(
        placeNameCounts.entries.map(
          (entry) => FieldRankingItem(label: entry.key, count: entry.value),
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
        tagCloud.map((item) => FieldRankingItem(label: item.tag, count: item.count)),
      ),
    ),
  };
}

List<FieldRankingItem> _buildFieldRankingItems(Iterable<FieldRankingItem> items) {
  return items.toList()..sort((a, b) => b.count.compareTo(a.count));
}

String _formatHourRange(int hour) {
  final endHour = (hour + 1) % 24;
  final startText = hour.toString().padLeft(2, '0');
  final endText = endHour.toString().padLeft(2, '0');
  return '$startText:00-$endText:00';
}

