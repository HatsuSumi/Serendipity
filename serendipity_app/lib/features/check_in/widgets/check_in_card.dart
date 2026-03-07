import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../core/providers/check_in_provider.dart';
import '../../../core/providers/user_settings_provider.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/utils/check_in_badge_helper.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/utils/check_in_animation_helper.dart';
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

  @override
  Widget build(BuildContext context) {
    final checkInState = ref.watch(checkInProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                // 左侧：签到图标和状态
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
                                : '已连续签到 ${checkInState.consecutiveDays} 天',
                            style: TextStyle(
                              fontSize: 12,
                              color: checkInState.hasCheckedInToday
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                                  : colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                          if (checkInState.consecutiveDays > 0) ...[
                            const SizedBox(width: 8),
                            _buildBadgeWidget(checkInState.consecutiveDays, colorScheme),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // 右侧：签到按钮
                _buildCheckInButton(context, ref, checkInState, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakIndicator(CheckInState state, ColorScheme colorScheme) {
    final days = state.consecutiveDays;
    final maxDots = 7;
    final filledDots = days.clamp(0, maxDots);

    return Row(
      children: List.generate(maxDots, (index) {
        final isFilled = index < filledDots;
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
                      ? colorScheme.onSurface.withValues(alpha: 0.1)
                      : colorScheme.onPrimaryContainer.withValues(alpha: 0.2)),
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

  Widget _buildCheckInButton(
    BuildContext context,
    WidgetRef ref,
    CheckInState state,
    ColorScheme colorScheme,
  ) {
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
      onCheckInSuccess: _handleCheckInSuccess,
    );
  }
  
  /// 处理签到成功
  Future<void> _handleCheckInSuccess() async {
    // 读取用户设置
    final settings = ref.read(userSettingsProvider);
    
    // 触发粒子效果和震动（根据用户设置）
    if (widget.confettiController != null) {
      await CheckInAnimationHelper.triggerSuccessFeedback(
        confettiController: widget.confettiController!,
        enableVibration: settings.checkInVibrationEnabled,
        enableConfetti: settings.checkInConfettiEnabled,
      );
    }
    
    // 显示成功消息
    if (mounted && context.mounted) {
      MessageHelper.showSuccess(context, '签到成功！今天也要加油哦 ✨');
    }
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
