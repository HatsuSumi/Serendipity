import { Router } from 'express';
import { AchievementUnlockController } from '../controllers/achievementUnlockController';
import { authMiddleware } from '../middlewares/auth';

/**
 * 成就解锁路由
 * 
 * 所有路由都需要用户认证（authMiddleware）
 * 
 * 调用者：
 * - src/routes/index.ts：主路由注册
 */
export function createAchievementUnlockRoutes(achievementUnlockController: AchievementUnlockController): Router {
  const router = Router();

  // 上传成就解锁记录
  // POST /api/achievement-unlocks
  router.post('/', authMiddleware, achievementUnlockController.uploadAchievementUnlock);

  // 下载用户所有成就解锁记录
  // GET /api/achievement-unlocks?userId=xxx
  router.get('/', authMiddleware, achievementUnlockController.downloadAchievementUnlocks);

  return router;
}

