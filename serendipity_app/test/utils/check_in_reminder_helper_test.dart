import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/core/utils/check_in_reminder_helper.dart';

void main() {
  group('CheckInReminderHelper', () {
    group('generateContent', () {
      test('应该在连续签到6天时提示即将解锁7天成就', () {
        final content = CheckInReminderHelper.generateContent(
          consecutiveDays: 6,
          maxConsecutiveDays: 6,
        );
        expect(content, '再签到 1 天就能解锁"连续7天签到"成就啦！');
      });

      test('应该在连续签到29天时提示即将解锁30天成就', () {
        final content = CheckInReminderHelper.generateContent(
          consecutiveDays: 29,
          maxConsecutiveDays: 29,
        );
        expect(content, '再签到 1 天就能解锁"连续30天签到"成就啦！');
      });

      test('应该在连续签到90-99天时提示即将解锁签到大师成就', () {
        expect(
          CheckInReminderHelper.generateContent(
            consecutiveDays: 90,
            maxConsecutiveDays: 90,
          ),
          '再签到 10 天就能解锁"签到大师"成就啦！',
        );
        expect(
          CheckInReminderHelper.generateContent(
            consecutiveDays: 95,
            maxConsecutiveDays: 95,
          ),
          '再签到 5 天就能解锁"签到大师"成就啦！',
        );
        expect(
          CheckInReminderHelper.generateContent(
            consecutiveDays: 99,
            maxConsecutiveDays: 99,
          ),
          '再签到 1 天就能解锁"签到大师"成就啦！',
        );
      });

      test('应该在连续签到3天及以上时显示连续天数', () {
        expect(
          CheckInReminderHelper.generateContent(
            consecutiveDays: 3,
            maxConsecutiveDays: 3,
          ),
          '已连续签到 3 天，继续保持！',
        );
        expect(
          CheckInReminderHelper.generateContent(
            consecutiveDays: 10,
            maxConsecutiveDays: 10,
          ),
          '已连续签到 10 天，继续保持！',
        );
        expect(
          CheckInReminderHelper.generateContent(
            consecutiveDays: 50,
            maxConsecutiveDays: 50,
          ),
          '已连续签到 50 天，继续保持！',
        );
      });

      test('应该在连续签到1-2天时显示养成习惯提示', () {
        expect(
          CheckInReminderHelper.generateContent(
            consecutiveDays: 1,
            maxConsecutiveDays: 1,
          ),
          '养成每日签到的好习惯吧！',
        );
        expect(
          CheckInReminderHelper.generateContent(
            consecutiveDays: 2,
            maxConsecutiveDays: 2,
          ),
          '养成每日签到的好习惯吧！',
        );
      });

      test('应该在当前未连续签到且历史未形成习惯时显示中性提醒', () {
        final content = CheckInReminderHelper.generateContent(
          consecutiveDays: 0,
          maxConsecutiveDays: 0,
        );
        expect(content, '今天也别忘了签到哦～');
      });

      test('应该在当前未连续签到但历史形成过习惯时显示重新开始提示', () {
        final content = CheckInReminderHelper.generateContent(
          consecutiveDays: 0,
          maxConsecutiveDays: 2,
        );
        expect(content, '重新开始签到，加油！');
      });

      test('应该在负数连续天数时抛出 ArgumentError', () {
        expect(
          () => CheckInReminderHelper.generateContent(
            consecutiveDays: -1,
            maxConsecutiveDays: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('应该在最长连续天数小于连续天数时抛出 ArgumentError', () {
        expect(
          () => CheckInReminderHelper.generateContent(
            consecutiveDays: 2,
            maxConsecutiveDays: 1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('应该优先显示成就提示而非连续天数', () {
        final content = CheckInReminderHelper.generateContent(
          consecutiveDays: 6,
          maxConsecutiveDays: 6,
        );
        expect(content, contains('成就'));
        expect(content, isNot(contains('已连续签到')));
      });
    });

    test('title 应该是固定的', () {
      expect(CheckInReminderHelper.title, '别忘了今天的签到哦 🌟');
    });
  });
}

