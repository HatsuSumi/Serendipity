import { config } from './config';
import { logger } from './utils/logger';
import { initializeContainer, shutdownContainer } from './config/container';
import { createApp } from './app';

/**
 * 服务器启动流程：
 * 1. 初始化依赖注入容器（注册所有服务）
 * 2. 创建 Express 应用（配置中间件和路由）
 * 3. 启动 HTTP 服务器
 */

// 1. 初始化依赖注入容器
const container = initializeContainer();

// 2. 创建 Express 应用
const app = createApp(container);

// 3. 启动 HTTP 服务器
const PORT = config.port;

const server = app.listen(PORT, () => {
  logger.info(`Server is running on port ${PORT}`);
  logger.info(`Environment: ${config.nodeEnv}`);
  logger.info(`Health check: http://localhost:${PORT}/api/v1/health`);
});

// 优雅关闭
const gracefulShutdown = async (signal: string) => {
  logger.info(`${signal} received, shutting down gracefully`);
  
  server.close(async () => {
    logger.info('HTTP server closed');
    
    try {
      await shutdownContainer();
      logger.info('Graceful shutdown completed');
      process.exit(0);
    } catch (error) {
      logger.error('Error during shutdown:', error);
      process.exit(1);
    }
  });

  // 强制关闭超时
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// 未捕获的异常
process.on('uncaughtException', (error: Error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason: unknown) => {
  logger.error('Unhandled Rejection:', reason);
  process.exit(1);
});

