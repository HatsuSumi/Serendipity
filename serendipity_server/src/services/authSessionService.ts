import { User } from '@prisma/client';
import { IRefreshTokenRepository } from '../repositories/refreshTokenRepository';
import { JwtService, JwtPayload } from './jwtService';
import { AuthResponseDto } from '../types/auth.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { AUTH_CONFIG } from '../config/auth.config';
import { toAuthUserDto } from '../types/user.mapper';

export class AuthSessionService {
  constructor(
    private readonly refreshTokenRepository: IRefreshTokenRepository,
    private readonly jwtService: JwtService,
  ) {
    if (!refreshTokenRepository) {
      throw new Error('RefreshTokenRepository is required');
    }
    if (!jwtService) {
      throw new Error('JwtService is required');
    }
  }

  async refreshToken(user: User, refreshToken: string, deviceId: string): Promise<AuthResponseDto> {
    if (!refreshToken) {
      throw new AppError('刷新令牌不能为空', ErrorCode.INVALID_TOKEN);
    }
    if (!deviceId) {
      throw new AppError('设备ID不能为空', ErrorCode.INVALID_TOKEN);
    }

    await this.refreshTokenRepository.deleteByToken(refreshToken);
    return this.generateAuthResponse(user, deviceId);
  }

  async logout(userId: string): Promise<void> {
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    await this.refreshTokenRepository.deleteByUserId(userId);
  }

  generateAuthResponse(user: User, deviceId: string): Promise<AuthResponseDto> {
    return this.buildAuthResponse(user, deviceId, {
      deleteOldTokens: true,
    });
  }

  generateAuthResponseWithRecoveryKey(
    user: User,
    recoveryKey: string,
    deviceId: string,
  ): Promise<AuthResponseDto> {
    return this.buildAuthResponse(user, deviceId, {
      deleteOldTokens: false,
      recoveryKey,
    });
  }

  private async buildAuthResponse(
    user: User,
    deviceId: string,
    options: { deleteOldTokens: boolean; recoveryKey?: string },
  ): Promise<AuthResponseDto> {
    const payload: JwtPayload = {
      userId: user.id,
      deviceId,
      email: user.email || undefined,
      phone: user.phoneNumber || undefined,
    };

    const accessToken = this.jwtService.generateToken(payload);
    const refreshToken = this.jwtService.generateRefreshToken(payload);
    const expiresAt = new Date(
      Date.now() + AUTH_CONFIG.REFRESH_TOKEN_EXPIRY_DAYS * 24 * 60 * 60 * 1000,
    );

    await this.refreshTokenRepository.createOrReplace(user.id, refreshToken, expiresAt, deviceId);

    if (options.deleteOldTokens) {
      await this.refreshTokenRepository.deleteAllExceptNewest(user.id);
    }

    return {
      user: toAuthUserDto(user),
      tokens: {
        accessToken,
        refreshToken,
        expiresIn: AUTH_CONFIG.ACCESS_TOKEN_EXPIRY_SECONDS,
        expiresAt: new Date(Date.now() + AUTH_CONFIG.ACCESS_TOKEN_EXPIRY_SECONDS * 1000).toISOString(),
      },
      recoveryKey: options.recoveryKey,
    };
  }
}

