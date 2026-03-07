import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/phone_helper.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/countdown_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'widgets/agreement_notice.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

/// 登录页
/// 
/// 支持邮箱登录和手机号登录，遵循单一职责原则（SRP）和分层约束。
/// 
/// 调用者：
/// - WelcomePage：点击"登录"按钮跳转到此页面
/// - RegisterPage：点击"已有账号？登录"跳转到此页面
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // 表单 Key
  final _formKey = GlobalKey<FormState>();
  
  // 控制器
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  
  // 状态
  bool _isLoading = false;
  final bool _isEmailLogin = true; // true: 邮箱登录, false: 手机号登录
  bool _isCodeSent = false; // 验证码是否已发送
  String _countryCode = '+86'; // 国家代码，默认中国
  String? _verificationId; // 验证 ID（由 sendPhoneVerificationCode 返回）
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    // 清空验证 ID，防止内存泄漏
    _verificationId = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                
                // 登录方式切换
                _buildLoginTypeTabs(),
                
                const SizedBox(height: 32),
                
                // 登录表单
                _isEmailLogin ? _buildEmailLoginForm() : _buildPhoneLoginForm(),
                
                const SizedBox(height: 24),
                
                // 登录按钮
                AuthButton.primary(
                  text: _isEmailLogin ? '登录' : (_isCodeSent ? '登录' : '发送验证码'),
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // 忘记密码（仅邮箱登录显示）
                if (_isEmailLogin) _buildForgotPasswordLink(),
                
                const SizedBox(height: 16),
                
                // 协议提示
                const AgreementNotice(actionText: '登录'),
                
                const SizedBox(height: 32),
                
                // 注册链接
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建登录方式切换标签
  /// 
  /// 调用者：build()
  Widget _buildLoginTypeTabs() {
    // 暂时只显示邮箱登录，手机号登录需要配置 SMS 服务
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      child: Text(
        '邮箱登录',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
    
    /* 手机号登录暂时禁用，需要配置 SMS 服务
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!_isEmailLogin) {
                setState(() {
                  _isEmailLogin = true;
                  _isCodeSent = false;
                  _verificationId = null;
                  _verificationCodeController.clear();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _isEmailLogin
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '邮箱登录',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _isEmailLogin ? FontWeight.bold : FontWeight.normal,
                  color: _isEmailLogin
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_isEmailLogin) {
                setState(() {
                  _isEmailLogin = false;
                  _isCodeSent = false;
                  _verificationId = null;
                  _phoneController.clear();
                  _verificationCodeController.clear();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: !_isEmailLogin
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '手机号登录',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: !_isEmailLogin ? FontWeight.bold : FontWeight.normal,
                  color: !_isEmailLogin
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    */
  }
  
  /// 构建邮箱登录表单
  /// 
  /// 调用者：build()
  Widget _buildEmailLoginForm() {
    return Column(
      children: [
        AuthTextField(
          type: AuthTextFieldType.email,
          controller: _emailController,
          label: '邮箱',
          hint: '请输入邮箱',
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          type: AuthTextFieldType.password,
          controller: _passwordController,
          label: '密码',
          hint: '请输入密码',
          enabled: !_isLoading,
        ),
      ],
    );
  }
  
  /// 构建手机号登录表单
  /// 
  /// 调用者：build()
  Widget _buildPhoneLoginForm() {
    return Column(
      children: [
        AuthTextField(
          type: AuthTextFieldType.phone,
          controller: _phoneController,
          label: '手机号',
          hint: '请输入手机号',
          enabled: !_isLoading,
          countryCode: _countryCode,
          onCountryCodeChanged: (code) {
            setState(() {
              _countryCode = code;
            });
          },
        ),
        if (_isCodeSent) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AuthTextField(
                  type: AuthTextFieldType.verificationCode,
                  controller: _verificationCodeController,
                  label: '验证码',
                  hint: '请输入6位验证码',
                  enabled: !_isLoading,
                  maxLength: 6,
                ),
              ),
              const SizedBox(width: 8),
              CountdownButton(
                text: '重新发送',
                onPressed: () async {
                  final fullPhoneNumber = PhoneHelper.formatWithCountryCode(
                    _countryCode,
                    _phoneController.text,
                  );
                  
                  try {
                    _verificationId = await ref.read(authProvider.notifier).sendPhoneVerificationCode(fullPhoneNumber);
                    if (mounted) {
                      MessageHelper.showSuccess(context, '验证码已发送');
                    }
                    return true;
                  } catch (e) {
                    if (mounted) {
                      MessageHelper.showError(context, AuthErrorHelper.extractErrorMessage(e));
                    }
                    return false;
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  /// 构建忘记密码链接
  /// 
  /// 调用者：build()
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : () => _navigateToForgotPassword(context),
        child: const Text('忘记密码？'),
      ),
    );
  }
  
  /// 构建注册链接
  /// 
  /// 调用者：build()
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '还没有账号？',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => _navigateToRegister(context),
          child: const Text('注册'),
        ),
      ],
    );
  }
  
  /// 处理登录
  /// 
  /// 调用者：登录按钮的 onPressed
  Future<void> _handleLogin() async {
    // Fail Fast：表单验证
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_isEmailLogin) {
      await _handleEmailLogin();
    } else {
      if (_isCodeSent) {
        await _handlePhoneLogin();
      } else {
        await _sendVerificationCode();
      }
    }
  }
  
  /// 处理邮箱登录
  /// 
  /// 调用者：_handleLogin()
  Future<void> _handleEmailLogin() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 调用 AuthProvider 登录
      await ref.read(authProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // 登录成功，跳转到主页并显示消息
      if (mounted) {
        NavigationHelper.navigateToMainPageWithMessage(
          context,
          ref,
          '登录成功，欢迎回来！',
        );
      }
    } catch (e) {
      // 显示错误信息
      if (mounted) {
        MessageHelper.showError(context, AuthErrorHelper.extractErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 发送验证码
  /// 
  /// 调用者：_handleLogin()
  Future<void> _sendVerificationCode() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 拼接完整手机号（国家代码 + 手机号）
      final fullPhoneNumber = PhoneHelper.formatWithCountryCode(
        _countryCode,
        _phoneController.text,
      );
      
      // 调用 AuthProvider 发送验证码，并保存返回的 verificationId
      _verificationId = await ref.read(authProvider.notifier).sendPhoneVerificationCode(fullPhoneNumber);
      
      // 验证码发送成功
      if (mounted) {
        setState(() {
          _isCodeSent = true;
        });
        MessageHelper.showSuccess(context, '验证码已发送');
      }
    } catch (e) {
      // 显示错误信息
      if (mounted) {
        MessageHelper.showError(context, AuthErrorHelper.extractErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 处理手机号登录
  /// 
  /// 调用者：_handleLogin()
  Future<void> _handlePhoneLogin() async {
    // Fail Fast：必须先发送验证码
    if (_verificationId == null) {
      MessageHelper.showError(context, '请先发送验证码');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 拼接完整手机号（国家代码 + 手机号）
      final fullPhoneNumber = PhoneHelper.formatWithCountryCode(
        _countryCode,
        _phoneController.text,
      );
      
      // 调用 AuthProvider 登录，传入 verificationId
      await ref.read(authProvider.notifier).signInWithPhone(
        fullPhoneNumber,
        _verificationCodeController.text.trim(),
        _verificationId!,
      );
      
      // 登录成功，跳转到主页并显示消息
      if (mounted) {
        NavigationHelper.navigateToMainPageWithMessage(
          context,
          ref,
          '登录成功，欢迎回来！',
        );
      }
    } catch (e) {
      // 显示错误信息
      if (mounted) {
        MessageHelper.showError(context, AuthErrorHelper.extractErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 导航到忘记密码页
  /// 
  /// 调用者：忘记密码链接的 onPressed
  void _navigateToForgotPassword(BuildContext context) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      const ForgotPasswordPage(),
    );
  }
  
  /// 导航到注册页
  /// 
  /// 调用者：注册链接的 onPressed
  void _navigateToRegister(BuildContext context) {
    // 使用 pushReplacementWithTransition 替换当前页面，并应用用户设置的动画
    NavigationHelper.pushReplacementWithTransition(
      context,
      ref,
      const RegisterPage(),
    );
  }
}

