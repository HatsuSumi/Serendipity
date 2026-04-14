import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/navigation_helper.dart';
import '../auth/privacy_policy_page.dart';
import '../auth/user_agreement_page.dart';
import 'about_content.dart';
import 'design_decisions_page.dart';
import 'widgets/about_page_scaffold.dart';
import 'widgets/about_section_card.dart';
import 'widgets/about_support_cards.dart';
import 'widgets/about_version_card.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  late final Future<AboutPageSectionsResult> _sectionsFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = loadAboutPageSections();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AboutPageSectionsResult>(
      future: _sectionsFuture,
      builder: (context, snapshot) {
        final result = snapshot.data;
        final sections = result?.sections;
        final hasStatsError = result?.hasProjectStatsError ?? false;
        final isLoading =
            snapshot.connectionState != ConnectionState.done && result == null;

        return AboutPageScaffold(
          title: '关于 Serendipity',
          icon: Icons.error_outline,
          eyebrow: '关于 Serendipity',
          headline: 'Serendipity 是一个记录“错过”的 app。',
          description: '不是为了重逢，而是为了记住那些转瞬即逝的瞬间。',
          children: isLoading
              ? const [
                  _AboutLoadingCard(),
                ]
              : [
                  if (hasStatsError) const AboutStatsErrorCard(),
                    ...?sections?.map(
                      (section) => AboutSectionCard(section: section),
                    ),
                  const AboutStatementCard(),
                  const AboutFeedbackCard(),
                  const AboutSponsorCard(),
                  const AboutVersionCard(),
                  const SizedBox(height: 8),
                  AboutEntryCard(
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
                  AboutEntryCard(
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
                  AboutEntryCard(
                    icon: Icons.error_outline,
                    title: '查看更多设计决策与常见问题',
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
