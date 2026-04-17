import 'package:flutter/material.dart';

import '../../../../core/services/push_models.dart';

enum DiagnosticsViewTone {
  success,
  warning,
  muted,
}

DiagnosticsViewTone mapDiagnosticsTone(DiagnosticsTone tone) {
  return switch (tone) {
    DiagnosticsTone.success => DiagnosticsViewTone.success,
    DiagnosticsTone.warning => DiagnosticsViewTone.warning,
    DiagnosticsTone.muted => DiagnosticsViewTone.muted,
  };
}

DiagnosticsToneColors diagnosticsToneColors(
  BuildContext context,
  DiagnosticsViewTone tone,
) {
  final colorScheme = Theme.of(context).colorScheme;

  return switch (tone) {
    DiagnosticsViewTone.success => DiagnosticsToneColors(
        foreground: colorScheme.primary,
        background: colorScheme.primaryContainer.withValues(alpha: 0.28),
        border: colorScheme.primary.withValues(alpha: 0.25),
      ),
    DiagnosticsViewTone.warning => DiagnosticsToneColors(
        foreground: colorScheme.error,
        background: colorScheme.errorContainer.withValues(alpha: 0.4),
        border: colorScheme.error.withValues(alpha: 0.25),
      ),
    DiagnosticsViewTone.muted => DiagnosticsToneColors(
        foreground: colorScheme.onSurface,
        background: colorScheme.surfaceContainerHighest,
        border: colorScheme.outlineVariant,
      ),
  };
}

class DiagnosticsToneColors {
  const DiagnosticsToneColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

