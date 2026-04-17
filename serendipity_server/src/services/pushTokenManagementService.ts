import { PushToken } from '@prisma/client';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import {
  IPushTokenRepository,
  RegisterPushTokenData,
} from '../repositories/pushTokenRepository';
import { IUserRepository } from '../repositories/userRepository';

export class PushTokenManagementService {
  constructor(
    private readonly pushTokenRepository: IPushTokenRepository,
    private readonly userRepository: IUserRepository,
  ) {
    if (!pushTokenRepository) {
      throw new Error('PushTokenRepository is required');
    }
    if (!userRepository) {
      throw new Error('UserRepository is required');
    }
  }

  async registerPushToken(userId: string, data: RegisterPushTokenData): Promise<PushToken> {
    await this.ensureUserExists(userId);
    this.validateRegisterData(data);
    return this.pushTokenRepository.register(userId, data);
  }

  async unregisterPushToken(userId: string, token: string): Promise<void> {
    await this.ensureUserExists(userId);
    if (!token || token.trim() === '') {
      throw new AppError('push token is required', ErrorCode.INVALID_REQUEST);
    }

    await this.pushTokenRepository.deactivateByToken(userId, token);
  }

  async markPushTokenInvalid(token: string, reason: string): Promise<void> {
    if (!token || token.trim() === '') {
      throw new AppError('push token is required', ErrorCode.INVALID_REQUEST);
    }
    if (!reason || reason.trim() === '') {
      throw new AppError('invalid reason is required', ErrorCode.INVALID_REQUEST);
    }

    await this.pushTokenRepository.markInvalid(token, reason);
  }

  async listPushTokens(userId: string): Promise<PushToken[]> {
    await this.ensureUserExists(userId);
    return this.pushTokenRepository.findActiveByUserId(userId);
  }

  async ensureUserExists(userId: string): Promise<void> {
    if (!userId || userId.trim() === '') {
      throw new AppError('user id is required', ErrorCode.INVALID_REQUEST);
    }

    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new AppError('user not found', ErrorCode.USER_NOT_FOUND);
    }
  }

  private validateRegisterData(data: RegisterPushTokenData): void {
    if (!data.token || data.token.trim() === '') {
      throw new AppError('push token is required', ErrorCode.INVALID_REQUEST);
    }
    if (!data.platform || data.platform.trim() === '') {
      throw new AppError('platform is required', ErrorCode.INVALID_REQUEST);
    }
    if (!data.timezone || data.timezone.trim() === '') {
      throw new AppError('timezone is required', ErrorCode.INVALID_REQUEST);
    }

    try {
      Intl.DateTimeFormat('en-CA', { timeZone: data.timezone.trim() }).format(new Date());
    } catch {
      throw new AppError(`Invalid timezone: ${data.timezone.trim()}`, ErrorCode.INVALID_REQUEST);
    }
  }
}

