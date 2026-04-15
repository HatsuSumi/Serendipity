part of 'timeline_page.dart';

extension _TimelinePageNavigationActionsSection on _TimelinePageState {
  /// 导航到编辑记录页面
  void _navigateToEditRecord(BuildContext context, WidgetRef ref, EncounterRecord record) async {
    final result = await NavigationHelper.pushWithTransition(
      context,
      ref,
      CreateRecordPage(recordToEdit: record),
    );

    if (result != null && mounted) {
      ref.invalidate(recordsProvider);
    }
  }

  /// 导航到记录详情页面（统一方法）
  void _navigateToRecordDetail(BuildContext context, WidgetRef ref, EncounterRecord record) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      RecordDetailPage(record: record),
    );
  }

  /// 显示关联到故事线对话框
  void _showLinkToStoryLineDialog(BuildContext context, WidgetRef ref, EncounterRecord record) {
    DialogHelper.show(
      context: context,
      builder: (context) => LinkToStoryLineDialog(recordId: record.id),
    );
  }
}

