import 'package:flutter/material.dart';

import '../../../../core/services/push_models.dart';
import 'push_diagnostics_tone.dart';

class DiagnosticsSummaryCard extends StatelessWidget {
  const DiagnosticsSummaryCard({
    super.key,
    required this.snapshot,
  });

  final PushDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final syncTone = mapDiagnosticsTone(snapshot.lastSyncStatus.tone);

    final chips = <Widget>[
      DiagnosticsStatusChip(
        label: snapshot.permissionGranted ? '权限已授予' : '权限未授予',
        tone: snapshot.permissionGranted
            ? DiagnosticsViewTone.success
            : DiagnosticsViewTone.warning,
        icon: snapshot.permissionGranted
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
      ),
      DiagnosticsStatusChip(
        label: snapshot.tokenAvailable ? 'Token 已获取' : 'Token 获取失败',
        tone: snapshot.tokenAvailable
            ? DiagnosticsViewTone.success
            : DiagnosticsViewTone.warning,
        icon: snapshot.tokenAvailable
            ? Icons.vpn_key_outlined
            : Icons.key_off_outlined,
      ),
      DiagnosticsStatusChip(
        label: snapshot.currentTokenRegistered ? '已完成注册' : '尚未注册',
        tone: snapshot.currentTokenRegistered
            ? DiagnosticsViewTone.success
            : DiagnosticsViewTone.warning,
        icon: snapshot.currentTokenRegistered
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined,
      ),
      DiagnosticsStatusChip(
        label: snapshot.lastSyncStatus.statusLabel,
        tone: syncTone,
        icon: switch (syncTone) {
          DiagnosticsViewTone.success => Icons.sync_alt,
          DiagnosticsViewTone.warning => Icons.sync_problem_outlined,
          DiagnosticsViewTone.muted => Icons.schedule_outlined,
        },
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

class DiagnosticsStatusChip extends StatelessWidget {
  const DiagnosticsStatusChip({
    super.key,
    required this.label,
    required this.tone,
    required this.icon,
  });

  final String label;
  final DiagnosticsViewTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = diagnosticsToneColors(context, tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

