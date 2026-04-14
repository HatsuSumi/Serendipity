part of 'create_record_page.dart';

extension _CreateRecordPageLocationActions on _CreateRecordPageState {
  Future<void> _showPlaceHistoryDialog() async {
    final selected = await DialogHelper.show<String>(
      context: context,
      builder: (context) => PlaceHistoryDialog(
        placeHistory: _placeHistory,
        onHistoryChanged: () {
          _updateState(() {
            _loadPlaceHistory();
          });
        },
      ),
    );

    if (selected != null) {
      _updateState(() {
        _placeNameController.text = selected;
      });

      if (widget.isEditMode) {
        _onFormChanged();
      }
    }
  }

  Future<void> _showPlaceTypeDialog() async {
    final selected = await DialogHelper.show<PlaceType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择场所类型'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: PlaceType.values.map((type) {
              return ListTile(
                leading: Text(type.icon, style: const TextStyle(fontSize: 24)),
                title: Text(type.label),
                selected: _selectedPlaceType == type,
                onTap: () => Navigator.of(context).pop(type),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (selected != null || selected == null && _selectedPlaceType != null) {
      _updateState(() {
        _selectedPlaceType = selected;
      });

      if (widget.isEditMode) {
        _onFormChanged();
      }
    }
  }
}

