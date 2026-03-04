import { CommunityPost } from '@prisma/client';
import { ICommunityPostRepository } from '../repositories/communityPostRepository';
import {
  CreateCommunityPostDto,
  CreateCommunityPostResponseDto,
  CommunityPostResponseDto,
  CommunityPostListResponseDto,
  MyCommunityPostsResponseDto,
  FilterCommunityPostsQuery,
  TagDto,
} from '../types/community.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { fromJsonValue } from '../utils/prisma-json';

// 社区帖子服务接口
export interface ICommunityPostService {
  createPost(
    userId: string,
    data: CreateCommunityPostDto
  ): Promise<CreateCommunityPostResponseDto>;
  getRecentPosts(
    limit: number,
    lastTimestamp?: string,
    currentUserId?: string
  ): Promise<CommunityPostListResponseDto>;
  getMyPosts(userId: string): Promise<MyCommunityPostsResponseDto>;
  deletePost(postId: string, userId: string): Promise<void>;
  filterPosts(
    query: FilterCommunityPostsQuery,
    currentUserId?: string
  ): Promise<CommunityPostListResponseDto>;
}

// 社区帖子服务实现
export class CommunityPostService implements ICommunityPostService {
  constructor(private communityPostRepository: ICommunityPostRepository) {}

  async createPost(
    userId: string,
    data: CreateCommunityPostDto
  ): Promise<CreateCommunityPostResponseDto> {
    // 查询该用户是否已发布过该 recordId 的帖子
    const existingPost = await this.communityPostRepository.findByUserAndRecord(
      userId,
      data.recordId
    );

    let replaced = false;

    // 如果已存在，检查内容是否发生变化
    if (existingPost) {
      const hasChanged = this.hasPostContentChanged(existingPost, data);
      
      if (!hasChanged) {
        // 内容未变化，不允许重复发布
        throw new AppError(
          'This record has already been published with the same content',
          ErrorCode.CONFLICT
        );
      }

      // 内容已变化，删除旧帖
      await this.communityPostRepository.deleteById(existingPost.id, userId);
      replaced = true;
    }

    // 创建新帖子
    const post = await this.communityPostRepository.create(userId, data);

    return {
      id: post.id,
      publishedAt: post.publishedAt.toISOString(),
      replaced,
    };
  }

  // 检查帖子内容是否发生变化
  private hasPostContentChanged(
    existingPost: CommunityPost,
    newData: CreateCommunityPostDto
  ): boolean {
    // 辅助函数：统一处理 null 和 undefined
    const normalize = (value: any) => value ?? null;
    
    // 比较关键字段
    if (existingPost.timestamp.toISOString() !== new Date(newData.timestamp).toISOString()) {
      return true;
    }
    if (normalize(existingPost.address) !== normalize(newData.address)) {
      return true;
    }
    if (normalize(existingPost.placeName) !== normalize(newData.placeName)) {
      return true;
    }
    if (normalize(existingPost.placeType) !== normalize(newData.placeType)) {
      return true;
    }
    if (normalize(existingPost.province) !== normalize(newData.province)) {
      return true;
    }
    if (normalize(existingPost.city) !== normalize(newData.city)) {
      return true;
    }
    if (normalize(existingPost.area) !== normalize(newData.area)) {
      return true;
    }
    if (normalize(existingPost.description) !== normalize(newData.description)) {
      return true;
    }
    if (existingPost.status !== newData.status) {
      return true;
    }

    // 比较标签（需要深度比较）
    const existingTags = fromJsonValue(existingPost.tags);
    const newTags = newData.tags;
    
    if (JSON.stringify(existingTags) !== JSON.stringify(newTags)) {
      return true;
    }

    return false;
  }

  async getRecentPosts(
    limit: number = 20,
    lastTimestamp?: string,
    currentUserId?: string
  ): Promise<CommunityPostListResponseDto> {
    const lastDate = lastTimestamp ? new Date(lastTimestamp) : undefined;

    // 多查询一条，用于判断是否还有更多
    const posts = await this.communityPostRepository.findRecent(
      limit + 1,
      lastDate
    );

    const hasMore = posts.length > limit;
    const resultPosts = hasMore ? posts.slice(0, limit) : posts;

    return {
      posts: resultPosts.map((post) => this.toResponseDto(post, currentUserId)),
      hasMore,
    };
  }

  async getMyPosts(userId: string): Promise<MyCommunityPostsResponseDto> {
    const posts = await this.communityPostRepository.findByUserId(userId);

    return {
      posts: posts.map((post) => this.toResponseDto(post, userId)),
      total: posts.length,
    };
  }

  async deletePost(postId: string, userId: string): Promise<void> {
    // 先查询帖子是否存在
    const post = await this.communityPostRepository.findById(postId);

    if (!post) {
      throw new AppError('Post not found', ErrorCode.NOT_FOUND);
    }

    // 检查是否是帖子作者
    if (post.userId !== userId) {
      throw new AppError(
        'You are not authorized to delete this post',
        ErrorCode.FORBIDDEN
      );
    }

    await this.communityPostRepository.deleteById(postId, userId);
  }

  async filterPosts(
    query: FilterCommunityPostsQuery,
    currentUserId?: string
  ): Promise<CommunityPostListResponseDto> {
    const limit = query.limit || 20;

    const filters: any = {
      limit: limit + 1, // 多查询一条，用于判断是否还有更多
    };

    // 错过时间范围
    if (query.startDate) {
      filters.startDate = new Date(query.startDate);
    }
    if (query.endDate) {
      filters.endDate = new Date(query.endDate);
    }

    // 发布时间范围
    if (query.publishStartDate) {
      filters.publishStartDate = new Date(query.publishStartDate);
    }
    if (query.publishEndDate) {
      filters.publishEndDate = new Date(query.publishEndDate);
    }

    // 省份
    if (query.province) {
      filters.province = query.province;
    }

    // 城市
    if (query.city) {
      filters.city = query.city;
    }

    // 区县
    if (query.area) {
      filters.area = query.area;
    }

    // 场所类型（支持多选，OR逻辑）
    if (query.placeTypes) {
      const types = query.placeTypes.split(',').map(t => t.trim()).filter(t => t);
      if (types.length > 0) {
        filters.placeTypes = types;
      }
    }

    // 标签（支持多选，OR逻辑）
    if (query.tags) {
      const tags = query.tags.split(',').map(t => t.trim()).filter(t => t);
      if (tags.length > 0) {
        filters.tags = tags;
      }
    }

    // 状态（支持多选，OR逻辑）
    if (query.statuses) {
      const statuses = query.statuses.split(',').map(s => s.trim()).filter(s => s);
      if (statuses.length > 0) {
        filters.statuses = statuses;
      }
    }

    const posts = await this.communityPostRepository.findByFilters(filters);

    const hasMore = posts.length > limit;
    const resultPosts = hasMore ? posts.slice(0, limit) : posts;

    return {
      posts: resultPosts.map((post) => this.toResponseDto(post, currentUserId)),
      hasMore,
    };
  }

  // 转换为响应 DTO
  private toResponseDto(post: CommunityPost, currentUserId?: string): CommunityPostResponseDto {
    return {
      id: post.id,
      recordId: post.recordId,
      timestamp: post.timestamp.toISOString(),
      address: post.address || undefined,
      placeName: post.placeName || undefined,
      placeType: post.placeType || undefined,
      province: post.province || undefined,
      city: post.city || undefined,
      area: post.area || undefined,
      description: post.description || undefined,
      tags: fromJsonValue<TagDto[]>(post.tags),
      status: post.status,
      isOwner: currentUserId ? post.userId === currentUserId : undefined,
      publishedAt: post.publishedAt.toISOString(),
      createdAt: post.createdAt.toISOString(),
      updatedAt: post.updatedAt.toISOString(),
    };
  }
}

