import { Router } from 'express';
import { FavoriteController } from '../controllers/favoriteController';
import { authMiddleware } from '../middlewares/auth';

export function createFavoriteRoutes(favoriteController: FavoriteController): Router {
  const router = Router();

  // 收藏帖子
  router.post('/posts', authMiddleware, favoriteController.favoritePost);

  // 取消收藏帖子
  router.delete('/posts/:postId', authMiddleware, favoriteController.unfavoritePost);

  // 获取收藏的帖子列表
  router.get('/posts', authMiddleware, favoriteController.getFavoritedPosts);

  // 收藏记录
  router.post('/records', authMiddleware, favoriteController.favoriteRecord);

  // 取消收藏记录
  router.delete('/records/:recordId', authMiddleware, favoriteController.unfavoriteRecord);

  // 获取收藏的记录 ID 列表
  router.get('/records', authMiddleware, favoriteController.getFavoritedRecordIds);

  return router;
}

