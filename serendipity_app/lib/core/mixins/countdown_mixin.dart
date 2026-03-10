import 'dart:async';
import 'package:flutter/material.dart';

/// 倒计时 Mixin
/// 
/// 职责：
/// - 提供倒计时功能
/// - 管理 Timer 生命周期
/// - 提供倒计时状态
/// 
/// 使用场景：
/// - 对话框按钮倒计时（PublishWarningDialog、CommunityIntroDialog）
/// 
/// 使用方法：
/// ```dart
/// class _MyDialogState extends State<MyDialog> with CountdownMixin {
///   @override
///   void initState() {
///     super.initState();
///     startCountdown(); // 或 startCountdown(skipCountdown: true)
///   }
///   
///   @override
///   void dispose() {
///     disposeCountdown();
///     super.dispose();
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     return FilledButton(
///       onPressed: countdownFinished ? () { ... } : null,
///       child: Text(countdownFinished ? '确定' : '确定 ($countdown)'),
///     );
///   }
/// }
/// ```
mixin CountdownMixin<T extends StatefulWidget> on State<T> {
  int _countdown = 5;
  bool _countdownFinished = false;
  Timer? _timer;

  /// 获取当前倒计时秒数
  int get countdown => _countdown;

  /// 获取倒计时是否完成
  bool get countdownFinished => _countdownFinished;

  /// 启动倒计时
  /// 
  /// [skipCountdown] 是否跳过倒计时（直接完成）
  /// [onFinished] 倒计时完成时的回调（可选）
  /// 
  /// 调用者：
  /// - initState()
  void startCountdown({
    bool skipCountdown = false,
    VoidCallback? onFinished,
  }) {
    if (skipCountdown) {
      _countdownFinished = true;
      // 在下一帧触发重建，确保 UI 更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
          onFinished?.call();
        }
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Fail Fast: 如果 Widget 已 dispose，立即取消 Timer
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _countdownFinished = true;
          timer.cancel();
          
          // 倒计时完成回调
          if (mounted) {
            onFinished?.call();
          }
        }
      });
    });
  }

  /// 清理倒计时资源
  /// 
  /// 调用者：
  /// - dispose()
  void disposeCountdown() {
    _timer?.cancel();
  }
}

