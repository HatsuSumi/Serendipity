import { Router } from 'express';
import { CheckInController } from '../controllers/checkInController';
import { authMiddleware } from '../middlewares/auth';

/**
 * 签到路由
 * 
 * 所有路由都需要用户认证（authMiddleware）
 * 
 * 调用者：
 * - src/routes/index.ts：主路由注册
 */
export function createCheckInRoutes(checkInController: CheckInController): Router {
  const router = Router();

  // 上传单条签到记录
  // POST /api/check-ins
  router.post('/', authMiddleware, checkInController.createCheckIn);

  // 批量上传签到记录
  // POST /api/check-ins/batch
  router.post('/batch', authMiddleware, checkInController.batchCreateCheckIns);

  // 获取用户所有签到记录
  // GET /api/check-ins
  router.get('/', authMiddleware, checkInController.getCheckIns);

  // 删除签到记录
  // DELETE /api/check-ins/:id
  router.delete('/:id', authMiddleware, checkInController.deleteCheckIn);

  return router;
}

