import 'package:flutter/material.dart';
import '../../../core/utils/dialog_helper.dart';

/// 发布警告对话框
/// 
/// 职责：
/// - 提醒用户不要包含隐私信息
/// - 说明发布后可以删除但无法修改
/// 
/// 调用者：
/// - RecordDetailPage（单条发布）
/// - TimelinePage（单条发布）
/// - PublishToCommunityDialog（批量发布）
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
          ],
        ),
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
  /// - TimelinePage._showPublishToCommunityDialog()
  /// - PublishToCommunityDialog._showWarningBeforePublish()
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

