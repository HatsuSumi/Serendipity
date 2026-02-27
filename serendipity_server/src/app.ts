import express, { Application } from 'express';
import { createDefaultMiddlewares } from './config/middlewares';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler';
import routes from './routes';

const app: Application = express();

// 应用中间件
const middlewareManager = createDefaultMiddlewares();
middlewareManager.applyAll(app);

// 路由
app.use('/api/v1', routes);

// 404 处理
app.use(notFoundHandler);

// 错误处理
app.use(errorHandler);

export default app;

