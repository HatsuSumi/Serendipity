import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
