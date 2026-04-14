part of 'create_record_page.dart';

extension _CreateRecordPagePublishStatusActions on _CreateRecordPageState {
  Future<void> _checkPublishStatus() async {
    if (!widget.isEditMode || widget.recordToEdit == null) return;

    try {
      final publishNotifier = ref.read(communityPublishProvider.notifier);
      final statusMap = await publishNotifier.checkPublishStatus([widget.recordToEdit!]);
      final status = statusMap[widget.recordToEdit!.id] ?? 'can_publish';

      if (mounted) {
        _updateState(() {
          _publishStatus = status;
        });
      }
    } catch (e) {
      if (mounted) {
        _updateState(() {
          _publishStatus = 'can_publish';
        });
      }
    }
  }
}

