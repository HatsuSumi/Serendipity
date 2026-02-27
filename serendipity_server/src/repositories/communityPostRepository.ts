import { PrismaClient, CommunityPost } from '@prisma/client';
import { CreateCommunityPostDto } from '../types/community.dto';
import { toJsonValue } from '../utils/prisma-json';

// 社区帖子仓储接口
export interface ICommunityPostRepository {
  create(userId: string, data: CreateCommunityPostDto): Promise<CommunityPost>;
  findById(id: string): Promise<CommunityPost | null>;
  findByUserId(userId: string): Promise<CommunityPost[]>;
  findRecent(limit: number, lastTimestamp?: Date): Promise<CommunityPost[]>;
  findByFilters(filters: {
    startDate?: Date;
    endDate?: Date;
    cityName?: string;
    placeType?: string;
    tag?: string;
    status?: string;
    limit: number;
  }): Promise<CommunityPost[]>;
  deleteById(id: string, userId: string): Promise<void>;
}

// 社区帖子仓储实现
export class CommunityPostRepository implements ICommunityPostRepository {
  constructor(private prisma: PrismaClient) {}

  async create(
    userId: string,
    data: CreateCommunityPostDto
  ): Promise<CommunityPost> {
    return this.prisma.communityPost.create({
      data: {
        id: data.id,
        userId,
        recordId: data.recordId,
        timestamp: new Date(data.timestamp),
        address: data.address,
        placeName: data.placeName,
        placeType: data.placeType,
        cityName: data.cityName,
        description: data.description,
        tags: toJsonValue(data.tags),
        status: data.status,
        publishedAt: data.publishedAt
          ? new Date(data.publishedAt)
          : new Date(),
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    });
  }

  async findById(id: string): Promise<CommunityPost | null> {
    return this.prisma.communityPost.findUnique({
      where: { id },
    });
  }

  async findByUserId(userId: string): Promise<CommunityPost[]> {
    return this.prisma.communityPost.findMany({
      where: { userId },
      orderBy: { publishedAt: 'desc' },
    });
  }

  async findRecent(
    limit: number,
    lastTimestamp?: Date
  ): Promise<CommunityPost[]> {
    return this.prisma.communityPost.findMany({
      where: lastTimestamp
        ? {
            publishedAt: {
              lt: lastTimestamp,
            },
          }
        : undefined,
      orderBy: { publishedAt: 'desc' },
      take: limit,
    });
  }

  async findByFilters(filters: {
    startDate?: Date;
    endDate?: Date;
    cityName?: string;
    placeType?: string;
    tag?: string;
    status?: string;
    limit: number;
  }): Promise<CommunityPost[]> {
    const where: any = {};

    // 日期范围筛选
    if (filters.startDate || filters.endDate) {
      where.timestamp = {};
      if (filters.startDate) {
        where.timestamp.gte = filters.startDate;
      }
      if (filters.endDate) {
        where.timestamp.lte = filters.endDate;
      }
    }

    // 城市筛选
    if (filters.cityName) {
      where.cityName = filters.cityName;
    }

    // 场所类型筛选
    if (filters.placeType) {
      where.placeType = filters.placeType;
    }

    // 状态筛选
    if (filters.status) {
      where.status = filters.status;
    }

    // 标签筛选（JSONB 查询）
    if (filters.tag) {
      where.tags = {
        path: '$[*].tag',
        array_contains: filters.tag,
      };
    }

    return this.prisma.communityPost.findMany({
      where,
      orderBy: { publishedAt: 'desc' },
      take: filters.limit,
    });
  }

  async deleteById(id: string, userId: string): Promise<void> {
    await this.prisma.communityPost.delete({
      where: {
        id,
        userId, // 确保只能删除自己的帖子
      },
    });
  }
}

