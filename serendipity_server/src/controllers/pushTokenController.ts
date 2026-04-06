import { Request, Response, NextFunction } from 'express';
import { PushToken } from '@prisma/client';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import {
  IPushTokenService,
  ReminderDispatchExecution,
  ReminderDispatchSummary,
} from '../services/pushTokenService';
import {
  AnniversaryReminderTestPayload,
  PushTokenResponseDto,
  RegisterPushTokenDto,
  ReminderDispatchExecutionDto,
  ReminderDispatchSummaryDto,
  UnregisterPushTokenDto,
} from '../types/pushToken.dto';
import { sendSuccess } from '../utils/response';

const ANNIVERSARY_TEST_PAYLOAD: AnniversaryReminderTestPayload = {
  title: '今天是一个特别的纪念日 🌸',
  body: '1年前的今天，你在某个地方邂逅了TA（测试推送）',
};

export class PushTokenController {
  constructor(private pushTokenService: IPushTokenService) {
    if (!pushTokenService) {
      throw new Error('PushTokenService is required');
    }
  }

  registerPushToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data = req.body as RegisterPushTokenDto;
      const pushToken = await this.pushTokenService.registerPushToken(userId, data);
      sendSuccess(res, this.toPushTokenDto(pushToken), 'Push token registered successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  unregisterPushToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data = req.body as UnregisterPushTokenDto;
      await this.pushTokenService.unregisterPushToken(userId, data.token);
      sendSuccess(res, null, 'Push token unregistered successfully');
    } catch (error) {
      next(error);
    }
  };

  listPushTokens = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const pushTokens = await this.pushTokenService.listPushTokens(userId);
      sendSuccess(res, {
        pushTokens: pushTokens.map((pushToken) => this.toPushTokenDto(pushToken)),
      });
    } catch (error) {
      next(error);
    }
  };

  sendCheckInReminderTest = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const result = await this.pushTokenService.dispatchReminderNotificationsForUser(userId);
      this.sendDispatchTestResponse(res, result, 'Check-in reminder test sent successfully');
    } catch (error) {
      next(error);
    }
  };

  sendAnniversaryReminderTest = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const result = await this.pushTokenService.dispatchReminderNotificationsForUser(
        userId,
        new Date(),
        ANNIVERSARY_TEST_PAYLOAD,
      );
      this.sendDispatchTestResponse(res, result, 'Anniversary reminder test sent successfully');
    } catch (error) {
      next(error);
    }
  };

  private sendDispatchTestResponse(
    res: Response,
    result: ReminderDispatchSummary,
    successMessage: string,
  ): void {
    if (result.scannedCandidates === 0) {
      throw new AppError('当前账号没有可用的 push token，请先完成设备注册', ErrorCode.INVALID_REQUEST);
    }

    if (result.sentCount === 0 && result.failedCount > 0) {
      throw new AppError('测试推送提交失败，请检查 push token、FCM/APNs 配置与当前网络环境', ErrorCode.SERVICE_UNAVAILABLE);
    }

    sendSuccess(res, this.toReminderDispatchSummaryDto(result), successMessage);
  }

  private toReminderDispatchSummaryDto(summary: ReminderDispatchSummary): ReminderDispatchSummaryDto {
    return {
      dispatchSource: summary.dispatchSource,
      scannedCandidates: summary.scannedCandidates,
      sentCount: summary.sentCount,
      failedCount: summary.failedCount,
      executions: summary.executions.map((execution) => this.toReminderDispatchExecutionDto(execution)),
    };
  }

  private toReminderDispatchExecutionDto(execution: ReminderDispatchExecution): ReminderDispatchExecutionDto {
    return {
      userId: execution.userId,
      pushTokenId: execution.pushTokenId,
      platform: execution.platform,
      timezone: execution.timezone,
      reminderDate: execution.reminderDate.toISOString(),
      reminderTime: execution.reminderTime,
      status: execution.status,
      failureReason: execution.failureReason,
    };
  }

  private toPushTokenDto(pushToken: PushToken): PushTokenResponseDto {
    return {
      id: pushToken.id,
      token: pushToken.token,
      platform: pushToken.platform,
      timezone: pushToken.timezone,
      isActive: pushToken.isActive,
      lastUsedAt: pushToken.lastUsedAt.toISOString(),
      invalidatedAt: pushToken.invalidatedAt?.toISOString(),
      invalidReason: pushToken.invalidReason ?? undefined,
      createdAt: pushToken.createdAt.toISOString(),
      updatedAt: pushToken.updatedAt.toISOString(),
    };
  }
}
