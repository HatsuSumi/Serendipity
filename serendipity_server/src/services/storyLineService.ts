import { StoryLine } from '@prisma/client';
import { IStoryLineRepository } from '../repositories/storyLineRepository';
import {
  CreateStoryLineDto,
  UpdateStoryLineDto,
  BatchCreateStoryLinesDto,
  StoryLineResponseDto,
  BatchCreateStoryLinesResponseDto,
  GetStoryLinesResponseDto,
} from '../types/storyline.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { fromJsonValue } from '../utils/prisma-json';

// StoryLine Service 接口
export interface IStoryLineService {
  createStoryLine(
    userId: string,
    data: CreateStoryLineDto
  ): Promise<StoryLineResponseDto>;
  batchCreateStoryLines(
    userId: string,
    data: BatchCreateStoryLinesDto
  ): Promise<BatchCreateStoryLinesResponseDto>;
  getStoryLines(
    userId: string,
    lastSyncTime?: string,
    limit?: number,
    offset?: number
  ): Promise<GetStoryLinesResponseDto>;
  updateStoryLine(
    userId: string,
    id: string,
    data: UpdateStoryLineDto
  ): Promise<StoryLineResponseDto>;
  deleteStoryLine(userId: string, id: string): Promise<void>;
}

// StoryLine Service 实现
export class StoryLineService implements IStoryLineService {
  constructor(private storyLineRepository: IStoryLineRepository) {}

  async createStoryLine(
    userId: string,
    data: CreateStoryLineDto
  ): Promise<StoryLineResponseDto> {
    const storyline = await this.storyLineRepository.create(userId, data);
    return this.toResponseDto(storyline);
  }

  async batchCreateStoryLines(
    userId: string,
    data: BatchCreateStoryLinesDto
  ): Promise<BatchCreateStoryLinesResponseDto> {
    let succeeded = 0;
    let failed = 0;

    for (const storylineData of data.storylines) {
      try {
        await this.storyLineRepository.create(userId, storylineData);
        succeeded++;
      } catch (error) {
        failed++;
        // 继续处理其他故事线，不中断批量操作
      }
    }

    return {
      total: data.storylines.length,
      succeeded,
      failed,
      syncedAt: new Date(),
    };
  }

  async getStoryLines(
    userId: string,
    lastSyncTime?: string,
    limit: number = 100,
    offset: number = 0
  ): Promise<GetStoryLinesResponseDto> {
    const lastSyncDate = lastSyncTime ? new Date(lastSyncTime) : undefined;

    const { storylines, total } =
      await this.storyLineRepository.findByUserId(
        userId,
        lastSyncDate,
        limit,
        offset
      );

    return {
      storylines: storylines.map((storyline) =>
        this.toResponseDto(storyline)
      ),
      total,
      hasMore: offset + storylines.length < total,
      syncTime: new Date(),
    };
  }

  async updateStoryLine(
    userId: string,
    id: string,
    data: UpdateStoryLineDto
  ): Promise<StoryLineResponseDto> {
    // 检查故事线是否存在
    const existingStoryLine = await this.storyLineRepository.findById(
      id,
      userId
    );
    if (!existingStoryLine) {
      throw new AppError('StoryLine not found', ErrorCode.NOT_FOUND);
    }

    const storyline = await this.storyLineRepository.update(userId, id, data);
    return this.toResponseDto(storyline);
  }

  async deleteStoryLine(userId: string, id: string): Promise<void> {
    // 检查故事线是否存在
    const existingStoryLine = await this.storyLineRepository.findById(
      id,
      userId
    );
    if (!existingStoryLine) {
      throw new AppError('StoryLine not found', ErrorCode.NOT_FOUND);
    }

    await this.storyLineRepository.delete(id, userId);
  }

  // 将 Prisma StoryLine 转换为 DTO
  private toResponseDto(storyline: StoryLine): StoryLineResponseDto {
    return {
      id: storyline.id,
      userId: storyline.userId,
      name: storyline.name,
      recordIds: fromJsonValue<string[]>(storyline.recordIds),
      createdAt: storyline.createdAt,
      updatedAt: storyline.updatedAt,
    };
  }
}

