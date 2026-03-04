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
    publishStartDate?: Date;
    publishEndDate?: Date;
    province?: string;
    city?: string;
    area?: string;
    placeTypes?: string[];
    tag?: string;
    statuses?: string[];
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
        province: data.province,
        city: data.city,
        area: data.area,
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
    publishStartDate?: Date;
    publishEndDate?: Date;
    province?: string;
    city?: string;
    area?: string;
    placeTypes?: string[];
    tag?: string;
    statuses?: string[];
    limit: number;
  }): Promise<CommunityPost[]> {
    // 如果有标签筛选，使用原始 SQL 查询
    if (filters.tag) {
      return this.findByFiltersWithTag(filters);
    }

    const where: any = {};

    // 错过时间范围筛选（基于 timestamp 字段）
    if (filters.startDate || filters.endDate) {
      where.timestamp = {};
      if (filters.startDate) {
        where.timestamp.gte = filters.startDate;
      }
      if (filters.endDate) {
        where.timestamp.lte = filters.endDate;
      }
    }

    // 发布时间范围筛选（基于 publishedAt 字段）
    if (filters.publishStartDate || filters.publishEndDate) {
      where.publishedAt = {};
      if (filters.publishStartDate) {
        where.publishedAt.gte = filters.publishStartDate;
      }
      if (filters.publishEndDate) {
        where.publishedAt.lte = filters.publishEndDate;
      }
    }

    // 省份筛选
    if (filters.province) {
      where.province = filters.province;
    }

    // 城市筛选
    if (filters.city) {
      where.city = filters.city;
    }

    // 区县筛选
    if (filters.area) {
      where.area = filters.area;
    }

    // 场所类型筛选（多选，OR逻辑）
    if (filters.placeTypes && filters.placeTypes.length > 0) {
      where.placeType = {
        in: filters.placeTypes,
      };
    }

    // 状态筛选（多选，OR逻辑）
    if (filters.statuses && filters.statuses.length > 0) {
      where.status = {
        in: filters.statuses,
      };
    }

    return this.prisma.communityPost.findMany({
      where,
      orderBy: { publishedAt: 'desc' },
      take: filters.limit,
    });
  }

  // 带标签筛选的查询（使用原始 SQL）
  private async findByFiltersWithTag(filters: {
    startDate?: Date;
    endDate?: Date;
    publishStartDate?: Date;
    publishEndDate?: Date;
    province?: string;
    city?: string;
    area?: string;
    placeTypes?: string[];
    tag?: string;
    statuses?: string[];
    limit: number;
  }): Promise<CommunityPost[]> {
    const conditions: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    // 标签筛选（JSONB 查询）
    if (filters.tag) {
      conditions.push(
        `EXISTS (SELECT 1 FROM jsonb_array_elements(tags) AS t WHERE t->>'tag' = $${paramIndex})`
      );
      params.push(filters.tag);
      paramIndex++;
    }

    // 错过时间范围筛选
    if (filters.startDate) {
      conditions.push(`timestamp >= $${paramIndex}`);
      params.push(filters.startDate);
      paramIndex++;
    }
    if (filters.endDate) {
      conditions.push(`timestamp <= $${paramIndex}`);
      params.push(filters.endDate);
      paramIndex++;
    }

    // 发布时间范围筛选
    if (filters.publishStartDate) {
      conditions.push(`published_at >= $${paramIndex}`);
      params.push(filters.publishStartDate);
      paramIndex++;
    }
    if (filters.publishEndDate) {
      conditions.push(`published_at <= $${paramIndex}`);
      params.push(filters.publishEndDate);
      paramIndex++;
    }

    // 省份筛选
    if (filters.province) {
      conditions.push(`province = $${paramIndex}`);
      params.push(filters.province);
      paramIndex++;
    }

    // 城市筛选
    if (filters.city) {
      conditions.push(`city = $${paramIndex}`);
      params.push(filters.city);
      paramIndex++;
    }

    // 区县筛选
    if (filters.area) {
      conditions.push(`area = $${paramIndex}`);
      params.push(filters.area);
      paramIndex++;
    }

    // 场所类型筛选
    if (filters.placeTypes && filters.placeTypes.length > 0) {
      conditions.push(`place_type = ANY($${paramIndex})`);
      params.push(filters.placeTypes);
      paramIndex++;
    }

    // 状态筛选
    if (filters.statuses && filters.statuses.length > 0) {
      conditions.push(`status = ANY($${paramIndex})`);
      params.push(filters.statuses);
      paramIndex++;
    }

    const whereClause =
      conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const query = `
      SELECT 
        id,
        user_id as "userId",
        record_id as "recordId",
        timestamp,
        address,
        place_name as "placeName",
        place_type as "placeType",
        province,
        city,
        area,
        description,
        tags,
        status,
        published_at as "publishedAt",
        created_at as "createdAt",
        updated_at as "updatedAt"
      FROM "community_posts"
      ${whereClause}
      ORDER BY published_at DESC
      LIMIT $${paramIndex}
    `;
    params.push(filters.limit);

    return this.prisma.$queryRawUnsafe(query, ...params);
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

