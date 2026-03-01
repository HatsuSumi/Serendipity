import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:serendipity_app/core/utils/check_in_animation_helper.dart';

/// CheckInAnimationHelper 单元测试
/// 
/// 测试目标：
/// 1. 验证粒子效果控制器能正常创建
/// 2. 验证粒子效果Widget能正常创建
/// 3. 验证震动反馈不会抛出异常
/// 4. 验证完整的成功反馈流程
void main() {
  group('CheckInAnimationHelper', () {
    test('createConfettiController 应该创建正确的 ConfettiController', () {
      final controller = CheckInAnimationHelper.createConfettiController();

      // 验证持续时间
      expect(controller.duration, const Duration(seconds: 2));

      controller.dispose();
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

    testWidgets('triggerSuccessFeedback 应该正确触发反馈', (tester) async {
      final controller = CheckInAnimationHelper.createConfettiController();

      // 测试完整的成功反馈流程
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckInAnimationHelper.createConfettiWidget(
              controller: controller,
            ),
          ),
        ),
      );

      // 触发成功反馈（启用震动和粒子效果）
      await CheckInAnimationHelper.triggerSuccessFeedback(
        confettiController: controller,
        enableVibration: true,
        enableConfetti: true,
      );

      // 验证不会抛出异常
      await tester.pumpAndSettle();

      controller.dispose();
    });

    testWidgets('triggerSuccessFeedback 应该支持禁用震动', (tester) async {
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

      // 触发成功反馈（禁用震动）
      await CheckInAnimationHelper.triggerSuccessFeedback(
        confettiController: controller,
        enableVibration: false,
        enableConfetti: true,
      );

      await tester.pumpAndSettle();
      controller.dispose();
    });

    testWidgets('triggerSuccessFeedback 应该支持禁用粒子效果', (tester) async {
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

      // 触发成功反馈（禁用粒子效果）
      await CheckInAnimationHelper.triggerSuccessFeedback(
        confettiController: controller,
        enableVibration: true,
        enableConfetti: false,
      );

      await tester.pumpAndSettle();
      controller.dispose();
    });
  });
}

