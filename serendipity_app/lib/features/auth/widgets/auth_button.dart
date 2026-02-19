import 'package:flutter/material.dart';

/// 认证按钮类型
enum AuthButtonType {
  /// 主要按钮（填充背景）
  primary,
  
  /// 次要按钮（边框样式）
  secondary,
}

/// 认证按钮组件
/// 
/// 统一的按钮样式，用于登录、注册、忘记密码等认证页面。
/// 遵循单一职责原则（SRP）和 DRY 原则。
/// 
/// 调用者：
/// - WelcomePage：登录按钮、注册按钮
/// - LoginPage：登录按钮、第三方登录按钮
/// - RegisterPage：注册按钮
/// - ForgotPasswordPage：发送重置邮件按钮
class AuthButton extends StatelessWidget {
  /// 按钮类型
  final AuthButtonType type;
  
  /// 按钮文本
  final String text;
  
  /// 点击回调
  final VoidCallback? onPressed;
  
  /// 是否显示加载状态
  final bool isLoading;
  
  /// 按钮宽度（默认为无限宽）
  final double? width;
  
  /// 前缀图标
  final IconData? prefixIcon;
  
  const AuthButton({
    super.key,
    this.type = AuthButtonType.primary,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.prefixIcon,
  });
  
  /// 创建主要按钮（快捷构造函数）
  /// 
  /// 调用者：
  /// - LoginPage：登录按钮
  /// - RegisterPage：注册按钮
  const AuthButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.prefixIcon,
  }) : type = AuthButtonType.primary;
  
  /// 创建次要按钮（快捷构造函数）
  /// 
  /// 调用者：
  /// - LoginPage：第三方登录按钮
  /// - WelcomePage：注册按钮
  const AuthButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.prefixIcon,
  }) : type = AuthButtonType.secondary;

  @override
  Widget build(BuildContext context) {
    // 按钮内容
    final child = _buildButtonChild(context);
    
    // 按钮样式
    final buttonStyle = _getButtonStyle(context);
    
    // 根据类型构建按钮
    final button = type == AuthButtonType.primary
        ? ElevatedButton(
            onPressed: _getOnPressed(),
            style: buttonStyle,
            child: child,
          )
        : OutlinedButton(
            onPressed: _getOnPressed(),
            style: buttonStyle,
            child: child,
          );
    
    // 如果指定了宽度，使用 SizedBox 包裹
    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }
    
    return button;
  }
  
  /// 构建按钮内容
  /// 
  /// 调用者：build()
  Widget _buildButtonChild(BuildContext context) {
    final theme = Theme.of(context);
    
    // 如果正在加载，显示加载指示器
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == AuthButtonType.primary
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
          ),
        ),
      );
    }
    
    // 如果有前缀图标，显示图标和文本
    if (prefixIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(prefixIcon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    
    // 只显示文本
    return Text(text);
  }
  
  /// 获取按钮点击回调
  /// 
  /// 调用者：build()
  /// 
  /// Fail Fast：加载状态时禁用按钮
  VoidCallback? _getOnPressed() {
    // 如果正在加载，禁用按钮
    if (isLoading) {
      return null;
    }
    
    return onPressed;
  }
  
  /// 获取按钮样式
  /// 
  /// 调用者：build()
  ButtonStyle _getButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    
    return ButtonStyle(
      // 按钮高度
      minimumSize: WidgetStateProperty.all(const Size(0, 48)),
      
      // 按钮形状
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // 按钮颜色（主要按钮使用主题色，次要按钮透明）
      backgroundColor: type == AuthButtonType.primary
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.primary.withValues(alpha: 0.5);
              }
              return theme.colorScheme.primary;
            })
          : WidgetStateProperty.all(Colors.transparent),
      
      // 文字颜色
      foregroundColor: type == AuthButtonType.primary
          ? WidgetStateProperty.all(theme.colorScheme.onPrimary)
          : WidgetStateProperty.all(theme.colorScheme.primary),
      
      // 边框颜色（次要按钮）
      side: type == AuthButtonType.secondary
          ? WidgetStateProperty.all(
              BorderSide(color: theme.colorScheme.primary),
            )
          : null,
    );
  }
}

