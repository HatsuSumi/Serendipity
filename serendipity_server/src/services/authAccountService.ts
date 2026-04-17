import { IUserRepository } from '../repositories/userRepository';
import { IRefreshTokenRepository } from '../repositories/refreshTokenRepository';
import { AuthServiceSupport } from './authServiceSupport';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';

export class AuthAccountService {
  constructor(
    private readonly userRepository: IUserRepository,
    private readonly refreshTokenRepository: IRefreshTokenRepository,
    private readonly authServiceSupport: AuthServiceSupport,
  ) {
    if (!userRepository) {
      throw new Error('UserRepository is required');
    }
    if (!refreshTokenRepository) {
      throw new Error('RefreshTokenRepository is required');
    }
    if (!authServiceSupport) {
      throw new Error('AuthServiceSupport is required');
    }
  }

  async deleteAccount(userId: string, password: string): Promise<void> {
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!password) {
      throw new AppError('密码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = await this.authServiceSupport.ensureUserExists(userId);
    await this.authServiceSupport.ensurePasswordValid(user, password, '密码错误');

    await this.refreshTokenRepository.deleteByUserId(userId);
    await this.userRepository.deleteById(userId);
  }
}

