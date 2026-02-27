import bcrypt from 'bcrypt';
import { User } from '@prisma/client';
import { IUserRepository } from '../repositories/userRepository';
import { IRefreshTokenRepository } from '../repositories/refreshTokenRepository';
import { IVerificationService } from './verificationService';
import { JwtService, JwtPayload } from './jwtService';
import {
  RegisterEmailDto,
  RegisterPhoneDto,
  LoginEmailDto,
  LoginPhoneDto,
  ResetPasswordDto,
  ChangePasswordDto,
  ChangeEmailDto,
  ChangePhoneDto,
  AuthResponseDto,
  UserMeDto,
} from '../types/auth.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';

// 认证服务接口
export interface IAuthService {
  registerEmail(data: RegisterEmailDto): Promise<AuthResponseDto>;
  registerPhone(data: RegisterPhoneDto): Promise<AuthResponseDto>;
  loginEmail(data: LoginEmailDto): Promise<AuthResponseDto>;
  loginPhone(data: LoginPhoneDto): Promise<AuthResponseDto>;
  resetPassword(data: ResetPasswordDto): Promise<void>;
  changePassword(userId: string, data: ChangePasswordDto): Promise<void>;
  changeEmail(userId: string, data: ChangeEmailDto): Promise<void>;
  changePhone(userId: string, data: ChangePhoneDto): Promise<void>;
  getMe(userId: string): Promise<UserMeDto>;
  refreshToken(refreshToken: string): Promise<AuthResponseDto>;
  logout(userId: string): Promise<void>;
}

// 认证服务实现
export class AuthService implements IAuthService {
  private readonly SALT_ROUNDS = 10;
  private readonly REFRESH_TOKEN_EXPIRY_DAYS = 30;
  private readonly ACCESS_TOKEN_EXPIRY_SECONDS = 7 * 24 * 60 * 60; // 7天

  constructor(
    private userRepository: IUserRepository,
    private refreshTokenRepository: IRefreshTokenRepository,
    private verificationService: IVerificationService,
    private jwtService: JwtService
  ) {}

  async registerEmail(data: RegisterEmailDto): Promise<AuthResponseDto> {
    // 验证验证码
    await this.verificationService.verifyCode(
      data.email,
      data.verificationCode,
      'register'
    );

    // 检查邮箱是否已存在
    const existingUser = await this.userRepository.findByEmail(data.email);
    if (existingUser) {
      throw new AppError('Email already exists', ErrorCode.EMAIL_ALREADY_EXISTS);
    }

    // 哈希密码
    const passwordHash = await bcrypt.hash(data.password, this.SALT_ROUNDS);

    // 创建用户
    const user = await this.userRepository.create({
      email: data.email,
      passwordHash,
    });

    // 生成 Token
    return this.generateAuthResponse(user);
  }

  async registerPhone(data: RegisterPhoneDto): Promise<AuthResponseDto> {
    // 验证验证码
    await this.verificationService.verifyCode(
      data.phoneNumber,
      data.verificationCode,
      'register'
    );

    // 检查手机号是否已存在
    const existingUser = await this.userRepository.findByPhone(data.phoneNumber);
    if (existingUser) {
      throw new AppError(
        'Phone number already exists',
        ErrorCode.PHONE_ALREADY_EXISTS
      );
    }

    // 哈希密码
    const passwordHash = await bcrypt.hash(data.password, this.SALT_ROUNDS);

    // 创建用户
    const user = await this.userRepository.create({
      phoneNumber: data.phoneNumber,
      passwordHash,
    });

    // 生成 Token
    return this.generateAuthResponse(user);
  }

  async loginEmail(data: LoginEmailDto): Promise<AuthResponseDto> {
    // 查找用户
    const user = await this.userRepository.findByEmail(data.email);

    if (!user) {
      throw new AppError('Invalid credentials', ErrorCode.INVALID_CREDENTIALS);
    }

    // 验证密码
    const isPasswordValid = await bcrypt.compare(
      data.password,
      user.passwordHash
    );

    if (!isPasswordValid) {
      throw new AppError('Invalid credentials', ErrorCode.INVALID_CREDENTIALS);
    }

    // 更新最后登录时间
    await this.userRepository.updateLastLogin(user.id);

    // 生成 Token
    return this.generateAuthResponse(user);
  }

  async loginPhone(data: LoginPhoneDto): Promise<AuthResponseDto> {
    // 查找用户
    const user = await this.userRepository.findByPhone(data.phoneNumber);

    if (!user) {
      throw new AppError('Invalid credentials', ErrorCode.INVALID_CREDENTIALS);
    }

    // 验证密码
    const isPasswordValid = await bcrypt.compare(
      data.password,
      user.passwordHash
    );

    if (!isPasswordValid) {
      throw new AppError('Invalid credentials', ErrorCode.INVALID_CREDENTIALS);
    }

    // 更新最后登录时间
    await this.userRepository.updateLastLogin(user.id);

    // 生成 Token
    return this.generateAuthResponse(user);
  }

  async resetPassword(data: ResetPasswordDto): Promise<void> {
    // 验证验证码
    await this.verificationService.verifyCode(
      data.email,
      data.verificationCode,
      'reset_password'
    );

    // 查找用户
    const user = await this.userRepository.findByEmail(data.email);

    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    // 哈希新密码
    const passwordHash = await bcrypt.hash(data.newPassword, this.SALT_ROUNDS);

    // 更新密码
    await this.userRepository.updatePassword(user.id, passwordHash);

    // 删除所有刷新令牌（强制重新登录）
    await this.refreshTokenRepository.deleteByUserId(user.id);
  }

  async changePassword(
    userId: string,
    data: ChangePasswordDto
  ): Promise<void> {
    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    // 验证当前密码
    const isPasswordValid = await bcrypt.compare(
      data.currentPassword,
      user.passwordHash
    );

    if (!isPasswordValid) {
      throw new AppError(
        'Invalid current password',
        ErrorCode.INVALID_CREDENTIALS
      );
    }

    // 哈希新密码
    const passwordHash = await bcrypt.hash(data.newPassword, this.SALT_ROUNDS);

    // 更新密码
    await this.userRepository.updatePassword(userId, passwordHash);

    // 删除所有刷新令牌（强制重新登录）
    await this.refreshTokenRepository.deleteByUserId(userId);
  }

  async changeEmail(userId: string, data: ChangeEmailDto): Promise<void> {
    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    // 验证密码
    const isPasswordValid = await bcrypt.compare(
      data.password,
      user.passwordHash
    );

    if (!isPasswordValid) {
      throw new AppError('Invalid password', ErrorCode.INVALID_CREDENTIALS);
    }

    // 验证验证码
    await this.verificationService.verifyCode(
      data.newEmail,
      data.verificationCode,
      'register'
    );

    // 检查新邮箱是否已被使用
    const existingUser = await this.userRepository.findByEmail(data.newEmail);
    if (existingUser && existingUser.id !== userId) {
      throw new AppError('Email already in use', ErrorCode.EMAIL_ALREADY_EXISTS);
    }

    // 更新邮箱
    await this.userRepository.bindEmail(userId, data.newEmail);
  }

  async changePhone(userId: string, data: ChangePhoneDto): Promise<void> {
    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    // 验证验证码
    await this.verificationService.verifyCode(
      data.newPhoneNumber,
      data.verificationCode,
      'register'
    );

    // 检查新手机号是否已被使用
    const existingUser = await this.userRepository.findByPhone(
      data.newPhoneNumber
    );
    if (existingUser && existingUser.id !== userId) {
      throw new AppError(
        'Phone number already in use',
        ErrorCode.PHONE_ALREADY_EXISTS
      );
    }

    // 更新手机号
    await this.userRepository.bindPhone(userId, data.newPhoneNumber);
  }

  async getMe(userId: string): Promise<UserMeDto> {
    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    // TODO: 获取会员信息
    // 暂时返回默认会员信息
    return {
      id: user.id,
      email: user.email || undefined,
      phoneNumber: user.phoneNumber || undefined,
      displayName: user.displayName || undefined,
      createdAt: user.createdAt,
      membership: {
        tier: 'free',
        status: 'inactive',
      },
    };
  }

  async refreshToken(refreshToken: string): Promise<AuthResponseDto> {
    // 查找刷新令牌
    const tokenRecord =
      await this.refreshTokenRepository.findByToken(refreshToken);

    if (!tokenRecord) {
      throw new AppError('Invalid refresh token', ErrorCode.INVALID_TOKEN);
    }

    // 检查是否过期
    if (tokenRecord.expiresAt < new Date()) {
      await this.refreshTokenRepository.deleteByToken(refreshToken);
      throw new AppError('Refresh token expired', ErrorCode.TOKEN_EXPIRED);
    }

    // 查找用户
    const user = await this.userRepository.findById(tokenRecord.userId);

    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    // 删除旧的刷新令牌
    await this.refreshTokenRepository.deleteByToken(refreshToken);

    // 生成新的 Token
    return this.generateAuthResponse(user);
  }

  async logout(userId: string): Promise<void> {
    await this.refreshTokenRepository.deleteByUserId(userId);
  }

  private async generateAuthResponse(user: User): Promise<AuthResponseDto> {
    const payload: JwtPayload = {
      userId: user.id,
      email: user.email || undefined,
      phone: user.phoneNumber || undefined,
    };

    const accessToken = this.jwtService.generateToken(payload);
    const refreshToken = this.jwtService.generateRefreshToken(payload);

    // 保存刷新令牌
    const expiresAt = new Date(
      Date.now() + this.REFRESH_TOKEN_EXPIRY_DAYS * 24 * 60 * 60 * 1000
    );
    await this.refreshTokenRepository.create(user.id, refreshToken, expiresAt);

    return {
      user: {
        id: user.id,
        email: user.email || undefined,
        phoneNumber: user.phoneNumber || undefined,
        createdAt: user.createdAt,
      },
      tokens: {
        accessToken,
        refreshToken,
        expiresIn: this.ACCESS_TOKEN_EXPIRY_SECONDS,
      },
    };
  }
}
