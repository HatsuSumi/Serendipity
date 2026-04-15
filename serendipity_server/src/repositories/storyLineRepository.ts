import { PrismaClient, StoryLine, Prisma } from '@prisma/client';
import {
  CreateStoryLineDto,
  UpdateStoryLineDto,
} from '../types/storyline.dto';
import { toJsonValue } from '../utils/prisma-json';

const storyLineSyncSelect = {
  id: true,
  userId: true,
  sourceDeviceId: true,
  name: true,
  recordIds: true,
  isPinned: true,
  createdAt: true,
  updatedAt: true,
  deletedAt: true,
} satisfies Prisma.StoryLineSelect;

type StoryLineSyncRow = Prisma.StoryLineGetPayload<{
  select: typeof storyLineSyncSelect;
}>;

/**
 * StoryLine Repository 接口
 * 负责故事线数据的持久化操作
 */
export interface IStoryLineRepository {
  create(userId: string, data: CreateStoryLineDto): Promise<StoryLine>;

  batchCreate(userId: string, storylines: CreateStoryLineDto[]): Promise<StoryLine[]>;

  findByIdGlobal(id: string): Promise<StoryLine | null>;

  findById(id: string, userId: string): Promise<StoryLine | null>;

  findByUserId(
    scope: { userId: string },
    lastSyncTime?: Date,
    limit?: number,
    offset?: number
  ): Promise<{ storylines: StoryLineSyncRow[]; total: number }>;

  update(id: string, data: UpdateStoryLineDto): Promise<StoryLine>;

  delete(id: string, deletedAt: Date): Promise<void>;
}

/**
 * StoryLine Repository 实现
 * 负责故事线数据的持久化操作
 */
export class StoryLineRepository implements IStoryLineRepository {
  constructor(private prisma: PrismaClient) {}

  async create(userId: string, data: CreateStoryLineDto): Promise<StoryLine> {
    return this.prisma.storyLine.create({
      data: {
        id: data.id,
        userId,
        sourceDeviceId: data.sourceDeviceId,
        name: data.name,
        recordIds: toJsonValue(data.recordIds),
        isPinned: data.isPinned,
        createdAt: new Date(data.createdAt),
        updatedAt: new Date(data.updatedAt),
        deletedAt: data.deletedAt ? new Date(data.deletedAt) : null,
      },
    });
  }

  async batchCreate(userId: string, storylines: CreateStoryLineDto[]): Promise<StoryLine[]> {
    return this.prisma.$transaction(
      storylines.map((data) =>
        this.prisma.storyLine.create({
          data: {
            id: data.id,
            userId,
            sourceDeviceId: data.sourceDeviceId,
            name: data.name,
            recordIds: toJsonValue(data.recordIds),
            isPinned: data.isPinned,
            createdAt: new Date(data.createdAt),
            updatedAt: new Date(data.updatedAt),
            deletedAt: data.deletedAt ? new Date(data.deletedAt) : null,
          },
        })
      )
    );
  }

  async findByIdGlobal(id: string): Promise<StoryLine | null> {
    return this.prisma.storyLine.findUnique({
      where: { id },
    });
  }

  async findById(id: string, userId: string): Promise<StoryLine | null> {
    return this.prisma.storyLine.findFirst({
      where: { id, userId, deletedAt: null },
    });
  }

  async findByUserId(
    scope: { userId: string },
    lastSyncTime?: Date,
    limit: number = 100,
    offset: number = 0
  ): Promise<{ storylines: StoryLineSyncRow[]; total: number }> {
    const where = {
      userId: scope.userId,
      ...(lastSyncTime && { updatedAt: { gt: lastSyncTime } }),
    };

    const [storylines, total] = await Promise.all([
      this.prisma.storyLine.findMany({
        where,
        select: storyLineSyncSelect,  
        orderBy: { updatedAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.storyLine.count({ where }),
    ]);

    return { storylines, total };
  }

  async update(id: string, data: UpdateStoryLineDto): Promise<StoryLine> {
    const updateData: Prisma.StoryLineUpdateInput = {
      updatedAt: new Date(data.updatedAt),
    };

    if (data.name !== undefined) {
      updateData.name = data.name;
    }
    if (data.recordIds !== undefined) {
      updateData.recordIds = toJsonValue(data.recordIds);
    }
    if (data.isPinned !== undefined) {
      updateData.isPinned = data.isPinned;
    }
    if (data.deletedAt !== undefined) {
      updateData.deletedAt = data.deletedAt == null ? null : new Date(data.deletedAt);
    }

    return this.prisma.storyLine.update({
      where: { id },
      data: updateData,
    });
  }

  async delete(id: string, deletedAt: Date): Promise<void> {
    await this.prisma.storyLine.update({
      where: { id },
      data: {
        deletedAt,
        updatedAt: deletedAt,
      },
    });
  }
}
