import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/phone_helper.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'widgets/agreement_notice.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_text_field.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailLogin = true;
  String _countryCode = '+86';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
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
                _buildLoginTypeTabs(),
                const SizedBox(height: 32),
                _isEmailLogin ? _buildEmailLoginForm() : _buildPhoneLoginForm(),
                const SizedBox(height: 24),
                AuthButton.primary(
                  text: '登录',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                _buildForgotPasswordLink(),
                const SizedBox(height: 16),
                const AgreementNotice(actionText: '登录'),
                const SizedBox(height: 32),
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTypeTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!_isEmailLogin) {
                setState(() {
                  _isEmailLogin = true;
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
                  fontWeight:
                      _isEmailLogin ? FontWeight.bold : FontWeight.normal,
                  color: _isEmailLogin
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
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
                  fontWeight:
                      !_isEmailLogin ? FontWeight.bold : FontWeight.normal,
                  color: !_isEmailLogin
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : () => _navigateToForgotPassword(context),
        child: const Text('忘记密码？'),
      ),
    );
  }

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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isEmailLogin) {
      await _handleEmailLogin();
    } else {
      await _handlePhoneLogin();
    }
  }

  Future<void> _handleEmailLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (mounted) {
        NavigationHelper.navigateToMainPageWithMessage(
          context,
          ref,
          '登录成功，欢迎回来！',
        );
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

  Future<void> _handlePhoneLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fullPhoneNumber = PhoneHelper.formatWithCountryCode(
        _countryCode,
        _phoneController.text,
      );

      await ref.read(authProvider.notifier).signInWithPhonePassword(
            fullPhoneNumber,
            _passwordController.text,
          );

      if (mounted) {
        NavigationHelper.navigateToMainPageWithMessage(
          context,
          ref,
          '登录成功，欢迎回来！',
        );
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

  void _navigateToForgotPassword(BuildContext context) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      ForgotPasswordPage(
        initialAccountType: _isEmailLogin
            ? ForgotPasswordAccountType.email
            : ForgotPasswordAccountType.phone,
        initialCountryCode: _countryCode,
      ),
    );
  }

  void _navigateToRegister(BuildContext context) {
    NavigationHelper.pushReplacementWithTransition(
      context,
      ref,
      const RegisterPage(),
    );
  }
}
