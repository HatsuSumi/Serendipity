import { Request, Response, NextFunction } from 'express';
import { CheckIn } from '@prisma/client';
import { ICheckInService } from '../services/checkInService';
import { CheckInResponseDto, CheckInStatusResponseDto } from '../types/checkIn.dto';
import { sendSuccess } from '../utils/response';

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
    if (!checkInService) {
      throw new Error('CheckInService is required');
    }
  }

  /**
   * 创建今天的签到记录
   *
   * POST /api/check-ins
   */
  createTodayCheckIn = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.userId) {
        throw new Error('User not authenticated');
      }

      const userId = req.user.userId;
      const checkIn = await this.checkInService.createTodayCheckIn(userId);

      sendSuccess(res, this.toResponseDto(checkIn), 'Check-in created successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  /**
   * 获取登录用户签到状态
   *
   * GET /api/check-ins/status?year=2026&month=3
   */
  getCheckInStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.userId) {
        throw new Error('User not authenticated');
      }

      const year = Number(req.query.year);
      const month = Number(req.query.month);
      const status = await this.checkInService.getCheckInStatus(req.user.userId, year, month);

      sendSuccess(res, this.toStatusResponseDto(status));
    } catch (error) {
      next(error);
    }
  };

  /**
   * 获取用户所有签到记录（支持增量同步）
   *
   * GET /api/check-ins?lastSyncTime=2024-01-01T00:00:00.000Z
   */
  getCheckIns = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.userId) {
        throw new Error('User not authenticated');
      }

      const userId = req.user.userId;
      const lastSyncTime = req.query.lastSyncTime as string | undefined;
      const checkIns = await this.checkInService.getCheckIns(userId, lastSyncTime);

      sendSuccess(res, {
        checkIns: checkIns.map((checkIn) => this.toResponseDto(checkIn)),
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * 删除签到记录
   *
   * DELETE /api/check-ins/:id
   */
  deleteCheckIn = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.userId) {
        throw new Error('User not authenticated');
      }

      const checkInId = req.params.id;
      if (!checkInId || (typeof checkInId === 'string' && checkInId.trim() === '')) {
        throw new Error('Check-in ID is required');
      }

      const userId = req.user.userId;
      const id = Array.isArray(checkInId) ? checkInId[0] : checkInId;
      await this.checkInService.deleteCheckIn(id, userId);

      sendSuccess(res, { message: 'Check-in deleted successfully' });
    } catch (error) {
      next(error);
    }
  };

  private toStatusResponseDto(status: Awaited<ReturnType<ICheckInService['getCheckInStatus']>>): CheckInStatusResponseDto {
    return {
      hasCheckedInToday: status.hasCheckedInToday,
      consecutiveDays: status.consecutiveDays,
      totalDays: status.totalDays,
      currentMonthDays: status.currentMonthDays,
      recentCheckIns: status.recentCheckIns.map((checkIn) => this.toResponseDto(checkIn)),
      checkedInDatesInMonth: status.checkedInDatesInMonth.map((date) => date.toISOString()),
    };
  }

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
