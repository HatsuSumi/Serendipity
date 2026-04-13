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
        deletedAt: null,
        createdAt,
        updatedAt,
      };

      prismaMock.storyLine.create.mockResolvedValue(mockStoryLine as any);

      const result = await storyLineRepository.create('user-id', {
        id: 'storyline-id',
        name: 'Test StoryLine',
        recordIds: [],
        isPinned: true,
        createdAt,
        updatedAt,
      });

      expect(result).toEqual(mockStoryLine);
      expect(prismaMock.storyLine.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          id: 'storyline-id',
          userId: 'user-id',
          isPinned: true,
        }),
      });
    });
  });

  describe('batchCreate', () => {
    it('应该批量创建故事线并保留 userId 归属', async () => {
      const createdAt = new Date();
      const updatedAt = new Date();

      await storyLineRepository.batchCreate('user-b', [
        {
          id: 'storyline-1',
          name: 'storyline-1',
          recordIds: [],
          isPinned: false,
          createdAt,
          updatedAt,
        },
        {
          id: 'storyline-2',
          name: 'storyline-2',
          recordIds: [],
          isPinned: true,
          createdAt,
          updatedAt,
        },
      ]);

      expect(prismaMock.$transaction).toHaveBeenCalledTimes(1);
      expect(prismaMock.storyLine.create).toHaveBeenCalledTimes(2);
      expect(prismaMock.storyLine.create).toHaveBeenNthCalledWith(
        1,
        expect.objectContaining({
          data: expect.objectContaining({
            id: 'storyline-1',
            userId: 'user-b',
            isPinned: false,
          }),
        })
      );
      expect(prismaMock.storyLine.create).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({
          data: expect.objectContaining({
            id: 'storyline-2',
            userId: 'user-b',
            isPinned: true,
          }),
        })
      );
    });
  });

  describe('findByIdGlobal', () => {
    it('应该根据 ID 全局查找故事线', async () => {
      const mockStoryLine = {
        id: 'storyline-id',
        userId: 'user-id',
        name: 'Test StoryLine',
        recordIds: [],
        isPinned: false,
        deletedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.storyLine.findUnique.mockResolvedValue(mockStoryLine as any);

      const result = await storyLineRepository.findByIdGlobal('storyline-id');

      expect(result).toEqual(mockStoryLine);
      expect(prismaMock.storyLine.findUnique).toHaveBeenCalledWith({
        where: { id: 'storyline-id' },
      });
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
    it('应该根据 ID 和 userId 查找故事线', async () => {
      const mockStoryLine = {
        id: 'storyline-id',
        userId: 'user-id',
        name: 'Test StoryLine',
        recordIds: [],
        isPinned: false,
        deletedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.storyLine.findFirst.mockResolvedValue(mockStoryLine as any);

      const result = await storyLineRepository.findById('storyline-id', 'user-id');

      expect(result).toEqual(mockStoryLine);
      expect(prismaMock.storyLine.findFirst).toHaveBeenCalledWith({
        where: { id: 'storyline-id', userId: 'user-id', deletedAt: null },
      });
    });
  });

  describe('delete', () => {
    it('应该将故事线墓碑化而不是物理删除', async () => {
      const deletedAt = new Date('2026-04-13T10:00:00.000Z');
      prismaMock.storyLine.update.mockResolvedValue({} as any);

      await storyLineRepository.delete('storyline-id', deletedAt);

      expect(prismaMock.storyLine.update).toHaveBeenCalledWith({
        where: { id: 'storyline-id' },
        data: {
          deletedAt,
          updatedAt: deletedAt,
        },
      });
    });
  });
});
