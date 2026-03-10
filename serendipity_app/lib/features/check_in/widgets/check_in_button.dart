import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/check_in_provider.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/utils/auth_error_helper.dart';

/// 签到按钮组件（带防抖逻辑和动画）
/// 
/// 功能：
/// - 防止重复点击
/// - 点击时缩放动画
/// 
/// 设计原则：
/// - 单一职责原则（SRP）：只负责签到按钮的交互和动画
/// - 通过回调通知父组件签到成功
class CheckInButton extends ConsumerStatefulWidget {
  final ColorScheme colorScheme;
  final VoidCallback onCheckInSuccess;
  final EdgeInsets padding;
  final double fontSize;
  final String text;

  const CheckInButton({
    super.key,
    required this.colorScheme,
    required this.onCheckInSuccess,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.fontSize = 14,
    this.text = '签到',
  });

  @override
  ConsumerState<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends ConsumerState<CheckInButton> {
  bool _isCheckingIn = false;
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isAnimating ? 0.7 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOutBack,
      child: ElevatedButton(
        onPressed: _isCheckingIn ? null : _handleCheckIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.colorScheme.primary,
          foregroundColor: widget.colorScheme.onPrimary,
          padding: widget.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isCheckingIn
            ? SizedBox(
                width: widget.fontSize,
                height: widget.fontSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckingIn) return;

    // 1. 播放按钮点击动画（缩小）
    setState(() {
      _isAnimating = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (!mounted) return;
    
    // 2. 恢复按钮大小
    setState(() {
      _isAnimating = false;
    });
    
    // 等待恢复动画完成
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (!mounted) return;
    
    // 3. 显示加载状态
    setState(() {
      _isCheckingIn = true;
    });

    try {
      // 4. 执行签到
      await ref.read(checkInProvider.notifier).checkIn();
      
      // 5. 通知父组件签到成功（在 Widget 销毁前调用）
      widget.onCheckInSuccess();
    } catch (e) {
      if (mounted && context.mounted) {
        MessageHelper.showError(context, '签到失败：${AuthErrorHelper.extractErrorMessage(e)}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }
}

