import { Request, Response, NextFunction } from 'express';
import { IFavoriteService } from '../services/favoriteService';
import { sendSuccess } from '../utils/response';
import { getParamAsString } from '../utils/request';

export class FavoriteController {
  constructor(private favoriteService: IFavoriteService) {}

  // 收藏帖子
  favoritePost = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const { postId } = req.body;
      await this.favoriteService.favoritePost(userId, postId);
      sendSuccess(res, null, 'Post favorited successfully');
    } catch (error) {
      next(error);
    }
  };

  // 取消收藏帖子
  unfavoritePost = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const postId = getParamAsString(req.params.postId);
      await this.favoriteService.unfavoritePost(userId, postId);
      sendSuccess(res, null, 'Post unfavorited successfully');
    } catch (error) {
      next(error);
    }
  };

  // 获取收藏的帖子列表
  getFavoritedPosts = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const result = await this.favoriteService.getFavoritedPosts(userId);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  // 收藏记录
  favoriteRecord = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const { recordId } = req.body;
      await this.favoriteService.favoriteRecord(userId, recordId);
      sendSuccess(res, null, 'Record favorited successfully');
    } catch (error) {
      next(error);
    }
  };

  // 取消收藏记录
  unfavoriteRecord = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const recordId = getParamAsString(req.params.recordId);
      await this.favoriteService.unfavoriteRecord(userId, recordId);
      sendSuccess(res, null, 'Record unfavorited successfully');
    } catch (error) {
      next(error);
    }
  };

  // 获取收藏的记录列表
  getFavoritedRecords = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const result = await this.favoriteService.getFavoritedRecords(userId);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };
}

