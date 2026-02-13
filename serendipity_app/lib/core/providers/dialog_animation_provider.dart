import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';

/// 对话框动画类型 Provider
final dialogAnimationProvider = StateProvider<DialogAnimationType>((ref) {
  // 默认：随机动画
  return DialogAnimationType.random;
});

