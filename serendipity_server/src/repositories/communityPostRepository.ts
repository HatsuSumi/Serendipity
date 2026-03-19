import { PrismaClient, CommunityPost, Prisma } from '@prisma/client';
import { CreateCommunityPostDto } from '../types/community.dto';
import { toJsonValue } from '../utils/prisma-json';

// 社区帖子仓储接口
export interface ICommunityPostRepository {
  create(userId: string, data: CreateCommunityPostDto): Promise<CommunityPost>;
  findById(id: string): Promise<CommunityPost | null>;
  findByUserId(userId: string): Promise<CommunityPost[]>;
  findByUserAndRecord(userId: string, recordId: string): Promise<CommunityPost | null>;
  findRecent(limit: number, lastTimestamp?: Date): Promise<CommunityPost[]>;
  findByFilters(filters: {
    userId?: string;
    startDate?: Date;
    endDate?: Date;
    publishStartDate?: Date;
    publishEndDate?: Date;
    province?: string;
    city?: string;
    area?: string;
    placeTypes?: string[];
    tags?: string[];
    statuses?: string[];
    tagMatchMode?: 'wholeWord' | 'contains';
    limit: number;
  }): Promise<CommunityPost[]>;
  findByUserAndRecords(userId: string, recordIds: string[]): Promise<CommunityPost[]>;
  findManyByIds(ids: string[]): Promise<CommunityPost[]>;
  deleteById(id: string, userId: string): Promise<void>;
  deleteByUserAndRecord(userId: string, recordId: string): Promise<void>;
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

  async findByUserAndRecord(userId: string, recordId: string): Promise<CommunityPost | null> {
    return this.prisma.communityPost.findFirst({
      where: {
        userId,
        recordId,
      },
    });
  }

  async findByUserAndRecords(userId: string, recordIds: string[]): Promise<CommunityPost[]> {
    return this.prisma.communityPost.findMany({
      where: {
        userId,
        recordId: {
          in: recordIds,
        },
      },
    });
  }

  async findManyByIds(ids: string[]): Promise<CommunityPost[]> {
    if (ids.length === 0) return [];
    return this.prisma.communityPost.findMany({
      where: { id: { in: ids } },
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
    userId?: string;
    startDate?: Date;
    endDate?: Date;
    publishStartDate?: Date;
    publishEndDate?: Date;
    province?: string;
    city?: string;
    area?: string;
    placeTypes?: string[];
    tags?: string[];
    statuses?: string[];
    tagMatchMode?: 'wholeWord' | 'contains';
    limit: number;
  }): Promise<CommunityPost[]> {
    // 如果有标签筛选，使用原始 SQL 查询
    if (filters.tags && filters.tags.length > 0) {
      return this.findByFiltersWithTags(filters);
    }

    const where: any = {};

    // 用户 ID 筛选（用于"我的发布"功能）
    if (filters.userId) {
      where.userId = filters.userId;
    }

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

  // 带标签筛选的查询（使用 Prisma.sql 模板标签）
  // 
  // 设计原则：
  // - 安全性优先：使用 Prisma.sql 防止 SQL 注入
  // - 类型安全：利用 TypeScript 类型检查
  // - 符合最佳实践：遵循 Prisma 官方推荐
  // 
  // 标签匹配逻辑：
  // - 全词匹配：标签完全相等（使用 @> 操作符）
  // - 包含匹配：标签包含关键词（使用 ILIKE）
  private async findByFiltersWithTags(filters: {
    userId?: string;
    startDate?: Date;
    endDate?: Date;
    publishStartDate?: Date;
    publishEndDate?: Date;
    province?: string;
    city?: string;
    area?: string;
    placeTypes?: string[];
    tags?: string[];
    statuses?: string[];
    tagMatchMode?: 'wholeWord' | 'contains';
    limit: number;
  }): Promise<CommunityPost[]> {
    const conditions: Prisma.Sql[] = [];
    const tagMatchMode = filters.tagMatchMode || 'contains';

    // 用户 ID 筛选（用于"我的发布"功能）
    if (filters.userId) {
      conditions.push(Prisma.sql`user_id = ${filters.userId}`);
    }

    // 标签筛选（JSONB 查询，OR 逻辑：匹配任意一个标签即可）
    if (filters.tags && filters.tags.length > 0) {
      const tagConditions = filters.tags.map(tag => {
        if (tagMatchMode === 'wholeWord') {
          // 全词匹配：标签完全相等
          return Prisma.sql`EXISTS (
            SELECT 1 FROM jsonb_array_elements(tags) AS t
            WHERE t->>'tag' = ${tag}
          )`;
        } else {
          // 包含匹配：标签包含关键词
          return Prisma.sql`EXISTS (
            SELECT 1 FROM jsonb_array_elements(tags) AS t
            WHERE t->>'tag' ILIKE ${`%${tag}%`}
          )`;
        }
      });
      conditions.push(Prisma.sql`(${Prisma.join(tagConditions, ' OR ')})`);
    }

    // 错过时间范围筛选
    if (filters.startDate) {
      conditions.push(Prisma.sql`timestamp >= ${filters.startDate}`);
    }
    if (filters.endDate) {
      conditions.push(Prisma.sql`timestamp <= ${filters.endDate}`);
    }

    // 发布时间范围筛选
    if (filters.publishStartDate) {
      conditions.push(Prisma.sql`published_at >= ${filters.publishStartDate}`);
    }
    if (filters.publishEndDate) {
      conditions.push(Prisma.sql`published_at <= ${filters.publishEndDate}`);
    }

    // 省份筛选
    if (filters.province) {
      conditions.push(Prisma.sql`province = ${filters.province}`);
    }

    // 城市筛选
    if (filters.city) {
      conditions.push(Prisma.sql`city = ${filters.city}`);
    }

    // 区县筛选
    if (filters.area) {
      conditions.push(Prisma.sql`area = ${filters.area}`);
    }

    // 场所类型筛选（多选，OR 逻辑）
    if (filters.placeTypes && filters.placeTypes.length > 0) {
      conditions.push(Prisma.sql`place_type = ANY(${filters.placeTypes})`);
    }

    // 状态筛选（多选，OR 逻辑）
    if (filters.statuses && filters.statuses.length > 0) {
      conditions.push(Prisma.sql`status = ANY(${filters.statuses})`);
    }

    // 构建 WHERE 子句
    const whereClause = conditions.length > 0 
      ? Prisma.sql`WHERE ${Prisma.join(conditions, ' AND ')}`
      : Prisma.empty;

    // 构建完整查询（使用 Prisma.sql 模板标签）
    const query = Prisma.sql`
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
      LIMIT ${filters.limit}
    `;

    return this.prisma.$queryRaw<CommunityPost[]>(query);
  }

  async deleteById(id: string, userId: string): Promise<void> {
    await this.prisma.communityPost.delete({
      where: {
        id,
        userId, // 确保只能删除自己的帖子
      },
    });
  }

  async deleteByUserAndRecord(userId: string, recordId: string): Promise<void> {
    // deleteMany does not throw if record does not exist (idempotent)
    await this.prisma.communityPost.deleteMany({
      where: { userId, recordId },
    });
  }
}
