part of 'create_record_page.dart';

extension _CreateRecordPageReminderDialogs on _CreateRecordPageState {
  Future<void> _showIfReencounterReminderIfNeeded() async {
    try {
      final recordsAsync = ref.read(recordsProvider);
      final allRecords = recordsAsync.value ?? [];
      final records = allRecords.where((r) => r.storyLineId == _selectedStoryLineId).toList();

      final now = DateTime.now();
      final recordsWithMemo = records.where((record) =>
        record.ifReencounter != null &&
        record.ifReencounter!.isNotEmpty &&
        now.difference(record.createdAt).inSeconds > 1
      ).toList();

      if (recordsWithMemo.isEmpty) {
        return;
      }

      recordsWithMemo.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestRecord = recordsWithMemo.first;

      await DialogHelper.show(
        context: context,
        builder: (context) => _buildIfReencounterReminderDialog(latestRecord),
      );
    } catch (e) {
      // 出错时不影响流程，静默失败
    }
  }

  Widget _buildIfReencounterReminderDialog(EncounterRecord record) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('💭 '),
          Expanded(
            child: Text(
              '还记得你说过的话吗？',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '在 ${_formatReminderDate(record.timestamp)} ${record.status.label}时，你写下了：',
            style: TextStyle(
              fontSize: 14,
              color: _colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Text(
              '"${record.ifReencounter}"',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: _colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '现在，你们再次相遇了！✨',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('我知道了'),
        ),
      ],
    );
  }

  String _formatReminderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else {
      return DateTimeHelper.formatChineseDate(date);
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final result = await DialogHelper.show<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃修改？'),
        content: Text(
          widget.isEditMode ? '你有未保存的修改，确定要放弃吗？' : '你填写的内容还未保存，确定要放弃吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

