import { Router } from 'express';
import { CommunityPostController } from '../controllers/communityPostController';
import { authMiddleware, optionalAuthMiddleware } from '../middlewares/auth';
import { validateRequest } from '../utils/validation';
import { createCommunityPostValidation } from '../validators/communityValidators';

export function createCommunityRoutes(
  communityPostController: CommunityPostController
): Router {
  const router = Router();

  // 发布社区帖子（需要认证）
  router.post(
    '/posts',
    authMiddleware,
    createCommunityPostValidation,
    validateRequest,
    communityPostController.createPost
  );

  // 批量检查发布状态（需要认证）
  router.post(
    '/posts/check-status',
    authMiddleware,
    communityPostController.checkPublishStatus
  );

  // 获取社区帖子列表（公开，但支持可选认证以显示 isOwner）
  // 支持筛选参数：startDate, endDate, province, city, area, placeTypes, tags, statuses
  // 如果没有筛选参数，返回最近的帖子列表
  router.get('/posts', optionalAuthMiddleware, communityPostController.getPosts);

  // 获取我的社区帖子（需要认证）
  router.get(
    '/my-posts',
    authMiddleware,
    communityPostController.getMyPosts
  );

  // 删除社区帖子（需要认证）
  router.delete(
    '/posts/:id',
    authMiddleware,
    communityPostController.deletePost
  );

  // 按 recordId 删除社区帖子（需要认证）
  // 调用者：客户端删除记录时联动触发
  router.delete(
    '/posts/by-record/:recordId',
    authMiddleware,
    communityPostController.deletePostByRecordId
  );

  return router;
}

