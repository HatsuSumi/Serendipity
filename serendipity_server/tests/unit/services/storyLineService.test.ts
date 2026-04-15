import { StoryLineService } from '../../../src/services/storyLineService';
import { IStoryLineRepository } from '../../../src/repositories/storyLineRepository';
import { ErrorCode } from '../../../src/types/errors';

describe('StoryLineService', () => {
  let storyLineService: StoryLineService;
  let mockStoryLineRepository: jest.Mocked<IStoryLineRepository>;

  beforeEach(() => {
    mockStoryLineRepository = {
      create: jest.fn(),
      batchCreate: jest.fn(),
      findByIdGlobal: jest.fn(),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    };
    storyLineService = new StoryLineService(
      mockStoryLineRepository,
    );
  });

  describe('createStoryLine', () => {
    it('同 ID 不存在时应该创建故事线', async () => {
      const now = new Date('2026-04-12T12:00:00.000Z');
      mockStoryLineRepository.findByIdGlobal.mockResolvedValue(null);
      mockStoryLineRepository.create.mockResolvedValue({
        id: '550e8400-e29b-41d4-a716-446655440000',
        userId: 'user-a',
        name: 'new storyline',
        recordIds: [],
        isPinned: false,
        deletedAt: null,
        createdAt: now,
        updatedAt: now,
      });

      const result = await storyLineService.createStoryLine('user-a', {
        id: '550e8400-e29b-41d4-a716-446655440000',
        name: 'new storyline',
        recordIds: [],
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      });

      expect(mockStoryLineRepository.create).toHaveBeenCalledWith('user-a', expect.any(Object));
      expect(result.userId).toBe('user-a');
    });

    it('同 ID 且归属当前用户时应该走更新，不重新创建', async () => {
      const now = new Date('2026-04-12T12:00:00.000Z');
      mockStoryLineRepository.findByIdGlobal.mockResolvedValue({
        id: '550e8400-e29b-41d4-a716-446655440000',
        userId: 'user-a',
        name: 'old',
        recordIds: [],
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      } as any);
      mockStoryLineRepository.update.mockResolvedValue({
        id: '550e8400-e29b-41d4-a716-446655440000',
        userId: 'user-a',
        name: 'new',
        recordIds: ['r1'],
        isPinned: true,
        deletedAt: null,
        createdAt: now,
        updatedAt: now,
      } as any);

      const result = await storyLineService.createStoryLine('user-a', {
        id: '550e8400-e29b-41d4-a716-446655440000',
        name: 'new',
        recordIds: ['r1'],
        isPinned: true,
        createdAt: now,
        updatedAt: now,
      });

      expect(mockStoryLineRepository.create).not.toHaveBeenCalled();
      expect(mockStoryLineRepository.update).toHaveBeenCalledWith(
        '550e8400-e29b-41d4-a716-446655440000',
        {
          name: 'new',
          recordIds: ['r1'],
          isPinned: true,
          updatedAt: now,
          deletedAt: undefined,
        }
      );
      expect(result.name).toBe('new');
    });

    it('同 ID 但归属其他用户时应该抛出 conflict，禁止跨用户覆盖', async () => {
      const now = new Date('2026-04-12T12:00:00.000Z');
      mockStoryLineRepository.findByIdGlobal.mockResolvedValue({
        id: '550e8400-e29b-41d4-a716-446655440000',
        userId: 'user-a',
        name: 'existing',
        recordIds: [],
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      } as any);

      await expect(
        storyLineService.createStoryLine('user-b', {
          id: '550e8400-e29b-41d4-a716-446655440000',
          name: 'malicious overwrite',
          recordIds: [],
          isPinned: false,
          createdAt: now,
          updatedAt: now,
        })
      ).rejects.toMatchObject({
        code: ErrorCode.CONFLICT,
      });

      expect(mockStoryLineRepository.create).not.toHaveBeenCalled();
      expect(mockStoryLineRepository.update).not.toHaveBeenCalled();
    });
  });

  describe('getStoryLines', () => {
    it('用户下载故事线时应该返回该账号范围内的数据', async () => {
      const now = new Date('2026-04-12T12:00:00.000Z');
      mockStoryLineRepository.findByUserId.mockResolvedValue({
        storylines: [
          {
            id: '550e8400-e29b-41d4-a716-446655440000',
            userId: 'user-free',
            name: 'free storyline on current device',
            recordIds: ['r1'],
            isPinned: false,
            createdAt: now,
            updatedAt: now,
            deletedAt: null,
          } as any,
        ],
        total: 1,
      });

      const result = await storyLineService.getStoryLines('user-free');

      expect(mockStoryLineRepository.findByUserId).toHaveBeenCalledWith(
        { userId: 'user-free' },
        undefined,
        100,
        0
      );
      expect(result.storyLines).toHaveLength(1);
      expect(result.storyLines[0].userId).toBe('user-free');
    });

    it('用户增量下载故事线时应该保留账号范围和 lastSyncTime', async () => {
      const lastSyncTime = '2026-04-10T00:00:00.000Z';
      mockStoryLineRepository.findByUserId.mockResolvedValue({
        storylines: [],
        total: 0,
      });

      const result = await storyLineService.getStoryLines('user-free', lastSyncTime, 50, 10);

      expect(mockStoryLineRepository.findByUserId).toHaveBeenCalledWith(
        { userId: 'user-free' },
        new Date(lastSyncTime),
        50,
        10
      );
      expect(result).toMatchObject({
        storyLines: [],
        total: 0,
        hasMore: false,
      });
    });

    it('会员用户下载故事线时应该返回该用户的同步数据', async () => {
      const now = new Date('2026-04-12T12:00:00.000Z');
      mockStoryLineRepository.findByUserId.mockResolvedValue({
        storylines: [
          {
            id: '550e8400-e29b-41d4-a716-446655440000',
            userId: 'user-premium',
            name: 'premium storyline',
            recordIds: ['r1'],
            isPinned: false,
            createdAt: now,
            updatedAt: now,
            deletedAt: null,
          } as any,
        ],
        total: 1,
      });

      const result = await storyLineService.getStoryLines('user-premium');

      expect(mockStoryLineRepository.findByUserId).toHaveBeenCalledWith(
        { userId: 'user-premium' },
        undefined,
        100,
        0
      );
      expect(result.storyLines).toHaveLength(1);
      expect(result.storyLines[0].userId).toBe('user-premium');
    });
  });

});

