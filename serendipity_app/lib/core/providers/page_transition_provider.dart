import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';

/// 页面切换动画类型 Provider
final pageTransitionProvider = StateProvider<PageTransitionType>((ref) {
  // 默认：从右滑入（类似 iOS）
  return PageTransitionType.slideFromRight;
});

