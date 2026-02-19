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
  
  bool _isLoading = false;
  bool _isEmailSent = false;
  
  @override
  void dispose() {
    _emailController.dispose();
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
                  enabled: !_isLoading && !_isEmailSent,
                ),
                
                const SizedBox(height: 24),
                
                // 发送按钮
                AuthButton.primary(
                  text: _isEmailSent ? '重新发送' : '发送重置邮件',
                  onPressed: _handleSendResetEmail,
                  isLoading: _isLoading,
                ),
                
                if (_isEmailSent) ...[
                  const SizedBox(height: 24),
                  _buildSuccessMessage(),
                ],
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
      '请输入邮箱地址，系统将发送密码重置链接。',
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        height: 1.5,
      ),
    );
  }
  
  /// 构建成功提示信息
  /// 
  /// 调用者：build()
  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '重置邮件已发送！\n请查收邮件并按照说明重置密码。',
              style: TextStyle(
                color: Colors.green.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 处理发送重置邮件
  /// 
  /// 调用者：发送按钮的 onPressed
  Future<void> _handleSendResetEmail() async {
    // Fail Fast：表单验证
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 调用 AuthProvider 发送重置邮件
      await ref.read(authProvider.notifier).resetPassword(
        _emailController.text.trim(),
      );
      
      // 发送成功
      if (mounted) {
        setState(() {
          _isEmailSent = true;
        });
        MessageHelper.showSuccess(context, '重置邮件已发送');
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

