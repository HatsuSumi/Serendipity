import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// 页面切换动画工具类
class PageTransitionBuilder {
  /// 根据动画类型构建过渡动画
  static Widget buildTransition(
    PageTransitionType type,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (type) {
      case PageTransitionType.slideFromRight:
        return _slideTransition(
          animation,
          child,
          const Offset(1.0, 0.0), // 从右向左
        );
      
      case PageTransitionType.slideFromBottom:
        return _slideTransition(
          animation,
          child,
          const Offset(0.0, 1.0), // 从底向上
        );
      
      case PageTransitionType.slideFromLeft:
        return _slideTransition(
          animation,
          child,
          const Offset(-1.0, 0.0), // 从左向右
        );
      
      case PageTransitionType.slideFromTop:
        return _slideTransition(
          animation,
          child,
          const Offset(0.0, -1.0), // 从顶向下
        );
      
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      
      case PageTransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
    }
  }
  
  /// 滑动过渡动画
  static Widget _slideTransition(
    Animation<double> animation,
    Widget child,
    Offset begin,
  ) {
    const end = Offset.zero;
    const curve = Curves.easeInOut;
    
    var tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );
    
    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}

