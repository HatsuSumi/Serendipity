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
  CheckPublishStatusDto,
  CheckPublishStatusResponseDto,
  RecordPublishStatusDto,
  PublishStatus,
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
  checkPublishStatus(
    userId: string,
    records: CheckPublishStatusDto[]
  ): Promise<CheckPublishStatusResponseDto>;
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
          '该记录已发布过，且内容无变化',
          ErrorCode.CONFLICT
        );
      }

      // 内容已变化，但用户未确认替换
      if (!data.forceReplace) {
        throw new AppError(
          '该记录已发布过，内容已变化，请确认是否替换',
          ErrorCode.CONFLICT
        );
      }

      // 用户已确认，删除旧帖
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

  // 批量检查发布状态
  async checkPublishStatus(
    userId: string,
    records: CheckPublishStatusDto[]
  ): Promise<CheckPublishStatusResponseDto> {
    // Fail Fast: 参数验证
    if (!userId) {
      throw new AppError('userId is required', ErrorCode.VALIDATION_ERROR);
    }
    if (!records || records.length === 0) {
      throw new AppError('records is required', ErrorCode.VALIDATION_ERROR);
    }

    const statuses: RecordPublishStatusDto[] = [];

    for (const record of records) {
      // 查询是否已发布
      const existingPost = await this.communityPostRepository.findByUserAndRecord(
        userId,
        record.recordId
      );

      if (!existingPost) {
        // 未发布过，可以发布
        statuses.push({
          recordId: record.recordId,
          status: PublishStatus.CAN_PUBLISH,
        });
      } else {
        // 已发布过，检查内容是否变化
        const hasChanged = this.hasPostContentChanged(existingPost, record);
        
        if (hasChanged) {
          // 内容已变化，需要用户确认
          statuses.push({
            recordId: record.recordId,
            status: PublishStatus.NEED_CONFIRM,
          });
        } else {
          // 内容未变化，不能发布
          statuses.push({
            recordId: record.recordId,
            status: PublishStatus.CANNOT_PUBLISH,
          });
        }
      }
    }

    return { statuses };
  }

  // 检查帖子内容是否发生变化
  // 
  // 使用字段映射表驱动的比较逻辑，避免重复代码
  private hasPostContentChanged(
    existingPost: CommunityPost,
    newData: CreateCommunityPostDto | CheckPublishStatusDto
  ): boolean {
    // 辅助函数：统一处理 null 和 undefined
    const normalize = (value: any) => value ?? null;
    
    // 定义需要比较的字段映射表
    // key: 字段名, value: 转换函数（可选）
    const fieldComparisons: Array<{
      field: keyof CommunityPost;
      transform?: (value: any) => any;
    }> = [
      { field: 'timestamp', transform: (v) => new Date(v).toISOString() },
      { field: 'address' },
      { field: 'placeName' },
      { field: 'placeType' },
      { field: 'province' },
      { field: 'city' },
      { field: 'area' },
      { field: 'description' },
      { field: 'status' },
    ];

    // 遍历字段进行比较
    for (const { field, transform } of fieldComparisons) {
      const existingValue = transform 
        ? transform(existingPost[field])
        : normalize(existingPost[field]);
      
      const newValue = transform
        ? transform((newData as any)[field])
        : normalize((newData as any)[field]);

      if (existingValue !== newValue) {
        return true;
      }
    }

    // 比较标签（深度比较）
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
      posts: posts.map((post) => {
        const dto = this.toResponseDto(post, userId);
        // 明确保证：getMyPosts 返回的帖子一定是用户自己的
        // 避免前端需要额外判断 isOwner
        return {
          ...dto,
          isOwner: true,
        };
      }),
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

