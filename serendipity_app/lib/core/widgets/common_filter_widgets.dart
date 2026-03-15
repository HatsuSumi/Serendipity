import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/region_data.dart';
import '../utils/dialog_helper.dart';
import '../utils/validation_helper.dart';
import '../utils/date_time_helper.dart';
import '../widgets/empty_state_widget.dart';
import '../theme/status_color_extension.dart';
import '../../features/community/widgets/region_picker_dialog.dart';

/// 筛选区块组件
/// 
/// 职责：统一的筛选区块样式
/// 
/// 调用者：各筛选对话框
class FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const FilterSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// 时间范围选择器
/// 
/// 职责：提供开始日期和结束日期选择
/// 
/// 调用者：各筛选对话框
class TimeRangeSelector extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;

  const TimeRangeSelector({
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      if (isStartDate) {
        onStartDateChanged(picked);
      } else {
        onEndDateChanged(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _selectDate(context, true),
            child: Text(startDate != null
                ? '${startDate!.month}-${startDate!.day}'
                : '开始日期'),
          ),
        ),
        const SizedBox(width: 8),
        const Text('至'),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _selectDate(context, false),
            child: Text(endDate != null
                ? '${endDate!.month}-${endDate!.day}'
                : '结束日期'),
          ),
        ),
      ],
    );
  }
}

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
      builder: (context) => _PlaceTypeMultiSelectDialog(
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

/// 地区选择器
/// 
/// 职责：显示地区选择按钮
/// 
/// 调用者：各筛选对话框
class RegionSelector extends StatelessWidget {
  final SelectedRegion? selectedRegion;
  final ValueChanged<SelectedRegion?> onRegionChanged;

  const RegionSelector({
    required this.selectedRegion,
    required this.onRegionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return OutlinedButton(
      onPressed: () => _showRegionPicker(context),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedRegion?.displayText ?? '请选择地区',
              style: TextStyle(
                color: selectedRegion == null
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Future<void> _showRegionPicker(BuildContext context) async {
    final result = await RegionPickerDialog.show(
      context,
      initialSelection: selectedRegion,
    );

    if (result != null) {
      onRegionChanged(result);
    }
  }
}

/// 标签输入框
/// 
/// 职责：提供标签输入和解析
/// 
/// 调用者：各筛选对话框
class TagInputField extends StatelessWidget {
  final TextEditingController controller;

  const TagInputField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: '输入标签名称，多个标签用逗号分隔',
        helperText: '支持中英文逗号（, 或 ，）',
        helperMaxLines: 1,
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: 2,
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
      builder: (context) => _WeatherMultiSelectDialog(
        selectedWeathers: widget.selectedWeathers,
      ),
    );
    
    if (selected != null) {
      widget.onWeathersChanged(selected);
    }
  }
}

/// 场所类型多选对话框
class _PlaceTypeMultiSelectDialog extends StatefulWidget {
  final Set<PlaceType> selectedTypes;

  const _PlaceTypeMultiSelectDialog({
    required this.selectedTypes,
  });

  @override
  State<_PlaceTypeMultiSelectDialog> createState() => _PlaceTypeMultiSelectDialogState();
}

class _PlaceTypeMultiSelectDialogState extends State<_PlaceTypeMultiSelectDialog> {
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

/// 天气多选对话框
class _WeatherMultiSelectDialog extends StatefulWidget {
  final Set<Weather> selectedWeathers;

  const _WeatherMultiSelectDialog({
    required this.selectedWeathers,
  });

  @override
  State<_WeatherMultiSelectDialog> createState() => _WeatherMultiSelectDialogState();
}

class _WeatherMultiSelectDialogState extends State<_WeatherMultiSelectDialog> {
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

/// 标签解析工具函数
/// 
/// 职责：解析用户输入的标签字符串
/// 
/// 调用者：各筛选对话框
List<String>? parseTags(String input) {
  if (input.isEmpty) return null;
  
  final tags = input
      .replaceAll('，', ',')  // 中文逗号 → 英文逗号
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();
  
  return tags.isEmpty ? null : tags;
}

/// 构建高亮文本 Widget
/// 
/// 职责：在文本中高亮指定的关键词
/// 
/// 参数：
/// - text: 原始文本
/// - keyword: 要高亮的关键词（为空时返回普通文本）
/// - highlightColor: 高亮背景色
/// - textStyle: 文本样式
/// - maxLines: 最大行数
/// - overflow: 溢出处理
/// 
/// 调用者：记录卡片（高亮筛选关键词）
Widget buildHighlightedText(
  String text, {
  String? keyword,
  required Color highlightColor,
  TextStyle? textStyle,
  int? maxLines,
  TextOverflow? overflow,
}) {
  print('DEBUG buildHighlightedText: text=$text, keyword=$keyword, textStyle=$textStyle');
  
  if (keyword == null || keyword.isEmpty || !text.contains(keyword)) {
    print('DEBUG buildHighlightedText: returning plain Text');
    return Text(
      text,
      style: textStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  final parts = text.split(RegExp('($keyword)', caseSensitive: false));
  final keywordLower = keyword.toLowerCase();
  
  print('DEBUG buildHighlightedText: parts=$parts, keywordLower=$keywordLower');
  
  final children = parts.where((part) => part.isNotEmpty).map((part) {
    final isKeyword = part.toLowerCase() == keywordLower;
    print('DEBUG buildHighlightedText: part=$part, isKeyword=$isKeyword');
    return TextSpan(
      text: part,
      style: isKeyword
          ? TextStyle(
              backgroundColor: highlightColor,
              fontWeight: FontWeight.bold,
            )
          : null,
    );
  }).toList();
  
  print('DEBUG buildHighlightedText: children count=${children.length}');
  
  return RichText(
    maxLines: maxLines,
    overflow: overflow ?? TextOverflow.clip,
    text: TextSpan(
      style: textStyle,
      children: children,
    ),
  );
}

