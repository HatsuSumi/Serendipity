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
  router.get('/posts', optionalAuthMiddleware, communityPostController.getRecentPosts);

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

  // 筛选社区帖子（公开，但支持可选认证以显示 isOwner）
  router.get('/posts/filter', optionalAuthMiddleware, communityPostController.filterPosts);

  return router;
}

