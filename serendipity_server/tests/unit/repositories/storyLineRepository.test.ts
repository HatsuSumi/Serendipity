import { StoryLineRepository } from '../../../src/repositories/storyLineRepository';
import { prismaMock } from '../../mocks/prisma.mock';

describe('StoryLineRepository', () => {
  let storyLineRepository: StoryLineRepository;

  beforeEach(() => {
    storyLineRepository = new StoryLineRepository(prismaMock as any);
  });

  describe('create', () => {
    it('应该创建新故事线并持久化 isPinned', async () => {
      const createdAt = new Date();
      const updatedAt = new Date();
      const mockStoryLine = {
        id: 'storyline-id',
        userId: 'user-id',
        name: 'Test StoryLine',
        recordIds: [],
        isPinned: true,
        createdAt,
        updatedAt,
      };

      prismaMock.storyLine.upsert.mockResolvedValue(mockStoryLine as any);

      const result = await storyLineRepository.create('user-id', {
        id: 'storyline-id',
        name: 'Test StoryLine',
        recordIds: [],
        isPinned: true,
        createdAt,
        updatedAt,
      });

      expect(result).toEqual(mockStoryLine);
      expect(prismaMock.storyLine.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          update: expect.objectContaining({
            isPinned: true,
          }),
          create: expect.objectContaining({
            isPinned: true,
          }),
        })
      );
    });
  });

  describe('update', () => {
    it('应该更新故事线的 isPinned', async () => {
      const updatedAt = new Date();
      const mockStoryLine = {
        id: 'storyline-id',
        userId: 'user-id',
        name: 'Test StoryLine',
        recordIds: [],
        isPinned: true,
        createdAt: new Date(),
        updatedAt,
      };

      prismaMock.storyLine.update.mockResolvedValue(mockStoryLine as any);

      const result = await storyLineRepository.update('storyline-id', {
        isPinned: true,
        updatedAt,
      });

      expect(result).toEqual(mockStoryLine);
      expect(prismaMock.storyLine.update).toHaveBeenCalledWith({
        where: { id: 'storyline-id' },
        data: expect.objectContaining({
          isPinned: true,
          updatedAt,
        }),
      });
    });
  });

  describe('findById', () => {
    it('应该根据 ID 查找故事线', async () => {
      const mockStoryLine = {
        id: 'storyline-id',
        userId: 'user-id',
        name: 'Test StoryLine',
        recordIds: [],
        isPinned: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.storyLine.findFirst.mockResolvedValue(mockStoryLine as any);

      const result = await storyLineRepository.findById('storyline-id', 'user-id');

      expect(result).toEqual(mockStoryLine);
    });
  });
});

