import 'package:flutter/material.dart';

import 'about_content.dart';
import 'widgets/about_page_scaffold.dart';
import 'widgets/about_section_card.dart';

class DesignDecisionsPage extends StatelessWidget {
  const DesignDecisionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AboutPageScaffold(
      title: '设计决策',
      icon: Icons.error_outline,
      eyebrow: '设计决策',
      headline: '为什么产品这样设计？',
      description: '以下内容全部对应产品里的真实取舍、限制和边界说明。',
      children: designDecisionSections
          .map((section) => AboutSectionCard(section: section))
          .toList(growable: false),
    );
  }
}

