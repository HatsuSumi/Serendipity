part of 'create_record_page.dart';

extension _CreateRecordPageStatusAndDescriptionSections on _CreateRecordPageState {
  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '💫 状态',
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
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.help_outline,
                size: 20,
                color: _colorScheme.primary,
              ),
              onPressed: () => _showRecordGuideDialog(context),
              tooltip: '如何记录？',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EncounterStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return ChoiceChip(
              label: Text('${status.icon} ${status.label}'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateState(() {
                    _selectedStatus = status;
                  });

                  if (widget.isEditMode) {
                    _onFormChanged();
                  }
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📝 描述',
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
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '记录当时的情景、感受...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationStarterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '💬 对话契机',
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
          controller: _conversationStarterController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '记录你们是如何开始对话的...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

