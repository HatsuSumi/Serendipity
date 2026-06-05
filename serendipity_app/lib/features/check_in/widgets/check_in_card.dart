import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../../core/providers/check_in_provider.dart';
import '../../../core/providers/user_settings_provider.dart';
import '../../../core/utils/check_in_animation_helper.dart';
import '../../../core/utils/check_in_badge_helper.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../models/check_in_record.dart';
import '../check_in_page.dart';
import 'check_in_button.dart';

/// 签到卡片Widget
/// 
/// 显示在时间轴页面顶部，提供快速签到功能
/// 
/// 调用者：
/// - TimelinePage：显示在页面顶部
class CheckInCard extends ConsumerStatefulWidget {
  final ConfettiController? confettiController;

  const CheckInCard({
    super.key,
    this.confettiController,
  });

  @override
  ConsumerState<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends ConsumerState<CheckInCard> {
  late final ProviderSubscription<AsyncValue<CheckInState>>
      _checkInSubscription;
  bool _hasTriggeredCheckInFeedback = false;

  @override
  void initState() {
    super.initState();
    _checkInSubscription = ref.listenManual<AsyncValue<CheckInState>>(
      checkInProvider,
      (previous, next) {
        final previousState = previous?.valueOrNull;
        final nextState = next.valueOrNull;

        if (nextState == null) {
          return;
        }

        if (!nextState.hasCheckedInToday) {
          _hasTriggeredCheckInFeedback = false;
        }

        if (previousState == null) {
          return;
        }

        final becameCheckedIn =
            !previousState.hasCheckedInToday && nextState.hasCheckedInToday;

        if (!becameCheckedIn || _hasTriggeredCheckInFeedback) {
          return;
        }

        _hasTriggeredCheckInFeedback = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _playCheckInSuccessFeedback();
        });
      },
    );
  }

  @override
  void dispose() {
    _checkInSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInStateAsync = ref.watch(checkInProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return checkInStateAsync.when(
      data: (checkInState) => _buildCard(context, checkInState, colorScheme),
      loading: () => _buildLoadingCard(colorScheme),
      error: (error, stack) => _buildErrorCard(colorScheme),
    );
  }

  /// 构建签到卡片
  Widget _buildCard(
    BuildContext context,
    CheckInState checkInState,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: checkInState.hasCheckedInToday
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            NavigationHelper.pushWithTransition(
              context,
              ref,
              const CheckInPage(),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 20,
                            color: checkInState.hasCheckedInToday
                                ? colorScheme.onSurface.withValues(alpha: 0.6)
                                : colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '每日签到',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: checkInState.hasCheckedInToday
                                  ? colorScheme.onSurface.withValues(alpha: 0.6)
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStreakIndicator(checkInState, colorScheme),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            checkInState.hasCheckedInToday
                                ? '今天已签到'
                                : '已连续签到 ${checkInState.displayConsecutiveDays} 天',
                            style: TextStyle(
                              fontSize: 12,
                              color: checkInState.hasCheckedInToday
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                                  : colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                          if (checkInState.consecutiveDays > 0) ...[
                            const SizedBox(width: 8),
                            _buildBadgeWidget(
                              checkInState.consecutiveDays,
                              colorScheme,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildCheckInButton(checkInState, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 加载中卡片
  Widget _buildLoadingCard(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  /// 错误卡片
  Widget _buildErrorCard(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.errorContainer,
            colorScheme.errorContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '签到数据加载失败',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakIndicator(CheckInState state, ColorScheme colorScheme) {
    final weekDates = _buildCurrentWeekDates();
    final checkedInDates = _normalizeCheckInDates(state.recentCheckIns);

    return Row(
      children: List.generate(weekDates.length, (index) {
        final date = weekDates[index];
        final isFilled = checkedInDates.contains(date);
        final isToday = _isSameDate(date, DateTime.now());

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? Colors.green
                  : (state.hasCheckedInToday
                      ? colorScheme.onSurface.withValues(alpha: isToday ? 0.18 : 0.1)
                      : colorScheme.onPrimaryContainer.withValues(alpha: isToday ? 0.28 : 0.2)),
              border: isToday
                  ? Border.all(
                      color: state.hasCheckedInToday
                          ? colorScheme.onSurface.withValues(alpha: 0.35)
                          : colorScheme.onPrimaryContainer.withValues(alpha: 0.45),
                    )
                  : null,
            ),
            child: isFilled
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
        );
      }),
    );
  }

  List<DateTime> _buildCurrentWeekDates() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final weekStart = normalizedToday.subtract(Duration(days: normalizedToday.weekday - 1));

    return List.generate(
      DateTime.daysPerWeek,
      (index) => weekStart.add(Duration(days: index)),
    );
  }

  Set<DateTime> _normalizeCheckInDates(List<CheckInRecord> checkIns) {
    return checkIns
        .map((record) => DateTime(record.date.year, record.date.month, record.date.day))
        .toSet();
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  Widget _buildCheckInButton(CheckInState state, ColorScheme colorScheme) {
    if (state.hasCheckedInToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '已签到',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return CheckInButton(
      colorScheme: colorScheme,
    );
  }

  Future<void> _playCheckInSuccessFeedback() async {
    final settings = ref.read(userSettingsProvider);

    if (settings.checkInVibrationEnabled) {
      await CheckInAnimationHelper.triggerHapticFeedback();
    }
    if (settings.checkInConfettiEnabled && widget.confettiController != null) {
      widget.confettiController!.play();
    }

    if (!mounted || !context.mounted) {
      return;
    }

    final checkInState = ref.read(checkInProvider).value;
    final consecutiveDays = checkInState?.consecutiveDays ?? 0;
    final totalDays = checkInState?.totalDays ?? 0;

    if (consecutiveDays == 1 && totalDays > 1) {
      final recentCheckIns = checkInState?.recentCheckIns ?? [];
      int gapDays = 0;
      if (recentCheckIns.length >= 2) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final lastDate = recentCheckIns[1].date;
        gapDays = todayDate.difference(lastDate).inDays - 1;
      }
      final gapText = gapDays > 0 ? '你消失了 $gapDays 天。\n\n' : '';
      DialogHelper.show<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(
            '$gapText那段时间，\n是发生了什么，\n还是什么都没发生？',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.8,
              fontStyle: FontStyle.italic,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('没什么'),
            ),
          ],
        ),
      );
      return;
    }

    MessageHelper.showSuccess(context, '签到成功！今天也要加油哦 ✨');
  }

  Widget _buildBadgeWidget(int consecutiveDays, ColorScheme colorScheme) {
    final badge = CheckInBadgeHelper.getBadge(consecutiveDays);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.icon,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 2),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
