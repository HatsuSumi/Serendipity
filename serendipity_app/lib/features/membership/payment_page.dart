import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mixins/countdown_mixin.dart';
import '../../core/providers/membership_provider.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/message_helper.dart';

/// 支付页面
///
/// 职责：
/// - 展示支付方式选择（微信 / 支付宝）
/// - 展示对应收款码
/// - 用户确认扫码后调用 upgradeToPremium 解锁会员
/// - 显示感谢动画
///
/// 调用者：
/// - MembershipPage：用户选择金额 > ¥0 后跳转至此
///
/// 设计原则：
/// - 单一职责：只负责支付执行阶段，金额已由 MembershipPage 决定
/// - Fail Fast：amount 必须 > 0，否则调用方有逻辑错误
/// - DRY：复用 MessageHelper / AuthErrorHelper
class PaymentPage extends ConsumerStatefulWidget {
  /// 用户选择的支付金额，单位：元，必须 > 0
  final double amount;

  const PaymentPage({super.key, required this.amount})
      : assert(amount > 0, 'PaymentPage only handles amount > 0');

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

enum _PayMethod { wechat, alipay }

class _PaymentPageState extends ConsumerState<PaymentPage>
    with SingleTickerProviderStateMixin, CountdownMixin {
  _PayMethod _selectedMethod = _PayMethod.wechat;
  bool _isConfirming = false;
  bool _showThanks = false;


  // 感谢动画控制器
  late final AnimationController _thanksController;
  late final Animation<double> _thanksScale;
  late final Animation<double> _thanksOpacity;

  @override
  void initState() {
    super.initState();
    startCountdown(initialSeconds: 30);
    _thanksController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _thanksScale = CurvedAnimation(
      parent: _thanksController,
      curve: Curves.elasticOut,
    );
    _thanksOpacity = CurvedAnimation(
      parent: _thanksController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    disposeCountdown();
    _thanksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('确认支付'),
        // 支付进行中时禁止返回
        automaticallyImplyLeading: !_isConfirming,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _showThanks
            ? _ThanksView(
                key: const ValueKey('thanks'),
                scaleAnimation: _thanksScale,
                opacityAnimation: _thanksOpacity,
                onDone: () => Navigator.of(context).pop(true),
              )
            : _PaymentView(
                key: const ValueKey('payment'),
                amount: widget.amount,
                selectedMethod: _selectedMethod,
                isConfirming: _isConfirming,
                countdownFinished: countdownFinished,
                countdown: countdown,
                onMethodChanged: (method) =>
                    setState(() => _selectedMethod = method),
                onConfirm: _handleConfirm,
              ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    setState(() => _isConfirming = true);

    try {
      await ref
          .read(membershipProvider.notifier)
          .upgradeToPremium(widget.amount);

      if (!mounted) return;

      // 先切换到感谢界面，再播放动画
      setState(() {
        _showThanks = true;
        _isConfirming = false;
      });
      _thanksController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      MessageHelper.showError(
        context,
        '开通失败：${AuthErrorHelper.extractErrorMessage(e)}',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// 支付选择与收款码视图
// ---------------------------------------------------------------------------

class _PaymentView extends StatelessWidget {
  final double amount;
  final _PayMethod selectedMethod;
  final bool isConfirming;
  final bool countdownFinished;
  final int countdown;
  final ValueChanged<_PayMethod> onMethodChanged;
  final VoidCallback onConfirm;

  const _PaymentView({
    super.key,
    required this.amount,
    required this.selectedMethod,
    required this.isConfirming,
    required this.countdownFinished,
    required this.countdown,
    required this.onMethodChanged,
    required this.onConfirm,
  });

  String get _qrAsset {
    switch (selectedMethod) {
      case _PayMethod.wechat:
        return 'assets/images/wechat.png';
      case _PayMethod.alipay:
        return 'assets/images/alipay.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = amount.round();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 金额展示
        Center(
          child: Column(
            children: [
              Text(
                '¥$displayAmount',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '会员有效期 30 天',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 支付方式选择
        Row(
          children: [
            Expanded(
              child: _MethodTab(
                label: '微信支付',
                icon: Icons.wechat,
                iconColor: const Color(0xFF07C160),
                selected: selectedMethod == _PayMethod.wechat,
                onTap: () => onMethodChanged(_PayMethod.wechat),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MethodTab(
                label: '支付宝',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF1677FF),
                selected: selectedMethod == _PayMethod.alipay,
                onTap: () => onMethodChanged(_PayMethod.alipay),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 收款码
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(_qrAsset),
              width: 220,
              height: 300,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  _qrAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 引导文案
        Center(
          child: Text(
            '请扫码付款后点击下方按钮',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: 32),

        // 确认按钮
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (isConfirming || !countdownFinished) ? null : onConfirm,
            child: isConfirming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(countdownFinished ? '我已完成付款' : '我已完成付款（$countdown 秒）'),
          ),
        ),
        const SizedBox(height: 12),

        // 诚信提示
        Center(
          child: Text(
            '感谢你的支持，请在完成付款后点击上方按钮',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 支付方式 Tab
// ---------------------------------------------------------------------------

class _MethodTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTab({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 感谢视图
// ---------------------------------------------------------------------------

class _ThanksView extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final VoidCallback onDone;

  const _ThanksView({
    super.key,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: FadeTransition(
        opacity: opacityAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 24),
                Text(
                  '感谢你的支持！',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '你的支持让这个项目\n能够持续运营下去',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '会员功能已解锁',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: onDone,
                  child: const Text('开始使用'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

