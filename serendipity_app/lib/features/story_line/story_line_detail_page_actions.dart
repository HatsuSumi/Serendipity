import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/membership_provider.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/providers/records_command_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/page_transition_builder.dart';
import '../../core/utils/smart_navigator.dart';
import '../../models/enums.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../record/create_record_page.dart';
import '../record/record_detail_page.dart';
import 'add_existing_records_dialog.dart';
import 'story_line_detail_page.dart';
import 'story_line_export_card.dart';

class StoryLineDetailPageActions {
  const StoryLineDetailPageActions._();

  static void handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
    String action,
  ) {
    switch (action) {
      case 'add_existing':
        showAddExistingRecordsDialog(context, storyLine);
        break;
      case 'export':
        exportStoryLine(context, ref, storyLine);
        break;
      case 'rename':
        showRenameDialog(context, ref, storyLine);
        break;
      case 'delete':
        showDeleteConfirmDialog(context, ref, storyLine);
        break;
    }
  }

  static void handleRecordMenuAction(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
    StoryLine storyLine,
    String action,
  ) {
    switch (action) {
      case 'remove':
        showRemoveRecordConfirmDialog(context, ref, record, storyLine);
        break;
      case 'edit':
        navigateToEditRecord(context, ref, record);
        break;
      case 'delete':
        showDeleteRecordConfirmDialog(context, ref, record);
        break;
    }
  }

  static Future<void> showRemoveRecordConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
    StoryLine storyLine,
  ) async {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从故事线移除'),
        content: const Text('确定要将这条记录从故事线中移除吗？\n\n记录本身不会被删除，只是取消关联。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AsyncActionHelper.execute(
                context,
                action: () => ref.read(storyLinesProvider.notifier).unlinkRecord(record.id, storyLine.id),
                successMessage: '已从故事线移除',
                errorMessagePrefix: '移除失败',
              );
            },
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  static void navigateToEditRecord(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
  ) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      CreateRecordPage(recordToEdit: record),
    );
  }

  static Future<void> showDeleteRecordConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
  ) async {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AsyncActionHelper.execute(
                context,
                action: () => ref.read(recordsCommandProvider.notifier).deleteRecord(record.id),
                successMessage: '记录已删除',
                errorMessagePrefix: '删除失败',
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  static Future<void> exportStoryLine(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
  ) async {
    final membershipInfo = ref.read(membershipProvider).valueOrNull;
    if (membershipInfo == null || !membershipInfo.canExportStoryLineCard) {
      MessageHelper.showWarning(context, '导出故事线图文卡片是会员专属功能');
      return;
    }

    final records = List<EncounterRecord>.from(
      ref.read(storyLineRecordsProvider(storyLine.id)),
    )..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (records.isEmpty) {
      MessageHelper.showWarning(context, '故事线暂无记录，无法导出');
      return;
    }

    final success = await StoryLineExportCard.export(context, storyLine, records);
    if (!context.mounted) {
      return;
    }
    if (success) {
      MessageHelper.showSuccess(context, '已保存到相册');
    } else {
      MessageHelper.showError(context, '导出失败，请重试');
    }
  }

  static void showAddExistingRecordsDialog(BuildContext context, StoryLine storyLine) {
    DialogHelper.show(
      context: context,
      builder: (context) => AddExistingRecordsDialog(storyLine: storyLine),
    );
  }

  static Future<void> showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
  ) async {
    final newName = await DialogHelper.showRenameDialog(
      context: context,
      title: '重命名故事线',
      initialValue: storyLine.name,
      hintText: '输入新名称...',
      emptyWarning: '请输入故事线名称',
    );

    if (newName != null && context.mounted) {
      final updatedStoryLine = storyLine.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );

      await AsyncActionHelper.execute(
        context,
        action: () => ref.read(storyLinesProvider.notifier).updateStoryLine(updatedStoryLine),
        successMessage: '已重命名',
        errorMessagePrefix: '重命名失败',
      );
    }
  }

  static Future<void> showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
  ) async {
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '删除故事线',
      content: '删掉这条故事线，\n你还是会记得 TA。\n\n只是以后，\n不会再打开这里了。\n\n（记录不会被删除，只是取消关联）',
    );

    if (confirmed == true && context.mounted) {
      final success = await AsyncActionHelper.execute(
        context,
        action: () => ref.read(storyLinesProvider.notifier).deleteStoryLine(storyLine.id),
        successMessage: '故事线已删除',
        errorMessagePrefix: '删除失败',
      );

      if (success && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  static void navigateToRecordDetail(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
  ) {
    var transitionType = ref.read(pageTransitionProvider);
    if (transitionType == PageTransitionType.random) {
      transitionType = PageTransitionBuilder.getRandomType();
    }

    SmartNavigator.push(
      context: context,
      targetPage: RecordDetailPage(record: record),
      currentPageType: StoryLineDetailPage,
      targetPageType: RecordDetailPage,
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

  static void navigateToCreateRecord(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
  ) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      CreateRecordPage(initialStoryLineId: storyLine.id),
    );
  }
}

