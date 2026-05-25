import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// 签到动画工具类
/// 
/// 职责：
/// - 提供签到成功粒子效果
/// - 提供震动反馈
/// 
/// 设计原则：
/// - 单一职责原则（SRP）：只负责签到相关的动画和反馈
/// - DRY原则：统一管理所有签到动画逻辑，避免重复
/// - 依赖倒置原则（DIP）：不依赖具体Widget，通过参数传递
/// - 平台兼容优先：Android 使用更可靠的振动能力，其他平台保留系统触感反馈
class CheckInAnimationHelper {
  CheckInAnimationHelper._();

  static const int _androidVibrationDurationMs = 40;
  static const int _androidVibrationAmplitude = 180;

  /// 触发签到成功的完整反馈
  static Future<void> triggerSuccessFeedback({
    required ConfettiController confettiController,
    bool enableVibration = true,
    bool enableConfetti = true,
  }) async {
    if (enableVibration) {
      await triggerHapticFeedback();
    }

    if (enableConfetti) {
      confettiController.play();
    }
  }

  /// 触发震动反馈
  ///
  /// 实现策略：
  /// - Android：优先使用 vibration 插件直接触发短振动，提升 OEM 机型一致性
  /// - 其他平台：回退到系统 HapticFeedback
  static Future<void> triggerHapticFeedback() async {
    try {
      if (Platform.isAndroid) {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator) {
          final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
          await Vibration.vibrate(
            duration: _androidVibrationDurationMs,
            amplitude: hasAmplitudeControl ? _androidVibrationAmplitude : -1,
          );
          return;
        }
      }

      await HapticFeedback.mediumImpact();
    } catch (_) {
      // 震动失败不影响功能，静默处理
    }
  }

  /// 创建粒子效果控制器
  static ConfettiController createConfettiController() {
    return ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  /// 创建粒子效果Widget
  static Widget createConfettiWidget({
    required ConfettiController controller,
    List<Color>? colors,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirection: 3.14 / 2,
        emissionFrequency: 0.05,
        numberOfParticles: 20,
        gravity: 0.3,
        shouldLoop: false,
        colors: colors ?? [
          Colors.pink,
          Colors.purple,
          Colors.blue,
          Colors.orange,
          Colors.yellow,
        ],
      ),
    );
  }
}
