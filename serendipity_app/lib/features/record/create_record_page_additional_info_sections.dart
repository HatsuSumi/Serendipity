part of 'create_record_page.dart';

extension _CreateRecordPageAdditionalInfoSections on _CreateRecordPageState {
  Widget _buildEmotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '❤️ 情绪强度',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: _colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmotionIntensity.values.map((emotion) {
            final isSelected = _selectedEmotion == emotion;
            return ChoiceChip(
              label: Text(emotion.label),
              selected: isSelected,
              onSelected: (selected) {
                _updateState(() {
                  _selectedEmotion = selected ? emotion : null;
                });

                if (widget.isEditMode) {
                  _onFormChanged();
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBackgroundMusicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🎵 背景音乐',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: _colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _backgroundMusicController,
          decoration: InputDecoration(
            hintText: '记录当时在听的歌曲，格式：歌名 - 歌手',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.music_note),
          ),
        ),
      ],
    );
  }

  Widget _buildIfReencounterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '💡 如果再遇',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: _colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ifReencounterController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '下次见面想做什么、想说什么...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

