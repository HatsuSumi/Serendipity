import { Request, Response, NextFunction } from 'express';
import { IStoryLineService } from '../services/storyLineService';
import {
  CreateStoryLineDto,
  UpdateStoryLineDto,
  BatchCreateStoryLinesDto,
} from '../types/storyline.dto';
import { sendSuccess } from '../utils/response';
import { getParamAsString, getQueryAsString, getQueryAsInt } from '../utils/request';

// StoryLine Controller
export class StoryLineController {
  constructor(private storyLineService: IStoryLineService) {}

  createStoryLine = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: CreateStoryLineDto = req.body;
      const result = await this.storyLineService.createStoryLine(userId, data);
      sendSuccess(res, result, 'StoryLine created successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  batchCreateStoryLines = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: BatchCreateStoryLinesDto = req.body;
      const result = await this.storyLineService.batchCreateStoryLines(
        userId,
        data
      );
      sendSuccess(res, result, 'StoryLines uploaded successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  getStoryLines = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const lastSyncTime = getQueryAsString(req.query.lastSyncTime);
      const deviceId = getQueryAsString(req.query.deviceId);
      const limit = getQueryAsInt(req.query.limit);
      const offset = getQueryAsInt(req.query.offset);
      
      const result = await this.storyLineService.getStoryLines(
        userId,
        lastSyncTime,
        deviceId,
        limit,
        offset
      );
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  updateStoryLine = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const id = getParamAsString(req.params.id);
      const data: UpdateStoryLineDto = req.body;
      const result = await this.storyLineService.updateStoryLine(
        userId,
        id,
        data
      );
      sendSuccess(res, result, 'StoryLine updated successfully');
    } catch (error) {
      next(error);
    }
  };

  deleteStoryLine = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const id = getParamAsString(req.params.id);
      await this.storyLineService.deleteStoryLine(userId, id);
      sendSuccess(res, { message: 'StoryLine deleted successfully' });
    } catch (error) {
      next(error);
    }
  };
}

