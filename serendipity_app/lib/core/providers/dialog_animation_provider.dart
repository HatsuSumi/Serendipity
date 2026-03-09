import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import 'user_settings_provider.dart';

/// 对话框动画类型 Provider
/// 
/// 从 UserSettings 读取动画配置，支持多账号独立设置
final dialogAnimationProvider = Provider<DialogAnimationType>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.dialogAnimation;
});

