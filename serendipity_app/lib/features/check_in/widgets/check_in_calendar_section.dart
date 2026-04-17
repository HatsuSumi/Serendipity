import 'package:flutter/material.dart';

import '../../../core/providers/check_in_provider.dart';
import '../check_in_calendar_helper.dart';

class CheckInCalendarSection extends StatelessWidget {
  final CheckInState state;
  final DateTime currentMonth;
  final ColorScheme colorScheme;
  final List<DateTime> checkInDates;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;

  const CheckInCalendarSection({
    super.key,
    required this.state,
    required this.currentMonth,
    required this.colorScheme,
    required this.checkInDates,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = getDaysInMonth(currentMonth);
    final firstWeekday = getFirstWeekdayOfMonth(currentMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '签到日历',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: onPreviousMonth,
                  ),
                  Text(
                    '${currentMonth.year}年${currentMonth.month}月',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: onNextMonth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
                    return SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                ...List.generate((daysInMonth + firstWeekday + 6) ~/ 7, (weekIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (dayIndex) {
                        final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const SizedBox(width: 32, height: 32);
                        }

                        final date = DateTime(currentMonth.year, currentMonth.month, dayNumber);
                        final checkedIn = isCheckedIn(date, checkInDates);
                        final partOfStreak = isPartOfStreak(date, checkInDates);
                        final streakStart = isStreakStart(date, checkInDates);
                        final streakEnd = isStreakEnd(date, checkInDates);

                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: partOfStreak
                                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.horizontal(
                              left: streakStart ? const Radius.circular(16) : Radius.zero,
                              right: streakEnd ? const Radius.circular(16) : Radius.zero,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: checkedIn ? colorScheme.primary : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: checkedIn
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: checkedIn ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

