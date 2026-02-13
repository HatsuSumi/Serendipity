import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// 状态颜色系统
/// 
/// 负责根据当前主题和记录状态，提供对应的情感色调。
/// 
/// 设计原则：
/// - 状态色调是情感氛围，不是整体主题
/// - 在不同主题下调整亮度/饱和度，保持情感基调
/// - 确保在浅色和深色主题下都有足够对比度
class StatusColors {
  /// 根据状态和主题获取对应的颜色
  /// 
  /// [status] 记录状态
  /// [themeOption] 当前主题选项
  /// [brightness] 系统亮度（用于 system 主题）
  static Color getColor(
    EncounterStatus status,
    ThemeOption themeOption,
    Brightness brightness,
  ) {
    // 确定当前是浅色还是深色模式
    final isDark = _isDarkMode(themeOption, brightness);

    // 根据状态返回对应的颜色
    switch (status) {
      case EncounterStatus.missed:
        return _getMissedColor(themeOption, isDark);
      case EncounterStatus.reencounter:
        return _getReencounterColor(themeOption, isDark);
      case EncounterStatus.met:
        return _getMetColor(themeOption, isDark);
      case EncounterStatus.reunion:
        return _getReunionColor(themeOption, isDark);
      case EncounterStatus.farewell:
        return _getFarewellColor(themeOption, isDark);
      case EncounterStatus.lost:
        return _getLostColor(themeOption, isDark);
    }
  }

  /// 判断当前是否为深色模式
  static bool _isDarkMode(ThemeOption themeOption, Brightness brightness) {
    switch (themeOption) {
      case ThemeOption.light:
      case ThemeOption.misty:
      case ThemeOption.warm:
      case ThemeOption.autumn:
        return false;
      case ThemeOption.dark:
      case ThemeOption.midnight:
        return true;
      case ThemeOption.system:
        return brightness == Brightness.dark;
    }
  }

  // ==================== 错过 🌫️ ====================
  // 情感基调：朦胧、柔和、灰蓝色调

  static Color _getMissedColor(ThemeOption themeOption, bool isDark) {
    switch (themeOption) {
      case ThemeOption.light:
      case ThemeOption.system:
        return isDark
            ? const Color(0xFF9DB8C7) // 深色模式：提高亮度
            : const Color(0xFF7B9EB0); // 浅色模式：原始灰蓝

      case ThemeOption.dark:
        return const Color(0xFF9DB8C7); // 深色模式：提高亮度

      case ThemeOption.misty:
        // 朦胧主题：强化灰蓝色调
        return const Color(0xFF6B8E9F);

      case ThemeOption.midnight:
        // 深夜主题：冷色调，更深邃
        return const Color(0xFFB0C4D0);

      case ThemeOption.warm:
        // 温暖主题：加入暖色，柔和灰蓝
        return const Color(0xFF8FAAB8);

      case ThemeOption.autumn:
        // 秋日主题：加入棕色，复古灰蓝
        return const Color(0xFF8B9FA8);
    }
  }

  // ==================== 再遇 🌟 ====================
  // 情感基调：明亮、惊喜、金色点缀

  static Color _getReencounterColor(ThemeOption themeOption, bool isDark) {
    switch (themeOption) {
      case ThemeOption.light:
      case ThemeOption.system:
        return isDark
            ? const Color(0xFFFFE066) // 深色模式：降低饱和度
            : const Color(0xFFFFD700); // 浅色模式：纯金色

      case ThemeOption.dark:
        return const Color(0xFFFFE066);

      case ThemeOption.misty:
        // 朦胧主题：柔和金色
        return const Color(0xFFE8C547);

      case ThemeOption.midnight:
        // 深夜主题：冷金色
        return const Color(0xFFFFF176);

      case ThemeOption.warm:
        // 温暖主题：暖金色
        return const Color(0xFFFFCA28);

      case ThemeOption.autumn:
        // 秋日主题：琥珀金
        return const Color(0xFFFFB300);
    }
  }

  // ==================== 邂逅 💫 ====================
  // 情感基调：温暖、激动、粉橙色调

  static Color _getMetColor(ThemeOption themeOption, bool isDark) {
    switch (themeOption) {
      case ThemeOption.light:
      case ThemeOption.system:
        return isDark
            ? const Color(0xFFFFAB91) // 深色模式：提高亮度
            : const Color(0xFFFF9E80); // 浅色模式：粉橙

      case ThemeOption.dark:
        return const Color(0xFFFFAB91);

      case ThemeOption.misty:
        // 朦胧主题：柔和粉橙
        return const Color(0xFFFF8A65);

      case ThemeOption.midnight:
        // 深夜主题：明亮粉橙
        return const Color(0xFFFFB74D);

      case ThemeOption.warm:
        // 温暖主题：暖橙色
        return const Color(0xFFFF9E80);

      case ThemeOption.autumn:
        // 秋日主题：深橙色
        return const Color(0xFFFF7043);
    }
  }

  // ==================== 重逢 💝 ====================
  // 情感基调：圆满、幸福、玫瑰金色调

  static Color _getReunionColor(ThemeOption themeOption, bool isDark) {
    switch (themeOption) {
      case ThemeOption.light:
      case ThemeOption.system:
        return isDark
            ? const Color(0xFFF06292) // 深色模式：提高亮度
            : const Color(0xFFE91E63); // 浅色模式：玫瑰金

      case ThemeOption.dark:
        return const Color(0xFFF06292);

      case ThemeOption.misty:
        // 朦胧主题：柔和玫瑰
        return const Color(0xFFEC407A);

      case ThemeOption.midnight:
        // 深夜主题：明亮玫瑰
        return const Color(0xFFF48FB1);

      case ThemeOption.warm:
        // 温暖主题：暖玫瑰
        return const Color(0xFFE91E63);

      case ThemeOption.autumn:
        // 秋日主题：深玫瑰
        return const Color(0xFFC2185B);
    }
  }

  // ==================== 别离 🥀 ====================
  // 情感基调：淡然、接受、玫瑰灰色调

  static Color _getFarewellColor(ThemeOption themeOption, bool isDark) {
    switch (themeOption) {
      case ThemeOption.light:
      case ThemeOption.system:
        return isDark
            ? const Color(0xFFD7CCC8) // 深色模式：提高亮度
            : const Color(0xFFBCAAA4); // 浅色模式：玫瑰灰

      case ThemeOption.dark:
        return const Color(0xFFD7CCC8);

      case ThemeOption.misty:
        // 朦胧主题：冷灰色
        return const Color(0xFFB0A199);

      case ThemeOption.midnight:
        // 深夜主题：明亮灰
        return const Color(0xFFE0D5D0);

      case ThemeOption.warm:
        // 温暖主题：暖灰色
        return const Color(0xFFC9B8B0);

      case ThemeOption.autumn:
        // 秋日主题：棕灰色
        return const Color(0xFFA1887F);
    }
  }

  // ==================== 失联 🍂 ====================
  // 情感基调：平静、释怀、秋叶色调

  static Color _getLostColor(ThemeOption themeOption, bool isDark) {
    switch (themeOption) {
      case ThemeOption.light:
      case ThemeOption.system:
        return isDark
            ? const Color(0xFFE0B589) // 深色模式：提高亮度
            : const Color(0xFFD4A574); // 浅色模式：秋叶色

      case ThemeOption.dark:
        return const Color(0xFFE0B589);

      case ThemeOption.misty:
        // 朦胧主题：冷秋色
        return const Color(0xFFC89F6F);

      case ThemeOption.midnight:
        // 深夜主题：明亮秋色
        return const Color(0xFFECC89E);

      case ThemeOption.warm:
        // 温暖主题：暖秋色
        return const Color(0xFFDDB87A);

      case ThemeOption.autumn:
        // 秋日主题：深秋色
        return const Color(0xFFBF8F5F);
    }
  }
}

