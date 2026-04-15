part of 'timeline_page.dart';

extension _TimelinePagePublishDeleteActionsSection on _TimelinePageState {
  /// 发布到社区
  void _showPublishToCommunityDialog(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
  ) async {
    final publishNotifier = ref.read(communityPublishProvider.notifier);

    try {
      final statusMap = await publishNotifier.checkPublishStatus([record]);
      final status = statusMap[record.id] ?? 'can_publish';

      if (status == 'cannot_publish') {
        if (context.mounted) {
          MessageHelper.showError(context, '该记录已发布且内容未变化');
        }
        return;
      }

      if (!context.mounted) return;
      final shouldPublish = await PublishWarningDialog.show(context, ref);

      if (!shouldPublish) return;

      if (status == 'need_confirm') {
        if (!context.mounted) return;

        final confirmed = await DialogHelper.show<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('发布确认'),
            content: const Text('该记录已发布到社区，重新发布会替换旧帖，是否继续？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确认'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        if (!context.mounted) return;
        final localContext = context;
        await AsyncActionHelper.execute(
          localContext,
          action: () => publishNotifier.publishPost(record, forceReplace: true),
          successMessage: '已发布到树洞',
          errorMessagePrefix: '发布失败',
        );
      } else {
        if (!context.mounted) return;
        final localContext = context;
        await AsyncActionHelper.execute(
          localContext,
          action: () => publishNotifier.publishPost(record),
          successMessage: '已发布到树洞',
          errorMessagePrefix: '发布失败',
        );
      }
    } catch (e) {
      if (context.mounted) {
        MessageHelper.showError(context, '检查发布状态失败：${AuthErrorHelper.extractErrorMessage(e)}');
      }
    }
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, EncounterRecord record) async {
    final content = await _buildDeleteContent(ref, record);
    if (!context.mounted) return;
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '删除记录',
      content: content,
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(recordsProvider.notifier).deleteRecord(record.id);
        if (context.mounted) {
          MessageHelper.showSuccess(context, '记录已删除');
        }
      } catch (e) {
        if (context.mounted) {
          MessageHelper.showError(context, '删除失败：${AuthErrorHelper.extractErrorMessage(e)}');
        }
      }
    }
  }

  /// 构建删除确认内容
  static Future<String> _buildDeleteContent(WidgetRef ref, EncounterRecord record) async {
    final lines = <String>['确定要删除这条记录吗？此操作无法撤销。'];

    if (record.storyLineId != null) {
      lines.add('删除这条记录会自动取消关联故事线。');
    }

    final myPostsValue = ref.read(myPostsProvider);
    final myPosts = myPostsValue.valueOrNull;
    if (myPosts != null) {
      final isPublished = myPosts.any((post) => post.recordId == record.id);
      if (isPublished) {
        lines.add('删除这条记录会自动删除社区帖子。');
      }
    }

    return lines.join('\n\n');
  }
}

