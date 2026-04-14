import { IRecordRepository } from '../../../src/repositories/recordRepository';
import { RecordService } from '../../../src/services/recordService';

describe('RecordService', () => {
  let recordService: RecordService;
  let mockRecordRepository: jest.Mocked<IRecordRepository>;

  const createMockRecord = () => {
    const now = new Date('2026-04-12T12:00:00.000Z');
    return {
      id: '550e8400-e29b-41d4-a716-446655440000',
      userId: 'user-premium',
      sourceDeviceId: 'device-test',
      timestamp: now,
      location: { province: 'Guangdong', city: 'Shenzhen' },
      description: 'record',
      tags: [],
      emotion: 'happy',
      status: 'pending',
      storyLineId: null,
      ifReencounter: null,
      conversationStarter: null,
      backgroundMusic: null,
      weather: [],
      isPinned: false,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    } as any;
  };

  beforeEach(() => {
    mockRecordRepository = {
      create: jest.fn(),
      batchCreate: jest.fn(),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByFilters: jest.fn(),
      findManyByIds: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    };

    recordService = new RecordService(
      mockRecordRepository,
    );
  });

  describe('getRecords', () => {
    it('用户下载记录时应该返回该账号范围内的同步数据', async () => {
      const now = new Date('2026-04-12T12:00:00.000Z');
      mockRecordRepository.findByUserId.mockResolvedValue({
        records: [
          {
            ...createMockRecord(),
            userId: 'user-free',
            sourceDeviceId: 'device-free-1',
            createdAt: now,
            updatedAt: now,
          },
        ],
        total: 1,
      });

      const result = await recordService.getRecords('user-free');

      expect(mockRecordRepository.findByUserId).toHaveBeenCalledWith(
        { userId: 'user-free' },
        undefined,
        100,
        0,
      );
      expect(result.records).toHaveLength(1);
      expect(result.records[0].ownerId).toBe('user-free');
      expect(result.records[0].sourceDeviceId).toBe('device-free-1');
    });

    it('用户增量下载记录时应该保留账号范围和 lastSyncTime', async () => {
      const lastSyncTime = '2026-04-10T00:00:00.000Z';
      mockRecordRepository.findByUserId.mockResolvedValue({
        records: [],
        total: 0,
      });

      const result = await recordService.getRecords('user-free', lastSyncTime, 50, 10);

      expect(mockRecordRepository.findByUserId).toHaveBeenCalledWith(
        { userId: 'user-free' },
        new Date(lastSyncTime),
        50,
        10,
      );
      expect(result).toMatchObject({
        records: [],
        total: 0,
        hasMore: false,
      });
    });

    it('会员用户下载记录时应该返回该用户的同步数据', async () => {
      mockRecordRepository.findByUserId.mockResolvedValue({
        records: [createMockRecord()],
        total: 1,
      });

      const result = await recordService.getRecords('user-premium');

      expect(mockRecordRepository.findByUserId).toHaveBeenCalledWith(
        { userId: 'user-premium' },
        undefined,
        100,
        0,
      );
      expect(result.records).toHaveLength(1);
      expect(result.records[0].ownerId).toBe('user-premium');
    });
  });

  describe('filterRecords', () => {
    it('用户筛选记录时应该返回筛选结果', async () => {
      mockRecordRepository.findByFilters.mockResolvedValue({
        records: [createMockRecord()],
        total: 1,
      });

      const result = await recordService.filterRecords('user-free', {
        city: 'Shenzhen',
        statuses: 'pending',
        limit: 20,
        offset: 0,
      });

      expect(mockRecordRepository.findByFilters).toHaveBeenCalledWith(
        'user-free',
        expect.objectContaining({
          city: 'Shenzhen',
          statuses: ['pending'],
          limit: 20,
          offset: 0,
        }),
      );
      expect(result.records).toHaveLength(1);
      expect(result.records[0].ownerId).toBe('user-premium');
    });
  });
});

