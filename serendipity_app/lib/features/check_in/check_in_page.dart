import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/check_in_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/check_in_badge_helper.dart';

/// 签到详情页面
/// 
/// 显示签到日历、统计数据、成就进度
/// 
/// 调用者：
/// - CheckInCard：点击卡片进入
/// - SettingsPage：从设置页面进入
class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final checkInState = ref.watch(checkInProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日签到'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 签到按钮区域
            _buildCheckInSection(checkInState, colorScheme),
            
            const SizedBox(height: 16),
            
            // 统计数据
            _buildStatsSection(checkInState, colorScheme),
            
            const SizedBox(height: 24),
            
            // 签到日历
            _buildCalendarSection(checkInState, colorScheme),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInSection(CheckInState state, ColorScheme colorScheme) {
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
          Text(
            state.hasCheckedInToday ? '✓' : '❌',
            style: const TextStyle(fontSize: 48),
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
                _buildBadge(state.consecutiveDays, colorScheme),
              ],
            ],
          ),
          if (!state.hasCheckedInToday) ...[
            const SizedBox(height: 20),
            _CheckInButton(colorScheme: colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(CheckInState state, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.local_fire_department,
              '连续签到',
              '${state.consecutiveDays} 天',
              colorScheme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              Icons.calendar_month,
              '本月签到',
              '${state.currentMonthDays} 天',
              colorScheme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              Icons.emoji_events,
              '累计签到',
              '${state.totalDays} 天',
              colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
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

  Widget _buildCalendarSection(CheckInState state, ColorScheme colorScheme) {
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
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(
                          _currentMonth.year,
                          _currentMonth.month - 1,
                        );
                      });
                    },
                  ),
                  Text(
                    '${_currentMonth.year}年${_currentMonth.month}月',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      final now = DateTime.now();
                      final nextMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                      );
                      // 不能查看未来月份
                      if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                        setState(() {
                          _currentMonth = nextMonth;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendar(state, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCalendar(CheckInState state, ColorScheme colorScheme) {
    final checkInDates = ref.read(checkInProvider.notifier).getCheckInDatesInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );

    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0=周日, 1=周一, ...

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
          // 星期标题
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
          // 日期网格
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

                  final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                  final isCheckedIn = checkInDates.any((d) =>
                      d.year == date.year &&
                      d.month == date.month &&
                      d.day == date.day);

                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCheckedIn
                          ? colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCheckedIn
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: isCheckedIn ? FontWeight.bold : FontWeight.normal,
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
    );
  }

  Widget _buildBadge(int consecutiveDays, ColorScheme colorScheme) {
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

/// 签到按钮组件（带防抖逻辑）
/// 
/// 使用 StatefulWidget 管理按钮状态，防止重复点击
class _CheckInButton extends ConsumerStatefulWidget {
  final ColorScheme colorScheme;

  const _CheckInButton({required this.colorScheme});

  @override
  ConsumerState<_CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends ConsumerState<_CheckInButton> {
  bool _isCheckingIn = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isCheckingIn ? null : _handleCheckIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.colorScheme.primary,
        foregroundColor: widget.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: _isCheckingIn
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.colorScheme.onPrimary,
                ),
              ),
            )
          : const Text(
              '立即签到',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckingIn) return;

    setState(() {
      _isCheckingIn = true;
    });

    try {
      await ref.read(checkInProvider.notifier).checkIn();
      if (mounted && context.mounted) {
        MessageHelper.showSuccess(context, '签到成功！今天也要加油哦 ✨');
      }
    } catch (e) {
      if (mounted && context.mounted) {
        MessageHelper.showError(context, '签到失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }
}

