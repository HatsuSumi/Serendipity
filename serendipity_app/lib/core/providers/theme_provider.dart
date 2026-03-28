import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../core/theme/app_theme.dart';
import 'user_settings_provider.dart';

/// 当前主题选项 Provider
///
/// 从 UserSettings 读取主题配置，支持多账号独立设置
final themeOptionProvider = Provider<ThemeOption>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.theme;
});

/// 当前主题 ColorScheme Provider
///
/// 直接从 themeOption 推导，不依赖 MediaQuery 或 Theme.of(context)。
/// system 主题下返回浅色 ColorScheme（深色由 MaterialApp 的 darkTheme 处理）。
/// 页面 watch 此 Provider 可确保主题切换时立即获得正确颜色，无竞态条件。
final appColorSchemeProvider = Provider<ColorScheme>((ref) {
  final themeOption = ref.watch(themeOptionProvider);
  return AppTheme.getColorScheme(themeOption);
});

/// 当前主题 TextTheme Provider
///
/// 同 appColorSchemeProvider，直接从 themeOption 推导。
final appTextThemeProvider = Provider<TextTheme>((ref) {
  final themeOption = ref.watch(themeOptionProvider);
  return AppTheme.getTextTheme(themeOption);
});

