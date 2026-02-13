import 'dart:math';
import 'package:flutter/material.dart';

/// 对话框动画类型
enum DialogAnimationType {
  fade,        // 淡入
  scale,       // 缩放
  slideUp,     // 从下往上滑入
  slideDown,   // 从上往下滑入
  slideLeft,   // 从右往左滑入
  slideRight,  // 从左往右滑入
  fadeScale,   // 淡入+缩放
  fadeSlide,   // 淡入+滑动
}

/// 对话框辅助工具类
class DialogHelper {
  DialogHelper._();

  /// 显示自定义动画对话框
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    DialogAnimationType? animationType,
  }) {
    // 如果没有指定动画类型，随机选择一个
    final selectedAnimation = animationType ?? _getRandomAnimationType();
    
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          animation: animation,
          child: child,
          type: selectedAnimation,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
    );
  }

  /// 获取随机动画类型
  static DialogAnimationType _getRandomAnimationType() {
    final random = Random();
    final values = DialogAnimationType.values;
    return values[random.nextInt(values.length)];
  }

  /// 构建动画过渡效果
  static Widget _buildTransition({
    required Animation<double> animation,
    required Widget child,
    required DialogAnimationType type,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    switch (type) {
      case DialogAnimationType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case DialogAnimationType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: child,
        );

      case DialogAnimationType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case DialogAnimationType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case DialogAnimationType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case DialogAnimationType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case DialogAnimationType.fadeScale:
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );

      case DialogAnimationType.fadeSlide:
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
    }
  }
}

