import 'package:flutter/material.dart';

/// 带倒计时功能的按钮
/// 
/// 用于发送验证码等需要防止频繁点击的场景。
/// 遵循单一职责原则（SRP）和 DRY 原则。
/// 
/// 调用者：
/// - LoginPage：发送手机验证码
/// - RegisterPage：发送手机验证码
/// - SettingsPage：更换/绑定手机号时发送验证码
class CountdownButton extends StatefulWidget {
  /// 按钮文本
  final String text;
  
  /// 点击回调（返回 true 表示操作成功，开始倒计时）
  final Future<bool> Function() onPressed;
  
  /// 倒计时秒数（默认 60 秒）
  final int countdownSeconds;
  
  /// 倒计时文本格式（默认 "{count}s"）
  final String Function(int)? countdownTextBuilder;
  
  /// 是否启用
  final bool enabled;
  
  const CountdownButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.countdownSeconds = 60,
    this.countdownTextBuilder,
    this.enabled = true,
  });

  @override
  State<CountdownButton> createState() => _CountdownButtonState();
}

class _CountdownButtonState extends State<CountdownButton> {
  int _countdown = 0;
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled || _countdown > 0 || _isLoading;
    
    return ElevatedButton(
      onPressed: isDisabled ? null : _handlePressed,
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_getButtonText()),
    );
  }
  
  /// 获取按钮文本
  String _getButtonText() {
    if (_countdown > 0) {
      return widget.countdownTextBuilder?.call(_countdown) ?? '${_countdown}s';
    }
    return widget.text;
  }
  
  /// 处理按钮点击
  Future<void> _handlePressed() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await widget.onPressed();
      
      if (success && mounted) {
        // 操作成功，开始倒计时
        setState(() {
          _countdown = widget.countdownSeconds;
        });
        
        _startCountdown();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 启动倒计时
  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
        });
        return _countdown > 0;
      }
      return false;
    });
  }
}

