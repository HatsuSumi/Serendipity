import { CommunityPostRepository } from '../../../src/repositories/communityPostRepository';
import { prismaMock } from '../../mocks/prisma.mock';

describe('CommunityPostRepository', () => {
  let communityPostRepository: CommunityPostRepository;

  beforeEach(() => {
    communityPostRepository = new CommunityPostRepository(prismaMock as any);
  });

  describe('create', () => {
    it('应该创建新社区帖子', async () => {
      const mockPost = {
        id: 'post-id',
        userId: 'user-id',
        recordId: 'record-id',
        timestamp: new Date(),
        tags: [],
        status: 'active',
        publishedAt: new Date(),
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.communityPost.create.mockResolvedValue(mockPost as any);

      const result = await communityPostRepository.create('user-id', {
        id: 'post-id',
        recordId: 'record-id',
        timestamp: new Date().toISOString(),
        tags: [],
        status: 'active',
      });

      expect(result).toEqual(mockPost);
      expect(prismaMock.communityPost.create).toHaveBeenCalled();
    });
  });

  describe('findById', () => {
    it('应该根据 ID 查找帖子', async () => {
      const mockPost = {
        id: 'post-id',
        userId: 'user-id',
        recordId: 'record-id',
        timestamp: new Date(),
        tags: [],
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.communityPost.findUnique.mockResolvedValue(mockPost as any);

      const result = await communityPostRepository.findById('post-id');

      expect(result).toEqual(mockPost);
    });
  });
});


