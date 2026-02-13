import 'dart:math';
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
    // 处理特殊类型
    if (type == PageTransitionType.none) {
      // 无动画，直接返回
      return child;
    } else if (type == PageTransitionType.random) {
      // 随机选择一个动画（排除 none 和 random）
      type = _getRandomType();
    }
    
    switch (type) {
      case PageTransitionType.none:
      case PageTransitionType.random:
        return child; // 不应该到这里
        
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
  
  /// 获取随机动画类型（排除 none 和 random）
  static PageTransitionType _getRandomType() {
    final random = Random();
    final validTypes = PageTransitionType.values
        .where((type) => type != PageTransitionType.none && type != PageTransitionType.random)
        .toList();
    return validTypes[random.nextInt(validTypes.length)];
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

