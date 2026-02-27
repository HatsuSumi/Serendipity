import { Application } from 'express';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { config } from '../config';
import { logger } from '../utils/logger';

// 中间件配置接口
export interface MiddlewareConfig {
  apply(app: Application): void;
}

// 安全中间件
export class SecurityMiddleware implements MiddlewareConfig {
  apply(app: Application): void {
    app.use(helmet());
  }
}

// CORS 中间件
export class CorsMiddleware implements MiddlewareConfig {
  apply(app: Application): void {
    app.use(
      cors({
        origin: config.cors.origin,
        credentials: true,
      })
    );
  }
}

// 请求体解析中间件
export class BodyParserMiddleware implements MiddlewareConfig {
  apply(app: Application): void {
    app.use(express.json({ limit: '10mb' }));
    app.use(express.urlencoded({ extended: true, limit: '10mb' }));
  }
}

// 请求日志中间件
export class RequestLoggerMiddleware implements MiddlewareConfig {
  apply(app: Application): void {
    app.use((req, _res, next) => {
      logger.info(`${req.method} ${req.path}`, {
        ip: req.ip,
        userAgent: req.get('user-agent'),
      });
      next();
    });
  }
}

// 限流中间件
export class RateLimitMiddleware implements MiddlewareConfig {
  apply(app: Application): void {
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 分钟
      max: 100, // 限制 100 个请求
      message: 'Too many requests from this IP, please try again later.',
    });
    app.use('/api', limiter);
  }
}

// 中间件管理器
export class MiddlewareManager {
  private middlewares: MiddlewareConfig[] = [];

  add(middleware: MiddlewareConfig): this {
    this.middlewares.push(middleware);
    return this;
  }

  applyAll(app: Application): void {
    this.middlewares.forEach((middleware) => middleware.apply(app));
  }
}

// 默认中间件配置
export const createDefaultMiddlewares = (): MiddlewareManager => {
  return new MiddlewareManager()
    .add(new SecurityMiddleware())
    .add(new CorsMiddleware())
    .add(new BodyParserMiddleware())
    .add(new RequestLoggerMiddleware())
    .add(new RateLimitMiddleware());
};

