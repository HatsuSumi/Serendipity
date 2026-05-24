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
  late final ProviderSubscription<int> _checkInSuccessSubscription;

  @override
  void initState() {
    super.initState();
    _checkInSuccessSubscription = ref.listenManual<int>(
      checkInSuccessEventProvider,
      (previous, next) {
        if (previous == null || next == previous) {
          return;
        }

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
    _checkInSuccessSubscription.close();
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
    return Row(
      children: [
        Text(
          '${state.totalDays}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: state.hasCheckedInToday
                ? colorScheme.onSurface
                : colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '累计签到天数',
          style: TextStyle(
            fontSize: 14,
            color: state.hasCheckedInToday
                ? colorScheme.onSurface.withValues(alpha: 0.7)
                : colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeWidget(int consecutiveDays, ColorScheme colorScheme) {
    final badge = CheckInBadgeHelper.getBadge(consecutiveDays);

    return GestureDetector(
      onTap: () => _showBadgeDialog(badge, colorScheme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          badge.icon,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCheckInButton(CheckInState state, ColorScheme colorScheme) {
    if (state.hasCheckedInToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '已签到',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return CheckInButton(colorScheme: colorScheme);
  }

  Future<void> _playCheckInSuccessFeedback() async {
    final settings = ref.read(userSettingsProvider);

    if (settings.checkInVibrationEnabled) {
      await CheckInAnimationHelper.triggerHapticFeedback();
    }
    if (settings.checkInConfettiEnabled && widget.confettiController != null) {
      widget.confettiController!.play();
    }

    if (mounted && context.mounted) {
      MessageHelper.showSuccess(context, '签到成功！今天也要加油哦 ✨');
    }
  }

  Future<void> _showBadgeDialog(CheckInBadgeLevel badge, ColorScheme colorScheme) {
    return DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(child: Text(badge.name)),
          ],
        ),
        content: Text('连续签到 ${badge.minDays} 天以上可获得该徽章。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
