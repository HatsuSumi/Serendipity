import { Router } from 'express';
import { StatisticsController } from '../controllers/statisticsController';
import { authMiddleware } from '../middlewares/auth';

/**
 * 统计路由
 *
 * 所有端点均需 JWT 认证。
 */
export function createStatisticsRoutes(statisticsController: StatisticsController): Router {
  const router = Router();

  // 获取账号全局统计总览
  router.get('/overview', authMiddleware, statisticsController.getOverview);

  return router;
}

