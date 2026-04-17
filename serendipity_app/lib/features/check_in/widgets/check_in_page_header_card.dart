import 'package:flutter/material.dart';

import '../../../core/providers/check_in_provider.dart';
import '../../../core/utils/check_in_badge_helper.dart';
import 'check_in_button.dart';

class CheckInPageHeaderCard extends StatelessWidget {
  final CheckInState state;
  final ColorScheme colorScheme;
  final VoidCallback onCheckInSuccess;

  const CheckInPageHeaderCard({
    super.key,
    required this.state,
    required this.colorScheme,
    required this.onCheckInSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: state.hasCheckedInToday
              ? [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainerHigh,
                ]
              : [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.hasCheckedInToday
                  ? Colors.green
                  : colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
            ),
            child: Icon(
              state.hasCheckedInToday ? Icons.check : Icons.event_available,
              size: 32,
              color: state.hasCheckedInToday
                  ? Colors.white
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.hasCheckedInToday ? '今天已签到' : '点击签到',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: state.hasCheckedInToday
                  ? colorScheme.onSurface.withValues(alpha: 0.6)
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.hasCheckedInToday
                    ? '今天也要加油哦 ✨'
                    : '已连续签到 ${state.consecutiveDays} 天',
                style: TextStyle(
                  fontSize: 14,
                  color: state.hasCheckedInToday
                      ? colorScheme.onSurface.withValues(alpha: 0.5)
                      : colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              if (state.consecutiveDays > 0) ...[
                const SizedBox(width: 8),
                _CheckInBadge(
                  consecutiveDays: state.consecutiveDays,
                  colorScheme: colorScheme,
                ),
              ],
            ],
          ),
          if (!state.hasCheckedInToday) ...[
            const SizedBox(height: 20),
            CheckInButton(
              colorScheme: colorScheme,
              onCheckInSuccess: onCheckInSuccess,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              fontSize: 16,
              text: '立即签到',
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckInBadge extends StatelessWidget {
  final int consecutiveDays;
  final ColorScheme colorScheme;

  const _CheckInBadge({
    required this.consecutiveDays,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final badge = CheckInBadgeHelper.getBadge(consecutiveDays);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.icon,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

