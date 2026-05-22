import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/phone_helper.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_text_field.dart';

enum ForgotPasswordAccountType { email, phone }

/// 忘记密码页
///
/// 通过账号标识（邮箱或手机号）+ 恢复密钥重置密码，遵循单一职责原则（SRP）和分层约束。
///
/// 调用者：
/// - LoginPage：点击"忘记密码"链接跳转到此页面
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({
    super.key,
    this.initialAccountType = ForgotPasswordAccountType.email,
    this.initialCountryCode = '+86',
  });

  final ForgotPasswordAccountType initialAccountType;
  final String initialCountryCode;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _recoveryKeyController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late ForgotPasswordAccountType _accountType;
  late String _countryCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _accountType = widget.initialAccountType;
    _countryCode = widget.initialCountryCode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _recoveryKeyController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('忘记密码'),
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
                _buildAccountTypeTabs(),
                const SizedBox(height: 24),
                _buildDescription(),
                const SizedBox(height: 32),
                _accountType == ForgotPasswordAccountType.email
                    ? _buildEmailField()
                    : _buildPhoneField(),
                const SizedBox(height: 16),
                AuthTextField(
                  type: AuthTextFieldType.password,
                  controller: _recoveryKeyController,
                  label: '恢复密钥',
                  hint: '请输入注册时保存的恢复密钥',
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  type: AuthTextFieldType.password,
                  controller: _newPasswordController,
                  label: '新密码',
                  hint: '请输入新密码（至少6位）',
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  type: AuthTextFieldType.password,
                  controller: _confirmPasswordController,
                  label: '确认新密码',
                  hint: '请再次输入新密码',
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                AuthButton.primary(
                  text: '重置密码',
                  onPressed: _handleResetPassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    if (_accountType != ForgotPasswordAccountType.email) {
                      setState(() {
                        _accountType = ForgotPasswordAccountType.email;
                      });
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _accountType == ForgotPasswordAccountType.email
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '邮箱找回',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _accountType == ForgotPasswordAccountType.email
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _accountType == ForgotPasswordAccountType.email
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
            onTap: _isLoading
                ? null
                : () {
                    if (_accountType != ForgotPasswordAccountType.phone) {
                      setState(() {
                        _accountType = ForgotPasswordAccountType.phone;
                      });
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _accountType == ForgotPasswordAccountType.phone
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '手机号找回',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _accountType == ForgotPasswordAccountType.phone
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _accountType == ForgotPasswordAccountType.phone
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

  Widget _buildDescription() {
    final description = _accountType == ForgotPasswordAccountType.email
        ? '请输入邮箱地址和恢复密钥，然后设置新密码。'
        : '请输入完整手机号和恢复密钥，然后设置新密码。';

    return Text(
      description,
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        height: 1.5,
      ),
    );
  }

  Widget _buildEmailField() {
    return AuthTextField(
      type: AuthTextFieldType.email,
      controller: _emailController,
      label: '邮箱',
      hint: '请输入注册时使用的邮箱',
      enabled: !_isLoading,
    );
  }

  Widget _buildPhoneField() {
    return AuthTextField(
      type: AuthTextFieldType.phone,
      controller: _phoneController,
      label: '手机号',
      hint: '请输入注册时使用的手机号',
      enabled: !_isLoading,
      countryCode: _countryCode,
      onCountryCodeChanged: (code) {
        setState(() {
          _countryCode = code;
        });
      },
    );
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      MessageHelper.showError(context, '两次输入的密码不一致');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final accountType = _accountType == ForgotPasswordAccountType.phone
        ? 'phone'
        : 'email';
    final account = _accountType == ForgotPasswordAccountType.phone
        ? PhoneHelper.formatWithCountryCode(_countryCode, _phoneController.text)
        : _emailController.text.trim();

    try {
      await ref.read(authProvider.notifier).resetPassword(
            accountType,
            account,
            _recoveryKeyController.text.trim(),
            _newPasswordController.text,
          );

      if (mounted) {
        MessageHelper.showSuccess(context, '密码重置成功，请使用新密码登录');
        Navigator.of(context).pop();
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
}
