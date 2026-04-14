import { CheckInService } from '../../../src/services/checkInService';
import { ICheckInRepository } from '../../../src/repositories/checkInRepository';
import { IUserTimezoneResolver } from '../../../src/services/userTimezoneResolver';
import { ErrorCode } from '../../../src/types/errors';

describe('CheckInService', () => {
  let checkInService: CheckInService;
  let mockCheckInRepository: jest.Mocked<ICheckInRepository>;
  let mockUserTimezoneResolver: jest.Mocked<IUserTimezoneResolver>;

  beforeEach(() => {
    mockCheckInRepository = {
      create: jest.fn(),
      findById: jest.fn(),
      findActiveById: jest.fn(),
      findByUserId: jest.fn(),
      findByUserAndDate: jest.fn(),
      deleteById: jest.fn(),
    };

    mockUserTimezoneResolver = {
      resolveTimezone: jest.fn(),
    };

    checkInService = new CheckInService(
      mockCheckInRepository,
      mockUserTimezoneResolver,
    );
  });

  describe('createTodayCheckIn', () => {
    it('应该按用户时区创建签到日期', async () => {
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-04-01T16:30:00.000Z'));
      mockUserTimezoneResolver.resolveTimezone.mockResolvedValue('Asia/Shanghai');
      mockCheckInRepository.findByUserAndDate.mockResolvedValue(null);
      mockCheckInRepository.create.mockImplementation(async (_userId, data) => ({
        id: data.id,
        userId: 'user-1',
        date: data.date,
        checkedAt: data.checkedAt,
        createdAt: data.checkedAt,
        updatedAt: data.checkedAt,
      }) as any);

      const result = await checkInService.createTodayCheckIn('user-1');

      expect(mockCheckInRepository.findByUserAndDate).toHaveBeenCalledWith(
        'user-1',
        new Date('2026-04-02T00:00:00.000Z'),
      );
      expect(result.date.toISOString()).toBe('2026-04-02T00:00:00.000Z');
      jest.useRealTimers();
    });

    it('当天已签到时应该返回冲突错误', async () => {
      mockUserTimezoneResolver.resolveTimezone.mockResolvedValue(undefined);
      mockCheckInRepository.findByUserAndDate.mockResolvedValue({ id: 'exists' } as any);

      await expect(checkInService.createTodayCheckIn('user-1')).rejects.toMatchObject({
        code: ErrorCode.CONFLICT,
      });
    });
  });

  describe('getCheckInStatus', () => {
    it('无签到记录时应该返回空状态结果', async () => {
      mockUserTimezoneResolver.resolveTimezone.mockResolvedValue(undefined);
      mockCheckInRepository.findByUserId.mockResolvedValue([]);

      const result = await checkInService.getCheckInStatus('user-free', 2026, 4);

      expect(mockCheckInRepository.findByUserId).toHaveBeenCalledWith('user-free');
      expect(result).toEqual({
        hasCheckedInToday: false,
        consecutiveDays: 0,
        totalDays: 0,
        currentMonthDays: 0,
        recentCheckIns: [],
        checkedInDatesInMonth: [],
      });
    });

    it('应该按用户时区判断今日签到与目标月份数据', async () => {
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-04-01T16:30:00.000Z'));
      mockUserTimezoneResolver.resolveTimezone.mockResolvedValue('Asia/Shanghai');
      mockCheckInRepository.findByUserId.mockResolvedValue([
        {
          id: 'today',
          userId: 'user-1',
          date: new Date('2026-04-02T00:00:00.000Z'),
          checkedAt: new Date('2026-04-01T16:30:00.000Z'),
          createdAt: new Date('2026-04-01T16:30:00.000Z'),
          updatedAt: new Date('2026-04-01T16:30:00.000Z'),
        },
        {
          id: 'yesterday',
          userId: 'user-1',
          date: new Date('2026-04-01T00:00:00.000Z'),
          checkedAt: new Date('2026-03-31T16:30:00.000Z'),
          createdAt: new Date('2026-03-31T16:30:00.000Z'),
          updatedAt: new Date('2026-03-31T16:30:00.000Z'),
        }, 
        {
          id: 'march-last',
          userId: 'user-1',
          date: new Date('2026-03-31T00:00:00.000Z'),
          checkedAt: new Date('2026-03-30T16:30:00.000Z'),
          createdAt: new Date('2026-03-30T16:30:00.000Z'),
          updatedAt: new Date('2026-03-30T16:30:00.000Z'),
        },
      ] as any);

      const result = await checkInService.getCheckInStatus('user-1', 2026, 4);

      expect(result.hasCheckedInToday).toBe(true);
      expect(result.consecutiveDays).toBe(3);
      expect(result.currentMonthDays).toBe(2);
      expect(result.checkedInDatesInMonth.map((item) => item.toISOString())).toEqual([
        '2026-04-02T00:00:00.000Z',
        '2026-04-01T00:00:00.000Z',
      ]);
      jest.useRealTimers();
    });
  });

  describe('getCheckIns', () => {
    it('未传 lastSyncTime 时应该按全量同步查询', async () => {
      mockCheckInRepository.findByUserId.mockResolvedValue([]);

      const result = await checkInService.getCheckIns('user-all');

      expect(mockCheckInRepository.findByUserId).toHaveBeenCalledWith('user-all', undefined);
      expect(result).toEqual([]);
    });

    it('下载签到记录时应该返回仓储同步数据', async () => {
      const checkIns = [
        {
          id: 'check-in-1',
          userId: 'user-premium',
          date: new Date('2026-04-02T00:00:00.000Z'),
          checkedAt: new Date('2026-04-01T16:30:00.000Z'),
          createdAt: new Date('2026-04-01T16:30:00.000Z'),
          updatedAt: new Date('2026-04-01T16:30:00.000Z'),
          deletedAt: null,
        },
      ] as any;

      mockCheckInRepository.findByUserId.mockResolvedValue(checkIns);

      const result = await checkInService.getCheckIns('user-premium', '2026-04-01T00:00:00.000Z');

      expect(mockCheckInRepository.findByUserId).toHaveBeenCalledWith(
        'user-premium',
        new Date('2026-04-01T00:00:00.000Z'),
      );
      expect(result).toEqual(checkIns);
    });
  });
});

