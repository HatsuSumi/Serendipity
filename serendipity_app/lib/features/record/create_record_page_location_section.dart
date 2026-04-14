part of 'create_record_page.dart';

extension _CreateRecordPageLocationSection on _CreateRecordPageState {
  Widget _buildLocationSection() {
    final defaultPlaceTypes = PlaceType.values.take(10).toList();
    final displayedPlaceTypes = _selectedPlaceType != null &&
            !defaultPlaceTypes.contains(_selectedPlaceType)
        ? [
            _selectedPlaceType!,
            ...defaultPlaceTypes,
          ].take(10).toList()
        : defaultPlaceTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📍 地点',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildLocationStatus(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: _ignoreGPS,
                onChanged: (value) {
                  _updateState(() {
                    _ignoreGPS = value ?? false;
                  });

                  if (widget.isEditMode) {
                    _onFormChanged();
                  }
                },
                title: const Text('忽略 GPS 定位'),
                subtitle: Text(
                  '只使用下面输入的地点名称（用于UI显示）',
                  style: TextStyle(
                    fontSize: 12,
                    color: _colorScheme.onSurfaceVariant,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.help_outline,
                size: 20,
                color: _colorScheme.primary,
              ),
              onPressed: () => _showIgnoreGPSHelpDialog(context),
              tooltip: '为什么要忽略GPS？',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '地点名称（可选）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '可以写地址，也可以取个名字',
              style: TextStyle(
                fontSize: 12,
                color: _colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _placeNameController,
                decoration: InputDecoration(
                  hintText: '例如：地铁10号线、常去的咖啡馆',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: _showPlaceHistoryDialog,
              icon: const Icon(Icons.history),
              tooltip: '历史地点',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '场所类型（可选）',
          style: TextStyle(
            fontSize: 14,
            color: _colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayedPlaceTypes.map((type) {
            final isSelected = _selectedPlaceType == type;
            return FilterChip(
              label: Text('${type.icon} ${type.label}'),
              selected: isSelected,
              onSelected: (selected) {
                _updateState(() {
                  _selectedPlaceType = selected ? type : null;
                });

                if (widget.isEditMode) {
                  _onFormChanged();
                }
              },
            );
          }).toList(),
        ),
        if (PlaceType.values.length > 10)
          TextButton(
            onPressed: _showPlaceTypeDialog,
            child: const Text('查看全部场所类型 →'),
          ),
      ],
    );
  }
}

