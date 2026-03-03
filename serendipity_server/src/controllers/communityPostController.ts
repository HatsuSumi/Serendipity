import { Request, Response, NextFunction } from 'express';
import { ICommunityPostService } from '../services/communityPostService';
import { CreateCommunityPostDto, FilterCommunityPostsQuery } from '../types/community.dto';
import { sendSuccess } from '../utils/response';
import { getQueryAsString, getQueryAsInt, getParamAsString } from '../utils/request';

// 社区帖子控制器
export class CommunityPostController {
  constructor(private communityPostService: ICommunityPostService) {}

  // 发布社区帖子
  createPost = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: CreateCommunityPostDto = req.body;

      const result = await this.communityPostService.createPost(userId, data);

      sendSuccess(
        res,
        {
          id: result.id,
          publishedAt: result.publishedAt,
        },
        'Post published successfully',
        201
      );
    } catch (error) {
      next(error);
    }
  };

  // 获取社区帖子列表
  getRecentPosts = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const limit = getQueryAsInt(req.query.limit) || 20;
      const lastTimestamp = getQueryAsString(req.query.lastTimestamp);
      const currentUserId = req.user?.userId; // 可选，用于判断 isOwner

      const result = await this.communityPostService.getRecentPosts(
        limit,
        lastTimestamp,
        currentUserId
      );

      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  // 获取我的社区帖子
  getMyPosts = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;

      const result = await this.communityPostService.getMyPosts(userId);

      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  // 删除社区帖子
  deletePost = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const postId = getParamAsString(req.params.id);

      await this.communityPostService.deletePost(postId, userId);

      sendSuccess(res, { message: 'Post deleted successfully' });
    } catch (error) {
      next(error);
    }
  };

  // 筛选社区帖子
  filterPosts = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const query: FilterCommunityPostsQuery = {
        startDate: getQueryAsString(req.query.startDate),
        endDate: getQueryAsString(req.query.endDate),
        publishStartDate: getQueryAsString(req.query.publishStartDate),
        publishEndDate: getQueryAsString(req.query.publishEndDate),
        province: getQueryAsString(req.query.province),
        city: getQueryAsString(req.query.city),
        area: getQueryAsString(req.query.area),
        placeTypes: getQueryAsString(req.query.placeTypes),
        tag: getQueryAsString(req.query.tag),
        status: getQueryAsString(req.query.status),
        limit: getQueryAsInt(req.query.limit),
      };

      const currentUserId = req.user?.userId; // 可选，用于判断 isOwner

      const result = await this.communityPostService.filterPosts(query, currentUserId);

      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };
}

