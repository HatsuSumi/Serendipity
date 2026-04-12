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

    storyLineService = new StoryLineService(mockStoryLineRepository);
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
        createdAt: now,
        updatedAt: now,
      } as any);

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

  describe('batchCreateStoryLines', () => {
    it('批量中存在其他用户的同 ID 故事线时应该抛出 conflict', async () => {
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
        storyLineService.batchCreateStoryLines('user-b', {
          storyLines: [
            {
              id: '550e8400-e29b-41d4-a716-446655440000',
              name: 'overwrite',
              recordIds: [],
              isPinned: false,
              createdAt: now,
              updatedAt: now,
            },
          ],
        })
      ).rejects.toMatchObject({
        code: ErrorCode.CONFLICT,
      });

      expect(mockStoryLineRepository.batchCreate).not.toHaveBeenCalled();
      expect(mockStoryLineRepository.update).not.toHaveBeenCalled();
    });
  });
});

