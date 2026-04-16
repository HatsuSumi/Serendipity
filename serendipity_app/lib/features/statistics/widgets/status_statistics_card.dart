import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/statistics_provider.dart';
import '../../../models/statistics.dart';

class StatusStatisticsCard extends ConsumerWidget {
  final BasicStatistics stats;

  const StatusStatisticsCard({
    super.key,
    required this.stats,
  });

  static const _labels = ['错过', '回避', '再遇', '邂逅', '重逢', '别离', '失联'];
  static const _icons = ['🌫️', '🙈', '🌟', '💫', '💝', '🥀', '🍂'];
  static const _colors = [
    Color(0xFF90A4AE),
    Color(0xFFFFB74D),
    Color(0xFFFFD54F),
    Color(0xFFFF8A65),
    Color(0xFFEC407A),
    Color(0xFFB0BEC5),
    Color(0xFFBCAAA4),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isListMode = ref.watch(statusViewModeProvider);
    final counts = <int>[
      stats.missedCount,
      stats.avoidCount,
      stats.reencounterCount,
      stats.metCount,
      stats.reunionCount,
      stats.farewellCount,
      stats.lostCount,
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📋 总共记录 ${stats.totalRecords} 条',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TabButton(
                      icon: Icons.list_rounded,
                      selected: isListMode,
                      onTap: () =>
                          ref.read(statusViewModeProvider.notifier).state = true,
                      colorScheme: colorScheme,
                    ),
                    _TabButton(
                      icon: Icons.pie_chart_outline_rounded,
                      selected: !isListMode,
                      onTap: () =>
                          ref.read(statusViewModeProvider.notifier).state = false,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isListMode
                ? _StatusList(
                    key: const ValueKey('list'),
                    counts: counts,
                    colorScheme: colorScheme,
                  )
                : _StatusPieChart(
                    key: const ValueKey('pie'),
                    counts: counts,
                    colorScheme: colorScheme,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _TabButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StatusList extends StatelessWidget {
  final List<int> counts;
  final ColorScheme colorScheme;

  const _StatusList({
    super.key,
    required this.counts,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(StatusStatisticsCard._labels.length, (i) {
        final isLast = i == StatusStatisticsCard._labels.length - 1;
        return Column(
          children: [
            _StatusLine(
              StatusStatisticsCard._labels[i],
              counts[i],
              StatusStatisticsCard._icons[i],
              colorScheme,
              highlight: i == 4,
            ),
            if (!isLast) const SizedBox(height: 12),
          ],
        );
      }),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final List<int> counts;
  final ColorScheme colorScheme;

  const _StatusPieChart({
    super.key,
    required this.counts,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final total = counts.fold(0, (a, b) => a + b);
    if (total == 0) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            '暂无数据',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < counts.length; i++) {
      if (counts[i] == 0) continue;
      final pct = counts[i] / total * 100;
      sections.add(
        PieChartSectionData(
          value: counts[i].toDouble(),
          color: StatusStatisticsCard._colors[i],
          title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: 64,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 32,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: List.generate(counts.length, (i) {
            if (counts[i] == 0) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: StatusStatisticsCard._colors[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${StatusStatisticsCard._icons[i]} ${StatusStatisticsCard._labels[i]} ${counts[i]}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final int count;
  final String icon;
  final ColorScheme colorScheme;
  final bool highlight;

  const _StatusLine(
    this.label,
    this.count,
    this.icon,
    this.colorScheme, {
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$icon $label',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          '$count 人${highlight ? ' ❤️' : ''}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

