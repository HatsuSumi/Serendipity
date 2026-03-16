import { Request, Response, NextFunction } from 'express';
import { IRecordService } from '../services/recordService';
import {
  CreateRecordDto,
  UpdateRecordDto,
  BatchCreateRecordsDto,
} from '../types/record.dto';
import { sendSuccess } from '../utils/response';
import { getParamAsString, getQueryAsString, getQueryAsInt } from '../utils/request';

// Record Controller
export class RecordController {
  constructor(private recordService: IRecordService) {}

  createRecord = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: CreateRecordDto = req.body;
      const result = await this.recordService.createRecord(userId, data);
      sendSuccess(res, result, 'Record created successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  batchCreateRecords = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: BatchCreateRecordsDto = req.body;
      const result = await this.recordService.batchCreateRecords(userId, data);
      sendSuccess(res, result, 'Records uploaded successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  getRecords = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const lastSyncTime = getQueryAsString(req.query.lastSyncTime);
      const limit = getQueryAsInt(req.query.limit);
      const offset = getQueryAsInt(req.query.offset);
      
      const result = await this.recordService.getRecords(
        userId,
        lastSyncTime,
        limit,
        offset
      );
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  updateRecord = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const id = getParamAsString(req.params.id);
      const data: UpdateRecordDto = req.body;
      const result = await this.recordService.updateRecord(userId, id, data);
      sendSuccess(res, result, 'Record updated successfully');
    } catch (error) {
      next(error);
    }
  };

  deleteRecord = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const id = getParamAsString(req.params.id);
      await this.recordService.deleteRecord(userId, id);
      sendSuccess(res, { message: 'Record deleted successfully' });
    } catch (error) {
      next(error);
    }
  };

  filterRecords = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      
      // 参数提取
      const startDate = getQueryAsString(req.query.startDate);
      const endDate = getQueryAsString(req.query.endDate);
      const province = getQueryAsString(req.query.province);
      const city = getQueryAsString(req.query.city);
      const area = getQueryAsString(req.query.area);
      const placeTypes = getQueryAsString(req.query.placeTypes);
      const tags = getQueryAsString(req.query.tags);
      const statuses = getQueryAsString(req.query.statuses);
      const emotionIntensities = getQueryAsString(req.query.emotionIntensities);
      const weathers = getQueryAsString(req.query.weathers);
      const tagMatchMode = getQueryAsString(req.query.tagMatchMode);
      const sortBy = getQueryAsString(req.query.sortBy) as 'createdAt' | 'updatedAt' | undefined;
      const sortOrder = getQueryAsString(req.query.sortOrder) as 'asc' | 'desc' | undefined;
      const limit = getQueryAsInt(req.query.limit) || 20;
      const offset = getQueryAsInt(req.query.offset) || 0;

      const result = await this.recordService.filterRecords(userId, {
        startDate,
        endDate,
        province,
        city,
        area,
        placeTypes,
        tags,
        statuses,
        emotionIntensities,
        weathers,
        tagMatchMode: tagMatchMode as 'wholeWord' | 'contains' | undefined,
        sortBy,
        sortOrder,
        limit,
        offset,
      });

      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };
}

