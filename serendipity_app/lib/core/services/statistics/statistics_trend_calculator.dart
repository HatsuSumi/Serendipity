part of '../statistics_service.dart';

/// 趋势类统计计算。
Map<EncounterStatus?, List<MonthlyRecord>> _calculateMonthlyDistribution(
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
    for (final (year, month) in months) {
      counts[key]!['$year-$month'] = 0;
    }
  }

  for (final record in records) {
    final timestamp = record.timestamp;
    final key = '${timestamp.year}-${timestamp.month}';
    if (!counts[null]!.containsKey(key)) continue;
    counts[null]![key] = (counts[null]![key] ?? 0) + 1;
    counts[record.status]![key] = (counts[record.status]![key] ?? 0) + 1;
  }

  final result = <EncounterStatus?, List<MonthlyRecord>>{};
  for (final statusKey in allKeys) {
    result[statusKey] = months
        .map(
          (yearMonth) => MonthlyRecord(
            year: yearMonth.$1,
            month: yearMonth.$2,
            count: counts[statusKey]!['${yearMonth.$1}-${yearMonth.$2}'] ?? 0,
          ),
        )
        .toList();
  }
  return result;
}

List<MonthlySuccessRate> _calculateMonthlySuccessRates(
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
    final successRate = totalCount == 0 ? 0.0 : (successCount / totalCount) * 100;

    return MonthlySuccessRate(
      year: yearMonth.$1,
      month: yearMonth.$2,
      successRate: successRate,
      successCount: successCount,
      totalCount: totalCount,
    );
  }).toList();
}

List<(int, int)> _buildMonthlyWindow(
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

