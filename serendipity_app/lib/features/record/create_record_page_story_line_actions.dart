part of 'create_record_page.dart';

extension _CreateRecordPageStoryLineActions on _CreateRecordPageState {
  Future<void> _showStoryLineSelectionDialog() async {
    final storyLinesAsync = ref.read(storyLinesProvider);

    final storyLines = storyLinesAsync.when(
      data: (data) => data,
      loading: () => <StoryLine>[],
      error: (_, _) => <StoryLine>[],
    );

    if (!mounted) return;

    final result = await DialogHelper.show<String>(
      context: context,
      builder: (context) => StoryLineSelectionDialog(
        storyLines: storyLines,
        currentStoryLineId: _selectedStoryLineId,
      ),
    );

    if (result != null && mounted) {
      _updateState(() {
        _selectedStoryLineId = result;
      });

      if (widget.isEditMode) {
        _onFormChanged();
      }
    }
  }
}

