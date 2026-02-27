/**
 * 用户路由
 * 
 * 职责：定义用户相关的 API 路由
 */

import { Router } from 'express';
import { UserController } from '../controllers/userController';
import { authMiddleware } from '../middlewares/auth';
import { validateRequest } from '../utils/validation';
import {
  updateUserValidation,
  updateUserSettingsValidation,
} from '../validators/userValidators';

/**
 * 创建用户路由
 * @param userController - 用户控制器实例
 * @returns Express Router
 */
export const createUserRoutes = (userController: UserController): Router => {
  const router = Router();

  // 所有路由都需要认证
  router.use(authMiddleware);

  // PUT /api/v1/users/me - 更新用户信息
  router.put(
    '/me',
    updateUserValidation,
    validateRequest,
    userController.updateUser
  );

  // GET /api/v1/users/settings - 获取用户设置
  router.get('/settings', userController.getUserSettings);

  // PUT /api/v1/users/settings - 更新用户设置
  router.put(
    '/settings',
    updateUserSettingsValidation,
    validateRequest,
    userController.updateUserSettings
  );

  return router;
};

