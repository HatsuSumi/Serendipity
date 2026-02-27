import { Request, Response } from 'express';
import { sendSuccess } from '../utils/response';

export const healthCheck = (_req: Request, res: Response): void => {
  sendSuccess(res, {
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
};

