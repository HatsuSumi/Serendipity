import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/page_transition_builder.dart';
import '../../core/utils/smart_navigator.dart';
import '../community/dialogs/publish_warning_dialog.dart';
import '../story_line/link_to_story_line_dialog.dart';
import '../story_line/story_line_detail_page.dart';
import 'create_record_page.dart';
import 'widgets/record_detail_action_menu.dart';
import 'widgets/record_export_card.dart';
import 'record_detail_page.dart';

class RecordDetailController {
  final WidgetRef ref;
  final bool Function() isMounted;

  const RecordDetailController({
    required this.ref,
    required this.isMounted,
  });

  void navigateToEditPage(BuildContext context, EncounterRecord record) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      CreateRecordPage(recordToEdit: record),
    ).then((result) {
      if (isMounted() && result != null && result is EncounterRecord) {
        ref.invalidate(recordsProvider);
      }
    });
  }

  void navigateToStoryLineDetail(BuildContext context, EncounterRecord record) {
    if (record.storyLineId == null) return;

    final storyLinesAsync = ref.read(storyLinesProvider);
    final storyLines = storyLinesAsync.value;
    if (storyLines == null) {
      MessageHelper.showError(context, '故事线数据未加载');
      return;
    }

    StoryLine? storyLine;
    try {
      storyLine = storyLines.firstWhere((sl) => sl.id == record.storyLineId);
    } catch (_) {
      MessageHelper.showError(context, '故事线不存在');
      return;
    }

    var transitionType = ref.read(pageTransitionProvider);
    if (transitionType == PageTransitionType.random) {
      transitionType = PageTransitionBuilder.getRandomType();
    }

    SmartNavigator.push(
      context: context,
      targetPage: StoryLineDetailPage(storyLineId: storyLine.id),
      currentPageType: RecordDetailPage,
      targetPageType: StoryLineDetailPage,
      transitionDuration: transitionType == PageTransitionType.none
          ? Duration.zero
          : const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return PageTransitionBuilder.buildTransition(
          transitionType,
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
    );
  }

  Future<void> handleMenuAction(
    BuildContext context,
    RecordDetailAction action,
    EncounterRecord record,
  ) async {
    switch (action) {
      case RecordDetailAction.export:
        await exportRecord(context, record);
        return;
      case RecordDetailAction.storyline:
        showLinkToStoryLineDialog(context, record);
        return;
      case RecordDetailAction.community:
        await publishToCommunity(context, record);
        return;
      case RecordDetailAction.delete:
        await showDeleteConfirmDialog(context, record);
        return;
    }
  }

  Future<void> exportRecord(BuildContext context, EncounterRecord record) async {
    final success = await RecordExportCard.export(context, record);
    if (!context.mounted) return;
    if (success) {
      MessageHelper.showSuccess(context, '已保存到相册');
    } else {
      MessageHelper.showError(context, '导出失败，请重试');
    }
  }

  Future<void> publishToCommunity(BuildContext context, EncounterRecord record) async {
    final publishNotifier = ref.read(communityPublishProvider.notifier);

    try {
      final statusMap = await publishNotifier.checkPublishStatus([record]);
      final status = statusMap[record.id] ?? 'can_publish';

      if (!context.mounted) return;
      if (status == 'cannot_publish') {
        MessageHelper.showError(context, '该记录已发布且内容未变化');
        return;
      }

      if (!isMounted() || !context.mounted) return;
      final shouldPublish = await PublishWarningDialog.show(context, ref);
      if (!shouldPublish) return;

      if (status == 'need_confirm') {
        if (!isMounted() || !context.mounted) return;
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

        if (!isMounted() || !context.mounted) return;
        await AsyncActionHelper.execute(
          context,
          action: () => publishNotifier.publishPost(record, forceReplace: true),
          successMessage: '已发布到树洞',
          errorMessagePrefix: '发布失败',
        );
        return;
      }

      if (!isMounted() || !context.mounted) return;
      await AsyncActionHelper.execute(
        context,
        action: () => publishNotifier.publishPost(record),
        successMessage: '已发布到树洞',
        errorMessagePrefix: '发布失败',
      );
    } catch (e) {
      if (!context.mounted) return;
      MessageHelper.showError(context, '检查发布状态失败：${AuthErrorHelper.extractErrorMessage(e)}');
    }
  }

  void showLinkToStoryLineDialog(BuildContext context, EncounterRecord record) {
    DialogHelper.show(
      context: context,
      builder: (context) => LinkToStoryLineDialog(recordId: record.id),
    ).then((result) {
      if (result == true && isMounted()) {
        ref.invalidate(recordsProvider);
      }
    });
  }

  Future<void> showDeleteConfirmDialog(BuildContext context, EncounterRecord record) async {
    final content = await buildDeleteContent(record);
    if (!context.mounted) return;
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '删除记录',
      content: content,
    );

    if (confirmed == true && context.mounted) {
      await deleteRecord(context, record);
    }
  }

  Future<String> buildDeleteContent(EncounterRecord record) async {
    final lines = <String>['确定要删除这条记录吗？此操作无法撤销。'];

    if (record.storyLineId != null) {
      lines.add('删除这条记录会自动取消关联故事线。');
    }

    final myPosts = await ref.read(myPostsProvider.future);
    final isPublished = myPosts.any((post) => post.recordId == record.id);
    if (isPublished) {
      lines.add('删除这条记录会自动删除社区帖子。');
    }

    return lines.join('\n\n');
  }

  Future<void> deleteRecord(BuildContext context, EncounterRecord record) async {
    try {
      await ref.read(recordsProvider.notifier).deleteRecord(record.id);
      if (!isMounted()) return;
      ref.invalidate(recordsProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      MessageHelper.showSuccess(context, '记录已删除');
    } catch (e) {
      if (!isMounted() || !context.mounted) return;
      MessageHelper.showError(context, '删除失败：${AuthErrorHelper.extractErrorMessage(e)}');
    }
  }
}

