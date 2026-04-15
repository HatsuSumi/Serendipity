import { FavoriteService } from '../../../src/services/favoriteService';
import {
  FavoritePostSnapshotDto,
  FavoriteRecordSnapshotDto,
} from '../../../src/types/favorite.dto';
import { IFavoriteRepository } from '../../../src/repositories/favoriteRepository';
import { ICommunityPostRepository } from '../../../src/repositories/communityPostRepository';
import { IRecordRepository } from '../../../src/repositories/recordRepository';
import { createMockUser } from '../../helpers/factories';
import { AppError } from '../../../src/middlewares/errorHandler';
import { ErrorCode } from '../../../src/types/errors';
import { CommunityPost, Prisma, Record } from '@prisma/client';
import { toJsonValue } from '../../../src/utils/prisma-json';

const createMockCommunityPost = (overrides?: Partial<CommunityPost>): CommunityPost => ({
  id: 'post-1',
  userId: 'owner-1',
  recordId: 'record-1',
  timestamp: new Date('2026-04-12T10:00:00.000Z'),
  address: '深圳市南山区科技园',
  placeName: '科技园',
  placeType: 'cafe',
  province: '广东省',
  city: '深圳市',
  area: '南山区',
  description: 'hello',
  tags: toJsonValue([{ tag: '温柔' }]) as Prisma.JsonValue,
  status: 'missed',
  publishedAt: new Date('2026-04-12T10:05:00.000Z'),
  createdAt: new Date('2026-04-12T10:05:00.000Z'),
  updatedAt: new Date('2026-04-12T10:05:00.000Z'),
  ...overrides,
});

const createMockRecord = (overrides?: Partial<Record>): Record => ({
  id: 'record-1',
  userId: 'test-user-id',
  timestamp: new Date('2026-04-12T10:00:00.000Z'),
  location: toJsonValue({ address: '深圳市南山区科技园', placeName: '科技园', city: '深圳市', area: '南山区' }) as Prisma.JsonValue,
  description: 'record desc',
  tags: toJsonValue([{ tag: '心动', note: '擦肩而过' }]) as Prisma.JsonValue,
  emotion: 'high',
  status: 'missed',
  storyLineId: null,
  ifReencounter: null,
  conversationStarter: null,
  backgroundMusic: null,
  weather: toJsonValue(['sunny']) as Prisma.JsonValue,
  isPinned: false,
  deletedAt: null,
  createdAt: new Date('2026-04-12T10:00:00.000Z'),
  updatedAt: new Date('2026-04-12T10:10:00.000Z'),
  ...overrides,
});

describe('FavoriteService', () => {
  let favoriteService: FavoriteService;
  let mockFavoriteRepository: jest.Mocked<IFavoriteRepository>;
  let mockCommunityPostRepository: jest.Mocked<ICommunityPostRepository>;
  let mockRecordRepository: jest.Mocked<IRecordRepository>;

  beforeEach(() => {
    mockFavoriteRepository = {
      favoritePost: jest.fn(),
      unfavoritePost: jest.fn(),
      getFavoritedPosts: jest.fn(),
      favoriteRecord: jest.fn(),
      unfavoriteRecord: jest.fn(),
      getFavoritedRecordIds: jest.fn(),
    };

    mockCommunityPostRepository = {
      create: jest.fn(),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByUserAndRecord: jest.fn(),
      findRecent: jest.fn(),
      findByFilters: jest.fn(),
      findByUserAndRecords: jest.fn(),
      findManyByIds: jest.fn(),
      deleteById: jest.fn(),
      deleteByUserAndRecord: jest.fn(),
    };

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

    favoriteService = new FavoriteService(
      mockFavoriteRepository,
      mockCommunityPostRepository,
      mockRecordRepository,
    );
  });

  it('收藏帖子时应该持久化服务端快照', async () => {
    const post = createMockCommunityPost();
    mockCommunityPostRepository.findById.mockResolvedValue(post);

    await favoriteService.favoritePost('test-user-id', post.id);

    expect(mockFavoriteRepository.favoritePost).toHaveBeenCalledWith(
      'test-user-id',
      post.id,
      expect.objectContaining({
        id: post.id,
        recordId: post.recordId,
        placeName: post.placeName ?? undefined,
        status: post.status,
      }),
    );
  });

  it('获取收藏帖子时应该返回已删除帖子的云端快照', async () => {
    const deletedSnapshot: FavoritePostSnapshotDto = {
      id: 'deleted-post',
      recordId: 'record-x',
      timestamp: '2026-04-12T10:00:00.000Z',
      address: '深圳市南山区科技园',
      placeName: '旧帖子',
      placeType: 'cafe',
      province: '广东省',
      city: '深圳市',
      area: '南山区',
      description: '已删快照',
      tags: [{ tag: '温柔' }],
      status: 'missed',
      isOwner: true,
      publishedAt: '2026-04-12T10:05:00.000Z',
      createdAt: '2026-04-12T10:05:00.000Z',
      updatedAt: '2026-04-12T10:05:00.000Z',
    };

    mockFavoriteRepository.getFavoritedPosts.mockResolvedValue([
      { postId: 'deleted-post', postSnapshot: deletedSnapshot as any },
    ]);
    mockCommunityPostRepository.findManyByIds.mockResolvedValue([]);

    const result = await favoriteService.getFavoritedPosts('test-user-id');

    expect(result.posts).toEqual([]);
    expect(result.deletedPostIds).toEqual(['deleted-post']);
    expect(result.deletedPosts).toEqual([deletedSnapshot]);
  });

  it('收藏记录时应该持久化服务端快照', async () => {
    const record = createMockRecord();
    mockRecordRepository.findById.mockResolvedValue(record);

    await favoriteService.favoriteRecord('test-user-id', record.id);

    expect(mockFavoriteRepository.favoriteRecord).toHaveBeenCalledWith(
      'test-user-id',
      record.id,
      expect.objectContaining({
        id: record.id,
        ownerId: record.userId,
        status: record.status,
        isPinned: false,
      }),
    );
  });

  it('获取收藏记录时应该返回已删除记录的云端快照', async () => {
    const deletedSnapshot: FavoriteRecordSnapshotDto = {
      id: 'deleted-record',
      ownerId: createMockUser().id,
      timestamp: '2026-04-12T10:00:00.000Z',
      location: { address: '深圳市南山区科技园', placeName: '科技园' },
      description: 'record desc',
      tags: [{ tag: '心动', note: '擦肩而过' }],
      emotion: 'high',
      status: 'missed',
      weather: ['sunny'],
      isPinned: false,
      createdAt: '2026-04-12T10:00:00.000Z',
      updatedAt: '2026-04-12T10:10:00.000Z',
    };

    mockFavoriteRepository.getFavoritedRecordIds.mockResolvedValue([
      { recordId: 'deleted-record', recordSnapshot: deletedSnapshot as any },
    ]);
    mockRecordRepository.findManyByIds.mockResolvedValue([]);

    const result = await favoriteService.getFavoritedRecords('test-user-id');

    expect(result.records).toEqual([]);
    expect(result.deletedRecordIds).toEqual(['deleted-record']);
    expect(result.deletedRecords).toEqual([deletedSnapshot]);
  });

  it('收藏不存在的帖子时应该抛出 not found', async () => {
    mockCommunityPostRepository.findById.mockResolvedValue(null);

    await expect(favoriteService.favoritePost('test-user-id', 'missing-post')).rejects.toMatchObject({
      code: ErrorCode.NOT_FOUND,
    } satisfies Partial<AppError>);
  });
});

