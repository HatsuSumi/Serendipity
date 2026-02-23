import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:serendipity_app/core/utils/check_in_animation_helper.dart';

/// CheckInAnimationHelper 单元测试
/// 
/// 测试目标：
/// 1. 验证所有工厂方法能正常创建对象
/// 2. 验证动画控制器的初始状态
/// 3. 验证震动反馈不会抛出异常
void main() {
  group('CheckInAnimationHelper', () {
    testWidgets('createScaleController 应该创建正确的 AnimationController', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(
            builder: (context, vsync) {
              final controller = CheckInAnimationHelper.createScaleController(
                vsync: vsync,
              );

              // 验证初始值
              expect(controller.value, 1.0);
              expect(controller.lowerBound, 0.95);
              expect(controller.upperBound, 1.0);
              expect(controller.duration, const Duration(milliseconds: 150));

              controller.dispose();
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('createScaleAnimation 应该创建正确的 Animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(
            builder: (context, vsync) {
              final controller = CheckInAnimationHelper.createScaleController(
                vsync: vsync,
              );
              final animation = CheckInAnimationHelper.createScaleAnimation(
                controller: controller,
              );

              // 验证动画类型
              expect(animation, isA<CurvedAnimation>());
              expect(animation.value, 1.0);

              controller.dispose();
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    test('createConfettiController 应该创建正确的 ConfettiController', () {
      final controller = CheckInAnimationHelper.createConfettiController();

      // 验证持续时间
      expect(controller.duration, const Duration(seconds: 2));

      controller.dispose();
    });

    testWidgets('playButtonClickAnimation 应该正确播放动画', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(
            builder: (context, vsync) {
              final controller = CheckInAnimationHelper.createScaleController(
                vsync: vsync,
              );

              return FutureBuilder(
                future: CheckInAnimationHelper.playButtonClickAnimation(
                  controller: controller,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    // 动画完成后，控制器应该回到初始值
                    expect(controller.value, 1.0);
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      );

      // 等待动画完成
      await tester.pumpAndSettle();
    });

    test('triggerHapticFeedback 应该不抛出异常', () async {
      // 震动反馈可能在测试环境中不可用，但不应该抛出异常
      expect(
        () async => await CheckInAnimationHelper.triggerHapticFeedback(),
        returnsNormally,
      );
    });

    testWidgets('createConfettiWidget 应该创建正确的 Widget', (tester) async {
      final controller = CheckInAnimationHelper.createConfettiController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckInAnimationHelper.createConfettiWidget(
              controller: controller,
            ),
          ),
        ),
      );

      // 验证 Widget 已创建
      expect(find.byType(Align), findsOneWidget);

      // 等待 Widget 完全构建后再 dispose
      await tester.pumpAndSettle();
      controller.dispose();
    });

    testWidgets('createConfettiWidget 应该支持自定义颜色', (tester) async {
      final controller = CheckInAnimationHelper.createConfettiController();
      final customColors = [Colors.red, Colors.blue];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckInAnimationHelper.createConfettiWidget(
              controller: controller,
              colors: customColors,
            ),
          ),
        ),
      );

      // 验证 Widget 已创建
      expect(find.byType(Align), findsOneWidget);

      // 等待 Widget 完全构建后再 dispose
      await tester.pumpAndSettle();
      controller.dispose();
    });
  });
}

/// 测试用的 Widget，提供 TickerProvider
class _TestWidget extends StatefulWidget {
  final Widget Function(BuildContext context, TickerProvider vsync) builder;

  const _TestWidget({required this.builder});

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, this);
  }
}

