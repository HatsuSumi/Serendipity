import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutVersionCard extends StatelessWidget {
  const AboutVersionCard({super.key});

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
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final versionText = switch (snapshot.connectionState) {
              ConnectionState.done when snapshot.hasData =>
                '版本：${snapshot.data!.version}',
              _ => '版本：读取中...',
            };

            final buildNumberText = switch (snapshot.connectionState) {
              ConnectionState.done when snapshot.hasData =>
                '构建号：${snapshot.data!.buildNumber}',
              _ => '构建号：读取中...',
            };

            final textStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.8);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '版本信息',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                SelectableText(versionText, style: textStyle),
                const SizedBox(height: 12),
                SelectableText(buildNumberText, style: textStyle),
                const SizedBox(height: 12),
                SelectableText('最后更新：2026-03-24', style: textStyle),
              ],
            );
          },
        ),
      ),
    );
  }
}

