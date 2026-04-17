import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../core/providers/check_in_provider.dart';
import '../../core/providers/user_settings_provider.dart';
import '../../core/utils/check_in_animation_helper.dart';
import '../../core/utils/message_helper.dart';
import 'check_in_calendar_helper.dart';
import 'widgets/check_in_calendar_section.dart';
import 'widgets/check_in_page_header_card.dart';
import 'widgets/check_in_stats_section.dart';

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
  ConfettiController? _confettiController;
  
  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _confettiController = CheckInAnimationHelper.createConfettiController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkInProvider.notifier).refresh(month: _currentMonth);
    });
  }
  
  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInStateAsync = ref.watch(checkInProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日签到'),
        centerTitle: true,
      ),
      body: checkInStateAsync.when(
        data: (checkInState) => _buildContent(checkInState, colorScheme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('加载失败：$error'),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建主内容
  Widget _buildContent(CheckInState checkInState, ColorScheme colorScheme) {
    final checkInDates = ref.read(checkInProvider.notifier).getCheckInDatesInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              CheckInPageHeaderCard(
                state: checkInState,
                colorScheme: colorScheme,
                onCheckInSuccess: _handleCheckInSuccess,
              ),
              const SizedBox(height: 16),
              CheckInStatsSection(
                state: checkInState,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 24),
              CheckInCalendarSection(
                state: checkInState,
                currentMonth: _currentMonth,
                colorScheme: colorScheme,
                checkInDates: checkInDates,
                onPreviousMonth: _showPreviousMonth,
                onNextMonth: _canGoToNextMonth() ? _showNextMonth : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (_confettiController != null)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: CheckInAnimationHelper.createConfettiWidget(
                controller: _confettiController!,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showPreviousMonth() async {
    final previousMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month - 1,
    );
    setState(() {
      _currentMonth = previousMonth;
    });
    await ref.read(checkInProvider.notifier).refresh(month: previousMonth);
  }

  Future<void> _showNextMonth() async {
    final nextMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
    );
    if (!_canGoToNextMonth()) {
      return;
    }
    setState(() {
      _currentMonth = nextMonth;
    });
    await ref.read(checkInProvider.notifier).refresh(month: nextMonth);
  }

  bool _canGoToNextMonth() {
    return canGoToNextMonth(_currentMonth, DateTime.now());
  }

  /// 处理签到成功
  Future<void> _handleCheckInSuccess() async {
    final settings = ref.read(userSettingsProvider);

    if (_confettiController != null) {
      await CheckInAnimationHelper.triggerSuccessFeedback(
        confettiController: _confettiController!,
        enableVibration: settings.checkInVibrationEnabled,
        enableConfetti: settings.checkInConfettiEnabled,
      );
    }

    if (mounted && context.mounted) {
      MessageHelper.showSuccess(context, '签到成功！今天也要加油哦 ✨');
    }
  }
}

