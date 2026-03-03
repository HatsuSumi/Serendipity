import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { authMiddleware } from '../middlewares/auth';
import { validateRequest } from '../utils/validation';
import {
  registerEmailValidation,
  registerPhoneValidation,
  loginEmailValidation,
  loginPhoneValidation,
  sendVerificationCodeValidation,
  resetPasswordValidation,
  refreshTokenValidation,
  changePasswordValidation,
  changeEmailValidation,
  changePhoneValidation,
} from '../validators/authValidators';

export const createAuthRoutes = (authController: AuthController): Router => {
  const router = Router();

  // 公开路由
  router.post(
    '/register/email',
    registerEmailValidation,
    validateRequest,
    authController.registerEmail
  );

  router.post(
    '/register/phone',
    registerPhoneValidation,
    validateRequest,
    authController.registerPhone
  );

  router.post(
    '/login/email',
    loginEmailValidation,
    validateRequest,
    authController.loginEmail
  );

  router.post(
    '/login/phone',
    loginPhoneValidation,
    validateRequest,
    authController.loginPhone
  );

  router.post(
    '/send-verification-code',
    sendVerificationCodeValidation,
    validateRequest,
    authController.sendVerificationCode
  );

  router.post(
    '/reset-password',
    resetPasswordValidation,
    validateRequest,
    authController.resetPassword
  );

  router.post(
    '/refresh-token',
    refreshTokenValidation,
    validateRequest,
    authController.refreshToken
  );

  // 需要认证的路由
  router.get('/me', authMiddleware, authController.getMe);

  router.post('/logout', authMiddleware, authController.logout);

  router.put(
    '/password',
    authMiddleware,
    changePasswordValidation,
    validateRequest,
    authController.changePassword
  );

  router.put(
    '/email',
    authMiddleware,
    changeEmailValidation,
    validateRequest,
    authController.changeEmail
  );

  router.put(
    '/phone',
    authMiddleware,
    changePhoneValidation,
    validateRequest,
    authController.changePhone
  );

  router.post(
    '/recovery-key',
    authMiddleware,
    authController.generateRecoveryKey
  );

  router.get(
    '/recovery-key',
    authMiddleware,
    authController.getRecoveryKey
  );

  return router;
};
