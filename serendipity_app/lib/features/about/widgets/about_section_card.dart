import 'package:flutter/material.dart';

import '../about_content.dart';

class AboutSectionCard extends StatelessWidget {
  final AboutSectionContent section;

  const AboutSectionCard({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ..._buildParagraphs(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParagraphs(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      height: 1.8,
    );

    final widgets = <Widget>[];
    for (var index = 0; index < section.paragraphs.length; index++) {
      widgets.add(
        SelectableText(
          section.paragraphs[index],
          style: textStyle,
        ),
      );

      if (index != section.paragraphs.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }
}

