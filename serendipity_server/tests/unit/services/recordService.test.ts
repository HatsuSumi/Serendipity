import { IRecordRepository } from '../../../src/repositories/recordRepository';
import { RecordService } from '../../../src/services/recordService';
import { ISyncAccessPolicyService } from '../../../src/services/syncAccessPolicyService';

describe('RecordService', () => {
  let recordService: RecordService;
  let mockRecordRepository: jest.Mocked<IRecordRepository>;
  let mockSyncAccessPolicyService: jest.Mocked<ISyncAccessPolicyService>;

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

    mockSyncAccessPolicyService = {
      canDownloadCoreContent: jest.fn(),
      buildCoreContentScope: jest.fn(),
    };

    recordService = new RecordService(
      mockRecordRepository,
      mockSyncAccessPolicyService,
    );
  });

  describe('getRecords', () => {
    it('免费版用户下载记录时应该只拉取当前设备范围内的同步数据', async () => {
      const now = new Date('2026-04-12T12:00:00.000Z');
      mockSyncAccessPolicyService.buildCoreContentScope.mockResolvedValue({
        userId: 'user-free',
        sourceDeviceId: 'device-free-1',
      });
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

      const result = await recordService.getRecords('user-free', undefined, 'device-free-1');

      expect(mockSyncAccessPolicyService.buildCoreContentScope).toHaveBeenCalledWith(
        'user-free',
        'device-free-1'
      );
      expect(mockRecordRepository.findByUserId).toHaveBeenCalledWith(
        { userId: 'user-free', sourceDeviceId: 'device-free-1' },
        undefined,
        100,
        0,
      );
      expect(result.records).toHaveLength(1);
      expect(result.records[0].ownerId).toBe('user-free');
      expect(result.records[0].sourceDeviceId).toBe('device-free-1');
    });

    it('免费版用户增量下载记录时应该保留设备范围和 lastSyncTime', async () => {
      const lastSyncTime = '2026-04-10T00:00:00.000Z';
      mockSyncAccessPolicyService.buildCoreContentScope.mockResolvedValue({
        userId: 'user-free',
        sourceDeviceId: 'device-free-2',
      });
      mockRecordRepository.findByUserId.mockResolvedValue({
        records: [],
        total: 0,
      });

      const result = await recordService.getRecords('user-free', lastSyncTime, 'device-free-2', 50, 10);

      expect(mockSyncAccessPolicyService.buildCoreContentScope).toHaveBeenCalledWith(
        'user-free',
        'device-free-2'
      );
      expect(mockRecordRepository.findByUserId).toHaveBeenCalledWith(
        { userId: 'user-free', sourceDeviceId: 'device-free-2' },
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
      mockSyncAccessPolicyService.buildCoreContentScope.mockResolvedValue({
        userId: 'user-premium',
      });
      mockRecordRepository.findByUserId.mockResolvedValue({
        records: [createMockRecord()],
        total: 1,
      });

      const result = await recordService.getRecords('user-premium', undefined, 'device-1');

      expect(mockSyncAccessPolicyService.buildCoreContentScope).toHaveBeenCalledWith(
        'user-premium',
        'device-1'
      );
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
    it('免费版用户筛选记录时应该返回空结果，不拉取业务主数据', async () => {
      mockSyncAccessPolicyService.canDownloadCoreContent.mockResolvedValue(false);

      const result = await recordService.filterRecords('user-free', {
        limit: 20,
        offset: 0,
      });

      expect(mockSyncAccessPolicyService.canDownloadCoreContent).toHaveBeenCalledWith('user-free');
      expect(mockRecordRepository.findByFilters).not.toHaveBeenCalled();
      expect(result).toMatchObject({
        records: [],
        total: 0,
        hasMore: false,
      });
    });

    it('会员用户筛选记录时应该返回筛选结果', async () => {
      mockSyncAccessPolicyService.canDownloadCoreContent.mockResolvedValue(true);
      mockRecordRepository.findByFilters.mockResolvedValue({
        records: [createMockRecord()],
        total: 1,
      });

      const result = await recordService.filterRecords('user-premium', {
        city: 'Shenzhen',
        statuses: 'pending',
        limit: 20,
        offset: 0,
      });

      expect(mockSyncAccessPolicyService.canDownloadCoreContent).toHaveBeenCalledWith('user-premium');
      expect(mockRecordRepository.findByFilters).toHaveBeenCalledWith(
        'user-premium',
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

