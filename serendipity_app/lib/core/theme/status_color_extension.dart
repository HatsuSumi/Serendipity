import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../providers/theme_provider.dart';
import 'status_colors.dart';

/// EncounterStatus 的颜色扩展
/// 
/// 提供便捷的方法来获取状态对应的主题自适应颜色
extension StatusColorExtension on EncounterStatus {
  /// 获取当前状态在指定主题下的颜色
  /// 
  /// 使用示例：
  /// ```dart
  /// final color = record.status.getColor(context, ref);
  /// ```
  Color getColor(BuildContext context, WidgetRef ref) {
    // 获取当前主题选项
    final themeOption = ref.watch(themeOptionProvider);
    
    // 获取系统亮度
    final brightness = MediaQuery.of(context).platformBrightness;
    
    // 返回对应的颜色
    return StatusColors.getColor(this, themeOption, brightness);
  }
}

