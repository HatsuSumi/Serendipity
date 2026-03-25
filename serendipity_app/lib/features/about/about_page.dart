import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/navigation_helper.dart';
import '../auth/privacy_policy_page.dart';
import '../auth/user_agreement_page.dart';
import 'about_content.dart';
import 'design_decisions_page.dart';
import 'widgets/about_page_scaffold.dart';
import 'widgets/about_section_card.dart';
import 'widgets/about_version_card.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  static const _serviceStatement =
      '我不保证服务永远可用（可能因维护、故障、时间、精力、成本和开发者抑郁症加重等原因中断），开发者目前年入零元，服务器费用都是父母出的，我可不想每次续费都用父母的钱，因此随时会考虑关停所有服务器功能，只保留离线使用功能，因为项目免费开源，免费的项目几乎不会有人主动赞助，所以我年入零元，我的个人网站，个人作品集，遗书：https://hatsusumi.github.io/FinalTestamentProofILived/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<AboutSectionContent>>(
      future: loadAboutPageSections(),
      builder: (context, snapshot) {
        final sections = snapshot.data;
        final hasError = snapshot.hasError;
        final isLoading =
            snapshot.connectionState != ConnectionState.done &&
            sections == null;

        return AboutPageScaffold(
          title: '关于 Serendipity',
          icon: Icons.error_outline,
          eyebrow: '关于 Serendipity',
          headline: 'Serendipity 是一个记录“错过”的 app。',
          description: '不是为了重逢，而是为了记住那些转瞬即逝的瞬间。',
          children: [
            if (isLoading)
              const _AboutLoadingCard()
            else if (hasError)
              const _AboutStatsErrorCard()
            else
              ...?sections?.map(
                (section) => AboutSectionCard(section: section),
              ),
            const _AboutStatementCard(statement: _serviceStatement),
            const _AboutSponsorCard(),
            const AboutVersionCard(),
            const SizedBox(height: 8),
            _AboutEntryCard(
              icon: Icons.description_outlined,
              title: '用户协议',
              subtitle: '查看使用规则与服务说明',
              onTap: () {
                NavigationHelper.pushWithTransition(
                  context,
                  ref,
                  const UserAgreementPage(),
                );
              },
            ),
            _AboutEntryCard(
              icon: Icons.privacy_tip_outlined,
              title: '隐私政策',
              subtitle: '查看数据收集、使用与保护方式',
              onTap: () {
                NavigationHelper.pushWithTransition(
                  context,
                  ref,
                  const PrivacyPolicyPage(),
                );
              },
            ),
            _AboutEntryCard(
              icon: Icons.error_outline,
              title: '查看更多设计决策',
              subtitle: '为什么产品这样设计？',
              onTap: () {
                NavigationHelper.pushWithTransition(
                  context,
                  ref,
                  const DesignDecisionsPage(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AboutLoadingCard extends StatelessWidget {
  const _AboutLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _AboutStatsErrorCard extends StatelessWidget {
  const _AboutStatsErrorCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
        ),
        child: Text(
          '项目规模数据暂时无法读取。',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
        ),
      ),
    );
  }
}

class _AboutStatementCard extends StatelessWidget {
  final String statement;

  const _AboutStatementCard({required this.statement});

  static const _websiteUrl =
      'https://hatsusumi.github.io/FinalTestamentProofILived/';
  static const _statementPrefix =
      '我不保证服务永远可用（可能因维护、故障、时间、精力、成本和开发者抑郁症加重等原因中断），开发者目前年入零元，服务器费用都是父母出的，我可不想每次续费都用父母的钱，因此随时会考虑关停所有服务器功能，只保留离线使用功能，因为项目免费开源，免费的项目几乎不会有人主动赞助，所以我年入零元，我的个人网站，个人作品集，遗书：';

  Future<void> _openWebsite() async {
    final uri = Uri.parse(_websiteUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, color: colorScheme.error),
                const SizedBox(width: 10),
                Text(
                  '声明',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(text: _statementPrefix),
                  TextSpan(
                    text: _websiteUrl,
                    style: TextStyle(
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _openWebsite,
                  ),
                  const TextSpan(text: '（建议使用电脑浏览器打开）'),
                ],
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                color: colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutSponsorCard extends StatelessWidget {
  const _AboutSponsorCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '赞助支持（完全自愿）',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SponsorQrTile(
                    assetPath: 'assets/images/alipay.png',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _SponsorQrTile(
                    assetPath: 'assets/images/wechat.png',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorQrTile extends StatelessWidget {
  final String assetPath;

  const _SponsorQrTile({
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          assetPath,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}

class _AboutEntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AboutEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.16),
                  colorScheme.secondary.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
