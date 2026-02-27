import { Response } from 'express';

// 成功响应接口
export interface SuccessResponse<T = unknown> {
  success: true;
  data: T;
  message?: string;
}

// 错误响应接口
export interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

// 统一成功响应
export const sendSuccess = <T>(
  res: Response,
  data: T,
  message?: string,
  statusCode = 200
): void => {
  const response: SuccessResponse<T> = {
    success: true,
    data,
  };

  if (message) {
    response.message = message;
  }

  res.status(statusCode).json(response);
};

// 统一创建响应
export const createSuccessResponse = <T>(
  data: T,
  message?: string
): SuccessResponse<T> => {
  const response: SuccessResponse<T> = {
    success: true,
    data,
  };

  if (message) {
    response.message = message;
  }

  return response;
};

