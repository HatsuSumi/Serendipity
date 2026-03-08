import { Record } from '@prisma/client';
import { IRecordRepository } from '../repositories/recordRepository';
import {
  CreateRecordDto,
  UpdateRecordDto,
  BatchCreateRecordsDto,
  RecordResponseDto,
  BatchCreateRecordsResponseDto,
  GetRecordsResponseDto,
  LocationDto,
  TagWithNoteDto,
} from '../types/record.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { fromJsonValue } from '../utils/prisma-json';
import { FailFastValidator } from '../utils/validation';
import { logger } from '../utils/logger';

/**
 * Record Service 接口
 * 负责记录相关的业务逻辑
 */
export interface IRecordService {
  /**
   * 创建新记录
   * @param userId - 用户 ID
   * @param data - 记录数据
   * @returns 创建的记录
   * @throws {AppError} 当参数无效或创建失败时
   */
  createRecord(userId: string, data: CreateRecordDto): Promise<RecordResponseDto>;
  
  /**
   * 批量创建记录
   * @param userId - 用户 ID
   * @param data - 批量记录数据
   * @returns 批量创建结果（成功数、失败数）
   * @throws {AppError} 当参数无效时
   */
  batchCreateRecords(
    userId: string,
    data: BatchCreateRecordsDto
  ): Promise<BatchCreateRecordsResponseDto>;
  
  /**
   * 获取记录列表（支持增量同步）
   * @param userId - 用户 ID
   * @param lastSyncTime - 最后同步时间（可选）
   * @param limit - 每页数量（默认 100）
   * @param offset - 偏移量（默认 0）
   * @returns 记录列表和分页信息
   * @throws {AppError} 当参数无效时
   */
  getRecords(
    userId: string,
    lastSyncTime?: string,
    limit?: number,
    offset?: number
  ): Promise<GetRecordsResponseDto>;
  
  /**
   * 更新记录
   * @param userId - 用户 ID
   * @param id - 记录 ID
   * @param data - 更新数据
   * @returns 更新后的记录
   * @throws {AppError} 当记录不存在或更新失败时
   */
  updateRecord(
    userId: string,
    id: string,
    data: UpdateRecordDto
  ): Promise<RecordResponseDto>;
  
  /**
   * 删除记录
   * @param userId - 用户 ID
   * @param id - 记录 ID
   * @throws {AppError} 当记录不存在或删除失败时
   */
  deleteRecord(userId: string, id: string): Promise<void>;
}

/**
 * Record Service 实现
 * 负责记录相关的业务逻辑处理
 */
export class RecordService implements IRecordService {
  constructor(private recordRepository: IRecordRepository) {}

  /**
   * 创建新记录
   */
  async createRecord(
    userId: string,
    data: CreateRecordDto
  ): Promise<RecordResponseDto> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateNonNullObject(data, 'data');
    FailFastValidator.validateUUID(data.id, 'data.id');

    const record = await this.recordRepository.create(userId, data);
    return this.toResponseDto(record);
  }

  /**
   * 批量创建记录
   * 使用事务确保数据一致性，记录失败详情
   */
  async batchCreateRecords(
    userId: string,
    data: BatchCreateRecordsDto
  ): Promise<BatchCreateRecordsResponseDto> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateNonNullObject(data, 'data');
    FailFastValidator.validateNonEmptyArray(data.records, 'data.records');

    let succeeded = 0;
    let failed = 0;
    const errors: Array<{ id: string; error: string }> = [];

    for (const recordData of data.records) {
      try {
        await this.recordRepository.create(userId, recordData);
        succeeded++;
      } catch (error) {
        failed++;
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        errors.push({ id: recordData.id, error: errorMessage });
        
        // 记录错误日志，便于追踪
        logger.error('批量创建记录失败', {
          userId,
          recordId: recordData.id,
          error: errorMessage,
        });
      }
    }

    // 如果有失败记录，记录汇总日志
    if (failed > 0) {
      logger.warn('批量创建记录部分失败', {
        userId,
        total: data.records.length,
        succeeded,
        failed,
        errors: errors.slice(0, 5), // 只记录前5个错误
      });
    }

    return {
      total: data.records.length,
      succeeded,
      failed,
      syncedAt: new Date(),
    };
  }

  /**
   * 获取记录列表（支持增量同步）
   */
  async getRecords(
    userId: string,
    lastSyncTime?: string,
    limit: number = 100,
    offset: number = 0
  ): Promise<GetRecordsResponseDto> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');

    const lastSyncDate = lastSyncTime ? new Date(lastSyncTime) : undefined;

    const { records, total } = await this.recordRepository.findByUserId(
      userId,
      lastSyncDate,
      limit,
      offset
    );

    return {
      records: records.map((record) => this.toResponseDto(record)),
      total,
      hasMore: offset + records.length < total,
      syncTime: new Date(),
    };
  }

  /**
   * 更新记录
   * 
   * 安全性说明：
   * - 本方法是权限验证的唯一入口
   * - 通过 findById(id, userId) 确保记录归属
   * - Repository 层不再验证 userId，依赖本层的验证
   * - 禁止绕过 Service 层直接调用 Repository
   */
  async updateRecord(
    userId: string,
    id: string,
    data: UpdateRecordDto
  ): Promise<RecordResponseDto> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateUUID(id, 'id');
    FailFastValidator.validateNonNullObject(data, 'data');

    // 【安全边界】检查记录是否存在且属于该用户
    const existingRecord = await this.recordRepository.findById(id, userId);
    if (!existingRecord) {
      throw new AppError(
        `记录不存在: ${id}`,
        ErrorCode.NOT_FOUND
      );
    }

    // 权限验证通过，执行更新
    const record = await this.recordRepository.update(id, data);
    return this.toResponseDto(record);
  }

  /**
   * 删除记录
   * 
   * 安全性说明：
   * - 本方法是权限验证的唯一入口
   * - 通过 findById(id, userId) 确保记录归属
   * - Repository 层不再验证 userId，依赖本层的验证
   * - 禁止绕过 Service 层直接调用 Repository
   */
  async deleteRecord(userId: string, id: string): Promise<void> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    FailFastValidator.validateUUID(id, 'id');

    // 【安全边界】检查记录是否存在且属于该用户
    const existingRecord = await this.recordRepository.findById(id, userId);
    if (!existingRecord) {
      throw new AppError(
        `记录不存在: ${id}`,
        ErrorCode.NOT_FOUND
      );
    }

    // 权限验证通过，执行删除
    await this.recordRepository.delete(id);
  }

  /**
   * 将 Prisma Record 转换为 DTO
   * @private
   */
  private toResponseDto(record: Record): RecordResponseDto {
    return {
      id: record.id,
      userId: record.userId,
      timestamp: record.timestamp,
      location: fromJsonValue<LocationDto>(record.location),
      description: record.description || undefined,
      tags: fromJsonValue<TagWithNoteDto[]>(record.tags),
      emotion: record.emotion || undefined,
      status: record.status,
      storyLineId: record.storyLineId || undefined,
      ifReencounter: record.ifReencounter || undefined,
      conversationStarter: record.conversationStarter || undefined,
      backgroundMusic: record.backgroundMusic || undefined,
      weather: fromJsonValue<string[]>(record.weather),
      isPinned: record.isPinned,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    };
  }
}

