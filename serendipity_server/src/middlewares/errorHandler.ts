import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';
import { ErrorCode, ErrorStatusMap } from '../types/errors';

export class AppError extends Error {
  statusCode: number;
  code: ErrorCode;
  isOperational: boolean;

  constructor(message: string, code: ErrorCode = ErrorCode.INTERNAL_ERROR) {
    super(message);
    this.code = code;
    this.statusCode = ErrorStatusMap[code];
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  if (err instanceof AppError) {
    logger.error('Operational error:', {
      code: err.code,
      message: err.message,
      statusCode: err.statusCode,
      path: req.path,
      method: req.method,
    });

    res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
      },
    });
    return;
  }

  // 未知错误
  logger.error('Unexpected error:', {
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  res.status(500).json({
    success: false,
    error: {
      code: ErrorCode.INTERNAL_ERROR,
      message: 'Internal server error',
    },
  });
};

export const notFoundHandler = (
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  res.status(404).json({
    success: false,
    error: {
      code: ErrorCode.NOT_FOUND,
      message: `Route ${req.originalUrl} not found`,
    },
  });
};

