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

// Record Service 接口
export interface IRecordService {
  createRecord(userId: string, data: CreateRecordDto): Promise<RecordResponseDto>;
  batchCreateRecords(
    userId: string,
    data: BatchCreateRecordsDto
  ): Promise<BatchCreateRecordsResponseDto>;
  getRecords(
    userId: string,
    lastSyncTime?: string,
    limit?: number,
    offset?: number
  ): Promise<GetRecordsResponseDto>;
  updateRecord(
    userId: string,
    id: string,
    data: UpdateRecordDto
  ): Promise<RecordResponseDto>;
  deleteRecord(userId: string, id: string): Promise<void>;
}

// Record Service 实现
export class RecordService implements IRecordService {
  constructor(private recordRepository: IRecordRepository) {}

  async createRecord(
    userId: string,
    data: CreateRecordDto
  ): Promise<RecordResponseDto> {
    const record = await this.recordRepository.create(userId, data);
    return this.toResponseDto(record);
  }

  async batchCreateRecords(
    userId: string,
    data: BatchCreateRecordsDto
  ): Promise<BatchCreateRecordsResponseDto> {
    let succeeded = 0;
    let failed = 0;

    for (const recordData of data.records) {
      try {
        await this.recordRepository.create(userId, recordData);
        succeeded++;
      } catch (error) {
        failed++;
        // 继续处理其他记录，不中断批量操作
      }
    }

    return {
      total: data.records.length,
      succeeded,
      failed,
      syncedAt: new Date(),
    };
  }

  async getRecords(
    userId: string,
    lastSyncTime?: string,
    limit: number = 100,
    offset: number = 0
  ): Promise<GetRecordsResponseDto> {
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

  async updateRecord(
    userId: string,
    id: string,
    data: UpdateRecordDto
  ): Promise<RecordResponseDto> {
    // 检查记录是否存在
    const existingRecord = await this.recordRepository.findById(id, userId);
    if (!existingRecord) {
      throw new AppError('Record not found', ErrorCode.NOT_FOUND);
    }

    const record = await this.recordRepository.update(userId, id, data);
    return this.toResponseDto(record);
  }

  async deleteRecord(userId: string, id: string): Promise<void> {
    // 检查记录是否存在
    const existingRecord = await this.recordRepository.findById(id, userId);
    if (!existingRecord) {
      throw new AppError('Record not found', ErrorCode.NOT_FOUND);
    }

    await this.recordRepository.delete(id, userId);
  }

  // 将 Prisma Record 转换为 DTO
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

