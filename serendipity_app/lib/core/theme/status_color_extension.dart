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
    
    // 从系统亮度推导实际亮度（system 主题跟随系统，其余主题自定义）
    // 不使用 Theme.of(context).brightness，因为 Navigator 内部页面
    // 的 context 在 Web 平台上可能拿到旧的 ThemeData
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final brightness = switch (themeOption) {
      ThemeOption.dark || ThemeOption.midnight => Brightness.dark,
      ThemeOption.system => systemBrightness,
      _ => Brightness.light,
    };
    
    final color = StatusColors.getColor(this, themeOption, brightness);
    
    // 返回对应的颜色
    return color;
  }
}

