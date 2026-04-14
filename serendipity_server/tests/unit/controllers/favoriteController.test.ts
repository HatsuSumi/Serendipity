import { FavoriteController } from '../../../src/controllers/favoriteController';
import { IFavoriteService } from '../../../src/services/favoriteService';
import { createMockRequest, createMockResponse, createMockNext } from '../../helpers/factories';

describe('FavoriteController', () => {
  let favoriteController: FavoriteController;
  let mockFavoriteService: jest.Mocked<IFavoriteService>;

  beforeEach(() => {
    mockFavoriteService = {
      favoritePost: jest.fn(),
      unfavoritePost: jest.fn(),
      getFavoritedPosts: jest.fn(),
      favoriteRecord: jest.fn(),
      unfavoriteRecord: jest.fn(),
      getFavoritedRecords: jest.fn(),
    };

    favoriteController = new FavoriteController(mockFavoriteService);
  });

  it('获取收藏帖子时应该返回完整结果结构', async () => {
    const req = createMockRequest({
      user: { userId: 'test-user-id' },
    });
    const res = createMockResponse();
    const next = createMockNext();
    const result = {
      posts: [],
      deletedPosts: [
        {
          id: 'deleted-post',
          recordId: 'record-1',
          timestamp: '2026-04-12T10:00:00.000Z',
          tags: [{ tag: '温柔' }],
          status: 'missed',
          publishedAt: '2026-04-12T10:05:00.000Z',
          createdAt: '2026-04-12T10:05:00.000Z',
          updatedAt: '2026-04-12T10:05:00.000Z',
        },
      ],
      deletedPostIds: ['deleted-post'],
    };
    mockFavoriteService.getFavoritedPosts.mockResolvedValue(result);

    await favoriteController.getFavoritedPosts(req, res, next);

    expect(mockFavoriteService.getFavoritedPosts).toHaveBeenCalledWith('test-user-id');
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: result,
    });
    expect(next).not.toHaveBeenCalled();
  });

  it('获取收藏记录时应该返回完整结果结构', async () => {
    const req = createMockRequest({
      user: { userId: 'test-user-id' },
    });
    const res = createMockResponse();
    const next = createMockNext();
    const result = {
      records: [
        {
          id: 'record-1',
          sourceDeviceId: 'device-test',
          ownerId: 'test-user-id',
          timestamp: '2026-04-12T09:00:00.000Z',
          location: { placeName: '科技园' },
          tags: [{ tag: '相遇' }],
          status: 'missed',
          weather: ['sunny'],
          isPinned: false,
          createdAt: '2026-04-12T09:00:00.000Z',
          updatedAt: '2026-04-12T09:10:00.000Z',
        },
      ],
      deletedRecords: [
        {
          id: 'deleted-record',
          sourceDeviceId: 'device-test',
          ownerId: 'test-user-id',
          timestamp: '2026-04-12T10:00:00.000Z',
          location: { placeName: '科技园' },
          tags: [{ tag: '心动' }],
          status: 'missed',
          weather: ['sunny'],
          isPinned: false,
          createdAt: '2026-04-12T10:00:00.000Z',
          updatedAt: '2026-04-12T10:10:00.000Z',
        },
      ],
      deletedRecordIds: ['deleted-record'],
    };
    mockFavoriteService.getFavoritedRecords.mockResolvedValue(result);

    await favoriteController.getFavoritedRecords(req, res, next);

    expect(mockFavoriteService.getFavoritedRecords).toHaveBeenCalledWith('test-user-id');
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: result,
    });
    expect(next).not.toHaveBeenCalled();
  });
});

