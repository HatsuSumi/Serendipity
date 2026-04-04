import { Router } from 'express';
import { PushTokenController } from '../controllers/pushTokenController';
import { authMiddleware } from '../middlewares/auth';
import { validateRequest } from '../utils/validation';
import {
  registerPushTokenValidation,
  unregisterPushTokenValidation,
} from '../validators/pushTokenValidators';

export function createPushTokenRoutes(pushTokenController: PushTokenController): Router {
  const router = Router();

  router.post(
    '/',
    authMiddleware,
    registerPushTokenValidation,
    validateRequest,
    pushTokenController.registerPushToken,
  );

  router.delete(
    '/',
    authMiddleware,
    unregisterPushTokenValidation,
    validateRequest,
    pushTokenController.unregisterPushToken,
  );

  router.get('/', authMiddleware, pushTokenController.listPushTokens);
  router.post(
    '/test/check-in-reminder',
    authMiddleware,
    pushTokenController.sendCheckInReminderTest,
  );
  router.post(
    '/test/anniversary-reminder',
    authMiddleware,
    pushTokenController.sendAnniversaryReminderTest,
  );

  return router;
}
