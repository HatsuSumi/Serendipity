import { PrismaClient, Record, Prisma } from '@prisma/client';
import { CreateRecordDto, UpdateRecordDto } from '../types/record.dto';
import { toJsonValue } from '../utils/prisma-json';

const recordSyncSelect = {
  id: true,
  userId: true,
  sourceDeviceId: true,
  timestamp: true,
  location: true,
  description: true,
  tags: true,
  emotion: true,
  status: true,
  storyLineId: true,
  ifReencounter: true,
  conversationStarter: true,
  backgroundMusic: true,
  weather: true,
  isPinned: true,
  createdAt: true,
  updatedAt: true,
  deletedAt: true,
} satisfies Prisma.RecordSelect;

type RecordSyncRow = Prisma.RecordGetPayload<{
  select: typeof recordSyncSelect;
}>;

/**
 * Record Repository 接口
 * 负责记录数据的持久化操作
 */
export interface IRecordRepository {
  /**
   * 创建或更新记录（使用 upsert）
   * @param userId - 用户 ID
   * @param data - 记录数据
   * @returns 创建或更新的记录
   */
  create(userId: string, data: CreateRecordDto): Promise<Record>;
  
  /**
   * 批量创建或更新记录（使用事务）
   * @param userId - 用户 ID
   * @param records - 记录数据数组
   * @returns 成功创建的记录数组
   */
  batchCreate(userId: string, records: CreateRecordDto[]): Promise<Record[]>;
  
  /**
   * 根据 ID 查找记录
   * @param id - 记录 ID
   * @param userId - 用户 ID
   * @returns 记录对象，不存在则返回 null
   */
  findById(id: string, userId: string): Promise<Record | null>;
  
  /**
   * 根据用户 ID 查找记录列表（支持增量同步和分页）
   * @param userId - 用户 ID
   * @param lastSyncTime - 最后同步时间（可选）
   * @param limit - 每页数量（默认 100）
   * @param offset - 偏移量（默认 0）
   * @returns 记录列表和总数
   */
  findByUserId(
    scope: { userId: string },
    lastSyncTime?: Date,
    limit?: number,
    offset?: number
  ): Promise<{ records: RecordSyncRow[]; total: number }>;
  
  /**
   * 筛选记录（支持多条件组合）
   * @param userId - 用户 ID
   * @param filters - 筛选条件
   * @returns 筛选结果和总数
   */
  findByFilters(
    userId: string,
    filters: {
      startDate?: Date;
      endDate?: Date;
      province?: string;
      city?: string;
      area?: string;
      placeNameKeywords?: string[];
      descriptionKeywords?: string[];
      ifReencounterKeywords?: string[];
      conversationStarterKeywords?: string[];
      backgroundMusicKeywords?: string[];
      placeTypes?: string[];
      statuses?: string[];
      emotionIntensities?: string[];
      weathers?: string[];
      tags?: string[];
      tagMatchMode?: 'wholeWord' | 'contains';
      sortBy?: 'createdAt' | 'updatedAt';
      sortOrder?: 'asc' | 'desc';
      limit: number;
      offset: number;
    }
  ): Promise<{ records: Record[]; total: number }>;
  
  /**
   * 批量根据 ID 列表查找记录（跨用户，用于收藏有效性检查）
   * @param ids - 记录 ID 列表
   * @returns 存在的记录列表
   */
  findManyByIds(ids: string[]): Promise<Record[]>;

  /**
   * @returns 更新后的记录
   * @note 权限验证应在 Service 层完成
   */
  update(id: string, data: UpdateRecordDto): Promise<Record>;
  
  /**
   * 删除记录（墓碑化）
   * @param id - 记录 ID
   * @param deletedAt - 删除时间
   * @note 权限验证应在 Service 层完成
   */
  delete(id: string, deletedAt: Date): Promise<void>;
}

/**
 * Record Repository 实现
 * 负责记录数据的持久化操作
 */
export class RecordRepository implements IRecordRepository {
  // 字段名映射表：Prisma 字段名 -> 数据库列名
  private readonly dbColumnMap: { [key: string]: string } = {
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  };

  constructor(private prisma: PrismaClient) {}

  private getDbColumnName(fieldName: string): string {
    if (!this.dbColumnMap[fieldName]) {
      throw new Error(`Unknown field name: ${fieldName}`);
    }
    return this.dbColumnMap[fieldName];
  }

  /**
   * 创建或更新记录（使用 upsert）
   * 如果记录已存在则更新，否则创建新记录
   */
  async create(userId: string, data: CreateRecordDto): Promise<Record> {
    return this.prisma.record.upsert({
      where: { id: data.id },
      update: {
        sourceDeviceId: data.sourceDeviceId,
        timestamp: new Date(data.timestamp),
        location: toJsonValue(data.location),
        description: data.description,
        tags: toJsonValue(data.tags),
        emotion: data.emotion,
        status: data.status,
        storyLineId: data.storyLineId,
        ifReencounter: data.ifReencounter,
        conversationStarter: data.conversationStarter,
        backgroundMusic: data.backgroundMusic,
        weather: toJsonValue(data.weather),
        isPinned: data.isPinned,
        updatedAt: new Date(data.updatedAt),
        deletedAt: data.deletedAt ? new Date(data.deletedAt) : null,
      },
      create: {
        id: data.id,
        userId,
        sourceDeviceId: data.sourceDeviceId,
        timestamp: new Date(data.timestamp),
        location: toJsonValue(data.location),
        description: data.description,
        tags: toJsonValue(data.tags),
        emotion: data.emotion,
        status: data.status,
        storyLineId: data.storyLineId,
        ifReencounter: data.ifReencounter,
        conversationStarter: data.conversationStarter,
        backgroundMusic: data.backgroundMusic,
        weather: toJsonValue(data.weather),
        isPinned: data.isPinned,
        createdAt: new Date(data.createdAt),
        updatedAt: new Date(data.updatedAt),
        deletedAt: data.deletedAt ? new Date(data.deletedAt) : null,
      },
    });
  }

  /**
   * 批量创建或更新记录（使用事务）
   * 性能优化：使用 Prisma 事务批量处理，避免 N+1 问题
   */
  async batchCreate(userId: string, records: CreateRecordDto[]): Promise<Record[]> {
    return this.prisma.$transaction(
      records.map((data) =>
        this.prisma.record.upsert({
          where: { id: data.id },
          update: {
            sourceDeviceId: data.sourceDeviceId,
            timestamp: new Date(data.timestamp),
            location: toJsonValue(data.location),
            description: data.description,
            tags: toJsonValue(data.tags),
            emotion: data.emotion,
            status: data.status,
            storyLineId: data.storyLineId,
            ifReencounter: data.ifReencounter,
            conversationStarter: data.conversationStarter,
            backgroundMusic: data.backgroundMusic,
            weather: toJsonValue(data.weather),
            isPinned: data.isPinned,
            updatedAt: new Date(data.updatedAt),
            deletedAt: data.deletedAt ? new Date(data.deletedAt) : null,
          },
          create: {
            id: data.id,
            userId,
            sourceDeviceId: data.sourceDeviceId,
            timestamp: new Date(data.timestamp),
            location: toJsonValue(data.location),
            description: data.description,
            tags: toJsonValue(data.tags),
            emotion: data.emotion,
            status: data.status,
            storyLineId: data.storyLineId,
            ifReencounter: data.ifReencounter,
            conversationStarter: data.conversationStarter,
            backgroundMusic: data.backgroundMusic,
            weather: toJsonValue(data.weather),
            isPinned: data.isPinned,
            createdAt: new Date(data.createdAt),
            updatedAt: new Date(data.updatedAt),
            deletedAt: data.deletedAt ? new Date(data.deletedAt) : null,
          },
        })
      )
    );
  }

  async findById(id: string, userId: string): Promise<Record | null> {
    return this.prisma.record.findFirst({
      where: { id, userId, deletedAt: null },
    });
  }

  async findByUserId(
    scope: { userId: string },
    lastSyncTime?: Date,
    limit: number = 100,
    offset: number = 0
  ): Promise<{ records: RecordSyncRow[]; total: number }> {
    const where = {
      userId: scope.userId,
      ...(lastSyncTime && { updatedAt: { gt: lastSyncTime } }),
    };

    const [records, total] = await Promise.all([
      this.prisma.record.findMany({
        where,
        select: recordSyncSelect,
        orderBy: { updatedAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.record.count({ where }),
    ]);

    return { records, total };
  }

  async findByFilters(
    userId: string,
    filters: {
      startDate?: Date;
      endDate?: Date;
      province?: string;
      city?: string;
      area?: string;
      placeNameKeywords?: string[];
      descriptionKeywords?: string[];
      ifReencounterKeywords?: string[];
      conversationStarterKeywords?: string[];
      backgroundMusicKeywords?: string[];
      placeTypes?: string[];
      statuses?: string[];
      emotionIntensities?: string[];
      weathers?: string[];
      tags?: string[];
      tagMatchMode?: 'wholeWord' | 'contains';
      sortBy?: 'createdAt' | 'updatedAt';
      sortOrder?: 'asc' | 'desc';
      limit: number;
      offset: number;
    }
  ): Promise<{ records: Record[]; total: number }> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId cannot be empty');
    }
    if (filters.limit <= 0) {
      throw new Error('limit must be positive');
    }
    if (filters.offset < 0) {
      throw new Error('offset cannot be negative');
    }
    if (filters.startDate && filters.endDate && filters.startDate > filters.endDate) {
      throw new Error('startDate must be before endDate');
    }

    const conditions: Prisma.Sql[] = [];
    conditions.push(Prisma.sql`user_id = ${userId}`);
    conditions.push(Prisma.sql`deleted_at IS NULL`);

    if (filters.startDate) {
      conditions.push(Prisma.sql`timestamp >= ${filters.startDate}`);
    }
    if (filters.endDate) {
      conditions.push(Prisma.sql`timestamp <= ${filters.endDate}`);
    }
    if (filters.province) {
      conditions.push(Prisma.sql`location->>'province' = ${filters.province}`);
    }
    if (filters.city) {
      conditions.push(Prisma.sql`location->>'city' = ${filters.city}`);
    }
    if (filters.area) {
      conditions.push(Prisma.sql`location->>'area' = ${filters.area}`);
    }
    if (filters.placeNameKeywords && filters.placeNameKeywords.length > 0) {
      const placeNameConditions = filters.placeNameKeywords.map(
        (keyword) => Prisma.sql`COALESCE(location->>'placeName', '') ILIKE ${`%${keyword}%`}`
      );
      conditions.push(Prisma.sql`(${Prisma.join(placeNameConditions, ' OR ')})`);
    }

    if (filters.descriptionKeywords && filters.descriptionKeywords.length > 0) {
      const descriptionConditions = filters.descriptionKeywords.map(
        (keyword) => Prisma.sql`COALESCE(description, '') ILIKE ${`%${keyword}%`}`
      );
      conditions.push(Prisma.sql`(${Prisma.join(descriptionConditions, ' OR ')})`);
    }

    if (filters.ifReencounterKeywords && filters.ifReencounterKeywords.length > 0) {
      const ifReencounterConditions = filters.ifReencounterKeywords.map(
        (keyword) => Prisma.sql`COALESCE(if_reencounter, '') ILIKE ${`%${keyword}%`}`
      );
      conditions.push(Prisma.sql`(${Prisma.join(ifReencounterConditions, ' OR ')})`);
    }

    if (filters.conversationStarterKeywords && filters.conversationStarterKeywords.length > 0) {
      const conversationStarterConditions = filters.conversationStarterKeywords.map(
        (keyword) => Prisma.sql`COALESCE(conversation_starter, '') ILIKE ${`%${keyword}%`}`
      );
      conditions.push(Prisma.sql`(${Prisma.join(conversationStarterConditions, ' OR ')})`);
    }

    if (filters.backgroundMusicKeywords && filters.backgroundMusicKeywords.length > 0) {
      const backgroundMusicConditions = filters.backgroundMusicKeywords.map(
        (keyword) => Prisma.sql`COALESCE(background_music, '') ILIKE ${`%${keyword}%`}`
      );
      conditions.push(Prisma.sql`(${Prisma.join(backgroundMusicConditions, ' OR ')})`);
    }

    if (filters.placeTypes && filters.placeTypes.length > 0) {
      const placeTypeConditions = filters.placeTypes.map(
        (type) => Prisma.sql`location->>'placeType' = ${type}`
      );
      conditions.push(Prisma.sql`(${Prisma.join(placeTypeConditions, ' OR ')})`);
    }

    if (filters.statuses && filters.statuses.length > 0) {
      const statusConditions = filters.statuses.map(
        (status) => Prisma.sql`status = ${status}`
      );
      conditions.push(Prisma.sql`(${Prisma.join(statusConditions, ' OR ')})`);
    }

    if (filters.emotionIntensities && filters.emotionIntensities.length > 0) {
      const emotionConditions = filters.emotionIntensities.map(
        (emotion) => Prisma.sql`emotion = ${emotion}`
      );
      conditions.push(Prisma.sql`(${Prisma.join(emotionConditions, ' OR ')})`);
    }

    if (filters.weathers && filters.weathers.length > 0) {
      const weatherConditions = filters.weathers.map(
        (weather) => Prisma.sql`weather @> ${JSON.stringify([weather])}`
      );
      conditions.push(Prisma.sql`(${Prisma.join(weatherConditions, ' OR ')})`);
    }

    if (filters.tags && filters.tags.length > 0) {
      const tagMatchMode = filters.tagMatchMode || 'contains';
      const tagConditions = filters.tags.map(tag => {
        if (tagMatchMode === 'wholeWord') {
          return Prisma.sql`EXISTS (
            SELECT 1 FROM jsonb_array_elements(tags) AS t
            WHERE t->>'tag' = ${tag}
          )`;
        }
        return Prisma.sql`EXISTS (
          SELECT 1 FROM jsonb_array_elements(tags) AS t
          WHERE t->>'tag' ILIKE ${`%${tag}%`}
        )`;
      });
      conditions.push(Prisma.sql`(${Prisma.join(tagConditions, ' OR ')})`);
    }

    const sortBy = filters.sortBy || 'createdAt';
    const sortOrder = filters.sortOrder || 'desc';
    const dbColumnName = this.getDbColumnName(sortBy);
    const whereClause = Prisma.sql`WHERE ${Prisma.join(conditions, ' AND ')}`;

    const query = Prisma.sql`
      SELECT 
        id,
        user_id as "userId",
        timestamp,
        location,
        description,
        tags,
        emotion,
        status,
        story_line_id as "storyLineId",
        if_reencounter as "ifReencounter",
        conversation_starter as "conversationStarter",
        background_music as "backgroundMusic",
        weather,
        is_pinned as "isPinned",
        created_at as "createdAt",
        updated_at as "updatedAt",
        deleted_at as "deletedAt"
      FROM "records"
      ${whereClause}
      ORDER BY ${Prisma.raw(dbColumnName)} ${Prisma.raw(sortOrder.toUpperCase())}
      LIMIT ${filters.limit}
      OFFSET ${filters.offset}
    `;

    const countQuery = Prisma.sql`
      SELECT COUNT(*)::int as total
      FROM "records"
      ${whereClause}
    `;

    const [records, countResult] = await Promise.all([
      this.prisma.$queryRaw<Record[]>(query),
      this.prisma.$queryRaw<Array<{ total: number }>>(countQuery),
    ]);

    return {
      records,
      total: countResult[0]?.total ?? 0,
    };
  }

  async findManyByIds(ids: string[]): Promise<Record[]> {
    if (ids.length === 0) {
      return [];
    }

    return this.prisma.record.findMany({
      where: {
        id: { in: ids },
        deletedAt: null,
      },
    });
  }

  async update(id: string, data: UpdateRecordDto): Promise<Record> {
    const updateData: Prisma.RecordUncheckedUpdateInput = {
      updatedAt: new Date(data.updatedAt),
    };

    if (data.timestamp !== undefined) updateData.timestamp = new Date(data.timestamp);
    if (data.location !== undefined) updateData.location = toJsonValue(data.location);
    if (data.description !== undefined) updateData.description = data.description;
    if (data.tags !== undefined) updateData.tags = toJsonValue(data.tags);
    if (data.emotion !== undefined) updateData.emotion = data.emotion;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.storyLineId !== undefined) updateData.storyLineId = data.storyLineId;
    if (data.ifReencounter !== undefined) updateData.ifReencounter = data.ifReencounter;
    if (data.conversationStarter !== undefined) updateData.conversationStarter = data.conversationStarter;
    if (data.backgroundMusic !== undefined) updateData.backgroundMusic = data.backgroundMusic;
    if (data.weather !== undefined) updateData.weather = toJsonValue(data.weather);
    if (data.isPinned !== undefined) updateData.isPinned = data.isPinned;
    if (data.deletedAt !== undefined) {
      updateData.deletedAt = data.deletedAt == null ? null : new Date(data.deletedAt);
    }

    return this.prisma.record.update({
      where: { id },
      data: updateData,
    });
  }
  
  async delete(id: string, deletedAt: Date): Promise<void> {
    await this.prisma.record.update({
      where: { id },
      data: {
        deletedAt,
        updatedAt: deletedAt,
      },
    });
  }
}
