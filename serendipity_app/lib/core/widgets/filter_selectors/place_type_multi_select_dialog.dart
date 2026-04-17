import 'package:flutter/material.dart';

import '../../../models/enums.dart';

class PlaceTypeMultiSelectDialog extends StatefulWidget {
  final Set<PlaceType> selectedTypes;

  const PlaceTypeMultiSelectDialog({
    super.key,
    required this.selectedTypes,
  });

  @override
  State<PlaceTypeMultiSelectDialog> createState() => _PlaceTypeMultiSelectDialogState();
}

class _PlaceTypeMultiSelectDialogState extends State<PlaceTypeMultiSelectDialog> {
  late Set<PlaceType> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择场所类型'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: PlaceType.values.map((type) {
            final isSelected = _selectedTypes.contains(type);
            return CheckboxListTile(
              secondary: Text(type.icon, style: const TextStyle(fontSize: 24)),
              title: Text(type.label),
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedTypes.add(type);
                  } else {
                    _selectedTypes.remove(type);
                  }
                });
              },
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
          onPressed: () {
            setState(() {
              _selectedTypes.clear();
            });
          },
          child: const Text('清除'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedTypes),
          child: Text('确定 (${_selectedTypes.length})'),
        ),
      ],
    );
  }
}

