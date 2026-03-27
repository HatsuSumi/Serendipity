import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/membership_provider.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import 'payment_page.dart';

class MembershipPage extends ConsumerStatefulWidget {
  const MembershipPage({super.key});

  @override
  ConsumerState<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends ConsumerState<MembershipPage> {
  double _selectedAmount = 1;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final membershipAsync = ref.watch(membershipProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('会员中心')),
      body: membershipAsync.when(
        data: (membershipInfo) {
          final hasActiveMembership = membershipInfo.isPremium;
          final expiresAt = membershipInfo.membership?.expiresAt;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasActiveMembership
                              ? Icons.workspace_premium
                              : Icons.workspace_premium_outlined,
                          color: colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasActiveMembership ? '会员有效中' : '免费版',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasActiveMembership
                          ? '有效期至 ${expiresAt == null ? '长期有效' : DateTimeHelper.formatDateTime(expiresAt)}'
                          : '可自定支持金额，开通后立即生效，固定有效期 30 天。',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildBenefitsCard(context),
              const SizedBox(height: 20),
              authState.when(
                data: (user) {
                  if (user == null) {
                    return _buildLoginPrompt(context);
                  }
                  if (hasActiveMembership) {
                    return _buildActiveMembershipCard(context, membershipInfo);
                  }
                  return _buildUpgradeCard(context);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildErrorCard(
                  context,
                  '账号信息加载失败：${AuthErrorHelper.extractErrorMessage(error)}',
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorCard(
          context,
          '会员状态加载失败：${AuthErrorHelper.extractErrorMessage(error)}',
        ),
      ),
    );
  }

  Widget _buildBenefitsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '会员权益',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _MembershipBenefitRow(
              title: '高级统计区',
              detail: '统计面板页面新增高级统计区（标签词云图、月度记录数图表、情绪强度分布图、天气分布图、场所类型分布图、成功率趋势图、字段分布明细），故事线详情页新增故事线标签词云',
            ),
            _MembershipBenefitRow(title: '故事线', detail: '免费版最多 3 条，会员无限制'),
            _MembershipBenefitRow(title: '主题', detail: '解锁朦胧、深夜、温暖、秋日主题'),
            _MembershipBenefitRow(title: '同步', detail: '免费版单设备，会员多设备同步'),
            _MembershipBenefitRow(title: '导出', detail: '故事线详情页支持导出故事线为图文卡片'),
            _MembershipBenefitRow(
              title: '提醒',
              detail: '所有“邂逅”记录都会生成周年纪念日提醒，支持本地提醒与当天首次打开 app 的弹窗提醒',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '请先登录',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('会员状态与有效期需要绑定账号后才能开通和保存。'),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMembershipCard(
    BuildContext context,
    MembershipInfo membershipInfo,
  ) {
    final expiresAt = membershipInfo.membership?.expiresAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              expiresAt == null
                  ? '当前会员有效，不限制到期时间。'
                  : '当前会员有效至 ${DateTimeHelper.formatDateTime(expiresAt)}。',
            ),
            const SizedBox(height: 8),
            const Text('会员有效期间不支持重复开通。'),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    final displayAmount = _selectedAmount.round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '开通会员',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('选择本期支持金额，当前金额：¥$displayAmount/月'),
            const SizedBox(height: 12),
            Slider(
              min: 0,
              max: 648,
              divisions: 648,
              value: _selectedAmount,
              label: '¥$displayAmount',
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _selectedAmount = value;
                      });
                    },
            ),
            const SizedBox(height: 8),
            const Text('拖动滑块选择你愿意支持的金额，确认后开始本期会员。'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitUpgrade,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('确认支付'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }

  Future<void> _submitUpgrade() async {
    final amount = _selectedAmount.roundToDouble();

    // 金额 = 0：直接解锁，无需支付页面
    if (amount == 0) {
      setState(() => _isSubmitting = true);
      try {
        await ref.read(membershipProvider.notifier).upgradeToPremium(0);
        if (!mounted) return;
        MessageHelper.showSuccess(context, '会员已开通，有效期 30 天');
      } catch (e) {
        if (!mounted) return;
        MessageHelper.showError(
          context,
          '开通失败：${AuthErrorHelper.extractErrorMessage(e)}',
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    // 金额 > 0：跳转支付页面
    final paid = await NavigationHelper.pushWithTransition<bool>(
      context,
      ref,
      PaymentPage(amount: amount),
    );

    // 支付页面已负责解锁和感谢动画，返回 true 时直接弹出提示
    if (paid == true && mounted) {
      MessageHelper.showSuccess(context, '会员已开通，有效期 30 天');
    }
  }
}

class _MembershipBenefitRow extends StatelessWidget {
  final String title;
  final String detail;

  const _MembershipBenefitRow({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle_outline, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$title：',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

