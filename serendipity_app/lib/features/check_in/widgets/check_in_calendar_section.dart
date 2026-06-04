import 'package:flutter/material.dart';

import '../../../core/providers/check_in_provider.dart';
import '../check_in_calendar_helper.dart';

class CheckInCalendarSection extends StatelessWidget {
  static const double _dayDotSize = 28;
  static const double _dayCellHeight = 36;

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
    final totalCells = (daysInMonth + firstWeekday + 6) ~/ 7 * 7;

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
                  children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
                    return Expanded(
                      child: SizedBox(
                        height: 20,
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
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                ...List.generate(totalCells ~/ 7, (weekIndex) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: weekIndex == totalCells ~/ 7 - 1 ? 0 : 8,
                    ),
                    child: Row(
                      children: List.generate(7, (dayIndex) {
                        final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                        final isValidDay = dayNumber >= 1 && dayNumber <= daysInMonth;

                        if (!isValidDay) {
                          return const Expanded(
                            child: SizedBox(height: _dayCellHeight),
                          );
                        }

                        final date = DateTime(
                          currentMonth.year,
                          currentMonth.month,
                          dayNumber,
                        );
                        final checkedIn = isCheckedIn(date, checkInDates);
                        final hasLeftConnection = checkedIn &&
                            isCheckedIn(
                              date.subtract(const Duration(days: 1)),
                              checkInDates,
                            );
                        final hasRightConnection = checkedIn &&
                            isCheckedIn(
                              date.add(const Duration(days: 1)),
                              checkInDates,
                            );

                        return Expanded(
                          child: SizedBox(
                            height: _dayCellHeight,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final horizontalInset =
                                    (constraints.maxWidth - _dayDotSize) / 2;
                                final leftInset =
                                    hasLeftConnection ? 0.0 : horizontalInset;
                                final rightInset =
                                    hasRightConnection ? 0.0 : horizontalInset;

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (checkedIn)
                                      Positioned(
                                        left: leftInset,
                                        right: rightInset,
                                        child: Container(
                                          height: _dayDotSize,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(
                                                hasLeftConnection ? 0 : _dayDotSize / 2,
                                              ),
                                              right: Radius.circular(
                                                hasRightConnection ? 0 : _dayDotSize / 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Center(
                                      child: Text(
                                        '$dayNumber',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: checkedIn
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontWeight: checkedIn
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
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
