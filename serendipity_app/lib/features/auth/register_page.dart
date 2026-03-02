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
import 'widgets/recovery_key_dialog.dart';
import 'login_page.dart';

/// 注册页
/// 
/// 支持邮箱注册和手机号注册，遵循单一职责原则（SRP）和分层约束。
/// 
/// 调用者：
/// - WelcomePage：点击"注册"按钮跳转到此页面
/// - LoginPage：点击"没有账号？注册"跳转到此页面
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  
  bool _isLoading = false;
  final bool _isEmailRegister = true;
  bool _isCodeSent = false;
  String _countryCode = '+86'; // 国家代码，默认中国
  String? _verificationId; // 验证 ID（由 sendPhoneVerificationCode 返回）
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        title: const Text('注册'),
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
                _buildRegisterTypeTabs(),
                const SizedBox(height: 32),
                _isEmailRegister ? _buildEmailRegisterForm() : _buildPhoneRegisterForm(),
                const SizedBox(height: 24),
                AuthButton.primary(
                  text: _isEmailRegister ? '注册' : (_isCodeSent ? '注册' : '发送验证码'),
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 32),
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRegisterTypeTabs() {
    // 暂时只显示邮箱注册，手机号注册需要配置 SMS 服务
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
        '邮箱注册',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
    
    /* 手机号注册暂时禁用，需要配置 SMS 服务
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!_isEmailRegister) {
                setState(() {
                  _isEmailRegister = true;
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
                    color: _isEmailRegister
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '邮箱注册',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _isEmailRegister ? FontWeight.bold : FontWeight.normal,
                  color: _isEmailRegister
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
              if (_isEmailRegister) {
                setState(() {
                  _isEmailRegister = false;
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
                    color: !_isEmailRegister
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '手机号注册',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: !_isEmailRegister ? FontWeight.bold : FontWeight.normal,
                  color: !_isEmailRegister
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
  
  Widget _buildEmailRegisterForm() {
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
          hint: '请输入密码（至少6位）',
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          type: AuthTextFieldType.password,
          controller: _confirmPasswordController,
          label: '确认密码',
          hint: '请再次输入密码',
          enabled: !_isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '确认密码不能为空';
            }
            if (value != _passwordController.text) {
              return '两次输入的密码不一致';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildPhoneRegisterForm() {
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
  
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '已有账号？',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => _navigateToLogin(context),
          child: const Text('登录'),
        ),
      ],
    );
  }
  
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_isEmailRegister) {
      await _handleEmailRegister();
    } else {
      if (_isCodeSent) {
        await _handlePhoneRegister();
      } else {
        await _sendVerificationCode();
      }
    }
  }
  
  Future<void> _handleEmailRegister() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 调用 AuthProvider 注册，获取恢复密钥
      final recoveryKey = await ref.read(authProvider.notifier).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // 注册成功
      if (mounted) {
        // 如果有恢复密钥，显示恢复密钥对话框
        if (recoveryKey != null && recoveryKey.isNotEmpty) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false, // 禁止点击外部关闭
            builder: (context) => RecoveryKeyDialog(recoveryKey: recoveryKey),
          );
        }
        
        // 跳转到主页并显示消息
        if (mounted) {
          NavigationHelper.navigateToMainPageWithMessage(
            context,
            ref,
            '注册成功，欢迎使用！',
          );
        }
      }
    } catch (e) {
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
      
      if (mounted) {
        setState(() {
          _isCodeSent = true;
        });
        MessageHelper.showSuccess(context, '验证码已发送');
      }
    } catch (e) {
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
  
  Future<void> _handlePhoneRegister() async {
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
      
      // 调用 AuthProvider 注册，获取恢复密钥
      final recoveryKey = await ref.read(authProvider.notifier).signUpWithPhone(
        fullPhoneNumber,
        _verificationCodeController.text.trim(),
        _verificationId!,
      );
      
      // 注册成功
      if (mounted) {
        // 如果有恢复密钥，显示恢复密钥对话框
        if (recoveryKey != null && recoveryKey.isNotEmpty) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false, // 禁止点击外部关闭
            builder: (context) => RecoveryKeyDialog(recoveryKey: recoveryKey),
          );
        }
        
        // 跳转到主页并显示消息
        if (mounted) {
          NavigationHelper.navigateToMainPageWithMessage(
            context,
            ref,
            '注册成功，欢迎使用！',
          );
        }
      }
    } catch (e) {
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
  
  void _navigateToLogin(BuildContext context) {
    // 使用 pushReplacementWithTransition 替换当前页面，并应用用户设置的动画
    NavigationHelper.pushReplacementWithTransition(
      context,
      ref,
      const LoginPage(),
    );
  }
}

