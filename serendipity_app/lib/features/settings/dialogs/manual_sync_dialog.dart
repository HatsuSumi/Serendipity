import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/sync_history.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/sync_status_provider.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/providers/story_lines_provider.dart';
import '../../../core/providers/check_in_provider.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/auth_error_helper.dart';

/// 手动同步对话框
class ManualSyncDialog extends ConsumerStatefulWidget {
  const ManualSyncDialog({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    return DialogHelper.show<void>(
      context: context,
      builder: (context) => const ManualSyncDialog(),
    );
  }

  @override
  ConsumerState<ManualSyncDialog> createState() => _ManualSyncDialogState();
}

class _ManualSyncDialogState extends ConsumerState<ManualSyncDialog> {
  bool _isSyncing = false;
  String _currentStep = '';
  SyncResult? _syncResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSync();
    });
  }

  Future<void> _startSync() async {
    if (!mounted) return;

    setState(() {
      _isSyncing = true;
      _currentStep = '准备同步...';
      _syncResult = null;
      _errorMessage = null;
    });

    ref.read(syncStatusProvider.notifier).startSync();

    try {
      final user = await ref.read(authProvider.notifier).currentUser;
      if (user == null) throw StateError('用户未登录');

      // 从 SyncService 读取持久化的上次同步时间，自动判断全量/增量
      final syncService = ref.read(syncServiceProvider);
      final lastSyncTime = await syncService.getLastSyncTime(user.id);

      final result = await syncService.syncAllData(
        user,
        lastSyncTime: lastSyncTime,
        source: SyncSource.manual,
        onProgress: (step) {
          // 进度回调：更新 UI 显示当前步骤
          if (mounted) {
            setState(() {
              _currentStep = step;
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _currentStep = '同步完成';
        _syncResult = result;
      });

      // 更新 UI 状态（增量时间已由 SyncService 持久化，此处只更新手动同步时间）
      ref.read(syncStatusProvider.notifier).syncSuccess(result);

      // 触发同步完成信号，让 syncHistoriesProvider 等自动刷新
      ref.read(syncCompletedProvider.notifier).state++;

      ref.invalidate(recordsProvider);
      ref.invalidate(storyLinesProvider);
      ref.invalidate(checkInProvider);
    } catch (e) {
      final cleanMessage = AuthErrorHelper.extractErrorMessage(e);
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _errorMessage = cleanMessage;
      });
      ref.read(syncStatusProvider.notifier).syncError(cleanMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('手动同步'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSyncing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _currentStep,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            if (_syncResult != null) _buildSyncResultSection(context),
            if (_errorMessage != null) _buildErrorSection(context),
          ],
        ),
      ),
      actions: [
        if (!_isSyncing)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
      ],
    );
  }

  Widget _buildErrorSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncResultSection(BuildContext context) {
    final result = _syncResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '同步统计',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildStatRow(context,
          icon: Icons.cloud_upload_outlined,
          label: '上传',
          records: result.uploadedRecords,
          storyLines: result.uploadedStoryLines,
          checkIns: result.uploadedCheckIns,
        ),
        const SizedBox(height: 8),
        _buildStatRow(context,
          icon: Icons.cloud_download_outlined,
          label: '下载',
          records: result.downloadedRecords,
          storyLines: result.downloadedStoryLines,
          checkIns: result.downloadedCheckIns,
        ),
        const SizedBox(height: 8),
        if (result.mergedRecords > 0 ||
            result.mergedStoryLines > 0 ||
            result.mergedCheckIns > 0) ...[
          _buildStatRow(context,
            icon: Icons.merge_outlined,
            label: '冲突合并',
            records: result.mergedRecords,
            storyLines: result.mergedStoryLines,
            checkIns: result.mergedCheckIns,
            isWarning: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20,
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '检测到数据冲突，已自动合并（保留最新版本）',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!result.hasChanges) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              '数据已是最新，无需同步',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int records,
    required int storyLines,
    required int checkIns,
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20,
          color: isWarning
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text('$label：',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '$records 条记录、$storyLines 条故事线、$checkIns 条签到',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}