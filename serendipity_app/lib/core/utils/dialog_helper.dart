import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../providers/dialog_animation_provider.dart';

/// 内部动画类型（用于实际动画实现）
enum _InternalAnimationType {
  fade,
  scale,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  fadeScale,
  fadeSlide,
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
  }) {
    // 从 Provider 读取用户设置的动画类型
    final container = ProviderScope.containerOf(context);
    final userPreference = container.read(dialogAnimationProvider);
    
    // 根据用户设置选择动画
    final selectedAnimation = _selectAnimation(userPreference);
    
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

  /// 根据用户设置选择动画类型
  static _InternalAnimationType _selectAnimation(DialogAnimationType userPreference) {
    if (userPreference == DialogAnimationType.random) {
      // 随机选择（排除 random 本身）
      return _getRandomAnimationType();
    } else {
      // 映射用户选择到内部动画类型
      return _mapToInternalType(userPreference);
    }
  }

  /// 映射用户选择到内部动画类型
  static _InternalAnimationType _mapToInternalType(DialogAnimationType type) {
    switch (type) {
      case DialogAnimationType.random:
        return _getRandomAnimationType(); // 不应该到这里
      case DialogAnimationType.fade:
        return _InternalAnimationType.fade;
      case DialogAnimationType.scale:
        return _InternalAnimationType.scale;
      case DialogAnimationType.slideUp:
        return _InternalAnimationType.slideUp;
      case DialogAnimationType.slideDown:
        return _InternalAnimationType.slideDown;
      case DialogAnimationType.slideLeft:
        return _InternalAnimationType.slideLeft;
      case DialogAnimationType.slideRight:
        return _InternalAnimationType.slideRight;
      case DialogAnimationType.fadeScale:
        return _InternalAnimationType.fadeScale;
      case DialogAnimationType.fadeSlide:
        return _InternalAnimationType.fadeSlide;
    }
  }

  /// 获取随机动画类型
  static _InternalAnimationType _getRandomAnimationType() {
    final random = Random();
    final values = _InternalAnimationType.values;
    return values[random.nextInt(values.length)];
  }

  /// 构建动画过渡效果
  static Widget _buildTransition({
    required Animation<double> animation,
    required Widget child,
    required _InternalAnimationType type,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    switch (type) {
      case _InternalAnimationType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case _InternalAnimationType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: child,
        );

      case _InternalAnimationType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case _InternalAnimationType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case _InternalAnimationType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case _InternalAnimationType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case _InternalAnimationType.fadeScale:
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );

      case _InternalAnimationType.fadeSlide:
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

