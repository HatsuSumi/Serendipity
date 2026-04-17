import 'package:flutter/material.dart';

import '../../../models/enums.dart';

class WeatherMultiSelectDialog extends StatefulWidget {
  final Set<Weather> selectedWeathers;

  const WeatherMultiSelectDialog({
    super.key,
    required this.selectedWeathers,
  });

  @override
  State<WeatherMultiSelectDialog> createState() => _WeatherMultiSelectDialogState();
}

class _WeatherMultiSelectDialogState extends State<WeatherMultiSelectDialog> {
  late Set<Weather> _selectedWeathers;

  @override
  void initState() {
    super.initState();
    _selectedWeathers = Set.from(widget.selectedWeathers);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择天气'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: Weather.values.map((weather) {
            final isSelected = _selectedWeathers.contains(weather);
            return CheckboxListTile(
              secondary: Text(weather.icon, style: const TextStyle(fontSize: 24)),
              title: Text(weather.label),
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedWeathers.add(weather);
                  } else {
                    _selectedWeathers.remove(weather);
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
              _selectedWeathers.clear();
            });
          },
          child: const Text('清除'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedWeathers),
          child: Text('确定 (${_selectedWeathers.length})'),
        ),
      ],
    );
  }
}

