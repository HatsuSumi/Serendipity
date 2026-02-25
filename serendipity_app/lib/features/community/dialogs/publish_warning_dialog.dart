import 'package:flutter/material.dart';
import '../../../core/utils/dialog_helper.dart';

/// 发布警告对话框
/// 
/// 职责：
/// - 提醒用户不要包含隐私信息
/// - 说明发布后可以删除但无法修改
/// 
/// 调用者：
/// - RecordDetailPage（发布到社区菜单）
/// - CreateRecordPage（勾选"发布到树洞"时）
class PublishWarningDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const PublishWarningDialog({
    super.key,
    required this.onConfirm,
  });

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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('你即将匿名发布这条记录到社区。'),
          const SizedBox(height: 16),
          Text(
            '请确保不包含：',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildWarningItem('手机号、微信号、QQ号'),
          _buildWarningItem('真实姓名、地址'),
          _buildWarningItem('其他隐私信息'),
          const SizedBox(height: 16),
          Text(
            '发布后可以删除，但无法修改。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('确认发布'),
        ),
      ],
    );
  }

  /// 构建警告项
  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text),
    );
  }

  /// 显示对话框（静态方法）
  /// 
  /// 调用者：
  /// - RecordDetailPage._publishToCommunity()
  /// - CreateRecordPage._saveRecord()
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) async {
    await DialogHelper.show(
      context: context,
      builder: (context) => PublishWarningDialog(onConfirm: onConfirm),
    );
  }
}

