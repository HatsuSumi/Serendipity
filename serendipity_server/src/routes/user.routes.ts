/**
 * 用户路由
 * 
 * 职责：定义用户相关的 API 路由
 */

import { Router } from 'express';
import { UserController } from '../controllers/userController';
import { authMiddleware } from '../middlewares/auth';
import { validateRequest } from '../utils/validation';
import { uploadAvatarMiddleware } from '../middlewares/upload';
import {
  updateUserValidation,
  activateMembershipValidation,
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

  // POST /api/v1/users/avatar - 上传头像
  router.post('/avatar', uploadAvatarMiddleware, userController.uploadAvatar);

  // GET /api/v1/users/membership - 获取用户会员信息
  router.get('/membership', userController.getMembership);

  // POST /api/v1/users/membership - 开通会员
  router.post(
    '/membership',
    activateMembershipValidation,
    validateRequest,
    userController.activateMembership
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

