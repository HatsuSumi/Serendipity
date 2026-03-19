import { IFavoriteRepository } from '../repositories/favoriteRepository';
import { ICommunityPostRepository } from '../repositories/communityPostRepository';
import { IRecordRepository } from '../repositories/recordRepository';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { fromJsonValue } from '../utils/prisma-json';
import { CommunityPost } from '@prisma/client';

export interface FavoritedPostsResponseDto {
  posts: CommunityPostResponseDto[];
  /// 已被删除但仍在收藏列表中的帖子 ID（孤儿收藏）
  deletedPostIds: string[];
}

export interface FavoritedRecordIdsResponseDto {
  recordIds: string[];
  /// 已被删除但仍在收藏列表中的记录 ID（孤儿收藏）
  deletedRecordIds: string[];
}

export interface CommunityPostResponseDto {
  id: string;
  recordId: string;
  timestamp: string;
  address?: string;
  placeName?: string;
  placeType?: string;
  province?: string;
  city?: string;
  area?: string;
  description?: string;
  tags: any[];
  status: string;
  publishedAt: string;
  createdAt: string;
  updatedAt: string;
}

export interface IFavoriteService {
  favoritePost(userId: string, postId: string): Promise<void>;
  unfavoritePost(userId: string, postId: string): Promise<void>;
  getFavoritedPosts(userId: string): Promise<FavoritedPostsResponseDto>;
  favoriteRecord(userId: string, recordId: string): Promise<void>;
  unfavoriteRecord(userId: string, recordId: string): Promise<void>;
  getFavoritedRecordIds(userId: string): Promise<FavoritedRecordIdsResponseDto>;
}

export class FavoriteService implements IFavoriteService {
  constructor(
    private favoriteRepository: IFavoriteRepository,
    private communityPostRepository: ICommunityPostRepository,
    private recordRepository: IRecordRepository,
  ) {}

  async favoritePost(userId: string, postId: string): Promise<void> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);
    if (!postId) throw new AppError('postId is required', ErrorCode.VALIDATION_ERROR);

    const post = await this.communityPostRepository.findById(postId);
    if (!post) throw new AppError('Post not found', ErrorCode.NOT_FOUND);

    await this.favoriteRepository.favoritePost(userId, postId);
  }

  async unfavoritePost(userId: string, postId: string): Promise<void> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);
    if (!postId) throw new AppError('postId is required', ErrorCode.VALIDATION_ERROR);

    await this.favoriteRepository.unfavoritePost(userId, postId);
  }

  async getFavoritedPosts(userId: string): Promise<FavoritedPostsResponseDto> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);

    const postIds = await this.favoriteRepository.getFavoritedPosts(userId);
    if (postIds.length === 0) return { posts: [], deletedPostIds: [] };

    // 单次批量查询，消除 N+1 问题
    const existingPosts = await this.communityPostRepository.findManyByIds(postIds);
    const existingIdSet = new Set(existingPosts.map(p => p.id));
    const deletedPostIds = postIds.filter(id => !existingIdSet.has(id));

    // 保持原始收藏顺序
    const postMap = new Map(existingPosts.map(p => [p.id, p]));
    const orderedPosts = postIds
      .filter(id => existingIdSet.has(id))
      .map(id => postMap.get(id)!);

    return {
      posts: orderedPosts.map(post => this.toPostDto(post)),
      deletedPostIds,
    };
  }

  async favoriteRecord(userId: string, recordId: string): Promise<void> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);
    if (!recordId) throw new AppError('recordId is required', ErrorCode.VALIDATION_ERROR);

    await this.favoriteRepository.favoriteRecord(userId, recordId);
  }

  async unfavoriteRecord(userId: string, recordId: string): Promise<void> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);
    if (!recordId) throw new AppError('recordId is required', ErrorCode.VALIDATION_ERROR);

    await this.favoriteRepository.unfavoriteRecord(userId, recordId);
  }

  async getFavoritedRecordIds(userId: string): Promise<FavoritedRecordIdsResponseDto> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);

    const allRecordIds = await this.favoriteRepository.getFavoritedRecordIds(userId);
    if (allRecordIds.length === 0) return { recordIds: [], deletedRecordIds: [] };

    // 单次批量查询，消除 N+1 问题
    const existingRecords = await this.recordRepository.findManyByIds(allRecordIds);
    const existingIdSet = new Set(existingRecords.map(r => r.id));
    const recordIds = allRecordIds.filter(id => existingIdSet.has(id));
    const deletedRecordIds = allRecordIds.filter(id => !existingIdSet.has(id));

    return { recordIds, deletedRecordIds };
  }

  private toPostDto(post: CommunityPost): CommunityPostResponseDto {
    return {
      id: post.id,
      recordId: post.recordId,
      timestamp: post.timestamp.toISOString(),
      address: post.address ?? undefined,
      placeName: post.placeName ?? undefined,
      placeType: post.placeType ?? undefined,
      province: post.province ?? undefined,
      city: post.city ?? undefined,
      area: post.area ?? undefined,
      description: post.description ?? undefined,
      tags: fromJsonValue(post.tags),
      status: post.status,
      publishedAt: post.publishedAt.toISOString(),
      createdAt: post.createdAt.toISOString(),
      updatedAt: post.updatedAt.toISOString(),
    };
  }
}

