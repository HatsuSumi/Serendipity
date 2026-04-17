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

  /**
   * 筛选记录（支持多条件组合）
   * @param userId - 用户 ID
   * @param filters - 筛选条件
   * @returns 筛选结果和分页信息
   * @throws {AppError} 当参数无效时
   */
  filterRecords(
    userId: string,
    filters: {
      startDate?: string;
      endDate?: string;
      province?: string;
      city?: string;
      area?: string;
      placeNameKeywords?: string;
      descriptionKeywords?: string;
      ifReencounterKeywords?: string;
      conversationStarterKeywords?: string;
      backgroundMusicKeywords?: string;
      placeTypes?: string;
      tags?: string;
      statuses?: string;
      emotionIntensities?: string;
      weathers?: string;
      tagMatchMode?: 'wholeWord' | 'contains';
      sortBy?: 'createdAt' | 'updatedAt';
      sortOrder?: 'asc' | 'desc';
      limit: number;
      offset: number;
    }
  ): Promise<GetRecordsResponseDto>;
}

/**
 * Record Service 实现
 * 负责记录相关的业务逻辑处理
 */
export class RecordService implements IRecordService {
  constructor(
    private recordRepository: IRecordRepository,
  ) {}

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

    try {
      // 使用批量事务操作，性能提升 40-100 倍
      await this.recordRepository.batchCreate(userId, data.records);
      
      return {
        total: data.records.length,
        succeeded: data.records.length,
        failed: 0,
        syncedAt: new Date(),
      };
    } catch (error) {
      // 事务失败，记录详细错误
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      
      logger.error('批量创建记录失败', {
        userId,
        total: data.records.length,
        error: errorMessage,
      });

      // 事务失败意味着全部失败
      return {
        total: data.records.length,
        succeeded: 0,
        failed: data.records.length,
        syncedAt: new Date(),
      };
    }
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

    const scope = { userId };
    const lastSyncDate = lastSyncTime ? new Date(lastSyncTime) : undefined;

    const { records, total } = await this.recordRepository.findByUserId(
      scope,
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

    // 权限验证通过，执行删除（墓碑化）
    await this.recordRepository.delete(id, new Date());
  }

  /**
   * 筛选记录（支持多条件组合）
   * 
   * 设计原则：
   * - Fail Fast：参数验证在方法开始
   * - 字符串参数解析：placeTypes、tags、statuses 从逗号分隔字符串转换为数组
   * - 日期参数解析：startDate、endDate 从 ISO 字符串转换为 Date
   * - 权限验证：确保只能查看自己的记录
   */
  async filterRecords(
    userId: string,
    filters: {
      startDate?: string;
      endDate?: string;
      province?: string;
      city?: string;
      area?: string;
      placeNameKeywords?: string;
      descriptionKeywords?: string;
      ifReencounterKeywords?: string;
      conversationStarterKeywords?: string;
      backgroundMusicKeywords?: string;
      placeTypes?: string;
      tags?: string;
      statuses?: string;
      emotionIntensities?: string;
      weathers?: string;
      tagMatchMode?: 'wholeWord' | 'contains';
      sortBy?: 'createdAt' | 'updatedAt';
      sortOrder?: 'asc' | 'desc';
      limit: number;
      offset: number;
    }
  ): Promise<GetRecordsResponseDto> {
    // Fail Fast: 立即验证参数
    FailFastValidator.validateNonEmptyString(userId, 'userId');
    if (filters.limit <= 0) {
      throw new AppError('limit must be positive', ErrorCode.VALIDATION_ERROR);
    }
    if (filters.offset < 0) {
      throw new AppError('offset cannot be negative', ErrorCode.VALIDATION_ERROR);
    }

    // 调用 Repository 执行筛选
    const startDate = filters.startDate ? new Date(filters.startDate) : undefined;
    const endDate = filters.endDate ? new Date(filters.endDate) : undefined;

    if (startDate && isNaN(startDate.getTime())) {
      throw new AppError('Invalid startDate format', ErrorCode.VALIDATION_ERROR);
    }
    if (endDate && isNaN(endDate.getTime())) {
      throw new AppError('Invalid endDate format', ErrorCode.VALIDATION_ERROR);
    }

    // 解析数组参数（逗号分隔字符串转换为数组）
    const placeTypes = filters.placeTypes
      ? filters.placeTypes.split(',').map(t => t.trim()).filter(t => t)
      : undefined;
    const placeNameKeywords = filters.placeNameKeywords
      ? filters.placeNameKeywords.split(',').map(k => k.trim()).filter(k => k)
      : undefined;
    const descriptionKeywords = filters.descriptionKeywords
      ? filters.descriptionKeywords.split(',').map(k => k.trim()).filter(k => k)
      : undefined;
    const ifReencounterKeywords = filters.ifReencounterKeywords
      ? filters.ifReencounterKeywords.split(',').map(k => k.trim()).filter(k => k)
      : undefined;
    const conversationStarterKeywords = filters.conversationStarterKeywords
      ? filters.conversationStarterKeywords.split(',').map(k => k.trim()).filter(k => k)
      : undefined;
    const backgroundMusicKeywords = filters.backgroundMusicKeywords
      ? filters.backgroundMusicKeywords.split(',').map(k => k.trim()).filter(k => k)
      : undefined;
    const tags = filters.tags
      ? filters.tags.split(',').map(t => t.trim()).filter(t => t)
      : undefined;
    const statuses = filters.statuses
      ? filters.statuses.split(',').map(s => s.trim()).filter(s => s)
      : undefined;
    const emotionIntensities = filters.emotionIntensities
      ? filters.emotionIntensities.split(',').map(e => e.trim()).filter(e => e)
      : undefined;
    const weathers = filters.weathers
      ? filters.weathers.split(',').map(w => w.trim()).filter(w => w)
      : undefined;

    // 调用 Repository 执行筛选
    const { records, total } = await this.recordRepository.findByFilters(userId, {
      startDate,
      endDate,
      province: filters.province,
      city: filters.city,
      area: filters.area,
      placeNameKeywords,
      descriptionKeywords,
      ifReencounterKeywords,
      conversationStarterKeywords,
      backgroundMusicKeywords,
      placeTypes,
      statuses,
      emotionIntensities,
      weathers,
      tags,
      tagMatchMode: filters.tagMatchMode,
      sortBy: filters.sortBy || 'createdAt',
      sortOrder: filters.sortOrder || 'desc',
      limit: filters.limit,
      offset: filters.offset,
    });

    return {
      records: records.map((record) => this.toResponseDto(record)),
      total,
      hasMore: filters.offset + records.length < total,
      syncTime: new Date(),
    };
  }

  /**
   * 将 Prisma Record 转换为 DTO
   * @private
   */
  private toResponseDto(record: Record): RecordResponseDto {
    return {
      id: record.id,
      ownerId: record.userId,
      timestamp: record.timestamp.toISOString(),
      anniversaryMonth: record.anniversaryMonth,
      anniversaryDay: record.anniversaryDay,
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
      createdAt: record.createdAt.toISOString(),
      updatedAt: record.updatedAt.toISOString(),
      deletedAt: record.deletedAt?.toISOString(),
    };
  }
}

