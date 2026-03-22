import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/statistics_provider.dart';
import '../../models/enums.dart';
import '../../models/statistics.dart';
import '../../core/utils/dialog_helper.dart';

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

// ---------------------------------------------------------------------------
// 字段完整排名表格卡片
// ---------------------------------------------------------------------------

/// 字段完整排名表格卡片（会员版）
///
/// 用户可切换7个维度，每次只展示当前维度的完整排名，
/// 避免一次性渲染所有表格导致页面过长。
class _FieldRankingCard extends ConsumerWidget {
  final Map<FieldRankingDimension, FieldRankingTable> fieldRankings;

  const _FieldRankingCard({required this.fieldRankings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = ref.watch(fieldRankingDimensionProvider);
    final table = fieldRankings[selected];
    final items = table?.items ?? [];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 16,
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                '字段分布明细',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '完整排名，含长尾数据',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // 维度切换 chips（横向可滚动）
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: FieldRankingDimension.values.map((dim) {
                final isSelected = dim == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(fieldRankingDimensionProvider.notifier)
                        .state = dim,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
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
                        '${dim.icon} ${dim.label}',
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

          // 表格内容（AnimatedSwitcher 让切换有淡入效果）
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: items.isEmpty
                ? SizedBox(
                    key: ValueKey('empty-$selected'),
                    height: 60,
                    child: Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : _RankingTable(
                    key: ValueKey(selected),
                    items: items,
                    colorScheme: colorScheme,
                  ),
          ),
        ],
      ),
    );
  }
}

/// 排名表格内容
class _RankingTable extends StatelessWidget {
  final List<FieldRankingItem> items;
  final ColorScheme colorScheme;

  const _RankingTable({
    super.key,
    required this.items,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = items.first.count;

    return Column(
      children: [
        // 表头
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // 排名列
              SizedBox(
                width: 28,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // 名称列
              Expanded(
                child: Text(
                  '名称',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // 进度条占位
              const SizedBox(width: 80),
              // 次数列
              SizedBox(
                width: 36,
                child: Text(
                  '次数',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
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
        // 数据行
        ...items.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final item = entry.value;
          final ratio = maxCount == 0 ? 0.0 : item.count / maxCount;
          // Top 3 高亮色
          final rankColor = rank == 1
              ? const Color(0xFFFFD700)
              : rank == 2
                  ? const Color(0xFFC0C0C0)
                  : rank == 3
                      ? const Color(0xFFCD7F32)
                      : colorScheme.onSurfaceVariant;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // 排名
                SizedBox(
                  width: 28,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: rank <= 3
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: rankColor,
                    ),
                  ),
                ),
                // 名称
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 迷你进度条
                SizedBox(
                  width: 80,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor:
                            colorScheme.outline.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rank <= 3
                              ? rankColor
                              : colorScheme.primary
                                  .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                // 次数
                SizedBox(
                  width: 36,
                  child: Text(
                    '${item.count}',
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
        const SizedBox(height: 20),
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

/// 成功率计算公式说明对话框
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
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '月度记录数图表',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '情绪强度分布图',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '天气分布图',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '场所类型分布图',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '成功率趋势图',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '字段分布明细',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
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

        // 情绪强度分布
        _EmotionIntensityCard(
            distribution: stats.emotionIntensityDistribution),
        const SizedBox(height: 16),

        // 天气分布
        _WeatherDistributionCard(distribution: stats.weatherDistribution),
        const SizedBox(height: 16),

        // 场所类型分布
        _PlaceTypeDistributionCard(
            distribution: stats.placeTypeDistribution),
        const SizedBox(height: 16),

        // 月度记录数图表
        _MonthlyChartCard(monthlyDistributionByRange: stats.monthlyDistributionByRange),
        const SizedBox(height: 16),

        // 成功率趋势
        _SuccessRateTrendCard(
          monthlySuccessRatesByRange: stats.monthlySuccessRatesByRange,
        ),
        const SizedBox(height: 16),

        // 字段完整排名表格
        _FieldRankingCard(fieldRankings: stats.fieldRankings),
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
  final Map<dynamic, dynamic> monthlyDistributionByRange;

  const _MonthlyChartCard({required this.monthlyDistributionByRange});

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
        (monthlyDistributionByRange[chartRange] as Map?) ?? const {};
    final records = (monthlyDistribution[selectedStatus] as List?) ?? [];
    final isAllRange = chartRange == StatisticsChartRange.all;
    final monthLabelStep = _buildMonthLabelStep(records.length);
    final chartWidth = _buildChartWidth(records.length);

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
              records: records.cast<dynamic>(),
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
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.08),
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
  final List<dynamic> records;
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
        .map((record) => (record.count as int))
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
          final count = record.count as int;
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

// ---------------------------------------------------------------------------
// 情绪强度分布柱状图
// ---------------------------------------------------------------------------

/// 情绪强度分布卡片
class _EmotionIntensityCard extends StatelessWidget {
  final List<dynamic> distribution;

  const _EmotionIntensityCard({required this.distribution});

  static const _intensityLabels = [
    '几乎\n没感觉',
    '有点\n在意',
    '回家后\n还在想',
    '想了\n一整晚',
    '至今\n难忘',
  ];

  // 由浅到深的情感色带
  static const _barColors = [
    Color(0xFFB3E5FC),
    Color(0xFF81D4FA),
    Color(0xFF4FC3F7),
    Color(0xFF0288D1),
    Color(0xFF01579B),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = distribution.fold<int>(
        0, (sum, item) => sum + (item.count as int));

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
            '💓 情绪强度分布',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '暂无数据',
                  style:
                      TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: distribution
                          .map((e) => (e.count as int).toDouble())
                          .reduce((a, b) => a > b ? a : b) *
                      1.25,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} 条',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= distribution.length) {
                            return const SizedBox.shrink();
                          }
                          final count = distribution[idx].count as int;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _intensityLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _intensityLabels[idx],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(distribution.length, (i) {
                    final count = (distribution[i].count as int).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: count,
                          color: _barColors[i % _barColors.length],
                          width: 28,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: distribution
                                    .map((e) => (e.count as int).toDouble())
                                    .reduce((a, b) => a > b ? a : b) *
                                1.25,
                            color: colorScheme.outline
                                .withValues(alpha: 0.06),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 天气分布横向柱状图
// ---------------------------------------------------------------------------

/// 天气分布卡片
class _WeatherDistributionCard extends StatelessWidget {
  final List<dynamic> distribution;

  const _WeatherDistributionCard({required this.distribution});

  @override
  Widget build(BuildContext context) {
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
          Text(
            '🌤️ 天气分布',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (distribution.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '暂无数据',
                  style:
                      TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...distribution.take(8).map((item) {
              final maxCount = (distribution.first.count as int);
              final count = item.count as int;
              final ratio = maxCount == 0 ? 0.0 : count / maxCount;
              final weather = item.weather;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // 天气 icon + label
                    SizedBox(
                      width: 72,
                      child: Text(
                        '${weather.icon} ${weather.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 进度条
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 14,
                          backgroundColor: colorScheme.outline
                              .withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 数量
                    SizedBox(
                      width: 28,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 场所类型分布横向柱状图
// ---------------------------------------------------------------------------

/// 场所类型分布卡片
class _PlaceTypeDistributionCard extends StatelessWidget {
  final List<dynamic> distribution;

  const _PlaceTypeDistributionCard({required this.distribution});

  @override
  Widget build(BuildContext context) {
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
          Text(
            '📍 场所类型分布',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (distribution.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '暂无数据',
                  style:
                      TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...distribution.map((item) {
              final maxCount = (distribution.first.count as int);
              final count = item.count as int;
              final ratio = maxCount == 0 ? 0.0 : count / maxCount;
              final placeType = item.placeType;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${placeType.icon} ${placeType.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 14,
                          backgroundColor: colorScheme.outline
                              .withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.tertiary.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 月度成功率趋势折线图
// ---------------------------------------------------------------------------

/// 成功率趋势卡片
class _SuccessRateTrendCard extends ConsumerWidget {
  final Map<dynamic, dynamic> monthlySuccessRatesByRange;

  const _SuccessRateTrendCard({required this.monthlySuccessRatesByRange});

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
    final now = DateTime.now();
    final currentYear = now.year;
    final chartRange = ref.watch(successRateChartRangeProvider);
    final monthlySuccessRates =
        (monthlySuccessRatesByRange[chartRange] as List?) ?? const [];
    final isAllRange = chartRange == StatisticsChartRange.all;
    final monthLabelStep = _buildMonthLabelStep(monthlySuccessRates.length);
    final chartWidth = _buildChartWidth(monthlySuccessRates.length);

    final spots = <FlSpot>[];
    for (int i = 0; i < monthlySuccessRates.length; i++) {
      spots.add(FlSpot(
        i.toDouble(),
        (monthlySuccessRates[i].successRate as double),
      ));
    }

    final hasData = monthlySuccessRates.any(
      (r) => (r.successRate as double) > 0,
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
                                      final label = (r.year as int) == currentYear
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
                                    getDotPainter:
                                        (spot, percent, bar, index) =>
                                            FlDotCirclePainter(
                                      radius: spot.y > 0 ? 3.5 : 2,
                                      color: spot.y > 0
                                          ? colorScheme.tertiary
                                          : colorScheme.outline
                                              .withValues(alpha: 0.4),
                                      strokeWidth: 0,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: colorScheme.tertiary
                                        .withValues(alpha: 0.08),
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

