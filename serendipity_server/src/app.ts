import path from 'path';
import express, { Application } from 'express';
import { createDefaultMiddlewares } from './config/middlewares';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler';
import { createMainRoutes } from './routes';
import Container from './config/container';

/**
 * 创建 Express 应用
 *
 * 配置中间件、路由和错误处理。
 * 必须在依赖注入容器初始化后调用。
 *
 * @param container 已初始化的 DI 容器
 * @returns Express Application
 */
export const createApp = (container: Container): Application => {
  const app: Application = express();
  app.set('trust proxy', 1);

  // 应用中间件
  const middlewareManager = createDefaultMiddlewares();
  middlewareManager.applyAll(app);

  // 静态文件托管（头像等上传文件）
  app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

  // 注册路由
  app.use('/api/v1', createMainRoutes(container));

  // 404 处理
  app.use(notFoundHandler);

  // 错误处理
  app.use(errorHandler);

  return app;
};

