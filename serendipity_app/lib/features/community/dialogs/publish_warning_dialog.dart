import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/providers/user_settings_provider.dart';
import '../../../core/mixins/countdown_mixin.dart';

/// 发布警告对话框
/// 
/// 职责：
/// - 提醒用户不要包含隐私信息
/// - 说明发布后可以删除但无法修改
/// - 提供"不再提示"选项（5秒倒计时后可用）
/// 
/// 调用者：
/// - RecordDetailPage（单条发布）
/// - TimelinePage（单条发布）
/// - PublishToCommunityDialog（批量发布）
/// - CreateRecordPage（勾选"发布到树洞"时）
class PublishWarningDialog extends ConsumerStatefulWidget {
  final VoidCallback onConfirm;

  const PublishWarningDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  ConsumerState<PublishWarningDialog> createState() => _PublishWarningDialogState();

  /// 显示对话框（静态方法）
  /// 
  /// 调用者：
  /// - RecordDetailPage._publishToCommunity()
  /// - TimelinePage._showPublishToCommunityDialog()
  /// - PublishToCommunityDialog._showWarningBeforePublish()
  /// - CreateRecordPage._saveRecord()
  /// 
  /// 返回值：
  /// - true: 用户确认发布
  /// - false: 用户取消发布
  /// 
  /// 如果用户已设置"不再提示"，直接返回 true
  static Future<bool> show(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // 检查用户设置
    final hideWarning = ref.read(userSettingsProvider).hidePublishWarning;
    
    if (hideWarning) {
      // 用户已选择不再提示，直接返回 true
      return true;
    }
    
    // 显示警告对话框
    final result = await DialogHelper.show<bool>(
      context: context,
      builder: (context) => PublishWarningDialog(
        onConfirm: () {
          Navigator.of(context).pop(true);
        },
      ),
    );
    
    return result ?? false;
  }
}

class _PublishWarningDialogState extends ConsumerState<PublishWarningDialog> with CountdownMixin {
  bool _hideWarning = false;

  @override
  void initState() {
    super.initState();
    // 检查用户是否已看过警告，如果已看过则跳过倒计时
    final hasSeenWarning = ref.read(userSettingsProvider).hasSeenPublishWarning;
    startCountdown(
      skipCountdown: hasSeenWarning,
      onFinished: () {
        // 倒计时完成时标记用户已看过警告
        if (mounted) {
          ref.read(userSettingsProvider.notifier).markPublishWarningSeen();
        }
      },
    );
  }

  @override
  void dispose() {
    disposeCountdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          const Text('发布前请注意'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('你即将匿名发布这条记录到社区。'),
            const SizedBox(height: 16),
            Text(
              '社区帖子包含以下字段：',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text('错过时间、发布时间、地址、地点名称、场所类型、省市区、描述、标签、状态'),
            const SizedBox(height: 16),
            Text(
              '社区帖子不包含以下字段：',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text('精确GPS坐标、情绪强度、对话契机、背景音乐、天气、"如果再遇"备忘'),
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              '请确保不包含：',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildWarningItem('手机号、微信号、QQ号'),
            _buildWarningItem('真实姓名、家庭住址'),
            _buildWarningItem('其他隐私信息'),
            const SizedBox(height: 16),
            Text(
              '发布后可以删除，但无法修改。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 不再提示选项（5秒倒计时）
            _buildHideWarningOption(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: countdownFinished ? () async {
            // 如果勾选了"不再提示"，保存设置
            if (_hideWarning) {
              await ref.read(userSettingsProvider.notifier).updateHidePublishWarning(true);
            }
            
            if (context.mounted) {
              // 执行回调（关闭对话框并返回 true）
              widget.onConfirm();
            }
          } : null,
          child: Text(countdownFinished ? '确认发布' : '确认发布 ($countdown)'),
        ),
      ],
    );
  }

  /// 构建"不再提示"选项
  Widget _buildHideWarningOption(BuildContext context) {
    // 检查用户是否已看过警告
    final hasSeenWarning = ref.read(userSettingsProvider).hasSeenPublishWarning;
    
    if (!countdownFinished && !hasSeenWarning) {
      // 首次打开且倒计时中，显示提示文本
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '请仔细阅读警告内容 ($countdown 秒)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    // 倒计时结束或已看过警告，显示复选框
    return CheckboxListTile(
      value: _hideWarning,
      onChanged: (value) {
        setState(() {
          _hideWarning = value ?? false;
        });
      },
      title: const Text('不再提示'),
      subtitle: Text(
        '勾选后将永久隐藏此警告',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  /// 构建警告项
  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text),
    );
  }
}

