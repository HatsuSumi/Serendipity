import { PrismaClient, Record } from '@prisma/client';
import { CreateRecordDto, UpdateRecordDto } from '../types/record.dto';
import { toJsonValue } from '../utils/prisma-json';

// Record Repository 接口
export interface IRecordRepository {
  create(userId: string, data: CreateRecordDto): Promise<Record>;
  findById(id: string, userId: string): Promise<Record | null>;
  findByUserId(
    userId: string,
    lastSyncTime?: Date,
    limit?: number,
    offset?: number
  ): Promise<{ records: Record[]; total: number }>;
  update(id: string, userId: string, data: UpdateRecordDto): Promise<Record>;
  delete(id: string, userId: string): Promise<void>;
  countByUserId(userId: string, lastSyncTime?: Date): Promise<number>;
}

// Record Repository 实现
export class RecordRepository implements IRecordRepository {
  constructor(private prisma: PrismaClient) {}

  async create(userId: string, data: CreateRecordDto): Promise<Record> {
    return this.prisma.record.create({
      data: {
        id: data.id,
        userId,
        timestamp: data.timestamp,
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
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
      },
    });
  }

  async findById(id: string, userId: string): Promise<Record | null> {
    return this.prisma.record.findFirst({
      where: { id, userId },
    });
  }

  async findByUserId(
    userId: string,
    lastSyncTime?: Date,
    limit: number = 100,
    offset: number = 0
  ): Promise<{ records: Record[]; total: number }> {
    const where = {
      userId,
      ...(lastSyncTime && { updatedAt: { gt: lastSyncTime } }),
    };

    const [records, total] = await Promise.all([
      this.prisma.record.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.record.count({ where }),
    ]);

    return { records, total };
  }

  async update(
    id: string,
    userId: string,
    data: UpdateRecordDto
  ): Promise<Record> {
    const updateData: any = {
      updatedAt: data.updatedAt,
    };

    if (data.timestamp) updateData.timestamp = data.timestamp;
    if (data.location) updateData.location = toJsonValue(data.location);
    if (data.description !== undefined) updateData.description = data.description;
    if (data.tags) updateData.tags = toJsonValue(data.tags);
    if (data.emotion !== undefined) updateData.emotion = data.emotion;
    if (data.status) updateData.status = data.status;
    if (data.storyLineId !== undefined) updateData.storyLineId = data.storyLineId;
    if (data.ifReencounter !== undefined) updateData.ifReencounter = data.ifReencounter;
    if (data.conversationStarter !== undefined) updateData.conversationStarter = data.conversationStarter;
    if (data.backgroundMusic !== undefined) updateData.backgroundMusic = data.backgroundMusic;
    if (data.weather) updateData.weather = toJsonValue(data.weather);
    if (data.isPinned !== undefined) updateData.isPinned = data.isPinned;

    return this.prisma.record.update({
      where: { id, userId },
      data: updateData,
    });
  }

  async delete(id: string, userId: string): Promise<void> {
    await this.prisma.record.delete({
      where: { id, userId },
    });
  }

  async countByUserId(userId: string, lastSyncTime?: Date): Promise<number> {
    return this.prisma.record.count({
      where: {
        userId,
        ...(lastSyncTime && { updatedAt: { gt: lastSyncTime } }),
      },
    });
  }
}

