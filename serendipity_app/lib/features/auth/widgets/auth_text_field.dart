import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/validation_helper.dart';

/// 认证输入框类型
enum AuthTextFieldType {
  /// 邮箱
  email,
  
  /// 密码
  password,
  
  /// 手机号
  phone,
  
  /// 验证码
  verificationCode,
  
  /// 普通文本
  text,
}

/// 国家代码选项
class CountryCode {
  final String code;
  final String name;
  final String flag;
  
  const CountryCode({
    required this.code,
    required this.name,
    required this.flag,
  });
  
  /// 常用国家代码列表
  static const List<CountryCode> commonCodes = [
    CountryCode(code: '+86', name: '中国', flag: '🇨🇳'),
    CountryCode(code: '+1', name: '美国', flag: '🇺🇸'),
    CountryCode(code: '+44', name: '英国', flag: '🇬🇧'),
    CountryCode(code: '+81', name: '日本', flag: '🇯🇵'),
    CountryCode(code: '+82', name: '韩国', flag: '🇰🇷'),
    CountryCode(code: '+852', name: '香港', flag: '🇭🇰'),
    CountryCode(code: '+853', name: '澳门', flag: '🇲🇴'),
    CountryCode(code: '+886', name: '台湾', flag: '🇹🇼'),
  ];
}

/// 认证输入框组件
/// 
/// 统一的输入框样式，用于登录、注册、忘记密码等认证页面。
/// 遵循单一职责原则（SRP）和 DRY 原则。
/// 
/// 调用者：
/// - LoginPage：邮箱输入框、密码输入框、手机号输入框、验证码输入框
/// - RegisterPage：邮箱输入框、密码输入框、确认密码输入框
/// - ForgotPasswordPage：邮箱输入框
class AuthTextField extends StatefulWidget {
  /// 输入框类型
  final AuthTextFieldType type;
  
  /// 控制器
  final TextEditingController controller;
  
  /// 标签文本
  final String label;
  
  /// 提示文本
  final String? hint;
  
  /// 前缀图标
  final IconData? prefixIcon;
  
  /// 是否必填
  final bool required;
  
  /// 自定义验证器
  final String? Function(String?)? validator;
  
  /// 是否启用
  final bool enabled;
  
  /// 最大长度
  final int? maxLength;
  
  /// 输入完成回调
  final VoidCallback? onEditingComplete;
  
  /// 国家代码（仅手机号输入框使用）
  final String? countryCode;
  
  /// 国家代码变化回调（仅手机号输入框使用）
  final ValueChanged<String>? onCountryCodeChanged;
  
  const AuthTextField({
    super.key,
    required this.type,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.required = true,
    this.validator,
    this.enabled = true,
    this.maxLength,
    this.onEditingComplete,
    this.countryCode,
    this.onCountryCodeChanged,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  /// 密码是否可见
  bool _obscurePassword = true;
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      obscureText: _shouldObscureText(),
      keyboardType: _getKeyboardType(),
      inputFormatters: _getInputFormatters(),
      textInputAction: TextInputAction.next,
      onEditingComplete: widget.onEditingComplete,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.type == AuthTextFieldType.phone
            ? _buildPhonePrefix()
            : (widget.prefixIcon != null
                ? Icon(widget.prefixIcon)
                : _getDefaultPrefixIcon()),
        suffixIcon: _buildSuffixIcon(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        counterText: '', // 隐藏字符计数
      ),
      validator: widget.validator ?? _getDefaultValidator(),
    );
  }
  
  /// 构建手机号前缀（国家代码选择器）
  /// 
  /// 调用者：build()
  Widget _buildPhonePrefix() {
    final countryCode = widget.countryCode ?? '+86';
    final selectedCountry = CountryCode.commonCodes.firstWhere(
      (c) => c.code == countryCode,
      orElse: () => CountryCode.commonCodes.first,
    );
    
    return PopupMenuButton<String>(
      enabled: widget.enabled,
      offset: const Offset(0, 50),
      itemBuilder: (context) {
        return CountryCode.commonCodes.map((country) {
          return PopupMenuItem<String>(
            value: country.code,
            child: Row(
              children: [
                Text(
                  country.flag,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(country.name)),
                const SizedBox(width: 12),
                Text(
                  country.code,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (code) {
        widget.onCountryCodeChanged?.call(code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCountry.flag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 4),
            Text(
              selectedCountry.code,
              style: TextStyle(
                fontSize: 16,
                color: widget.enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: widget.enabled
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 是否应该隐藏文本（密码输入框）
  /// 
  /// 调用者：build()
  bool _shouldObscureText() {
    return widget.type == AuthTextFieldType.password && _obscurePassword;
  }
  
  /// 获取键盘类型
  /// 
  /// 调用者：build()
  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case AuthTextFieldType.email:
        return TextInputType.emailAddress;
      case AuthTextFieldType.phone:
        return TextInputType.phone;
      case AuthTextFieldType.verificationCode:
        return TextInputType.number;
      case AuthTextFieldType.password:
      case AuthTextFieldType.text:
        return TextInputType.text;
    }
  }
  
  /// 获取输入格式限制
  /// 
  /// 调用者：build()
  List<TextInputFormatter>? _getInputFormatters() {
    switch (widget.type) {
      case AuthTextFieldType.phone:
        // 手机号只允许数字和 + 号
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
        ];
      case AuthTextFieldType.verificationCode:
        // 验证码只允许数字
        return [
          FilteringTextInputFormatter.digitsOnly,
        ];
      default:
        return null;
    }
  }
  
  /// 获取默认前缀图标
  /// 
  /// 调用者：build()
  Widget? _getDefaultPrefixIcon() {
    switch (widget.type) {
      case AuthTextFieldType.email:
        return const Icon(Icons.email_outlined);
      case AuthTextFieldType.password:
        return const Icon(Icons.lock_outline);
      case AuthTextFieldType.phone:
        return const Icon(Icons.phone_outlined);
      case AuthTextFieldType.verificationCode:
        return const Icon(Icons.sms_outlined);
      case AuthTextFieldType.text:
        return null;
    }
  }
  
  /// 构建后缀图标（密码可见性切换）
  /// 
  /// 调用者：build()
  Widget? _buildSuffixIcon() {
    if (widget.type != AuthTextFieldType.password) {
      return null;
    }
    
    return IconButton(
      icon: Icon(
        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
    );
  }
  
  /// 获取默认验证器
  /// 
  /// 调用者：build()
  String? Function(String?)? _getDefaultValidator() {
    if (!widget.required) {
      return null;
    }
    
    return (value) {
      // Fail Fast：空值验证
      if (value == null || value.trim().isEmpty) {
        return '${widget.label}不能为空';
      }
      
      // 根据类型进行格式验证
      switch (widget.type) {
        case AuthTextFieldType.email:
          return _validateEmail(value);
        case AuthTextFieldType.password:
          return _validatePassword(value);
        case AuthTextFieldType.phone:
          return _validatePhone(value);
        case AuthTextFieldType.verificationCode:
          return _validateVerificationCode(value);
        case AuthTextFieldType.text:
          return null;
      }
    };
  }
  
  /// 验证邮箱格式
  /// 
  /// 调用者：_getDefaultValidator()
  /// 
  /// Fail Fast：格式不正确立即返回错误信息
  String? _validateEmail(String value) {
    // 使用统一的验证规则
    return ValidationHelper.validateEmailForUI(value);
  }
  
  /// 验证密码强度
  /// 
  /// 调用者：_getDefaultValidator()
  /// 
  /// Fail Fast：密码长度不足立即返回错误信息
  String? _validatePassword(String value) {
    // 使用统一的验证规则
    return ValidationHelper.validatePasswordForUI(value);
  }
  
  /// 验证手机号格式
  /// 
  /// 调用者：_getDefaultValidator()
  /// 
  /// Fail Fast：格式不正确立即返回错误信息
  String? _validatePhone(String value) {
    // 使用统一的验证规则
    return ValidationHelper.validatePhoneForUI(value);
  }
  
  /// 验证验证码格式
  /// 
  /// 调用者：_getDefaultValidator()
  /// 
  /// Fail Fast：长度不正确立即返回错误信息
  String? _validateVerificationCode(String value) {
    // 使用统一的验证规则
    return ValidationHelper.validateVerificationCodeForUI(value);
  }
}

