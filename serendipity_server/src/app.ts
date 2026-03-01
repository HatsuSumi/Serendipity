import express, { Application } from 'express';
import { createDefaultMiddlewares } from './config/middlewares';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler';
import { createMainRoutes } from './routes';

/**
 * 创建 Express 应用
 * 
 * 配置中间件、路由和错误处理。
 * 必须在依赖注入容器初始化后调用。
 * 
 * @returns Express Application
 */
export const createApp = (): Application => {
  const app: Application = express();

  // 应用中间件
  const middlewareManager = createDefaultMiddlewares();
  middlewareManager.applyAll(app);

  // 注册路由
  app.use('/api/v1', createMainRoutes());

  // 404 处理
  app.use(notFoundHandler);

  // 错误处理
  app.use(errorHandler);

  return app;
};

