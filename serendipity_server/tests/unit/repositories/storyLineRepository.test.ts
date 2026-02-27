import { StoryLineRepository } from '../../../src/repositories/storyLineRepository';
import { prismaMock } from '../../mocks/prisma.mock';

describe('StoryLineRepository', () => {
  let storyLineRepository: StoryLineRepository;

  beforeEach(() => {
    storyLineRepository = new StoryLineRepository(prismaMock as any);
  });

  describe('create', () => {
    it('应该创建新故事线', async () => {
      const mockStoryLine = {
        id: 'storyline-id',
        userId: 'user-id',
        name: 'Test StoryLine',
        recordIds: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.storyLine.create.mockResolvedValue(mockStoryLine as any);

      const result = await storyLineRepository.create('user-id', {
        id: 'storyline-id',
        name: 'Test StoryLine',
        recordIds: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      expect(result).toEqual(mockStoryLine);
      expect(prismaMock.storyLine.create).toHaveBeenCalled();
    });
  });

  describe('findById', () => {
    it('应该根据 ID 查找故事线', async () => {
      const mockStoryLine = {
        id: 'storyline-id',
        userId: 'user-id',
        name: 'Test StoryLine',
        recordIds: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.storyLine.findFirst.mockResolvedValue(mockStoryLine as any);

      const result = await storyLineRepository.findById('storyline-id', 'user-id');

      expect(result).toEqual(mockStoryLine);
    });
  });
});


