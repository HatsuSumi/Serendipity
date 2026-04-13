import { IStatisticsRepository } from '../../../src/repositories/statisticsRepository';
import {
  StatisticsOverviewDto,
  StatisticsService,
} from '../../../src/services/statisticsService';
import { ISyncAccessPolicyService } from '../../../src/services/syncAccessPolicyService';

describe('StatisticsService', () => {
  let statisticsService: StatisticsService;
  let mockStatisticsRepository: jest.Mocked<IStatisticsRepository>;
  let mockSyncAccessPolicyService: jest.Mocked<ISyncAccessPolicyService>;

  beforeEach(() => {
    mockStatisticsRepository = {
      getOverviewRaw: jest.fn(),
    };

    mockSyncAccessPolicyService = {
      canDownloadBusinessData: jest.fn(),
    };

    statisticsService = new StatisticsService(
      mockStatisticsRepository,
      mockSyncAccessPolicyService,
    );
  });

  describe('getOverview', () => {
    it('免费版用户获取统计总览时应该返回空结果，不拉取账号级业务统计', async () => {
      mockSyncAccessPolicyService.canDownloadBusinessData.mockResolvedValue(false);

      const result = await statisticsService.getOverview('user-free');

      expect(mockSyncAccessPolicyService.canDownloadBusinessData).toHaveBeenCalledWith('user-free');
      expect(mockStatisticsRepository.getOverviewRaw).not.toHaveBeenCalled();
      expect(result).toMatchObject({
        registeredAt: new Date(0).toISOString(),
        totalRecords: 0,
        pinnedRecordCount: 0,
        linkedRecordCount: 0,
        unlinkedRecordCount: 0,
        linkedRecordPercentage: 0,
        unlinkedRecordPercentage: 0,
        statusCounts: {
          missed: 0,
          avoid: 0,
          reencounter: 0,
          met: 0,
          reunion: 0,
          farewell: 0,
          lost: 0,
        },
        successRate: 0,
        storyLineCount: 0,
        pinnedStoryLineCount: 0,
        totalCheckInDays: 0,
        totalCheckInStartDate: null,
        totalCheckInEndDate: null,
        longestCheckInStreakDays: 0,
        longestCheckInStreakStartDate: null,
        longestCheckInStreakEndDate: null,
        favoritedRecordCount: 0,
        favoritedPostCount: 0,
        sourceVersion: 1,
      } satisfies Partial<StatisticsOverviewDto>);
      expect(typeof result.computedAt).toBe('string');
    });

    it('会员用户获取统计总览时应该返回账号全局聚合结果', async () => {
      const registeredAt = new Date('2026-04-10T08:00:00.000Z');
      const checkInStartDate = new Date('2026-04-01T00:00:00.000Z');
      const checkInEndDate = new Date('2026-04-12T00:00:00.000Z');
      const longestStreakStart = new Date('2026-04-05T00:00:00.000Z');
      const longestStreakEnd = new Date('2026-04-09T00:00:00.000Z');

      mockSyncAccessPolicyService.canDownloadBusinessData.mockResolvedValue(true);
      mockStatisticsRepository.getOverviewRaw.mockResolvedValue({
        registeredAt,
        totalRecords: 10,
        pinnedRecordCount: 2,
        linkedRecordCount: 4,
        statusCounts: {
          missed: 2,
          met: 3,
          reunion: 1,
        },
        storyLineCount: 3,
        pinnedStoryLineCount: 1,
        totalCheckInDays: 8,
        checkInStartDate,
        checkInEndDate,
        longestStreakDays: 5,
        longestStreakStart,
        longestStreakEnd,
        favoritedRecordCount: 6,
        favoritedPostCount: 7,
      });

      const result = await statisticsService.getOverview('user-premium');

      expect(mockSyncAccessPolicyService.canDownloadBusinessData).toHaveBeenCalledWith('user-premium');
      expect(mockStatisticsRepository.getOverviewRaw).toHaveBeenCalledWith('user-premium');
      expect(result).toMatchObject({
        registeredAt: registeredAt.toISOString(),
        totalRecords: 10,
        pinnedRecordCount: 2,
        linkedRecordCount: 4,
        unlinkedRecordCount: 6,
        linkedRecordPercentage: 40,
        unlinkedRecordPercentage: 60,
        statusCounts: {
          missed: 2,
          avoid: 0,
          reencounter: 0,
          met: 3,
          reunion: 1,
          farewell: 0,
          lost: 0,
        },
        successRate: 40,
        storyLineCount: 3,
        pinnedStoryLineCount: 1,
        totalCheckInDays: 8,
        totalCheckInStartDate: checkInStartDate.toISOString(),
        totalCheckInEndDate: checkInEndDate.toISOString(),
        longestCheckInStreakDays: 5,
        longestCheckInStreakStartDate: longestStreakStart.toISOString(),
        longestCheckInStreakEndDate: longestStreakEnd.toISOString(),
        favoritedRecordCount: 6,
        favoritedPostCount: 7,
        sourceVersion: 1,
      } satisfies Partial<StatisticsOverviewDto>);
      expect(typeof result.computedAt).toBe('string');
    });
  });
});

