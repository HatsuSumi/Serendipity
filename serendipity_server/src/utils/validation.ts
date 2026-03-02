import { Request, Response, NextFunction } from 'express';
import { validationResult } from 'express-validator';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';

// 验证规则接口
interface ValidationRuleConfig {
  required?: boolean;
  type?: 'string' | 'number' | 'boolean' | 'object' | 'array';
  minLength?: number;
  maxLength?: number;
  min?: number;
  max?: number;
  pattern?: RegExp;
  custom?: (value: unknown) => boolean | string;
}

// 验证规则类型
export type ValidationRule<T> = {
  [K in keyof T]?: ValidationRuleConfig;
};

// 验证请求体
export const validateBody = <T>(rules: ValidationRule<T>) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      const errors: string[] = [];

      for (const [field, rule] of Object.entries(rules) as [string, ValidationRuleConfig][]) {
        const value = req.body[field];

        // 必填验证
        if (rule.required && (value === undefined || value === null || value === '')) {
          errors.push(`${field} is required`);
          continue;
        }

        // 如果字段不存在且非必填，跳过后续验证
        if (value === undefined || value === null) {
          continue;
        }

        // 类型验证
        if (rule.type) {
          const actualType = Array.isArray(value) ? 'array' : typeof value;
          if (actualType !== rule.type) {
            errors.push(`${field} must be a ${rule.type}`);
            continue;
          }
        }

        // 字符串长度验证
        if (typeof value === 'string') {
          if (rule.minLength && value.length < rule.minLength) {
            errors.push(`${field} must be at least ${rule.minLength} characters`);
          }
          if (rule.maxLength && value.length > rule.maxLength) {
            errors.push(`${field} must be at most ${rule.maxLength} characters`);
          }
          if (rule.pattern && !rule.pattern.test(value)) {
            errors.push(`${field} format is invalid`);
          }
        }

        // 数字范围验证
        if (typeof value === 'number') {
          if (rule.min !== undefined && value < rule.min) {
            errors.push(`${field} must be at least ${rule.min}`);
          }
          if (rule.max !== undefined && value > rule.max) {
            errors.push(`${field} must be at most ${rule.max}`);
          }
        }

        // 自定义验证
        if (rule.custom) {
          const result = rule.custom(value);
          if (result !== true) {
            errors.push(typeof result === 'string' ? result : `${field} is invalid`);
          }
        }
      }

      if (errors.length > 0) {
        throw new AppError(errors.join(', '), ErrorCode.INVALID_REQUEST);
      }

      next();
    } catch (error) {
      next(error);
    }
  };
};

// express-validator 验证结果处理中间件
export const validateRequest = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    // 日志：输出验证错误详情
    console.log('='.repeat(80));
    console.log('[验证错误] 请求路径:', req.path);
    console.log('[验证错误] 请求体:', JSON.stringify(req.body, null, 2));
    console.log('[验证错误] 错误详情:', JSON.stringify(errors.array(), null, 2));
    console.log('='.repeat(80));
    
    const errorMessages = errors.array().map((err) => err.msg).join(', ');
    throw new AppError(errorMessages, ErrorCode.VALIDATION_ERROR);
  }
  
  next();
};

// 常用验证规则
export const ValidationPatterns = {
  email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  phone: /^\+?[1-9]\d{1,14}$/,
  uuid: /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
};

