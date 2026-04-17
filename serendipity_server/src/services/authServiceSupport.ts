import crypto from 'crypto';
import { User } from '@prisma/client';
import { IUserRepository } from '../repositories/userRepository';
import { IPasswordHasher } from './passwordHasher';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { AUTH_CONFIG } from '../config/auth.config';

export class AuthServiceSupport {
  constructor(
    private readonly userRepository: IUserRepository,
    private readonly passwordHasher: IPasswordHasher,
  ) {
    if (!userRepository) {
      throw new Error('UserRepository is required');
    }
    if (!passwordHasher) {
      throw new Error('PasswordHasher is required');
    }
  }

  validateRegisterData(identifier: string, password: string, deviceId: string): void {
    if (!identifier) {
      throw new AppError('邮箱或手机号不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!password || password.length < 6) {
      throw new AppError('密码长度必须至少 6 位', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!deviceId) {
      throw new AppError('设备ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
  }

  validateLoginData(identifier: string, password: string, deviceId: string): void {
    if (!identifier) {
      throw new AppError('邮箱或手机号不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!password) {
      throw new AppError('密码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!deviceId) {
      throw new AppError('设备ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
  }

  async validateUserCredentials(
    user: User | null,
    password: string,
    errorMessage: string,
  ): Promise<User> {
    if (!user) {
      throw new AppError(errorMessage, ErrorCode.INVALID_CREDENTIALS);
    }

    const isPasswordValid = await this.passwordHasher.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new AppError(errorMessage, ErrorCode.INVALID_CREDENTIALS);
    }

    return user;
  }

  async ensureUserExists(userId: string): Promise<User> {
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new AppError('用户不存在', ErrorCode.USER_NOT_FOUND);
    }

    return user;
  }

  async ensurePasswordValid(user: User, password: string, errorMessage: string): Promise<void> {
    const isPasswordValid = await this.passwordHasher.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new AppError(errorMessage, ErrorCode.INVALID_CREDENTIALS);
    }
  }

  generateRecoveryKeyString(): string {
    const recoveryKey = crypto.randomBytes(AUTH_CONFIG.RECOVERY_KEY_BYTES).toString('hex');
    const regex = new RegExp(`.{1,${AUTH_CONFIG.RECOVERY_KEY_GROUP_LENGTH}}`, 'g');
    return recoveryKey.match(regex)?.join('-') || recoveryKey;
  }
}

