import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/enums.dart';
import '../utils/page_transition_builder.dart';

/// 创建带自定义动画的页面
CustomTransitionPage<T> buildTransitionPage<T>({
  required LocalKey key,
  required Widget child,
  required PageTransitionType transitionType,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return PageTransitionBuilder.buildTransition(
        transitionType,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    },
  );
}

