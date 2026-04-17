import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../utils/dialog_helper.dart';
import 'place_type_multi_select_dialog.dart';
import 'weather_multi_select_dialog.dart';

/// 场所类型选择器
/// 
/// 职责：显示场所类型的 FilterChip 列表
/// 
/// 调用者：各筛选对话框
class PlaceTypeSelector extends StatefulWidget {
  final Set<PlaceType> selectedTypes;
  final ValueChanged<Set<PlaceType>> onTypesChanged;

  const PlaceTypeSelector({
    super.key,
    required this.selectedTypes,
    required this.onTypesChanged,
  });

  @override
  State<PlaceTypeSelector> createState() => _PlaceTypeSelectorState();
}

class _PlaceTypeSelectorState extends State<PlaceTypeSelector> {
  static final List<PlaceType> _displayedTypes = PlaceType.values.take(10).toList();
  static final bool _hasMoreTypes = PlaceType.values.length > 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _displayedTypes.map((type) {
            final isSelected = widget.selectedTypes.contains(type);
            return FilterChip(
              label: Text('${type.icon} ${type.label}'),
              selected: isSelected,
              onSelected: (selected) {
                final newTypes = Set<PlaceType>.from(widget.selectedTypes);
                if (selected) {
                  newTypes.add(type);
                } else {
                  newTypes.remove(type);
                }
                widget.onTypesChanged(newTypes);
              },
            );
          }).toList(),
        ),
        if (_hasMoreTypes)
          TextButton(
            onPressed: () => _showAllPlaceTypes(context),
            child: const Text('查看全部场所类型 →'),
          ),
      ],
    );
  }

  Future<void> _showAllPlaceTypes(BuildContext context) async {
    final selected = await DialogHelper.show<Set<PlaceType>>(
      context: context,
      builder: (context) => PlaceTypeMultiSelectDialog(
        selectedTypes: widget.selectedTypes,
      ),
    );

    if (selected != null) {
      widget.onTypesChanged(selected);
    }
  }
}

/// 状态选择器
/// 
/// 职责：显示状态的 FilterChip 列表
/// 
/// 调用者：各筛选对话框
class StatusSelector extends StatefulWidget {
  final Set<EncounterStatus> selectedStatuses;
  final ValueChanged<Set<EncounterStatus>> onStatusesChanged;

  const StatusSelector({
    super.key,
    required this.selectedStatuses,
    required this.onStatusesChanged,
  });

  @override
  State<StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends State<StatusSelector> {
  static final List<EncounterStatus> _allStatuses = EncounterStatus.values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allStatuses.map((status) {
        final isSelected = widget.selectedStatuses.contains(status);
        return FilterChip(
          label: Text('${status.icon} ${status.label}'),
          selected: isSelected,
          onSelected: (selected) {
            final newStatuses = Set<EncounterStatus>.from(widget.selectedStatuses);
            if (selected) {
              newStatuses.add(status);
            } else {
              newStatuses.remove(status);
            }
            widget.onStatusesChanged(newStatuses);
          },
        );
      }).toList(),
    );
  }
}

/// 情绪强度选择器
/// 
/// 职责：显示情绪强度的 FilterChip 列表
/// 
/// 调用者：记录筛选对话框
class EmotionIntensitySelector extends StatefulWidget {
  final Set<EmotionIntensity> selectedIntensities;
  final ValueChanged<Set<EmotionIntensity>> onIntensitiesChanged;

  const EmotionIntensitySelector({
    super.key,
    required this.selectedIntensities,
    required this.onIntensitiesChanged,
  });

  @override
  State<EmotionIntensitySelector> createState() => _EmotionIntensitySelectorState();
}

class _EmotionIntensitySelectorState extends State<EmotionIntensitySelector> {
  static final List<EmotionIntensity> _allIntensities = EmotionIntensity.values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allIntensities.map((intensity) {
        final isSelected = widget.selectedIntensities.contains(intensity);
        return FilterChip(
          label: Text(intensity.label),
          selected: isSelected,
          onSelected: (selected) {
            final newIntensities = Set<EmotionIntensity>.from(widget.selectedIntensities);
            if (selected) {
              newIntensities.add(intensity);
            } else {
              newIntensities.remove(intensity);
            }
            widget.onIntensitiesChanged(newIntensities);
          },
        );
      }).toList(),
    );
  }
}

/// 天气选择器
/// 
/// 职责：显示天气的 FilterChip 列表
/// 
/// 调用者：记录筛选对话框
class WeatherSelector extends StatefulWidget {
  final Set<Weather> selectedWeathers;
  final ValueChanged<Set<Weather>> onWeathersChanged;

  const WeatherSelector({
    super.key,
    required this.selectedWeathers,
    required this.onWeathersChanged,
  });

  @override
  State<WeatherSelector> createState() => _WeatherSelectorState();
}

class _WeatherSelectorState extends State<WeatherSelector> {
  static final List<Weather> _displayedWeathers = Weather.values.take(10).toList();
  static final bool _hasMoreWeathers = Weather.values.length > 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _displayedWeathers.map((weather) {
            final isSelected = widget.selectedWeathers.contains(weather);
            return FilterChip(
              label: Text('${weather.icon} ${weather.label}'),
              selected: isSelected,
              onSelected: (selected) {
                final newWeathers = Set<Weather>.from(widget.selectedWeathers);
                if (selected) {
                  newWeathers.add(weather);
                } else {
                  newWeathers.remove(weather);
                }
                widget.onWeathersChanged(newWeathers);
              },
            );
          }).toList(),
        ),
        if (_hasMoreWeathers)
          TextButton(
            onPressed: () => _showAllWeathers(context),
            child: const Text('查看全部天气 →'),
          ),
      ],
    );
  }

  Future<void> _showAllWeathers(BuildContext context) async {
    final selected = await DialogHelper.show<Set<Weather>>(
      context: context,
      builder: (context) => WeatherMultiSelectDialog(
        selectedWeathers: widget.selectedWeathers,
      ),
    );

    if (selected != null) {
      widget.onWeathersChanged(selected);
    }
  }
}

