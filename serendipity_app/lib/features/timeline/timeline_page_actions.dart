part of 'timeline_page.dart';

extension _TimelinePageActionsSection on _TimelinePageState {
  /// 处理菜单操作
  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _navigateToEditRecord(context, ref, record);
        break;
      case 'pin':
        _togglePinRecord(context, ref, record);
        break;
      case 'favorite':
        _toggleFavoriteRecord(context, ref, record);
        break;
      case 'link':
        _showLinkToStoryLineDialog(context, ref, record);
        break;
      case 'export':
        _exportRecord(context, record);
        break;
      case 'publish':
        _showPublishToCommunityDialog(context, ref, record);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, ref, record);
        break;
    }
  }

  /// 导出记录为图片并保存到相册
  void _exportRecord(BuildContext context, EncounterRecord record) async {
    final success = await RecordExportCard.export(context, record);
    if (!context.mounted) return;
    if (success) {
      MessageHelper.showSuccess(context, '已保存到相册');
    } else {
      MessageHelper.showError(context, '导出失败，请重试');
    }
  }

  /// 切换置顶状态
  void _togglePinRecord(BuildContext context, WidgetRef ref, EncounterRecord record) async {
    try {
      await ref.read(recordsProvider.notifier).togglePin(record.id);
      if (context.mounted) {
        MessageHelper.showSuccess(
          context,
          record.isPinned ? '已取消置顶' : '已置顶',
        );
      }
    } catch (e) {
      if (context.mounted) {
        MessageHelper.showError(context, '操作失败：${AuthErrorHelper.extractErrorMessage(e)}');
      }
    }
  }

  /// 切换记录收藏状态
  void _toggleFavoriteRecord(BuildContext context, WidgetRef ref, EncounterRecord record) async {
    final isFavorited =
        ref.read(favoritesProvider).valueOrNull?.isRecordFavorited(record.id) ?? false;
    final notifier = ref.read(favoritesProvider.notifier);
    try {
      if (isFavorited) {
        await notifier.unfavoriteRecord(record.id);
        if (context.mounted) MessageHelper.showSuccess(context, '已取消收藏');
      } else {
        await notifier.favoriteRecord(record);
        if (context.mounted) MessageHelper.showSuccess(context, '已收藏');
      }
    } catch (e) {
      if (context.mounted) {
        MessageHelper.showError(
          context,
          '操作失败：${AuthErrorHelper.extractErrorMessage(e)}',
        );
      }
    }
  }
}

