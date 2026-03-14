import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/phone_helper.dart';
import '../../core/providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'widgets/agreement_notice.dart';
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
  
  bool _isLoading = false;
  bool _isEmailRegister = true;
  String _countryCode = '+86'; // 国家代码，默认中国
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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
                  text: '注册',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                
                // 协议提示
                const AgreementNotice(actionText: '注册'),
                
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
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!_isEmailRegister) {
                setState(() {
                  _isEmailRegister = true;
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
      await _handlePhoneRegister();
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
  
  Future<void> _handlePhoneRegister() async {
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
      final recoveryKey = await ref.read(authProvider.notifier).signUpWithPhonePassword(
        fullPhoneNumber,
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
  
  void _navigateToLogin(BuildContext context) {
    // 使用 pushReplacementWithTransition 替换当前页面，并应用用户设置的动画
    NavigationHelper.pushReplacementWithTransition(
      context,
      ref,
      const LoginPage(),
    );
  }
}

