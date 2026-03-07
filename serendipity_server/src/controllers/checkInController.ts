import { Request, Response, NextFunction } from 'express';
import { ICheckInService } from '../services/checkInService';
import { CreateCheckInDto, BatchCreateCheckInsDto, CheckInResponseDto } from '../types/checkIn.dto';
import { sendSuccess } from '../utils/response';
import { CheckIn } from '@prisma/client';

/**
 * 签到控制器
 * 
 * 负责处理签到相关的 HTTP 请求，遵循单一职责原则（SRP）
 * 
 * 调用者：
 * - Express Router：路由层
 */
export class CheckInController {
  constructor(private checkInService: ICheckInService) {
    // Fail Fast：依赖检查
    if (!checkInService) {
      throw new Error('CheckInService is required');
    }
  }

  /**
   * 创建签到记录
   * 
   * POST /api/check-ins
   * 
   * 请求体：CreateCheckInDto
   * 响应：CheckInResponseDto
   * 
   * 调用者：Flutter App - CustomServerRemoteDataRepository.uploadCheckIn()
   */
  createCheckIn = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // Fail Fast：用户认证检查
      if (!req.user || !req.user.userId) {
        throw new Error('User not authenticated');
      }

      const userId = req.user.userId;
      const data: CreateCheckInDto = req.body;

      const checkIn = await this.checkInService.createCheckIn(userId, data);

      sendSuccess(res, this.toResponseDto(checkIn), 'Check-in created successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  /**
   * 批量创建签到记录
   * 
   * POST /api/check-ins/batch
   * 
   * 请求体：BatchCreateCheckInsDto
   * 响应：{ message: string }
   * 
   * 调用者：Flutter App - CustomServerRemoteDataRepository.uploadCheckIns()
   */
  batchCreateCheckIns = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // Fail Fast：用户认证检查
      if (!req.user || !req.user.userId) {
        throw new Error('User not authenticated');
      }

      const userId = req.user.userId;
      const { checkIns }: BatchCreateCheckInsDto = req.body;

      // Fail Fast：参数验证
      if (!Array.isArray(checkIns)) {
        throw new Error('checkIns must be an array');
      }

      await this.checkInService.batchCreateCheckIns(userId, checkIns);

      sendSuccess(res, { message: 'Check-ins synced successfully' });
    } catch (error) {
      next(error);
    }
  };

  /**
   * 获取用户所有签到记录
   * 
   * GET /api/check-ins
   * 
   * 响应：{ checkIns: CheckInResponseDto[] }
   * 
   * 调用者：Flutter App - CustomServerRemoteDataRepository.downloadCheckIns()
   */
  getCheckIns = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // Fail Fast：用户认证检查
      if (!req.user || !req.user.userId) {
        throw new Error('User not authenticated');
      }

      const userId = req.user.userId;

      const checkIns = await this.checkInService.getCheckIns(userId);

      sendSuccess(res, {
        checkIns: checkIns.map((c) => this.toResponseDto(c)),
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * 删除签到记录
   * 
   * DELETE /api/check-ins/:id
   * 
   * 响应：{ message: string }
   * 
   * 调用者：Flutter App - CustomServerRemoteDataRepository.deleteCheckIn()
   */
  deleteCheckIn = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // Fail Fast：用户认证检查
      if (!req.user || !req.user.userId) {
        throw new Error('User not authenticated');
      }

      const userId = req.user.userId;
      const checkInId = req.params.id;

      // Fail Fast：参数验证（处理数组情况）
      if (!checkInId || (typeof checkInId === 'string' && checkInId.trim() === '')) {
        throw new Error('Check-in ID is required');
      }
      
      // 确保 checkInId 是字符串
      const id = Array.isArray(checkInId) ? checkInId[0] : checkInId;

      await this.checkInService.deleteCheckIn(id, userId);

      sendSuccess(res, { message: 'Check-in deleted successfully' });
    } catch (error) {
      next(error);
    }
  };

  /**
   * 转换为响应 DTO
   * 
   * 调用者：本类的所有方法
   */
  private toResponseDto(checkIn: CheckIn): CheckInResponseDto {
    return {
      id: checkIn.id,
      userId: checkIn.userId,
      date: checkIn.date.toISOString(),
      checkedAt: checkIn.checkedAt.toISOString(),
      createdAt: checkIn.createdAt.toISOString(),
      updatedAt: checkIn.updatedAt.toISOString(),
    };
  }
}

