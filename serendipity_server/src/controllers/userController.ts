/**
 * 用户控制器
 * 
 * 职责：处理用户相关的 HTTP 请求
 */

import { Request, Response, NextFunction } from 'express';
import { IUserService } from '../services/userService';
import { UpdateUserDto, UpdateUserSettingsDto } from '../types/user.dto';
import { sendSuccess } from '../utils/response';

/**
 * 用户控制器
 */
export class UserController {
  constructor(private userService: IUserService) {}

  /**
   * 更新用户信息
   * PUT /api/v1/users/me
   */
  updateUser = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: UpdateUserDto = req.body;
      const result = await this.userService.updateUser(userId, data);
      sendSuccess(res, result, 'User updated successfully');
    } catch (error) {
      next(error);
    }
  };

  /**
   * 上传头像
   * POST /api/v1/users/avatar
   */
  uploadAvatar = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      if (!req.file) {
        throw new Error('No file uploaded');
      }
      const userId = req.user!.userId;
      const baseUrl = `${req.protocol}://${req.get('host')}`;
      const result = await this.userService.uploadAvatar(userId, req.file, baseUrl);
      sendSuccess(res, result, 'Avatar uploaded successfully');
    } catch (error) {
      next(error);
    }
  };

  /**
   * 获取用户设置
   * GET /api/v1/users/settings
   */
  getUserSettings = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const result = await this.userService.getUserSettings(userId);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  /**
   * 获取用户会员信息
   * GET /api/v1/users/membership
   */
  getMembership = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const result = await this.userService.getMembership(userId);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  /**
   * 更新用户设置
   * PUT /api/v1/users/settings
   */
  updateUserSettings = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: UpdateUserSettingsDto = req.body;
      const result = await this.userService.updateUserSettings(userId, data);
      sendSuccess(res, result, 'User settings updated successfully');
    } catch (error) {
      next(error);
    }
  };
}

