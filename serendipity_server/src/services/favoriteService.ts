import { CommunityPost, Record } from '@prisma/client';
import {
  FavoritePostRow,
  FavoriteRecordRow,
  IFavoriteRepository,
} from '../repositories/favoriteRepository';
import { ICommunityPostRepository } from '../repositories/communityPostRepository';
import { IRecordRepository } from '../repositories/recordRepository';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { fromJsonValue, fromJsonValueOptional } from '../utils/prisma-json';
import {
  FavoritePostSnapshotDto,
  FavoriteRecordSnapshotDto,
  FavoritedPostsResponseDto,
  FavoritedRecordsResponseDto,
} from '../types/favorite.dto';
import { CommunityPostResponseDto } from '../types/community.dto';
import { LocationDto, RecordResponseDto, TagWithNoteDto } from '../types/record.dto';

export interface IFavoriteService {
  favoritePost(userId: string, postId: string): Promise<void>;
  unfavoritePost(userId: string, postId: string): Promise<void>;
  getFavoritedPosts(userId: string): Promise<FavoritedPostsResponseDto>;
  favoriteRecord(userId: string, recordId: string): Promise<void>;
  unfavoriteRecord(userId: string, recordId: string): Promise<void>;
  getFavoritedRecords(userId: string): Promise<FavoritedRecordsResponseDto>;
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

    await this.favoriteRepository.favoritePost(userId, postId, this.toPostDto(post));
  }

  async unfavoritePost(userId: string, postId: string): Promise<void> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);
    if (!postId) throw new AppError('postId is required', ErrorCode.VALIDATION_ERROR);

    await this.favoriteRepository.unfavoritePost(userId, postId);
  }

  async getFavoritedPosts(userId: string): Promise<FavoritedPostsResponseDto> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);

    const favoriteRows = await this.favoriteRepository.getFavoritedPosts(userId);
    if (favoriteRows.length === 0) {
      return { posts: [], deletedPosts: [], deletedPostIds: [] };
    }

    const postIds = favoriteRows.map((row) => row.postId);
    const existingPosts = await this.communityPostRepository.findManyByIds(postIds);
    const existingIdSet = new Set(existingPosts.map((post) => post.id));
    const postMap = new Map(existingPosts.map((post) => [post.id, post]));

    const posts = postIds
      .filter((id) => existingIdSet.has(id))
      .map((id) => this.toPostDto(postMap.get(id)!));

    const deletedRows = favoriteRows.filter((row) => !existingIdSet.has(row.postId));
    const deletedPosts = deletedRows
      .map((row) => this.toDeletedPostSnapshot(row))
      .filter((post): post is CommunityPostResponseDto => post !== undefined);

    return {
      posts,
      deletedPosts,
      deletedPostIds: deletedPosts.map((post) => post.id),
    };
  }

  async favoriteRecord(userId: string, recordId: string): Promise<void> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);
    if (!recordId) throw new AppError('recordId is required', ErrorCode.VALIDATION_ERROR);

    const record = await this.recordRepository.findById(recordId, userId);
    if (!record) throw new AppError('Record not found', ErrorCode.NOT_FOUND);

    await this.favoriteRepository.favoriteRecord(userId, recordId, this.toRecordDto(record));
  }

  async unfavoriteRecord(userId: string, recordId: string): Promise<void> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);
    if (!recordId) throw new AppError('recordId is required', ErrorCode.VALIDATION_ERROR);

    await this.favoriteRepository.unfavoriteRecord(userId, recordId);
  }

  async getFavoritedRecords(userId: string): Promise<FavoritedRecordsResponseDto> {
    if (!userId) throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);

    const favoriteRows = await this.favoriteRepository.getFavoritedRecordIds(userId);
    if (favoriteRows.length === 0) {
      return { records: [], deletedRecords: [], deletedRecordIds: [] };
    }

    const allRecordIds = favoriteRows.map((row) => row.recordId);
    const existingRecords = await this.recordRepository.findManyByIds(allRecordIds);
    const existingIdSet = new Set(existingRecords.map((record) => record.id));
    const recordMap = new Map(existingRecords.map((record) => [record.id, record]));
    const records = allRecordIds
      .filter((id) => existingIdSet.has(id))
      .map((id) => this.toRecordDto(recordMap.get(id)!));
    const deletedRows = favoriteRows.filter((row) => !existingIdSet.has(row.recordId));
    const deletedRecords = deletedRows
      .map((row) => this.toDeletedRecordSnapshot(row))
      .filter((record): record is RecordResponseDto => record !== undefined);

    return {
      records,
      deletedRecords,
      deletedRecordIds: deletedRecords.map((record) => record.id),
    };
  }

  private toDeletedPostSnapshot(row: FavoritePostRow): CommunityPostResponseDto | undefined {
    return fromJsonValueOptional<FavoritePostSnapshotDto>(row.postSnapshot);
  }

  private toDeletedRecordSnapshot(row: FavoriteRecordRow): RecordResponseDto | undefined {
    return fromJsonValueOptional<FavoriteRecordSnapshotDto>(row.recordSnapshot);
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
      tags: fromJsonValue<TagWithNoteDto[]>(post.tags),
      status: post.status,
      isOwner: true,
      publishedAt: post.publishedAt.toISOString(),
      createdAt: post.createdAt.toISOString(),
      updatedAt: post.updatedAt.toISOString(),
    };
  }

  private toRecordDto(record: Record): RecordResponseDto {
    return {
      id: record.id,
      ownerId: record.userId,
      sourceDeviceId: record.sourceDeviceId,
      timestamp: record.timestamp.toISOString(),
      location: fromJsonValue<LocationDto>(record.location),
      description: record.description ?? undefined,
      tags: fromJsonValue<TagWithNoteDto[]>(record.tags),
      emotion: record.emotion ?? undefined,
      status: record.status,
      storyLineId: record.storyLineId ?? undefined,
      ifReencounter: record.ifReencounter ?? undefined,
      conversationStarter: record.conversationStarter ?? undefined,
      backgroundMusic: record.backgroundMusic ?? undefined,
      weather: fromJsonValue<string[]>(record.weather),
      isPinned: record.isPinned,
      createdAt: record.createdAt.toISOString(),
      updatedAt: record.updatedAt.toISOString(),
    };
  }
}
