import { IUserRepository } from '../repositories/userRepository';
import { IRefreshTokenRepository } from '../repositories/refreshTokenRepository';
import { IPasswordHasher } from './passwordHasher';
import { AuthServiceSupport } from './authServiceSupport';
import {
  GenerateRecoveryKeyResponseDto,
  ResetPasswordDto,
} from '../types/auth.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';

export class AuthRecoveryService {
  constructor(
    private readonly userRepository: IUserRepository,
    private readonly refreshTokenRepository: IRefreshTokenRepository,
    private readonly passwordHasher: IPasswordHasher,
    private readonly authServiceSupport: AuthServiceSupport,
  ) {
    if (!userRepository) {
      throw new Error('UserRepository is required');
    }
    if (!refreshTokenRepository) {
      throw new Error('RefreshTokenRepository is required');
    }
    if (!passwordHasher) {
      throw new Error('PasswordHasher is required');
    }
    if (!authServiceSupport) {
      throw new Error('AuthServiceSupport is required');
    }
  }

  async resetPassword(data: ResetPasswordDto): Promise<void> {
    if (!data.accountType || !['email', 'phone'].includes(data.accountType)) {
      throw new AppError('账号类型不正确', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.account) {
      throw new AppError(data.accountType === 'email' ? '邮箱不能为空' : '手机号不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.recoveryKey) {
      throw new AppError('恢复密钥不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.newPassword || data.newPassword.length < 6) {
      throw new AppError('新密码长度必须至少 6 位', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = data.accountType === 'email'
      ? await this.userRepository.findByEmail(data.account)
      : await this.userRepository.findByPhone(data.account);
    const invalidCredentialsMessage = data.accountType === 'email'
      ? '邮箱或恢复密钥错误'
      : '手机号或恢复密钥错误';

    if (!user) {
      throw new AppError(invalidCredentialsMessage, ErrorCode.INVALID_CREDENTIALS);
    }
    if (!user.recoveryKey) {
      throw new AppError('该账户未设置恢复密钥', ErrorCode.INVALID_CREDENTIALS);
    }
    if (data.recoveryKey !== user.recoveryKey) {
      throw new AppError(invalidCredentialsMessage, ErrorCode.INVALID_CREDENTIALS);
    }

    const passwordHash = await this.passwordHasher.hash(data.newPassword);
    await this.userRepository.updatePassword(user.id, passwordHash);
    await this.refreshTokenRepository.deleteByUserId(user.id);
  }

  async generateRecoveryKey(userId: string): Promise<GenerateRecoveryKeyResponseDto> {
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    await this.authServiceSupport.ensureUserExists(userId);

    const recoveryKey = this.authServiceSupport.generateRecoveryKeyString();
    await this.userRepository.updateRecoveryKey(userId, recoveryKey);

    return {
      recoveryKey,
      message: '请妥善保管恢复密钥，丢失后无法找回',
    };
  }

  async getRecoveryKey(userId: string): Promise<string | null> {
    const user = await this.authServiceSupport.ensureUserExists(userId);
    return user.recoveryKey;
  }
}

