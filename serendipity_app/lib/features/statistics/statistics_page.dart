import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/statistics_provider.dart';
import '../../models/enums.dart';

/// 统计页面
/// 
/// 职责：
/// - 展示用户的记录统计数据
/// - 支持基础统计（免费）和高级统计（会员）
/// - 提供会员升级入口
/// 
/// 设计原则：
/// - 分层约束：只负责 UI 展示，不涉及业务逻辑
/// - 单一职责：只展示统计数据，不处理数据计算
/// - 依赖倒置：依赖 Provider，不依赖具体的数据源
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 24),
            const SizedBox(width: 8),
            const Text('我的记录统计'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基础统计卡片
              _BasicStatisticsCard(),
              const SizedBox(height: 24),
              
              // 高级统计卡片（会员版）
              _AdvancedStatisticsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 基础统计卡片
class _BasicStatisticsCard extends ConsumerWidget {
  const _BasicStatisticsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basicStatsAsync = ref.watch(basicStatisticsProvider);

    return basicStatsAsync.when(
      data: (stats) => _buildBasicStatistics(context, stats),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('加载失败: $error'),
      ),
    );
  }

  Widget _buildBasicStatistics(BuildContext context, dynamic stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        const Text(
          '记录统计',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 状态统计卡片
        _StatusStatisticsCard(stats: stats),
        const SizedBox(height: 16),

        // 成功率、地点和时间统计
        _SuccessRateCard(stats: stats),
      ],
    );
  }
}

/// 状态统计卡片（列表/饼图可切换）
class _StatusStatisticsCard extends ConsumerWidget {
  final dynamic stats;

  const _StatusStatisticsCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isListMode = ref.watch(statusViewModeProvider);

    final counts = <int>[
      stats.missedCount as int,
      stats.avoidCount as int,
      stats.reencounterCount as int,
      stats.metCount as int,
      stats.reunionCount as int,
      stats.farewellCount as int,
      stats.lostCount as int,
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
          // 顶部：总计 + tab 切换
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
              // Tab 切换按钮
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
                      onTap: () => ref.read(statusViewModeProvider.notifier).state = true,
                      colorScheme: colorScheme,
                    ),
                    _TabButton(
                      icon: Icons.pie_chart_outline_rounded,
                      selected: !isListMode,
                      onTap: () => ref.read(statusViewModeProvider.notifier).state = false,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 内容区
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

/// Tab 切换按钮
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

/// 列表视图
class _StatusList extends StatelessWidget {
  final List<int> counts;
  final ColorScheme colorScheme;

  const _StatusList({super.key, required this.counts, required this.colorScheme});

  static const _labels = ['错过', '回避', '再遇', '邂逅', '重逢', '别离', '失联'];
  static const _icons  = ['🌫️', '🙈', '🌟', '💫', '💝', '🥀', '🍂'];

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
              highlight: i == 4, // 重逢
            ),
            if (!isLast) const SizedBox(height: 12),
          ],
        );
      }),
    );
  }
}

/// 饼图视图
class _StatusPieChart extends StatelessWidget {
  final List<int> counts;
  final ColorScheme colorScheme;

  const _StatusPieChart({super.key, required this.counts, required this.colorScheme});

  static const _labels = ['错过', '回避', '再遇', '邂逅', '重逢', '别离', '失联'];
  static const _icons  = ['🌫️', '🙈', '🌟', '💫', '💝', '🥀', '🍂'];

  // 与状态情感色调对应的颜色
  static const _colors = [
    Color(0xFF90A4AE), // 错过：灰蓝
    Color(0xFFFFB74D), // 回避：橙黄
    Color(0xFFFFD54F), // 再遇：金色
    Color(0xFFFF8A65), // 邂逅：粉橙
    Color(0xFFEC407A), // 重逢：玫瑰金
    Color(0xFFB0BEC5), // 别离：玫瑰灰
    Color(0xFFBCAAA4), // 失联：秋叶
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
        const SizedBox(height: 12),
        // 图例
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

/// 单行状态统计
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

/// 成功率和地点时间卡片（合并）
class _SuccessRateCard extends StatelessWidget {
  final dynamic stats;

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
    final timeStr = mostCommonHour != null ? '$mostCommonHour:00-${mostCommonHour + 1}:00' : '未知';
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
              const Text(
                '成功率',
                style: TextStyle(fontSize: 14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最常见的地点',
                style: TextStyle(fontSize: 14),
              ),
              Expanded(
                child: Text(
                  mostCommonPlace,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最常见的场所',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                placeTypeStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最常见的省',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                mostCommonProvince,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最常见的市',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                mostCommonCity,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最常见的区',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                mostCommonArea,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最常见的时间',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最常见的天气',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                weatherStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 高级统计卡片（会员版）
class _AdvancedStatisticsCard extends ConsumerWidget {
  const _AdvancedStatisticsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advancedStatsAsync = ref.watch(advancedStatisticsProvider);

    return advancedStatsAsync.when(
      data: (stats) {
        if (stats == null) {
          // 非会员，显示升级提示
          return _buildUpgradePrompt(context, ref);
        }
        // 会员，显示高级统计
        return _buildAdvancedStatistics(context, stats);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('加载失败: $error'),
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💎 高级统计',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '升级会员解锁：',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '标签词云图',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '月度记录数图表',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: 导航到会员升级页面
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('升级会员'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStatistics(BuildContext context, dynamic stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💎 高级统计',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 标签词云
        _TagCloudCard(tagCloud: stats.tagCloud),
        const SizedBox(height: 16),

        // 月度记录数图表
        _MonthlyChartCard(monthlyDistribution: stats.monthlyDistribution),
      ],
    );
  }
}

/// 标签词云卡片
class _TagCloudCard extends StatelessWidget {
  final List<dynamic> tagCloud;

  const _TagCloudCard({required this.tagCloud});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final primaryColor = colorScheme.primary;

    if (tagCloud.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            '暂无标签数据',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏷️ 我最常错过的类型',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...tagCloud.take(10).map((item) {
                final size = 12.0 + (item.size * 8); // 12-20 字体大小
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '[${item.tag}]',
                    style: TextStyle(
                      fontSize: size,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/// 月度记录数图表卡片（会员版）
class _MonthlyChartCard extends ConsumerWidget {
  final Map<dynamic, dynamic> monthlyDistribution;

  const _MonthlyChartCard({required this.monthlyDistribution});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedStatus = ref.watch(monthlyStatusFilterProvider);
    final records = (monthlyDistribution[selectedStatus] as List?) ?? [];

    // 构造折线图数据点
    final spots = <FlSpot>[];
    for (int i = 0; i < records.length; i++) {
      spots.add(FlSpot(i.toDouble(), (records[i].count as int).toDouble()));
    }

    final maxY = records.isEmpty
        ? 5.0
        : records
              .map((r) => (r.count as int).toDouble())
              .reduce((a, b) => a > b ? a : b)
              .clamp(1.0, double.infinity) *
          1.2;

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

          // 状态筛选 chips
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

          // 折线图
          SizedBox(
            height: 160,
            child: records.isEmpty
                ? Center(
                    child: Text(
                      '暂无数据',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : LineChart(
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
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= records.length) {
                                return const SizedBox.shrink();
                              }
                              // 每隔2个显示一个标签，避免拥挤
                              if (idx % 2 != 0) return const SizedBox.shrink();
                              final r = records[idx];
                              final label = r.year == currentYear
                                  ? '${r.month}月'
                                  : '${r.year}/${r.month}';
                              return Text(
                                label,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: colorScheme.onSurfaceVariant,
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
        ],
      ),
    );
  }
}

