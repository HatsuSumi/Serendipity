import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/navigation_helper.dart';
import '../../../core/providers/statistics_provider.dart';
import '../../membership/membership_page.dart';

import '../../../models/statistics.dart';
import 'emotion_intensity_card.dart';
import 'field_ranking_card.dart';
import 'monthly_chart_card.dart';
import 'place_type_distribution_card.dart';
import 'success_rate_trend_card.dart';
import 'tag_cloud_card.dart';
import 'weather_distribution_card.dart';

/// 高级统计区（会员版）
class AdvancedStatisticsSection extends ConsumerWidget {
  const AdvancedStatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advancedStatsAsync = ref.watch(advancedStatisticsProvider);

    return advancedStatsAsync.when(
      data: (stats) {
        if (stats == null) {
          return _buildUpgradePrompt(context, ref);
        }
        return _buildAdvancedStatistics(context, stats);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载失败: $error')),
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
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
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
                NavigationHelper.pushWithTransition(
                  context,
                  ref,
                  const MembershipPage(),
                );
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

  Widget _buildAdvancedStatistics(
    BuildContext context,
    AdvancedStatistics stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💎 高级统计',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TagCloudCard(tagCloud: stats.tagCloud),
        const SizedBox(height: 16),
        EmotionIntensityCard(distribution: stats.emotionIntensityDistribution),
        const SizedBox(height: 16),
        WeatherDistributionCard(distribution: stats.weatherDistribution),
        const SizedBox(height: 16),
        PlaceTypeDistributionCard(distribution: stats.placeTypeDistribution),
        const SizedBox(height: 16),
        MonthlyChartCard(
          monthlyDistributionByRange: stats.monthlyDistributionByRange,
        ),
        const SizedBox(height: 16),
        SuccessRateTrendCard(
          monthlySuccessRatesByRange: stats.monthlySuccessRatesByRange,
        ),
        const SizedBox(height: 16),
        FieldRankingCard(fieldRankings: stats.fieldRankings),
      ],
    );
  }
}
