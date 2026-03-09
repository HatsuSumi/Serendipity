import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/sync_status_provider.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/providers/story_lines_provider.dart';
import '../../../core/providers/check_in_provider.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/auth_error_helper.dart';

/// 手动同步对话框
/// 
/// 职责：
/// - 显示同步进度
/// - 显示同步结果统计
/// - 显示冲突合并信息
/// - 处理同步错误
/// 
/// 调用者：
/// - SettingsPage：手动同步按钮
/// 
/// 遵循原则：
/// - 单一职责（SRP）：只负责手动同步的 UI 交互
/// - 依赖倒置（DIP）：通过 Provider 获取依赖
/// - Fail Fast：参数验证立即抛出异常
class ManualSyncDialog extends ConsumerStatefulWidget {
  const ManualSyncDialog({super.key});

  /// 显示手动同步对话框
  /// 
  /// 调用者：SettingsPage
  /// 
  /// Fail Fast：
  /// - context 为 null：由 Dart 类型系统保证
  /// - ref 为 null：由 Dart 类型系统保证
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
    // 对话框打开后立即开始同步
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSync();
    });
  }

  /// 开始同步
  /// 
  /// 调用者：initState()
  Future<void> _startSync() async {
    if (!mounted) return;
    
    // 记录同步开始时间（在同步开始前）
    final syncStartTime = DateTime.now();
    
    setState(() {
      _isSyncing = true;
      _currentStep = '准备同步...';
      _syncResult = null;
      _errorMessage = null;
    });

    // 更新同步状态为"同步中"
    ref.read(syncStatusProvider.notifier).startSync();

    try {
      // 1. 检查用户是否登录
      final user = await ref.read(authProvider.notifier).currentUser;
      if (user == null) {
        throw StateError('用户未登录');
      }

      // 2. 上传本地数据
      if (!mounted) return;
      setState(() {
        _currentStep = '正在上传本地数据...';
      });
      await Future.delayed(const Duration(milliseconds: 500)); // 让用户看到进度

      // 3. 下载云端数据
      if (!mounted) return;
      setState(() {
        _currentStep = '正在下载云端数据...';
      });
      await Future.delayed(const Duration(milliseconds: 500)); // 让用户看到进度

      // 4. 合并数据
      if (!mounted) return;
      setState(() {
        _currentStep = '正在合并数据...';
      });

      // 执行同步（使用增量同步）
      final syncService = ref.read(syncServiceProvider);
      final syncStatus = ref.read(syncStatusProvider);
      final lastSyncTime = syncStatus.lastFullSyncTime;
      
      final result = await syncService.syncAllData(user, lastSyncTime: lastSyncTime);

      // 5. 同步成功
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _currentStep = '同步完成';
        _syncResult = result;
      });

      // 更新同步状态为"成功"（传入同步开始时间）
      ref.read(syncStatusProvider.notifier).syncSuccess(result, syncStartTime);

      // 刷新所有数据列表
      ref.invalidate(recordsProvider);
      ref.invalidate(storyLinesProvider);
      ref.invalidate(checkInProvider);
    } catch (e) {
      // 同步失败
      final cleanMessage = AuthErrorHelper.extractErrorMessage(e);
      
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _errorMessage = cleanMessage;
      });

      // 更新同步状态为"失败"
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
            // 同步进度
            if (_isSyncing) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _currentStep,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            
            // 同步结果
            if (_syncResult != null) ...[
              _buildSyncResultSection(context),
            ],
            
            // 错误信息
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
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
              ),
            ],
          ],
        ),
      ),
      actions: [
        // 同步中不显示按钮
        if (!_isSyncing)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
      ],
    );
  }

  /// 构建同步结果区域
  /// 
  /// 调用者：build()
  Widget _buildSyncResultSection(BuildContext context) {
    final result = _syncResult!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 成功图标
        Center(
          child: Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        
        // 同步统计
        Text(
          '同步统计',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        
        // 上传统计
        _buildStatRow(
          context,
          icon: Icons.cloud_upload_outlined,
          label: '上传',
          records: result.uploadedRecords,
          storyLines: result.uploadedStoryLines,
          checkIns: result.uploadedCheckIns,
        ),
        const SizedBox(height: 8),
        
        // 下载统计
        _buildStatRow(
          context,
          icon: Icons.cloud_download_outlined,
          label: '下载',
          records: result.downloadedRecords,
          storyLines: result.downloadedStoryLines,
          checkIns: result.downloadedCheckIns,
        ),
        const SizedBox(height: 8),
        
        // 冲突合并统计（如果有）
        if (result.mergedRecords > 0 || 
            result.mergedStoryLines > 0 || 
            result.mergedCheckIns > 0) ...[
          _buildStatRow(
            context,
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
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
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
        
        // 无数据变化提示
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

  /// 构建统计行
  /// 
  /// 调用者：_buildSyncResultSection()
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
        Icon(
          icon,
          size: 20,
          color: isWarning
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label：',
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

