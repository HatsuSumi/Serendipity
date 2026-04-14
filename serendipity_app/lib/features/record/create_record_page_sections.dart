part of 'create_record_page.dart';

extension _CreateRecordPageSections on _CreateRecordPageState {
  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '⏰ 时间',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTime,
          hoverDuration: const Duration(milliseconds: 300),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 12),
                Text(
                  DateTimeHelper.formatDateTime(_selectedTime),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.edit, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return TagsSection(
      tags: _tags,
      onTagsChanged: (updatedTags) {
        _updateState(() {
          _tags = updatedTags;
        });

        if (widget.isEditMode) {
          _onFormChanged();
        }
      },
    );
  }

  Widget _buildWeatherSection() {
    return WeatherSelectionSection(
      selectedWeather: _selectedWeather,
      onWeatherChanged: (updatedWeather) {
        _updateState(() {
          _selectedWeather = updatedWeather;
        });

        if (widget.isEditMode) {
          _onFormChanged();
        }
      },
    );
  }
}


