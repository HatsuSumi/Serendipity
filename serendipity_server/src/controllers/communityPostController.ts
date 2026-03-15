import { Request, Response, NextFunction } from 'express';
import { ICommunityPostService } from '../services/communityPostService';
import { CreateCommunityPostDto, FilterCommunityPostsQuery, CheckPublishStatusDto } from '../types/community.dto';
import { sendSuccess } from '../utils/response';
import { getQueryAsString, getQueryAsInt, getParamAsString } from '../utils/request';
import { isValidTagMatchMode } from '../validators/communityValidators';

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
        result,
        'Post published successfully',
        201
      );
    } catch (error) {
      next(error);
    }
  };

  // 批量检查发布状态
  checkPublishStatus = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const records: CheckPublishStatusDto[] = req.body.records;

      const result = await this.communityPostService.checkPublishStatus(userId, records);

      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  // 获取社区帖子列表（支持筛选）
  // 如果没有筛选参数，返回最近的帖子列表
  // 如果有筛选参数，返回筛选后的帖子列表
  getPosts = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const currentUserId = req.user?.userId; // 可选，用于判断 isOwner

      // 检查是否有筛选参数
      const hasFilterParams = 
        req.query.startDate ||
        req.query.endDate ||
        req.query.publishStartDate ||
        req.query.publishEndDate ||
        req.query.province ||
        req.query.city ||
        req.query.area ||
        req.query.placeTypes ||
        req.query.tags ||
        req.query.statuses;

      // 如果有筛选参数，使用筛选逻辑
      if (hasFilterParams) {
        const tagMatchModeStr = getQueryAsString(req.query.tagMatchMode);
        const tagMatchMode = isValidTagMatchMode(tagMatchModeStr) ? tagMatchModeStr : undefined;
        
        const query: FilterCommunityPostsQuery = {
          startDate: getQueryAsString(req.query.startDate),
          endDate: getQueryAsString(req.query.endDate),
          publishStartDate: getQueryAsString(req.query.publishStartDate),
          publishEndDate: getQueryAsString(req.query.publishEndDate),
          province: getQueryAsString(req.query.province),
          city: getQueryAsString(req.query.city),
          area: getQueryAsString(req.query.area),
          placeTypes: getQueryAsString(req.query.placeTypes),
          tags: getQueryAsString(req.query.tags),
          tagMatchMode,
          statuses: getQueryAsString(req.query.statuses),
          limit: getQueryAsInt(req.query.limit),
        };

        const result = await this.communityPostService.filterPosts(query, currentUserId);
        sendSuccess(res, result);
      } else {
        // 否则，返回最近的帖子列表
        const limit = getQueryAsInt(req.query.limit) || 20;
        const lastTimestamp = getQueryAsString(req.query.lastTimestamp);

        const result = await this.communityPostService.getRecentPosts(
          limit,
          lastTimestamp,
          currentUserId
        );
        sendSuccess(res, result);
      }
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

  // 删除社区帖子（按 recordId）
  // 调用者：记录删除时联动触发
  deletePostByRecordId = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const recordId = getParamAsString(req.params.recordId);

      await this.communityPostService.deletePostByRecordId(userId, recordId);

      sendSuccess(res, { message: 'Post deleted successfully' });
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
}

