import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../providers/dialog_animation_provider.dart';
import 'message_helper.dart';

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
      transitionDuration: selectedAnimation == null 
          ? Duration.zero 
          : const Duration(milliseconds: 250),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        if (selectedAnimation == null) {
          // 无动画，直接返回
          return child;
        }
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
  static _InternalAnimationType? _selectAnimation(DialogAnimationType userPreference) {
    if (userPreference == DialogAnimationType.none) {
      // 无动画
      return null;
    } else if (userPreference == DialogAnimationType.random) {
      // 随机选择（排除 none 和 random 本身）
      return _getRandomAnimationType();
    } else {
      // 映射用户选择到内部动画类型
      return _mapToInternalType(userPreference);
    }
  }

  /// 映射用户选择到内部动画类型
  static _InternalAnimationType _mapToInternalType(DialogAnimationType type) {
    switch (type) {
      case DialogAnimationType.none:
      case DialogAnimationType.random:
        // Fail Fast: 这两个值应该在 _selectAnimation 中处理
        throw AssertionError(
          'DialogAnimationType.none and DialogAnimationType.random '
          'should be handled in _selectAnimation, not here.'
        );
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

  /// 显示删除确认对话框
  /// 
  /// 返回 `true` 表示用户确认删除，`false` 或 `null` 表示取消
  /// 
  /// 示例：
  /// ```dart
  /// final confirmed = await DialogHelper.showDeleteConfirm(
  ///   context: context,
  ///   title: '删除记录',
  ///   content: '确定要删除这条记录吗？此操作无法撤销。',
  /// );
  /// 
  /// if (confirmed == true) {
  ///   // 执行删除操作
  /// }
  /// ```
  static Future<bool?> showDeleteConfirm({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return show<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示重命名对话框
  /// 
  /// 返回新名称字符串，如果用户取消则返回 `null`
  /// 
  /// 参数：
  /// - [context]: BuildContext
  /// - [title]: 对话框标题（例如：'重命名故事线'）
  /// - [initialValue]: 初始值（当前名称）
  /// - [hintText]: 输入框提示文本（例如：'输入新名称...'）
  /// - [emptyWarning]: 空值警告消息（例如：'请输入故事线名称'）
  /// 
  /// 示例：
  /// ```dart
  /// final newName = await DialogHelper.showRenameDialog(
  ///   context: context,
  ///   title: '重命名故事线',
  ///   initialValue: storyLine.name,
  ///   hintText: '输入新名称...',
  ///   emptyWarning: '请输入故事线名称',
  /// );
  /// 
  /// if (newName != null) {
  ///   // 执行重命名操作
  /// }
  /// ```
  static Future<String?> showRenameDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    String hintText = '输入新名称...',
    String emptyWarning = '名称不能为空',
  }) {
    final nameController = TextEditingController(text: initialValue);

    return show<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                // 使用 MessageHelper 显示警告
                MessageHelper.showError(context, emptyWarning);
                return;
              }
              Navigator.of(context).pop(name);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}

