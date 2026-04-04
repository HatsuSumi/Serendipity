import {
  buildCheckInReminderContent,
  calculateReminderConsecutiveDays,
} from '../../../src/services/checkInReminderContentBuilder';

describe('checkInReminderContentBuilder', () => {
  describe('buildCheckInReminderContent', () => {
    it('连续 6 天时应该提示即将解锁 7 天成就', () => {
      expect(buildCheckInReminderContent(6)).toEqual({
        title: '别忘了今天的签到哦 🌟',
        body: '再签到 1 天就能解锁"连续7天签到"成就啦！',
      });
    });

    it('连续 5 天时应该提示继续保持', () => {
      expect(buildCheckInReminderContent(5)).toEqual({
        title: '别忘了今天的签到哦 🌟',
        body: '已连续签到 5 天，继续保持！',
      });
    });

    it('连续 0 天时应该提示重新开始', () => {
      expect(buildCheckInReminderContent(0)).toEqual({
        title: '别忘了今天的签到哦 🌟',
        body: '重新开始签到，加油！',
      });
    });
  });

  describe('calculateReminderConsecutiveDays', () => {
    it('今天未签到但昨天在连续 streak 内时应该返回截至昨天的连续天数', () => {
      const reminderDate = new Date('2026-04-02T00:00:00.000Z');
      const checkInDates = [
        new Date('2026-04-01T00:00:00.000Z'),
        new Date('2026-03-31T00:00:00.000Z'),
        new Date('2026-03-30T00:00:00.000Z'),
      ];

      expect(calculateReminderConsecutiveDays(checkInDates, reminderDate)).toBe(3);
    });

    it('今天和昨天都未签到时应该返回 0', () => {
      const reminderDate = new Date('2026-04-03T00:00:00.000Z');
      const checkInDates = [
        new Date('2026-04-01T00:00:00.000Z'),
        new Date('2026-03-31T00:00:00.000Z'),
      ];

      expect(calculateReminderConsecutiveDays(checkInDates, reminderDate)).toBe(0);
    });
  });
});

