import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/navigation_helper.dart';
import '../user_agreement_page.dart';
import '../privacy_policy_page.dart';

/// 协议提示组件
/// 
/// 显示"登录/注册代表同意《用户协议》和《隐私协议》"提示
/// 
/// 调用者：
/// - LoginPage：登录页面底部，显示"登录代表同意"
/// - RegisterPage：注册页面底部，显示"注册代表同意"
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责显示协议提示和跳转
/// - DRY：登录和注册页面复用同一个组件
/// - 依赖倒置（DIP）：通过 NavigationHelper 跳转，不直接依赖具体页面
class AgreementNotice extends ConsumerWidget {
  /// 操作类型文本（如"登录"或"注册"）
  final String actionText;

  const AgreementNotice({
    super.key,
    required this.actionText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      height: 1.5,
    );
    final linkStyle = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.primary,
      height: 1.5,
    );

    return Text.rich(
      TextSpan(
        text: '$actionText代表同意',
        style: textStyle,
        children: [
          TextSpan(
            text: '《用户协议》',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _navigateToUserAgreement(context, ref),
          ),
          TextSpan(
            text: '和',
            style: textStyle,
          ),
          TextSpan(
            text: '《隐私协议》',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _navigateToPrivacyPolicy(context, ref),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// 跳转到用户协议页面
  /// 
  /// 调用者：《用户协议》链接的 onTap
  void _navigateToUserAgreement(BuildContext context, WidgetRef ref) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      const UserAgreementPage(),
    );
  }

  /// 跳转到隐私协议页面
  /// 
  /// 调用者：《隐私协议》链接的 onTap
  void _navigateToPrivacyPolicy(BuildContext context, WidgetRef ref) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      const PrivacyPolicyPage(),
    );
  }
}

