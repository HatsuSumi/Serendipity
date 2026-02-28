import express, { Application } from 'express';
import { createDefaultMiddlewares } from './config/middlewares';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler';

const app: Application = express();

// 应用中间件
const middlewareManager = createDefaultMiddlewares();
middlewareManager.applyAll(app);

// 路由将在容器初始化后注册
// 见 server.ts

// 404 处理
app.use(notFoundHandler);

// 错误处理
app.use(errorHandler);

export default app;

