import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/statistics.dart';

class BasicStatisticsOverviewCard extends StatelessWidget {
  final StatisticsOverview overview;

  const BasicStatisticsOverviewCard({
    super.key,
    required this.overview,
  });

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
          label: '账号创建时间',
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
                subtitle: '${overview.linkedRecordPercentage.toStringAsFixed(1)}%',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.link_off_rounded,
                label: '未关联故事线记录',
                value: '${overview.unlinkedRecordCount}',
                subtitle: '${overview.unlinkedRecordPercentage.toStringAsFixed(1)}%',
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

    final localStartDate = startDate.toLocal();
    final localEndDate = endDate.toLocal();
    return '${_dateFormatter.format(localStartDate)}-${_dateFormatter.format(localEndDate)}';
  }

  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    return _dateTimeFormatter.format(dateTime.toLocal());
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

