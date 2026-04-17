import 'package:flutter/material.dart';

import 'push_diagnostics_tone.dart';

class DiagnosticsSection extends StatelessWidget {
  const DiagnosticsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      items.add(children[index]);
      if (index != children.length - 1) {
        items.add(Divider(height: 1, color: colorScheme.outlineVariant));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class DiagnosticsItem extends StatelessWidget {
  const DiagnosticsItem({
    super.key,
    required this.label,
    required this.value,
    this.tone = DiagnosticsViewTone.muted,
    this.icon,
    this.isMonospace = false,
    this.emphasize = false,
    this.action,
  });

  final String label;
  final String value;
  final DiagnosticsViewTone tone;
  final IconData? icon;
  final bool isMonospace;
  final bool emphasize;
  final DiagnosticsCopyAction? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = diagnosticsToneColors(context, tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: emphasize ? colors.background : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 16, color: colors.foreground),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: colors.foreground,
                      fontWeight: emphasize || tone != DiagnosticsViewTone.muted
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontFamily: isMonospace ? 'monospace' : null,
                      height: 1.45,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 8),
                  DiagnosticsActionButton(
                    action: action!,
                    tone: tone,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosticsActionButton extends StatelessWidget {
  const DiagnosticsActionButton({
    super.key,
    required this.action,
    required this.tone,
  });

  final DiagnosticsCopyAction action;
  final DiagnosticsViewTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = diagnosticsToneColors(
      context,
      tone == DiagnosticsViewTone.muted ? DiagnosticsViewTone.success : tone,
    );

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 14, color: colors.foreground),
            const SizedBox(width: 4),
            Text(
              action.label,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagnosticsCopyAction {
  const DiagnosticsCopyAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onTap;
}

class DiagnosticsNotice extends StatelessWidget {
  const DiagnosticsNotice({
    super.key,
    required this.message,
    required this.tone,
  });

  final String message;
  final DiagnosticsViewTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = diagnosticsToneColors(context, tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colors.foreground,
          height: 1.45,
        ),
      ),
    );
  }
}

