import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/statistics_provider.dart';

import '../../../models/enums.dart';
import '../../../models/statistics.dart';

class MonthlyChartCard extends ConsumerWidget {
  final Map<StatisticsChartRange, Map<EncounterStatus?, List<MonthlyRecord>>>
      monthlyDistributionByRange;

  const MonthlyChartCard({
    super.key,
    required this.monthlyDistributionByRange,
  });

  static const _statusOptions = [
    (null, '全部', '📋'),
    (EncounterStatus.missed, '错过', '🌫️'),
    (EncounterStatus.avoid, '回避', '🙈'),
    (EncounterStatus.reencounter, '再遇', '🌟'),
    (EncounterStatus.met, '邂逅', '💫'),
    (EncounterStatus.reunion, '重逢', '💝'),
    (EncounterStatus.farewell, '别离', '🥀'),
    (EncounterStatus.lost, '失联', '🍂'),
  ];

  static int _buildMonthLabelStep(int length) {
    if (length <= 12) return 2;
    if (length <= 24) return 3;
    if (length <= 36) return 4;
    return 6;
  }

  static double _buildChartWidth(int length) {
    const baseWidth = 520.0;
    final computedWidth = length * 52.0;
    return computedWidth < baseWidth ? baseWidth : computedWidth;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedStatus = ref.watch(monthlyStatusFilterProvider);
    final chartRange = ref.watch(monthlyChartRangeProvider);
    final monthlyDistribution =
        monthlyDistributionByRange[chartRange] ?? const {};
    final records = monthlyDistribution[selectedStatus] ?? const <MonthlyRecord>[];
    final isAllRange = chartRange == StatisticsChartRange.all;
    final monthLabelStep = _buildMonthLabelStep(records.length);
    final chartWidth = _buildChartWidth(records.length);

    final spots = <FlSpot>[];
    for (int i = 0; i < records.length; i++) {
      spots.add(FlSpot(i.toDouble(), records[i].count.toDouble()));
    }

    final maxY = records.isEmpty
        ? 5.0
        : records
                    .map((r) => r.count.toDouble())
                    .reduce((a, b) => a > b ? a : b)
                    .clamp(1.0, double.infinity) *
                1.3;

    final now = DateTime.now();
    final currentYear = now.year;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 月度记录数',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: StatisticsChartRange.values.map((range) {
                final isSelected = chartRange == range;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(monthlyChartRangeProvider.notifier)
                        .state = range,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        range.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _statusOptions.map((opt) {
                final isSelected = selectedStatus == opt.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(monthlyStatusFilterProvider.notifier)
                        .state = opt.$1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${opt.$3} ${opt.$2}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (isAllRange)
            _MonthlyRecordTable(
              records: records,
              colorScheme: colorScheme,
            )
          else
            SizedBox(
              height: 160,
              child: records.isEmpty
                  ? Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth + 16,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: maxY,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: (maxY / 4).ceilToDouble(),
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: colorScheme.outline.withValues(alpha: 0.2),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    interval: (maxY / 4).ceilToDouble(),
                                    getTitlesWidget: (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 24,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.round();
                                      if ((value - idx).abs() > 0.001) {
                                        return const SizedBox.shrink();
                                      }
                                      if (idx < 0 || idx >= records.length) {
                                        return const SizedBox.shrink();
                                      }
                                      if (idx % monthLabelStep != 0 &&
                                          idx != records.length - 1) {
                                        return const SizedBox.shrink();
                                      }
                                      final r = records[idx];
                                      final label = r.year == currentYear
                                          ? '${r.month}月'
                                          : '${r.year}/${r.month}';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              lineTouchData: const LineTouchData(enabled: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  curveSmoothness: 0.3,
                                  color: colorScheme.primary,
                                  barWidth: 2.5,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, bar, index) =>
                                        FlDotCirclePainter(
                                      radius: 3,
                                      color: colorScheme.primary,
                                      strokeWidth: 0,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: colorScheme.primary.withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _MonthlyRecordTable extends StatelessWidget {
  final List<MonthlyRecord> records;
  final ColorScheme colorScheme;

  const _MonthlyRecordTable({
    required this.records,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            '暂无数据',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxCount = records
        .map((record) => record.count)
        .reduce((a, b) => a > b ? a : b);
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text('月份', style: headerStyle),
              ),
              Expanded(
                child: Text('记录数', style: headerStyle),
              ),
              const SizedBox(width: 80),
              SizedBox(
                width: 40,
                child: Text(
                  '次数',
                  textAlign: TextAlign.right,
                  style: headerStyle,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 8),
        ...records.reversed.map((record) {
          final count = record.count;
          final ratio = maxCount == 0 ? 0.0 : count / maxCount;
          final monthLabel =
              '${record.year}/${record.month.toString().padLeft(2, '0')}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    monthLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor:
                            colorScheme.outline.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

