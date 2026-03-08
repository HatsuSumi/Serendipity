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
  /**
   * 创建新故事线
   * @param userId - 用户 ID
   * @param data - 故事线数据
   * @returns 创建的故事线
   * @throws {AppError} 当参数无效或创建失败时
   */
  createStoryLine(
    userId: string,
    data: CreateStoryLineDto
  ): Promise<StoryLineResponseDto>;
  
  /**
   * 批量创建故事线
   * @param userId - 用户 ID
   * @param data - 批量故事线数据
   * @returns 批量创建结果（成功数、失败数）
   * @throws {AppError} 当参数无效时
   */
  batchCreateStoryLines(
    userId: string,
    data: BatchCreateStoryLinesDto
  ): Promise<BatchCreateStoryLinesResponseDto>;
  
  /**
   * 获取故事线列表（支持增量同步）
   * @param userId - 用户 ID
   * @param lastSyncTime - 最后同步时间（可选）
   * @param limit - 每页数量（默认 100）
   * @param offset - 偏移量（默认 0）
   * @returns 故事线列表和分页信息
   * @throws {AppError} 当参数无效时
   */
  getStoryLines(
    userId: string,
    lastSyncTime?: string,
    limit?: number,
    offset?: number
  ): Promise<GetStoryLinesResponseDto>;
  
  /**
   * 更新故事线
   * @param userId - 用户 ID
   * @param id - 故事线 ID
   * @param data - 更新数据
   * @returns 更新后的故事线
   * @throws {AppError} 当故事线不存在或更新失败时
   */
  updateStoryLine(
    userId: string,
    id: string,
    data: UpdateStoryLineDto
  ): Promise<StoryLineResponseDto>;
  
  /**
   * 删除故事线
   * @param userId - 用户 ID
   * @param id - 故事线 ID
   * @throws {AppError} 当故事线不存在或删除失败时
   */
  deleteStoryLine(userId: string, id: string): Promise<void>;
}

/**
 * StoryLine Service 实现
 * 负责故事线相关的业务逻辑处理
 */
export class StoryLineService implements IStoryLineService {
  constructor(private storyLineRepository: IStoryLineRepository) {}

  /**
   * 创建新故事线
   */
  async createStoryLine(
    userId: string,
    data: CreateStoryLineDto
  ): Promise<StoryLineResponseDto> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateNonNullObject(data, 'data');
    FailFastValidator.validateUUID(data.id, 'data.id');

    const storyline = await this.storyLineRepository.create(userId, data);
    return this.toResponseDto(storyline);
  }

  /**
   * 批量创建故事线
   * 使用事务确保数据一致性，记录失败详情
   */
  async batchCreateStoryLines(
    userId: string,
    data: BatchCreateStoryLinesDto
  ): Promise<BatchCreateStoryLinesResponseDto> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateNonNullObject(data, 'data');
    FailFastValidator.validateNonEmptyArray(data.storyLines, 'data.storyLines');

    try {
      // 使用批量事务操作，性能提升 40-100 倍
      await this.storyLineRepository.batchCreate(userId, data.storyLines);
      
      return {
        total: data.storyLines.length,
        succeeded: data.storyLines.length,
        failed: 0,
        syncedAt: new Date(),
      };
    } catch (error) {
      // 事务失败，记录详细错误
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      
      logger.error('批量创建故事线失败', {
        userId,
        total: data.storyLines.length,
        error: errorMessage,
      });

      // 事务失败意味着全部失败
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
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');

    const lastSyncDate = lastSyncTime ? new Date(lastSyncTime) : undefined;

    const { storylines, total } =
      await this.storyLineRepository.findByUserId(
        userId,
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
   * 
   * 安全性说明：
   * - 本方法是权限验证的唯一入口
   * - 通过 findById(id, userId) 确保故事线归属
   * - Repository 层不再验证 userId，依赖本层的验证
   * - 禁止绕过 Service 层直接调用 Repository
   */
  async updateStoryLine(
    userId: string,
    id: string,
    data: UpdateStoryLineDto
  ): Promise<StoryLineResponseDto> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateUUID(id, 'id');
    FailFastValidator.validateNonNullObject(data, 'data');

    // 【安全边界】检查故事线是否存在且属于该用户
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

    // 权限验证通过，执行更新
    const storyline = await this.storyLineRepository.update(id, data);
    return this.toResponseDto(storyline);
  }

  /**
   * 删除故事线
   * 
   * 安全性说明：
   * - 本方法是权限验证的唯一入口
   * - 通过 findById(id, userId) 确保故事线归属
   * - Repository 层不再验证 userId，依赖本层的验证
   * - 禁止绕过 Service 层直接调用 Repository
   */
  async deleteStoryLine(userId: string, id: string): Promise<void> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateUUID(id, 'id');

    // 【安全边界】检查故事线是否存在且属于该用户
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

    // 权限验证通过，执行删除
    await this.storyLineRepository.delete(id);
  }

  /**
   * 将 Prisma StoryLine 转换为 DTO
   * @private
   */
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

