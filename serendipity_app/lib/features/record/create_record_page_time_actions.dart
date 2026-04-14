part of 'create_record_page.dart';

extension _CreateRecordPageTimeActions on _CreateRecordPageState {
  Future<void> _selectTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    if (mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedTime),
      );

      if (time != null) {
        _updateState(() {
          _selectedTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });

        if (widget.isEditMode) {
          _onFormChanged();
        }
      }
    }
  }
}

