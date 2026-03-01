import { Router } from 'express';
import { healthCheck } from '../controllers/healthController';
import { createAuthRoutes } from './auth.routes';
import { createRecordRoutes } from './record.routes';
import { createStoryLineRoutes } from './storyline.routes';
import { createCommunityRoutes } from './community.routes';
import { createPaymentRoutes, createMembershipRoutes } from './payment.routes';
import { createUserRoutes } from './user.routes';
import Container from '../config/container';
import { AuthController } from '../controllers/authController';
import { RecordController } from '../controllers/recordController';
import { StoryLineController } from '../controllers/storyLineController';
import { CommunityPostController } from '../controllers/communityPostController';
import { PaymentController } from '../controllers/paymentController';
import { UserController } from '../controllers/userController';

/**
 * 创建主路由
 * 
 * 从依赖注入容器获取所有控制器，并注册路由。
 * 必须在容器初始化后调用。
 * 
 * @returns Express Router
 */
export const createMainRoutes = (): Router => {
  const router = Router();

  // 健康检查（无需认证）
  router.get('/health', healthCheck);

  // 从容器获取控制器实例
  const container = Container.getInstance();
  const authController = container.get<AuthController>('authController');
  const recordController = container.get<RecordController>('recordController');
  const storyLineController = container.get<StoryLineController>('storyLineController');
  const communityPostController = container.get<CommunityPostController>('communityPostController');
  const paymentController = container.get<PaymentController>('paymentController');
  const userController = container.get<UserController>('userController');

  // 注册子路由
  router.use('/auth', createAuthRoutes(authController));
  router.use('/records', createRecordRoutes(recordController));
  router.use('/storylines', createStoryLineRoutes(storyLineController));
  router.use('/community', createCommunityRoutes(communityPostController));
  router.use('/payment', createPaymentRoutes(paymentController));
  router.use('/membership', createMembershipRoutes(paymentController));
  router.use('/users', createUserRoutes(userController));

  return router;
};

