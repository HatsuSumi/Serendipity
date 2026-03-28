import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// 应用主题管理类
/// 负责根据 ThemeOption 生成对应的 ThemeData
class AppTheme {
  /// 根据主题选项获取对应的 ThemeData
  static ThemeData getTheme(ThemeOption option, Brightness systemBrightness) {
    switch (option) {
      case ThemeOption.light:
        return _lightTheme;
      case ThemeOption.dark:
        return _darkTheme;
      case ThemeOption.system:
        return systemBrightness == Brightness.light ? _lightTheme : _darkTheme;
      case ThemeOption.misty:
        return _mistyTheme;
      case ThemeOption.midnight:
        return _midnightTheme;
      case ThemeOption.warm:
        return _warmTheme;
      case ThemeOption.autumn:
        return _autumnTheme;
    }
  }

  /// 根据主题选项推导应用内实际 Brightness
  ///
  /// system 主题无法在 Provider 层读取 MediaQuery，默认返回 light。
  /// 调用者若需要精确处理 system 主题，应自行读取 platformBrightness。
  static Brightness getBrightness(ThemeOption option) {
    return switch (option) {
      ThemeOption.dark || ThemeOption.midnight => Brightness.dark,
      _ => Brightness.light,
    };
  }

  /// 根据主题选项直接获取 ColorScheme（不依赖 MediaQuery）
  ///
  /// system 主题下返回浅色 ColorScheme。
  static ColorScheme getColorScheme(ThemeOption option) {
    return getTheme(option, getBrightness(option)).colorScheme;
  }

  /// 根据主题选项直接获取 TextTheme（不依赖 MediaQuery）
  static TextTheme getTextTheme(ThemeOption option) {
    return getTheme(option, getBrightness(option)).textTheme;
  }

  /// 浅色主题（粉色系，浪漫温柔）
  static final ThemeData _lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.pink,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ).surface,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );

  /// 深色主题（粉色系深色版）
  static final ThemeData _darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.pink,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
        ).surface,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );

  /// 朦胧主题（会员专属 - 灰蓝色调，朦胧梦幻）
  static final ThemeData _mistyTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7B9EB0), // 灰蓝色
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFF0F4F7), // 浅灰蓝背景
        primary: const Color(0xFF7B9EB0),
        surfaceContainerHighest: const Color(0xFFE8EEF2), // 半透明效果的基础
        onSurfaceVariant: const Color(0xFF556070), // 显式中性灰蓝，避免 fromSeed 偏色
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Color(0xFFF0F4F7),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: const Color(0xFFFAFBFC).withValues(alpha: 0.9), // 半透明卡片
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );

  /// 深夜主题（会员专属 - 深蓝黑色调，静谧深邃）
  static final ThemeData _midnightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A237E),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF0D1117),
        primary: const Color(0xFF5C6BC0),
        onSurfaceVariant: const Color(0xFF9EAABF), // 显式中性蓝灰，深色背景下足够对比度
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Color(0xFF0D1117),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );

  /// 温暖主题（会员专属 - 米黄色调，温馨舒适）
  static final ThemeData _warmTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD4A574), // 米黄色（柔和的暖色）
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFFFF9E6), // 浅米黄背景
        primary: const Color(0xFFD4A574),
        secondary: const Color(0xFFE8B86D),
        onSurfaceVariant: const Color(0xFF6B5E4E), // 显式中性暖棕，避免偏橙
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Color(0xFFFFF9E6),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );

  /// 秋日主题（会员专属 - 棕红色调，怀旧复古）
  static final ThemeData _autumnTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8D6E63),
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFFBE9E7),
        primary: const Color(0xFF8D6E63),
        secondary: const Color(0xFFD84315),
        onSurfaceVariant: const Color(0xFF5D4037), // 显式中性深棕，避免偏红
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Color(0xFFFBE9E7),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );
}

