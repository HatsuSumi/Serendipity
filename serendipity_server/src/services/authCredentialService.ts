import { IUserRepository } from '../repositories/userRepository';
import { IPasswordHasher } from './passwordHasher';
import { AuthServiceSupport } from './authServiceSupport';
import {
  AuthResponseDto,
  ChangeEmailDto,
  ChangePasswordDto,
  ChangePhoneDto,
} from '../types/auth.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { toAuthUserDto } from '../types/user.mapper';

export class AuthCredentialService {
  constructor(
    private readonly userRepository: IUserRepository,
    private readonly passwordHasher: IPasswordHasher,
    private readonly authServiceSupport: AuthServiceSupport,
  ) {
    if (!userRepository) {
      throw new Error('UserRepository is required');
    }
    if (!passwordHasher) {
      throw new Error('PasswordHasher is required');
    }
    if (!authServiceSupport) {
      throw new Error('AuthServiceSupport is required');
    }
  }

  async changePassword(userId: string, data: ChangePasswordDto): Promise<void> {
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.currentPassword) {
      throw new AppError('当前密码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.newPassword || data.newPassword.length < 6) {
      throw new AppError('密码长度必须至少 6 位', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = await this.authServiceSupport.ensureUserExists(userId);
    await this.authServiceSupport.ensurePasswordValid(user, data.currentPassword, '当前密码错误');

    const passwordHash = await this.passwordHasher.hash(data.newPassword);
    await this.userRepository.updatePassword(userId, passwordHash);
  }

  async changeEmail(userId: string, data: ChangeEmailDto): Promise<AuthResponseDto['user']> {
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.newEmail) {
      throw new AppError('新邮箱不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.password) {
      throw new AppError('密码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = await this.authServiceSupport.ensureUserExists(userId);
    await this.authServiceSupport.ensurePasswordValid(user, data.password, '密码错误');

    if (!user.email) {
      throw new AppError('当前账号未绑定邮箱，无法更换', ErrorCode.VALIDATION_ERROR);
    }
    if (user.email === data.newEmail) {
      throw new AppError('新邮箱不能与当前邮箱相同', ErrorCode.VALIDATION_ERROR);
    }

    const existingUser = await this.userRepository.findByEmail(data.newEmail);
    if (existingUser && existingUser.id !== userId) {
      throw new AppError('邮箱已被使用', ErrorCode.EMAIL_ALREADY_EXISTS);
    }

    const updatedUser = await this.userRepository.bindEmail(userId, data.newEmail);
    return toAuthUserDto(updatedUser);
  }

  async changePhone(userId: string, data: ChangePhoneDto): Promise<AuthResponseDto['user']> {
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.newPhoneNumber) {
      throw new AppError('新手机号不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.password) {
      throw new AppError('密码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = await this.authServiceSupport.ensureUserExists(userId);
    await this.authServiceSupport.ensurePasswordValid(user, data.password, '密码错误');

    if (!user.phoneNumber) {
      throw new AppError('当前账号未绑定手机号，无法更换', ErrorCode.VALIDATION_ERROR);
    }
    if (user.phoneNumber === data.newPhoneNumber) {
      throw new AppError('新手机号不能与当前手机号相同', ErrorCode.VALIDATION_ERROR);
    }

    const existingUser = await this.userRepository.findByPhone(data.newPhoneNumber);
    if (existingUser && existingUser.id !== userId) {
      throw new AppError('手机号已被使用', ErrorCode.PHONE_ALREADY_EXISTS);
    }

    const updatedUser = await this.userRepository.bindPhone(userId, data.newPhoneNumber);
    return toAuthUserDto(updatedUser);
  }
}

