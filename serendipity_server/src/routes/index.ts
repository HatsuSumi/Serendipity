import { Router } from 'express';
import { healthCheck } from '../controllers/healthController';
import { createAuthRoutes } from './auth.routes';
import { createRecordRoutes } from './record.routes';
import { createStoryLineRoutes } from './storyline.routes';
import { createCommunityRoutes } from './community.routes';
import { createUserRoutes } from './user.routes';
import { createCheckInRoutes } from './checkIn.routes';
import { createAchievementUnlockRoutes } from './achievementUnlock.routes';
import { createFavoriteRoutes } from './favorite.routes';
import { createStatisticsRoutes } from './statistics.routes';
import { createPushTokenRoutes } from './pushToken.routes';
import Container from '../config/container';
import { TYPES } from '../config/types';
import { AuthController } from '../controllers/authController';
import { RecordController } from '../controllers/recordController';
import { StoryLineController } from '../controllers/storyLineController';
import { CommunityPostController } from '../controllers/communityPostController';
import { UserController } from '../controllers/userController';
import { CheckInController } from '../controllers/checkInController';
import { AchievementUnlockController } from '../controllers/achievementUnlockController';
import { FavoriteController } from '../controllers/favoriteController';
import { StatisticsController } from '../controllers/statisticsController';
import { PushTokenController } from '../controllers/pushTokenController';

/**
 * 创建主路由
 *
 * 从依赖注入容器获取所有控制器，并注册路由。
 * 必须在容器初始化后调用。
 *
 * @param container 已初始化的 DI 容器
 * @returns Express Router
 */
export const createMainRoutes = (container: Container): Router => {
  const router = Router();

  // 健康检查（无需认证）
  router.get('/health', healthCheck);

  // 从容器获取控制器实例
  const authController = container.get<AuthController>(TYPES.AuthController);
  const recordController = container.get<RecordController>(TYPES.RecordController);
  const storyLineController = container.get<StoryLineController>(TYPES.StoryLineController);
  const communityPostController = container.get<CommunityPostController>(TYPES.CommunityPostController);
  const userController = container.get<UserController>(TYPES.UserController);
  const checkInController = container.get<CheckInController>(TYPES.CheckInController);
  const achievementUnlockController = container.get<AchievementUnlockController>(TYPES.AchievementUnlockController);
  const favoriteController = container.get<FavoriteController>(TYPES.FavoriteController);
  const statisticsController = container.get<StatisticsController>(TYPES.StatisticsController);
  const pushTokenController = container.get<PushTokenController>(TYPES.PushTokenController);

  // 注册子路由
  router.use('/auth', createAuthRoutes(authController));
  router.use('/records', createRecordRoutes(recordController));
  router.use('/storylines', createStoryLineRoutes(storyLineController));
  router.use('/community', createCommunityRoutes(communityPostController));
  router.use('/users', createUserRoutes(userController));
  router.use('/check-ins', createCheckInRoutes(checkInController));
  router.use('/achievement-unlocks', createAchievementUnlockRoutes(achievementUnlockController));
  router.use('/favorites', createFavoriteRoutes(favoriteController));
  router.use('/statistics', createStatisticsRoutes(statisticsController));
  router.use('/push-tokens', createPushTokenRoutes(pushTokenController));

  return router;
};

