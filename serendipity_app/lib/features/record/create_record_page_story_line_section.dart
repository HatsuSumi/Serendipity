part of 'create_record_page.dart';

extension _CreateRecordPageStoryLineSection on _CreateRecordPageState {
  Widget _buildStoryLineSection() {
    String? storyLineName;
    if (_selectedStoryLineId != null) {
      final storyLinesAsync = ref.read(storyLinesProvider);
      final storyLines = storyLinesAsync.value ?? [];
      try {
        final storyLine = storyLines.firstWhere((sl) => sl.id == _selectedStoryLineId);
        storyLineName = storyLine.name;
      } catch (e) {
        storyLineName = null;
      }
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('关联到故事线'),
      subtitle: storyLineName != null
          ? Row(
              children: [
                const Text('📖 '),
                Expanded(
                  child: Text(
                    storyLineName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Text(
              '将多个相关记录串联成完整故事',
              style: TextStyle(
                fontSize: 12,
                color: _colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedStoryLineId != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _updateState(() {
                  _selectedStoryLineId = null;
                });

                if (widget.isEditMode) {
                  _onFormChanged();
                }
              },
              tooltip: '清除',
            ),
          TextButton(
            onPressed: _showStoryLineSelectionDialog,
            child: Text(_selectedStoryLineId != null ? '更改' : '选择'),
          ),
        ],
      ),
    );
  }
}

