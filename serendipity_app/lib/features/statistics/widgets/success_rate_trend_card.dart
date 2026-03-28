import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/statistics_provider.dart';
import '../../../core/providers/theme_provider.dart' show appColorSchemeProvider, appTextThemeProvider;
import '../../../models/statistics.dart';

class SuccessRateTrendCard extends ConsumerWidget {
  final Map<StatisticsChartRange, List<MonthlySuccessRate>>
      monthlySuccessRatesByRange;

  const SuccessRateTrendCard({
    super.key,
    required this.monthlySuccessRatesByRange,
  });

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
    final colorScheme = ref.watch(appColorSchemeProvider);
    ref.watch(appTextThemeProvider);
    final now = DateTime.now();
    final currentYear = now.year;
    final chartRange = ref.watch(successRateChartRangeProvider);
    final monthlySuccessRates =
        monthlySuccessRatesByRange[chartRange] ?? const <MonthlySuccessRate>[];
    final isAllRange = chartRange == StatisticsChartRange.all;
    final monthLabelStep = _buildMonthLabelStep(monthlySuccessRates.length);
    final chartWidth = _buildChartWidth(monthlySuccessRates.length);

    final spots = <FlSpot>[];
    for (int i = 0; i < monthlySuccessRates.length; i++) {
      spots.add(FlSpot(
        i.toDouble(),
        monthlySuccessRates[i].successRate,
      ));
    }

    final hasData = monthlySuccessRates.any(
      (r) => r.successRate > 0,
    );

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
            '📈 成功率趋势',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAllRange ? '全部时间，每月邂逅/重逢占比' : '每月邂逅/重逢占比',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
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
                        .read(successRateChartRangeProvider.notifier)
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
          const SizedBox(height: 16),
          if (isAllRange)
            _SuccessRateTable(
              monthlySuccessRates: monthlySuccessRates.cast<MonthlySuccessRate>(),
              colorScheme: colorScheme,
            )
          else
            SizedBox(
              height: 160,
              child: !hasData
                  ? Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
                              maxY: 105,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 25,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: colorScheme.outline.withValues(alpha: 0.2),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: 25,
                                    getTitlesWidget: (value, meta) {
                                      if (value > 100) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        '${value.toInt()}%',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    },
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
                                      if (idx < 0 ||
                                          idx >= monthlySuccessRates.length) {
                                        return const SizedBox.shrink();
                                      }
                                      if (idx % monthLabelStep != 0 &&
                                          idx != monthlySuccessRates.length - 1) {
                                        return const SizedBox.shrink();
                                      }
                                      final r = monthlySuccessRates[idx];
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
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  curveSmoothness: 0.35,
                                  color: colorScheme.tertiary,
                                  barWidth: 2.5,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, bar, index) =>
                                        FlDotCirclePainter(
                                      radius: spot.y > 0 ? 3.5 : 2,
                                      color: spot.y > 0
                                          ? colorScheme.tertiary
                                          : colorScheme.outline.withValues(alpha: 0.4),
                                      strokeWidth: 0,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: colorScheme.tertiary.withValues(alpha: 0.08),
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

class _SuccessRateTable extends StatelessWidget {
  final List<MonthlySuccessRate> monthlySuccessRates;
  final ColorScheme colorScheme;

  const _SuccessRateTable({
    required this.monthlySuccessRates,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlySuccessRates.isEmpty) {
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

    Widget buildCell(
      String text, {
      TextAlign textAlign = TextAlign.left,
      FontWeight? fontWeight,
      Color? color,
    }) {
      return Expanded(
        child: Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 12,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              buildCell(
                '月份',
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              buildCell(
                '成功率',
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              buildCell(
                '成功数',
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              buildCell(
                '总数',
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 8),
        ...monthlySuccessRates.reversed.map((record) {
          final monthLabel =
              '${record.year}/${record.month.toString().padLeft(2, '0')}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                buildCell(
                  monthLabel,
                  textAlign: TextAlign.center,
                  color: colorScheme.onSurface,
                ),
                buildCell(
                  '${record.successRate.toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                buildCell(
                  '${record.successCount}',
                  textAlign: TextAlign.center,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                buildCell(
                  '${record.totalCount}',
                  textAlign: TextAlign.center,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

