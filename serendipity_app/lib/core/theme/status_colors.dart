import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// 颜色对：浅色模式颜色 / 深色模式颜色
typedef _ColorPair = ({Color light, Color dark});

/// 状态颜色系统
/// 
/// 负责根据当前主题和记录状态，提供对应的情感色调。
/// 
/// 设计原则：
/// - 数据驱动设计（Data-Driven Design）
/// - 状态色调是情感氛围，不是整体主题
/// - 在不同主题下调整亮度/饱和度，保持情感基调
/// - 确保在浅色和深色主题下都有足够对比度
class StatusColors {
  // 私有构造函数，防止实例化
  StatusColors._();

  /// 状态颜色映射表
  /// 
  /// 结构：状态 -> 主题 -> (浅色颜色, 深色颜色)
  /// 
  /// 情感基调说明：
  /// - 错过 🌫️：朦胧、柔和、灰蓝色调
  /// - 再遇 🌟：明亮、惊喜、金色点缀
  /// - 邂逅 💫：温暖、激动、粉橙色调
  /// - 重逢 💝：圆满、幸福、玫瑰金色调
  /// - 别离 🥀：淡然、接受、玫瑰灰色调
  /// - 失联 🍂：平静、释怀、秋叶色调
  static const Map<EncounterStatus, Map<ThemeOption, _ColorPair>> _colorMap = {
    // ==================== 错过 🌫️ ====================
    EncounterStatus.missed: {
      ThemeOption.light: (
        light: Color(0xFF7B9EB0),
        dark: Color(0xFF9DB8C7),
      ),
      ThemeOption.dark: (
        light: Color(0xFF9DB8C7),
        dark: Color(0xFF9DB8C7),
      ),
      ThemeOption.misty: (
        light: Color(0xFF6B8E9F),
        dark: Color(0xFF6B8E9F),
      ),
      ThemeOption.midnight: (
        light: Color(0xFFB0C4D0),
        dark: Color(0xFFB0C4D0),
      ),
      ThemeOption.warm: (
        light: Color(0xFF8FAAB8),
        dark: Color(0xFF8FAAB8),
      ),
      ThemeOption.autumn: (
        light: Color(0xFF8B9FA8),
        dark: Color(0xFF8B9FA8),
      ),
      ThemeOption.system: (
        light: Color(0xFF7B9EB0),
        dark: Color(0xFF9DB8C7),
      ),
    },

    // ==================== 再遇 🌟 ====================
    EncounterStatus.reencounter: {
      ThemeOption.light: (
        light: Color(0xFFFFD700),
        dark: Color(0xFFFFE066),
      ),
      ThemeOption.dark: (
        light: Color(0xFFFFE066),
        dark: Color(0xFFFFE066),
      ),
      ThemeOption.misty: (
        light: Color(0xFFE8C547),
        dark: Color(0xFFE8C547),
      ),
      ThemeOption.midnight: (
        light: Color(0xFFFFF176),
        dark: Color(0xFFFFF176),
      ),
      ThemeOption.warm: (
        light: Color(0xFFFFCA28),
        dark: Color(0xFFFFCA28),
      ),
      ThemeOption.autumn: (
        light: Color(0xFFFFB300),
        dark: Color(0xFFFFB300),
      ),
      ThemeOption.system: (
        light: Color(0xFFFFD700),
        dark: Color(0xFFFFE066),
      ),
    },

    // ==================== 邂逅 💫 ====================
    EncounterStatus.met: {
      ThemeOption.light: (
        light: Color(0xFFFF9E80),
        dark: Color(0xFFFFAB91),
      ),
      ThemeOption.dark: (
        light: Color(0xFFFFAB91),
        dark: Color(0xFFFFAB91),
      ),
      ThemeOption.misty: (
        light: Color(0xFFFF8A65),
        dark: Color(0xFFFF8A65),
      ),
      ThemeOption.midnight: (
        light: Color(0xFFFFB74D),
        dark: Color(0xFFFFB74D),
      ),
      ThemeOption.warm: (
        light: Color(0xFFFF9E80),
        dark: Color(0xFFFF9E80),
      ),
      ThemeOption.autumn: (
        light: Color(0xFFFF7043),
        dark: Color(0xFFFF7043),
      ),
      ThemeOption.system: (
        light: Color(0xFFFF9E80),
        dark: Color(0xFFFFAB91),
      ),
    },

    // ==================== 重逢 💝 ====================
    EncounterStatus.reunion: {
      ThemeOption.light: (
        light: Color(0xFFE91E63),
        dark: Color(0xFFF06292),
      ),
      ThemeOption.dark: (
        light: Color(0xFFF06292),
        dark: Color(0xFFF06292),
      ),
      ThemeOption.misty: (
        light: Color(0xFFEC407A),
        dark: Color(0xFFEC407A),
      ),
      ThemeOption.midnight: (
        light: Color(0xFFF48FB1),
        dark: Color(0xFFF48FB1),
      ),
      ThemeOption.warm: (
        light: Color(0xFFE91E63),
        dark: Color(0xFFE91E63),
      ),
      ThemeOption.autumn: (
        light: Color(0xFFC2185B),
        dark: Color(0xFFC2185B),
      ),
      ThemeOption.system: (
        light: Color(0xFFE91E63),
        dark: Color(0xFFF06292),
      ),
    },

    // ==================== 别离 🥀 ====================
    EncounterStatus.farewell: {
      ThemeOption.light: (
        light: Color(0xFFBCAAA4),
        dark: Color(0xFFD7CCC8),
      ),
      ThemeOption.dark: (
        light: Color(0xFFD7CCC8),
        dark: Color(0xFFD7CCC8),
      ),
      ThemeOption.misty: (
        light: Color(0xFFB0A199),
        dark: Color(0xFFB0A199),
      ),
      ThemeOption.midnight: (
        light: Color(0xFFE0D5D0),
        dark: Color(0xFFE0D5D0),
      ),
      ThemeOption.warm: (
        light: Color(0xFFC9B8B0),
        dark: Color(0xFFC9B8B0),
      ),
      ThemeOption.autumn: (
        light: Color(0xFFA1887F),
        dark: Color(0xFFA1887F),
      ),
      ThemeOption.system: (
        light: Color(0xFFBCAAA4),
        dark: Color(0xFFD7CCC8),
      ),
    },

    // ==================== 失联 🍂 ====================
    EncounterStatus.lost: {
      ThemeOption.light: (
        light: Color(0xFFD4A574),
        dark: Color(0xFFE0B589),
      ),
      ThemeOption.dark: (
        light: Color(0xFFE0B589),
        dark: Color(0xFFE0B589),
      ),
      ThemeOption.misty: (
        light: Color(0xFFC89F6F),
        dark: Color(0xFFC89F6F),
      ),
      ThemeOption.midnight: (
        light: Color(0xFFECC89E),
        dark: Color(0xFFECC89E),
      ),
      ThemeOption.warm: (
        light: Color(0xFFDDB87A),
        dark: Color(0xFFDDB87A),
      ),
      ThemeOption.autumn: (
        light: Color(0xFFBF8F5F),
        dark: Color(0xFFBF8F5F),
      ),
      ThemeOption.system: (
        light: Color(0xFFD4A574),
        dark: Color(0xFFE0B589),
      ),
    },
  };

  /// 根据状态和主题获取对应的颜色
  /// 
  /// [status] 记录状态
  /// [themeOption] 当前主题选项
  /// [brightness] 系统亮度（用于 system 主题）
  /// 
  /// 注意：此方法依赖编译时常量Map，查找时间复杂度为O(1)
  static Color getColor(
    EncounterStatus status,
    ThemeOption themeOption,
    Brightness brightness,
  ) {
    // 获取颜色对
    final colorPair = _colorMap[status]?[themeOption];
    
    // Fail Fast：如果找不到颜色配置，立即报错
    assert(
      colorPair != null,
      'Color configuration not found for status=$status, theme=$themeOption. '
      'This is a programming error - all combinations must be defined in _colorMap.',
    );
    
    if (colorPair == null) {
      // 生产环境降级：返回灰色
      return const Color(0xFF9E9E9E);
    }

    // 判断是否使用深色模式颜色
    final isDark = _isDarkMode(themeOption, brightness);
    return isDark ? colorPair.dark : colorPair.light;
  }

  /// 判断当前是否为深色模式
  /// 
  /// 使用Dart 3.0的switch表达式，更简洁
  static bool _isDarkMode(ThemeOption themeOption, Brightness brightness) {
    return switch (themeOption) {
      ThemeOption.dark || ThemeOption.midnight => true,
      ThemeOption.system => brightness == Brightness.dark,
      _ => false,
    };
  }
}
