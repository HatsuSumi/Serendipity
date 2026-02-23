import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

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
class CheckInAnimationHelper {
  CheckInAnimationHelper._(); // 私有构造函数，防止实例化

  /// 触发签到成功的完整反馈
  /// 
  /// 包含：
  /// 1. 震动反馈
  /// 2. 粒子效果
  /// 
  /// 参数：
  /// - [confettiController] 粒子效果控制器
  /// 
  /// 使用示例：
  /// ```dart
  /// await CheckInAnimationHelper.triggerSuccessFeedback(
  ///   confettiController: _confettiController,
  /// );
  /// ```
  static Future<void> triggerSuccessFeedback({
    required ConfettiController confettiController,
  }) async {
    // 1. 触发震动反馈
    await triggerHapticFeedback();
    
    // 2. 触发粒子效果
    confettiController.play();
  }

  /// 触发震动反馈
  /// 
  /// 使用 HapticFeedback.mediumImpact() 提供中等强度的震动
  /// 
  /// 注意：
  /// - iOS 和 Android 都支持
  /// - 用户可以在系统设置中关闭震动
  /// - 不会抛出异常，静默失败
  static Future<void> triggerHapticFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // 震动失败不影响功能，静默处理
      // 遵循原则：UI层允许安全fallback
    }
  }

  /// 创建粒子效果控制器
  /// 
  /// 返回一个 ConfettiController，用于控制粒子效果
  /// 
  /// 使用示例：
  /// ```dart
  /// late ConfettiController _confettiController;
  /// 
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _confettiController = CheckInAnimationHelper.createConfettiController();
  /// }
  /// 
  /// @override
  /// void dispose() {
  ///   _confettiController.dispose();
  ///   super.dispose();
  /// }
  /// ```
  static ConfettiController createConfettiController() {
    return ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  /// 创建粒子效果Widget
  /// 
  /// 返回一个 ConfettiWidget，用于显示粒子效果
  /// 
  /// 参数：
  /// - [controller] ConfettiController
  /// - [colors] 粒子颜色列表（可选）
  /// 
  /// 使用示例：
  /// ```dart
  /// Stack(
  ///   children: [
  ///     // 你的内容
  ///     child,
  ///     // 粒子效果（覆盖在最上层）
  ///     CheckInAnimationHelper.createConfettiWidget(
  ///       controller: _confettiController,
  ///     ),
  ///   ],
  /// )
  /// ```
  static Widget createConfettiWidget({
    required ConfettiController controller,
    List<Color>? colors,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirection: 3.14 / 2, // 向下
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

