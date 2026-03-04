import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { AppError } from './errorHandler';
import { ErrorCode } from '../types/errors';
import { jwtService, JwtPayload } from '../services/jwtService';

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

export const authMiddleware = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('No token provided', ErrorCode.UNAUTHORIZED);
    }

    const token = authHeader.substring(7);

    const decoded = jwtService.verify(token);

    req.user = decoded;
    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      next(new AppError('Invalid token', ErrorCode.UNAUTHORIZED));
    } else if (error instanceof jwt.TokenExpiredError) {
      next(new AppError('Token expired', ErrorCode.UNAUTHORIZED));
    } else {
      next(error);
    }
  }
};

// 可选认证中间件（不强制要求登录，但如果有 token 则解析）
export const optionalAuthMiddleware = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  try {
    const authHeader = req.headers.authorization;

    // 如果没有 token，直接放行
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      next();
      return;
    }

    const token = authHeader.substring(7);

    try {
      const decoded = jwtService.verify(token);
      req.user = decoded;
    } catch (error) {
      // token 无效或过期，忽略错误，继续执行（不设置 req.user）
    }

    next();
  } catch (error) {
    next(error);
  }
};

