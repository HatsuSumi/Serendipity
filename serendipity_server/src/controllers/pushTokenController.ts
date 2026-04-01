import { Request, Response, NextFunction } from 'express';
import { IPushTokenService } from '../services/pushTokenService';
import { sendSuccess } from '../utils/response';
import { PushToken } from '@prisma/client';
import { PushTokenResponseDto, RegisterPushTokenDto, UnregisterPushTokenDto } from '../types/pushToken.dto';

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
