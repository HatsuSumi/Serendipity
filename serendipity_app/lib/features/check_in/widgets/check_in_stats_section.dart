import 'package:flutter/material.dart';

import '../../../core/providers/check_in_provider.dart';

class CheckInStatsSection extends StatelessWidget {
  final CheckInState state;
  final ColorScheme colorScheme;

  const CheckInStatsSection({
    super.key,
    required this.state,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _CheckInStatCard(
              icon: Icons.local_fire_department,
              label: '连续签到',
              value: '${state.consecutiveDays} 天',
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CheckInStatCard(
              icon: Icons.calendar_month,
              label: '本月签到',
              value: '${state.currentMonthDays} 天',
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CheckInStatCard(
              icon: Icons.emoji_events,
              label: '累计签到',
              value: '${state.totalDays} 天',
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _CheckInStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

