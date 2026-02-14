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

  /// 浅色主题（粉色系，浪漫温柔）
  static ThemeData get _lightTheme {
    return ThemeData(
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
  }

  /// 深色主题（粉色系深色版）
  static ThemeData get _darkTheme {
    return ThemeData(
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
    );
  }

  /// 朦胧主题（会员专属 - 灰蓝色调，朦胧梦幻）
  static ThemeData get _mistyTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7B9EB0), // 灰蓝色
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFF0F4F7), // 浅灰蓝背景
        primary: const Color(0xFF7B9EB0),
        surfaceContainerHighest: const Color(0xFFE8EEF2), // 半透明效果的基础
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
        color: const Color(0xFFFAFBFC).withOpacity(0.9), // 半透明卡片
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// 深夜主题（会员专属 - 深蓝黑色调，静谧深邃）
  static ThemeData get _midnightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A237E),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF0D1117),
        primary: const Color(0xFF5C6BC0),
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
    );
  }

  /// 温暖主题（会员专属 - 米黄色调，温馨舒适）
  static ThemeData get _warmTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD4A574), // 米黄色（柔和的暖色）
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFFFF9E6), // 浅米黄背景
        primary: const Color(0xFFD4A574),
        secondary: const Color(0xFFE8B86D),
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
    );
  }

  /// 秋日主题（会员专属 - 棕红色调，怀旧复古）
  static ThemeData get _autumnTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8D6E63),
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFFBE9E7),
        primary: const Color(0xFF8D6E63),
        secondary: const Color(0xFFD84315),
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
    );
  }

  /// 快捷访问：默认浅色主题
  static ThemeData get lightTheme => _lightTheme;

  /// 快捷访问：默认深色主题
  static ThemeData get darkTheme => _darkTheme;
}

