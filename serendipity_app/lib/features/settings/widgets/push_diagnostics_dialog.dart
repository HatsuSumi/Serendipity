import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/push_models.dart';
import '../../../core/utils/message_helper.dart';
import 'push_diagnostics/push_diagnostics_sections.dart';
import 'push_diagnostics/push_diagnostics_summary.dart';
import 'push_diagnostics/push_diagnostics_tone.dart';

class PushDiagnosticsDialog extends StatelessWidget {
  const PushDiagnosticsDialog({
    super.key,
    required this.snapshot,
  });

  final PushDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final syncTone = mapDiagnosticsTone(snapshot.lastSyncStatus.tone);

    return AlertDialog(
      title: const Text('推送诊断'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiagnosticsSummaryCard(snapshot: snapshot),
              const SizedBox(height: 16),
              DiagnosticsSection(
                title: '基础状态',
                children: [
                  DiagnosticsItem(label: '平台', value: snapshot.platform),
                  DiagnosticsItem(
                    label: '是否支持',
                    value: snapshot.isSupported ? '是' : '否',
                    tone: snapshot.isSupported
                        ? DiagnosticsViewTone.success
                        : DiagnosticsViewTone.muted,
                    icon: snapshot.isSupported
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                  ),
                  DiagnosticsItem(
                    label: '通知权限',
                    value: snapshot.permissionStatusText,
                    tone: snapshot.permissionGranted
                        ? DiagnosticsViewTone.success
                        : DiagnosticsViewTone.warning,
                    icon: snapshot.permissionGranted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DiagnosticsSection(
                title: 'Token 状态',
                children: [
                  DiagnosticsItem(
                    label: 'Token 获取',
                    value: snapshot.tokenAvailable ? '成功' : '失败',
                    tone: snapshot.tokenAvailable
                        ? DiagnosticsViewTone.success
                        : DiagnosticsViewTone.warning,
                    icon: snapshot.tokenAvailable
                        ? Icons.vpn_key_outlined
                        : Icons.key_off_outlined,
                  ),
                  DiagnosticsItem(
                    label: 'Token 摘要',
                    value: snapshot.tokenPreview,
                    isMonospace: true,
                    action: snapshot.tokenAvailable
                        ? DiagnosticsCopyAction(
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
                  DiagnosticsItem(
                    label: '当前 Token 注册',
                    value: snapshot.currentTokenRegistered ? '已注册' : '未注册',
                    tone: snapshot.currentTokenRegistered
                        ? DiagnosticsViewTone.success
                        : DiagnosticsViewTone.warning,
                    icon: snapshot.currentTokenRegistered
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                  ),
                  DiagnosticsItem(
                    label: '服务端注册数',
                    value: '${snapshot.registeredTokenCount}',
                  ),
                  DiagnosticsItem(
                    label: '注册状态',
                    value: snapshot.registrationStatusText,
                    tone: snapshot.tokenAvailable && snapshot.currentTokenRegistered
                        ? DiagnosticsViewTone.success
                        : DiagnosticsViewTone.muted,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DiagnosticsSection(
                title: '最近同步',
                children: [
                  DiagnosticsItem(
                    label: '同步结果',
                    value: snapshot.lastSyncStatus.statusLabel,
                    tone: syncTone,
                    icon: switch (syncTone) {
                      DiagnosticsViewTone.success => Icons.sync_alt,
                      DiagnosticsViewTone.warning => Icons.sync_problem_outlined,
                      DiagnosticsViewTone.muted => Icons.schedule_outlined,
                    },
                  ),
                  DiagnosticsItem(
                    label: '同步详情',
                    value: snapshot.lastSyncStatus.detailText,
                    tone: syncTone == DiagnosticsViewTone.warning
                        ? DiagnosticsViewTone.warning
                        : DiagnosticsViewTone.muted,
                    emphasize: syncTone == DiagnosticsViewTone.warning,
                  ),
                ],
              ),
              if (!snapshot.isSupported) ...[
                const SizedBox(height: 16),
                const DiagnosticsNotice(
                  message: '当前平台暂不支持本地推送能力诊断。',
                  tone: DiagnosticsViewTone.muted,
                ),
              ],
              if (snapshot.lastSyncStatus.tone == DiagnosticsTone.warning) ...[
                const SizedBox(height: 16),
                const DiagnosticsNotice(
                  message: '最近一次 token 同步失败，优先检查通知权限、网络环境与服务端注册链路。',
                  tone: DiagnosticsViewTone.warning,
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

