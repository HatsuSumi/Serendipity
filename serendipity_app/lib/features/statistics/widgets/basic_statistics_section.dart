import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/statistics_provider.dart';
import 'basic_statistics_overview_card.dart';
import 'status_statistics_card.dart';
import 'success_rate_card.dart';

class BasicStatisticsSection extends ConsumerWidget {
  const BasicStatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(statisticsOverviewProvider);

    return overviewAsync.when(
      data: (overview) {
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
            BasicStatisticsOverviewCard(overview: overview),
            const SizedBox(height: 16),
            StatusStatisticsCard(stats: stats),
            const SizedBox(height: 16),
            SuccessRateCard(stats: stats),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('加载失败: $error'),
      ),
    );
  }
}
