import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';

/// 当前主题选项 Provider
/// 默认跟随系统，后续可从用户设置中读取
final themeOptionProvider = StateProvider<ThemeOption>((ref) {
  return ThemeOption.system;
});

