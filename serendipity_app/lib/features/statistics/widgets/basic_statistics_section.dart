import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/statistics_provider.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../models/enums.dart';
import '../../../models/statistics.dart';

class BasicStatisticsSection extends ConsumerWidget {
  const BasicStatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(statisticsOverviewProvider);

    return overviewAsync.when(
      data: (overview) => _buildBasicStatistics(context, overview),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('加载失败: $error'),
      ),
    );
  }

  Widget _buildBasicStatistics(
    BuildContext context,
    StatisticsOverview overview,
  ) {
    final stats = overview.basic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '数据总览',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _OverviewSummaryCard(overview: overview),
        const SizedBox(height: 16),
        _StatusStatisticsCard(stats: stats),
        const SizedBox(height: 16),
        _SuccessRateCard(stats: stats),
      ],
    );
  }
}

class _OverviewSummaryCard extends StatelessWidget {
  final StatisticsOverview overview;

  const _OverviewSummaryCard({required this.overview});

  static final DateFormat _dateFormatter = DateFormat('yyyy/MM/dd');
  static final DateFormat _dateTimeFormatter = DateFormat('yyyy/MM/dd HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryWideTile(
          icon: Icons.schedule_rounded,
          label: '账号注册时间',
          value: _formatDateTime(overview.registeredAt) ?? '未登录',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.receipt_long_rounded,
                label: '记录数量',
                value: '${overview.basic.totalRecords}',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.auto_stories_rounded,
                label: '故事线数量',
                value: '${overview.storyLineCount}',
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.calendar_month_rounded,
                label: '累计签到天数',
                value: '${overview.totalCheckInDays}',
                subtitle: _formatDateRange(
                  overview.totalCheckInStartDate,
                  overview.totalCheckInEndDate,
                ),
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.local_fire_department_rounded,
                label: '最长连续签到天数',
                value: '${overview.longestCheckInStreakDays}',
                subtitle: _formatDateRange(
                  overview.longestCheckInStreakStartDate,
                  overview.longestCheckInStreakEndDate,
                ),
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.link_rounded,
                label: '已关联故事线记录',
                value: '${overview.linkedRecordCount}',
                subtitle:
                    '${overview.linkedRecordPercentage.toStringAsFixed(1)}%',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.link_off_rounded,
                label: '未关联故事线记录',
                value: '${overview.unlinkedRecordCount}',
                subtitle:
                    '${overview.unlinkedRecordPercentage.toStringAsFixed(1)}%',
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.favorite_rounded,
                label: '已收藏记录',
                value: '${overview.favoritedRecordCount}',
                subtitle: overview.favoritesAvailable ? null : '登录后可用',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.forum_rounded,
                label: '已收藏帖子',
                value: '${overview.favoritedPostCount}',
                subtitle: overview.favoritesAvailable ? null : '登录后可用',
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.push_pin_rounded,
                label: '已置顶记录',
                value: '${overview.pinnedRecordCount}',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.push_pin_rounded,
                label: '已置顶故事线',
                value: '${overview.pinnedStoryLineCount}',
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return null;
    }

    return '${_dateFormatter.format(startDate)}-${_dateFormatter.format(endDate)}';
  }

  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    return _dateTimeFormatter.format(dateTime);
  }
}

class _SummaryWideTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _SummaryWideTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final ColorScheme colorScheme;

  const _SummaryMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStatisticsCard extends ConsumerWidget {
  final BasicStatistics stats;

  const _StatusStatisticsCard({required this.stats});

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

  static const _labels = ['错过', '回避', '再遇', '邂逅', '重逢', '别离', '失联'];
  static const _icons = ['🌫️', '🙈', '🌟', '💫', '💝', '🥀', '🍂'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_labels.length, (i) {
        final isLast = i == _labels.length - 1;
        return Column(
          children: [
            _StatusLine(
              _labels[i],
              counts[i],
              _icons[i],
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
          color: _colors[i],
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
                    color: _colors[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_icons[i]} ${_labels[i]} ${counts[i]}',
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

class _SuccessRateCard extends StatelessWidget {
  final BasicStatistics stats;

  const _SuccessRateCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final successRate = stats.successRate;
    final mostCommonPlace = stats.mostCommonPlace ?? '未知';
    final mostCommonPlaceType = stats.mostCommonPlaceType;
    final placeTypeStr = mostCommonPlaceType != null
        ? '${mostCommonPlaceType.icon} ${mostCommonPlaceType.label}'
        : '未知';
    final mostCommonProvince = stats.mostCommonProvince ?? '未知';
    final mostCommonCity = stats.mostCommonCity ?? '未知';
    final mostCommonArea = stats.mostCommonArea ?? '未知';
    final mostCommonHour = stats.mostCommonHour;
    final timeStr =
        mostCommonHour != null ? '$mostCommonHour:00-${mostCommonHour + 1}:00' : '未知';
    final mostCommonWeather = stats.mostCommonWeather;
    final weatherStr = mostCommonWeather != null
        ? '${mostCommonWeather.icon} ${mostCommonWeather.label}'
        : '未知';
    final colorScheme = Theme.of(context).colorScheme;

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '成功率',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showSuccessRateDialog(context),
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '${successRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('最常见的地点', mostCommonPlace, expandValue: true),
          const SizedBox(height: 12),
          _buildInfoRow('最常见的场所', placeTypeStr),
          const SizedBox(height: 12),
          _buildInfoRow('最常见的省', mostCommonProvince),
          const SizedBox(height: 12),
          _buildInfoRow('最常见的市', mostCommonCity),
          const SizedBox(height: 12),
          _buildInfoRow('最常见的区', mostCommonArea),
          const SizedBox(height: 12),
          _buildInfoRow('最常见的时间', timeStr),
          const SizedBox(height: 12),
          _buildInfoRow('最常见的天气', weatherStr),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool expandValue = false}) {
    return Builder(
      builder: (context) {
        final valueWidget = Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
            if (expandValue) Expanded(child: valueWidget) else valueWidget,
          ],
        );
      },
    );
  }
}

void _showSuccessRateDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  DialogHelper.show(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('成功率计算公式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '成功率 = (邂逅 + 重逢) ÷ 总记录数 × 100%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '「邂逅」和「重逢」代表你们有过真实的交流，是记录里最珍贵的两种状态。',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

