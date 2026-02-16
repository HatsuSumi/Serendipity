import 'package:flutter/material.dart';

/// 消息提示工具类
/// 提供统一的消息提示样式和行为
class MessageHelper {
  /// 显示成功消息（右上角浮动）
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showOverlayMessage(
      context,
      message: message,
      duration: duration,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// 显示错误消息（右上角浮动）
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showOverlayMessage(
      context,
      message: message,
      duration: duration,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  /// 显示警告消息（右上角浮动）
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showOverlayMessage(
      context,
      message: message,
      duration: duration,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  /// 显示信息消息（右上角浮动）
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showOverlayMessage(
      context,
      message: message,
      duration: duration,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  /// 显示普通消息（右上角浮动，使用主题色）
  static void showMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showOverlayMessage(
      context,
      message: message,
      duration: duration,
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      icon: null,
    );
  }

  /// 内部方法：使用 Overlay 显示浮动消息
  static void _showOverlayMessage(
    BuildContext context, {
    required String message,
    required Duration duration,
    required Color backgroundColor,
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    // 用于控制动画的 ValueNotifier
    final animationController = ValueNotifier<double>(0.0);

    overlayEntry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<double>(
        valueListenable: animationController,
        builder: (context, value, child) {
          return Positioned(
            top: 80,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: AnimatedSlide(
                offset: Offset(1 - value, 0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: value,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 滑入动画
    Future.delayed(const Duration(milliseconds: 50), () {
      animationController.value = 1.0;
    });

    // 延迟后滑出并移除
    Future.delayed(duration, () async {
      // 滑出动画
      animationController.value = 0.0;
      
      // 等待动画完成后移除
      await Future.delayed(const Duration(milliseconds: 300));
      overlayEntry.remove();
      animationController.dispose();
    });
  }
}
