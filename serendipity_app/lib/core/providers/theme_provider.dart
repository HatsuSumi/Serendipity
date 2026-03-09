import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import 'user_settings_provider.dart';

/// 当前主题选项 Provider
/// 
/// 从 UserSettings 读取主题配置，支持多账号独立设置
final themeOptionProvider = Provider<ThemeOption>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.theme;
});

