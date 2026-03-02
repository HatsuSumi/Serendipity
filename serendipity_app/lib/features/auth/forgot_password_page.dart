import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';

/// 忘记密码页
/// 
/// 通过邮箱发送密码重置链接，遵循单一职责原则（SRP）和分层约束。
/// 
/// 调用者：
/// - LoginPage：点击"忘记密码"链接跳转到此页面
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _recoveryKeyController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
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
                
                // 说明文字
                _buildDescription(),
                
                const SizedBox(height: 32),
                
                // 邮箱输入框
                AuthTextField(
                  type: AuthTextFieldType.email,
                  controller: _emailController,
                  label: '邮箱',
                  hint: '请输入注册时使用的邮箱',
                  enabled: !_isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // 恢复密钥输入框
                AuthTextField(
                  type: AuthTextFieldType.password,
                  controller: _recoveryKeyController,
                  label: '恢复密钥',
                  hint: '请输入注册时保存的恢复密钥',
                  enabled: !_isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // 新密码输入框
                AuthTextField(
                  type: AuthTextFieldType.password,
                  controller: _newPasswordController,
                  label: '新密码',
                  hint: '请输入新密码（至少6位）',
                  enabled: !_isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // 确认新密码输入框
                AuthTextField(
                  type: AuthTextFieldType.password,
                  controller: _confirmPasswordController,
                  label: '确认新密码',
                  hint: '请再次输入新密码',
                  enabled: !_isLoading,
                ),
                
                const SizedBox(height: 24),
                
                // 重置按钮
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
  
  /// 构建说明文字
  /// 
  /// 调用者：build()
  Widget _buildDescription() {
    return Text(
      '请输入邮箱地址和恢复密钥，然后设置新密码。',
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        height: 1.5,
      ),
    );
  }
  
  /// 处理重置密码
  /// 
  /// 调用者：重置按钮的 onPressed
  Future<void> _handleResetPassword() async {
    // Fail Fast：表单验证
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Fail Fast：密码一致性验证
    if (_newPasswordController.text != _confirmPasswordController.text) {
      MessageHelper.showError(context, '两次输入的密码不一致');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 调用 AuthProvider 重置密码
      await ref.read(authProvider.notifier).resetPassword(
        _emailController.text.trim(),
        _recoveryKeyController.text.trim(),
        _newPasswordController.text,
      );
      
      // 重置成功，返回登录页
      if (mounted) {
        MessageHelper.showSuccess(context, '密码重置成功，请使用新密码登录');
        Navigator.of(context).pop();
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
}

