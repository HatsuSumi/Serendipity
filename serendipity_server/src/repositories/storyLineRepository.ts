import { PrismaClient, StoryLine } from '@prisma/client';
import {
  CreateStoryLineDto,
  UpdateStoryLineDto,
} from '../types/storyline.dto';
import { toJsonValue } from '../utils/prisma-json';

// StoryLine Repository 接口
export interface IStoryLineRepository {
  create(userId: string, data: CreateStoryLineDto): Promise<StoryLine>;
  findById(id: string, userId: string): Promise<StoryLine | null>;
  findByUserId(
    userId: string,
    lastSyncTime?: Date,
    limit?: number,
    offset?: number
  ): Promise<{ storylines: StoryLine[]; total: number }>;
  update(
    id: string,
    userId: string,
    data: UpdateStoryLineDto
  ): Promise<StoryLine>;
  delete(id: string, userId: string): Promise<void>;
  countByUserId(userId: string, lastSyncTime?: Date): Promise<number>;
}

// StoryLine Repository 实现
export class StoryLineRepository implements IStoryLineRepository {
  constructor(private prisma: PrismaClient) {}

  async create(userId: string, data: CreateStoryLineDto): Promise<StoryLine> {
    return this.prisma.storyLine.upsert({
      where: { id: data.id },
      update: {
        name: data.name,
        recordIds: toJsonValue(data.recordIds),
        updatedAt: new Date(data.updatedAt),
      },
      create: {
        id: data.id,
        userId,
        name: data.name,
        recordIds: toJsonValue(data.recordIds),
        createdAt: new Date(data.createdAt),
        updatedAt: new Date(data.updatedAt),
      },
    });
  }

  async findById(id: string, userId: string): Promise<StoryLine | null> {
    return this.prisma.storyLine.findFirst({
      where: { id, userId },
    });
  }

  async findByUserId(
    userId: string,
    lastSyncTime?: Date,
    limit: number = 100,
    offset: number = 0
  ): Promise<{ storylines: StoryLine[]; total: number }> {
    const where = {
      userId,
      ...(lastSyncTime && { updatedAt: { gt: lastSyncTime } }),
    };

    const [storylines, total] = await Promise.all([
      this.prisma.storyLine.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.storyLine.count({ where }),
    ]);

    return { storylines, total };
  }

  async update(
    id: string,
    userId: string,
    data: UpdateStoryLineDto
  ): Promise<StoryLine> {
    return this.prisma.storyLine.update({
      where: { id, userId },
      data: {
        ...(data.name && { name: data.name }),
        ...(data.recordIds && { recordIds: toJsonValue(data.recordIds) }),
        updatedAt: new Date(data.updatedAt),
      },
    });
  }

  async delete(id: string, userId: string): Promise<void> {
    await this.prisma.storyLine.delete({
      where: { id, userId },
    });
  }

  async countByUserId(userId: string, lastSyncTime?: Date): Promise<number> {
    return this.prisma.storyLine.count({
      where: {
        userId,
        ...(lastSyncTime && { updatedAt: { gt: lastSyncTime } }),
      },
    });
  }
}

