import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import 'user_settings_provider.dart';

/// 页面切换动画类型 Provider
/// 
/// 从 UserSettings 读取动画配置，支持多账号独立设置
final pageTransitionProvider = Provider<PageTransitionType>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.pageTransition;
});

