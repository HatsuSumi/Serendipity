import 'package:flutter/material.dart';

import '../../../core/utils/dialog_helper.dart';
import '../../../models/statistics.dart';

class SuccessRateCard extends StatelessWidget {
  final BasicStatistics stats;

  const SuccessRateCard({
    super.key,
    required this.stats,
  });

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
          if (successRate == 0 && stats.totalRecords >= 5) ...[
            Text(
              '每一次，都没有开口。\n\n你比任何人都清楚\n那一刻你在想什么。\n\n下一次，\n还是同样的答案吗？',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _InfoRow(label: '最常见的地点', value: mostCommonPlace, expandValue: true),
          const SizedBox(height: 12),
          _InfoRow(label: '最常见的场所', value: placeTypeStr),
          const SizedBox(height: 12),
          _InfoRow(label: '最常见的省', value: mostCommonProvince),
          const SizedBox(height: 12),
          _InfoRow(label: '最常见的市', value: mostCommonCity),
          const SizedBox(height: 12),
          _InfoRow(label: '最常见的区', value: mostCommonArea),
          const SizedBox(height: 12),
          _InfoRow(label: '最常见的时间', value: timeStr),
          const SizedBox(height: 12),
          _InfoRow(label: '最常见的天气', value: weatherStr),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool expandValue;

  const _InfoRow({
    required this.label,
    required this.value,
    this.expandValue = false,
  });

  @override
  Widget build(BuildContext context) {
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
          child: const Text('我知道了'),
        ),
      ],
    ),
  );
}

