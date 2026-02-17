import 'package:flutter/material.dart';
import '../../../models/enums.dart';

/// 天气选择组件
/// 
/// 用于选择天气，支持多选和分类展示，带动画效果
class WeatherSelectionSection extends StatefulWidget {
  final List<Weather> selectedWeather;
  final ValueChanged<List<Weather>> onWeatherChanged;
  
  const WeatherSelectionSection({
    super.key,
    required this.selectedWeather,
    required this.onWeatherChanged,
  });

  @override
  State<WeatherSelectionSection> createState() => _WeatherSelectionSectionState();
}

class _WeatherSelectionSectionState extends State<WeatherSelectionSection> {
  // 正在删除的天气（使用天气值而不是索引）
  final Set<int> _removingWeatherValues = {};
  
  // 正在添加的天气（用于添加动画）
  final Set<int> _addingWeatherValues = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '☀️ 天气',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选，支持多选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 已选择的天气（带添加/删除动画）
        if (widget.selectedWeather.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedWeather.map((weather) {
                final isRemoving = _removingWeatherValues.contains(weather.value);
                final isAdding = _addingWeatherValues.contains(weather.value);
                
                // 添加时从0到1，删除时从1到0，正常时保持1
                final scale = (isAdding || isRemoving) ? 0.0 : 1.0;
                final opacity = (isAdding || isRemoving) ? 0.0 : 1.0;
                
                return AnimatedScale(
                  key: ValueKey('scale_${weather.value}'),
                  scale: scale,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: opacity,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Chip(
                      avatar: Text(weather.icon),
                      label: Text(weather.label),
                      onDeleted: () => _removeWeatherWithAnimation(weather),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        
        // 按分类显示天气选项
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: WeatherCategory.values.map((category) {
              final weathersInCategory = Weather.values
                  .where((w) => w.category == category)
                  .toList();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 分类标题
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Row(
                      children: [
                        Text(
                          category.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 该分类下的天气选项
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: weathersInCategory.map((weather) {
                      final isSelected = widget.selectedWeather.contains(weather);
                      
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(weather.icon),
                            const SizedBox(width: 4),
                            Text(weather.label),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) async {
                          if (selected) {
                            await _addWeatherWithAnimation(weather, category);
                          } else {
                            await _removeWeatherWithAnimation(weather);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  
                  if (category != WeatherCategory.values.last)
                    const Divider(height: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 添加天气（带动画）
  Future<void> _addWeatherWithAnimation(Weather weather, WeatherCategory category) async {
    // 标记为正在添加
    setState(() {
      _addingWeatherValues.add(weather.value);
    });
    
    final updatedWeather = List<Weather>.from(widget.selectedWeather);
    
    // 天空状况只能选一个（互斥）
    if (category == WeatherCategory.sky) {
      updatedWeather.removeWhere((w) => w.category == WeatherCategory.sky);
    }
    // 风力只能选一个（互斥）
    if (category == WeatherCategory.wind) {
      updatedWeather.removeWhere((w) => w.category == WeatherCategory.wind);
    }
    
    updatedWeather.add(weather);
    widget.onWeatherChanged(updatedWeather);
    
    // 等待一帧后触发动画
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) {
      setState(() {
        _addingWeatherValues.remove(weather.value);
      });
    }
  }

  /// 删除天气（带动画）
  Future<void> _removeWeatherWithAnimation(Weather weather) async {
    // 标记为删除中，触发动画
    setState(() {
      _removingWeatherValues.add(weather.value);
    });
    
    // 等待动画完成
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 从列表中移除
    if (!mounted) return;
    
    final updatedWeather = List<Weather>.from(widget.selectedWeather)..remove(weather);
    widget.onWeatherChanged(updatedWeather);
    
    setState(() {
      _removingWeatherValues.remove(weather.value);
    });
  }
}

