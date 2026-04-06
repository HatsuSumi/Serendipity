import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/push_models.dart';
import '../../../core/utils/message_helper.dart';

class PushDiagnosticsDialog extends StatelessWidget {
  const PushDiagnosticsDialog({
    super.key,
    required this.snapshot,
  });

  final PushDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final syncTone = switch (snapshot.lastSyncStatus.tone) {
      DiagnosticsTone.success => _DiagnosticsTone.success,
      DiagnosticsTone.warning => _DiagnosticsTone.warning,
      DiagnosticsTone.muted => _DiagnosticsTone.muted,
    };

    return AlertDialog(
      title: const Text('推送诊断'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiagnosticsSummaryCard(snapshot: snapshot),
              const SizedBox(height: 16),
              _DiagnosticsSection(
                title: '基础状态',
                children: [
                  _DiagnosticsItem(label: '平台', value: snapshot.platform),
                  _DiagnosticsItem(
                    label: '是否支持',
                    value: snapshot.isSupported ? '是' : '否',
                    tone: snapshot.isSupported
                        ? _DiagnosticsTone.success
                        : _DiagnosticsTone.muted,
                    icon: snapshot.isSupported
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                  ),
                  _DiagnosticsItem(
                    label: '通知权限',
                    value: snapshot.permissionStatusText,
                    tone: snapshot.permissionGranted
                        ? _DiagnosticsTone.success
                        : _DiagnosticsTone.warning,
                    icon: snapshot.permissionGranted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DiagnosticsSection(
                title: 'Token 状态',
                children: [
                  _DiagnosticsItem(
                    label: 'Token 获取',
                    value: snapshot.tokenAvailable ? '成功' : '失败',
                    tone: snapshot.tokenAvailable
                        ? _DiagnosticsTone.success
                        : _DiagnosticsTone.warning,
                    icon: snapshot.tokenAvailable
                        ? Icons.vpn_key_outlined
                        : Icons.key_off_outlined,
                  ),
                  _DiagnosticsItem(
                    label: 'Token 摘要',
                    value: snapshot.tokenPreview,
                    isMonospace: true,
                    action: snapshot.tokenAvailable
                        ? _DiagnosticsCopyAction(
                            label: '复制',
                            icon: Icons.copy_rounded,
                            onTap: () async {
                              final token = snapshot.token;
                              if (token == null || token.isEmpty) {
                                return;
                              }
                              await Clipboard.setData(ClipboardData(text: token));
                              if (!context.mounted) {
                                return;
                              }
                              MessageHelper.showSuccess(context, 'Push Token 已复制');
                            },
                          )
                        : null,
                  ),
                  _DiagnosticsItem(
                    label: '当前 Token 注册',
                    value: snapshot.currentTokenRegistered ? '已注册' : '未注册',
                    tone: snapshot.currentTokenRegistered
                        ? _DiagnosticsTone.success
                        : _DiagnosticsTone.warning,
                    icon: snapshot.currentTokenRegistered
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                  ),
                  _DiagnosticsItem(
                    label: '服务端注册数',
                    value: '${snapshot.registeredTokenCount}',
                  ),
                  _DiagnosticsItem(
                    label: '注册状态',
                    value: snapshot.registrationStatusText,
                    tone: snapshot.tokenAvailable && snapshot.currentTokenRegistered
                        ? _DiagnosticsTone.success
                        : _DiagnosticsTone.muted,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DiagnosticsSection(
                title: '最近同步',
                children: [
                  _DiagnosticsItem(
                    label: '同步结果',
                    value: snapshot.lastSyncStatus.statusLabel,
                    tone: syncTone,
                    icon: switch (syncTone) {
                      _DiagnosticsTone.success => Icons.sync_alt,
                      _DiagnosticsTone.warning => Icons.sync_problem_outlined,
                      _DiagnosticsTone.muted => Icons.schedule_outlined,
                    },
                  ),
                  _DiagnosticsItem(
                    label: '同步详情',
                    value: snapshot.lastSyncStatus.detailText,
                    tone: syncTone == _DiagnosticsTone.warning
                        ? _DiagnosticsTone.warning
                        : _DiagnosticsTone.muted,
                    emphasize: syncTone == _DiagnosticsTone.warning,
                  ),
                ],
              ),
              if (!snapshot.isSupported) ...[
                const SizedBox(height: 16),
                _DiagnosticsNotice(
                  message: '当前平台暂不支持本地推送能力诊断。',
                  tone: _DiagnosticsTone.muted,
                ),
              ],
              if (snapshot.lastSyncStatus.tone == DiagnosticsTone.warning) ...[
                const SizedBox(height: 16),
                _DiagnosticsNotice(
                  message: '最近一次 token 同步失败，优先检查通知权限、网络环境与服务端注册链路。',
                  tone: _DiagnosticsTone.warning,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('我知道了'),
        ),
      ],
    );
  }
}

enum _DiagnosticsTone {
  success,
  warning,
  muted,
}

class _DiagnosticsSummaryCard extends StatelessWidget {
  const _DiagnosticsSummaryCard({required this.snapshot});

  final PushDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final syncTone = switch (snapshot.lastSyncStatus.tone) {
      DiagnosticsTone.success => _DiagnosticsTone.success,
      DiagnosticsTone.warning => _DiagnosticsTone.warning,
      DiagnosticsTone.muted => _DiagnosticsTone.muted,
    };

    final chips = <Widget>[
      _DiagnosticsStatusChip(
        label: snapshot.permissionGranted ? '权限已授予' : '权限未授予',
        tone: snapshot.permissionGranted
            ? _DiagnosticsTone.success
            : _DiagnosticsTone.warning,
        icon: snapshot.permissionGranted
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
      ),
      _DiagnosticsStatusChip(
        label: snapshot.tokenAvailable ? 'Token 已获取' : 'Token 获取失败',
        tone: snapshot.tokenAvailable
            ? _DiagnosticsTone.success
            : _DiagnosticsTone.warning,
        icon: snapshot.tokenAvailable
            ? Icons.vpn_key_outlined
            : Icons.key_off_outlined,
      ),
      _DiagnosticsStatusChip(
        label: snapshot.currentTokenRegistered ? '已完成注册' : '尚未注册',
        tone: snapshot.currentTokenRegistered
            ? _DiagnosticsTone.success
            : _DiagnosticsTone.warning,
        icon: snapshot.currentTokenRegistered
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined,
      ),
      _DiagnosticsStatusChip(
        label: snapshot.lastSyncStatus.statusLabel,
        tone: syncTone,
        icon: switch (syncTone) {
          _DiagnosticsTone.success => Icons.sync_alt,
          _DiagnosticsTone.warning => Icons.sync_problem_outlined,
          _DiagnosticsTone.muted => Icons.schedule_outlined,
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

class _DiagnosticsStatusChip extends StatelessWidget {
  const _DiagnosticsStatusChip({
    required this.label,
    required this.tone,
    required this.icon,
  });

  final String label;
  final _DiagnosticsTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone);

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

class _DiagnosticsSection extends StatelessWidget {
  const _DiagnosticsSection({
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

class _DiagnosticsItem extends StatelessWidget {
  const _DiagnosticsItem({
    required this.label,
    required this.value,
    this.tone = _DiagnosticsTone.muted,
    this.icon,
    this.isMonospace = false,
    this.emphasize = false,
    this.action,
  });

  final String label;
  final String value;
  final _DiagnosticsTone tone;
  final IconData? icon;
  final bool isMonospace;
  final bool emphasize;
  final _DiagnosticsCopyAction? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = _toneColors(context, tone);

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
                      fontWeight: emphasize || tone != _DiagnosticsTone.muted
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontFamily: isMonospace ? 'monospace' : null,
                      height: 1.45,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 8),
                  _DiagnosticsActionButton(
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

class _DiagnosticsActionButton extends StatelessWidget {
  const _DiagnosticsActionButton({
    required this.action,
    required this.tone,
  });

  final _DiagnosticsCopyAction action;
  final _DiagnosticsTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone == _DiagnosticsTone.muted ? _DiagnosticsTone.success : tone);

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

class _DiagnosticsCopyAction {
  const _DiagnosticsCopyAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onTap;
}

class _DiagnosticsNotice extends StatelessWidget {
  const _DiagnosticsNotice({
    required this.message,
    required this.tone,
  });

  final String message;
  final _DiagnosticsTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone);

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

_DiagnosticsToneColors _toneColors(BuildContext context, _DiagnosticsTone tone) {
  final colorScheme = Theme.of(context).colorScheme;

  return switch (tone) {
    _DiagnosticsTone.success => _DiagnosticsToneColors(
        foreground: colorScheme.primary,
        background: colorScheme.primaryContainer.withValues(alpha: 0.28),
        border: colorScheme.primary.withValues(alpha: 0.25),
      ),
    _DiagnosticsTone.warning => _DiagnosticsToneColors(
        foreground: colorScheme.error,
        background: colorScheme.errorContainer.withValues(alpha: 0.4),
        border: colorScheme.error.withValues(alpha: 0.25),
      ),
    _DiagnosticsTone.muted => _DiagnosticsToneColors(
        foreground: colorScheme.onSurface,
        background: colorScheme.surfaceContainerHighest,
        border: colorScheme.outlineVariant,
      ),
  };
}

class _DiagnosticsToneColors {
  const _DiagnosticsToneColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

