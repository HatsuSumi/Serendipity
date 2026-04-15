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
import { FailFastValidator } from '../utils/validation';
import { logger } from '../utils/logger';

/**
 * StoryLine Service 接口
 * 负责故事线相关的业务逻辑
 */
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

/**
 * StoryLine Service 实现
 * 负责故事线相关的业务逻辑处理
 */
export class StoryLineService implements IStoryLineService {
  constructor(
    private storyLineRepository: IStoryLineRepository,
  ) {}

  /**
   * 创建新故事线
   *
   * 安全边界：
   * - 同 ID 不存在：创建
   * - 同 ID 且属于当前用户：视为同步更新
   * - 同 ID 但属于其他用户：拒绝，防止跨用户覆盖
   */
  async createStoryLine(
    userId: string,
    data: CreateStoryLineDto
  ): Promise<StoryLineResponseDto> {
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateNonNullObject(data, 'data');
    FailFastValidator.validateUUID(data.id, 'data.id');

    const existingStoryLine = await this.storyLineRepository.findByIdGlobal(data.id);

    if (existingStoryLine == null) {
      const createdStoryLine = await this.storyLineRepository.create(userId, data);
      return this.toResponseDto(createdStoryLine);
    }

    if (existingStoryLine.userId !== userId) {
      throw new AppError(
        `故事线 ID 已被其他用户占用: ${data.id}`,
        ErrorCode.CONFLICT
      );
    }

    const updatedStoryLine = await this.storyLineRepository.update(data.id, {
      name: data.name,
      recordIds: data.recordIds,
      isPinned: data.isPinned,
      updatedAt: data.updatedAt,
      deletedAt: data.deletedAt,
    });

    return this.toResponseDto(updatedStoryLine);
  }

  /**
   * 批量创建故事线
   *
   * 安全边界：
   * - 先逐条验证归属，发现跨用户冲突直接整体失败
   * - 同用户已存在的记录走 update，不存在的记录走 create
   */
  async batchCreateStoryLines(
    userId: string,
    data: BatchCreateStoryLinesDto
  ): Promise<BatchCreateStoryLinesResponseDto> {
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateNonNullObject(data, 'data');
    FailFastValidator.validateNonEmptyArray(data.storyLines, 'data.storyLines');

    try {
      for (const storyLine of data.storyLines) {
        FailFastValidator.validateUUID(storyLine.id, 'storyLine.id');
        const existingStoryLine = await this.storyLineRepository.findByIdGlobal(storyLine.id);

        if (existingStoryLine != null && existingStoryLine.userId !== userId) {
          throw new AppError(
            `故事线 ID 已被其他用户占用: ${storyLine.id}`,
            ErrorCode.CONFLICT
          );
        }
      }

      const toCreate = [] as CreateStoryLineDto[];
      const toUpdate = [] as CreateStoryLineDto[];

      for (const storyLine of data.storyLines) {
        const existingStoryLine = await this.storyLineRepository.findByIdGlobal(storyLine.id);
        if (existingStoryLine == null) {
          toCreate.push(storyLine);
        } else {
          toUpdate.push(storyLine);
        }
      }

      if (toCreate.length > 0) {
        await this.storyLineRepository.batchCreate(userId, toCreate);
      }

      for (const storyLine of toUpdate) {
        await this.storyLineRepository.update(storyLine.id, {
          name: storyLine.name,
          recordIds: storyLine.recordIds,
          isPinned: storyLine.isPinned,
          updatedAt: storyLine.updatedAt,
          deletedAt: storyLine.deletedAt,
        });
      }

      return {
        total: data.storyLines.length,
        succeeded: data.storyLines.length,
        failed: 0,
        syncedAt: new Date(),
      };
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }

      const errorMessage = error instanceof Error ? error.message : 'Unknown error';

      logger.error('批量创建故事线失败', {
        userId,
        total: data.storyLines.length,
        error: errorMessage,
      });

      return {
        total: data.storyLines.length,
        succeeded: 0,
        failed: data.storyLines.length,
        syncedAt: new Date(),
      };
    }
  }

  /**
   * 获取故事线列表（支持增量同步）
   */
  async getStoryLines(
    userId: string,
    lastSyncTime?: string,
    limit: number = 100,
    offset: number = 0
  ): Promise<GetStoryLinesResponseDto> {
    FailFastValidator.validateNonEmptyString(userId, 'userId');

    const scope = { userId };
    const lastSyncDate = lastSyncTime ? new Date(lastSyncTime) : undefined;

    const { storylines, total } =
      await this.storyLineRepository.findByUserId(
        scope,
        lastSyncDate,
        limit,
        offset
      );

    return {
      storyLines: storylines.map((storyline) =>
        this.toResponseDto(storyline)
      ),
      total,
      hasMore: offset + storylines.length < total,
      syncTime: new Date(),
    };
  }

  /**
   * 更新故事线
   */
  async updateStoryLine(
    userId: string,
    id: string,
    data: UpdateStoryLineDto
  ): Promise<StoryLineResponseDto> {
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateUUID(id, 'id');
    FailFastValidator.validateNonNullObject(data, 'data');

    const existingStoryLine = await this.storyLineRepository.findById(
      id,
      userId
    );
    if (!existingStoryLine) {
      throw new AppError(
        `故事线不存在: ${id}`,
        ErrorCode.NOT_FOUND
      );
    }

    const storyline = await this.storyLineRepository.update(id, data);
    return this.toResponseDto(storyline);
  }

  /**
   * 删除故事线
   */
  async deleteStoryLine(userId: string, id: string): Promise<void> {
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateUUID(id, 'id');

    const existingStoryLine = await this.storyLineRepository.findById(
      id,
      userId
    );
    if (!existingStoryLine) {
      throw new AppError(
        `故事线不存在: ${id}`,
        ErrorCode.NOT_FOUND
      );
    }

    await this.storyLineRepository.delete(id, new Date());
  }

  private toResponseDto(storyline: StoryLine): StoryLineResponseDto {
    return {
      id: storyline.id,
      userId: storyline.userId,
      name: storyline.name,
      recordIds: fromJsonValue<string[]>(storyline.recordIds),
      isPinned: storyline.isPinned,
      createdAt: storyline.createdAt,
      updatedAt: storyline.updatedAt,
      deletedAt: storyline.deletedAt || undefined,
    };
  }
}
