import crypto from 'crypto';
import { User } from '@prisma/client';
import { IUserRepository } from '../repositories/userRepository';
import { IRefreshTokenRepository } from '../repositories/refreshTokenRepository';
import { IVerificationService } from './verificationService';
import { IPasswordHasher } from './passwordHasher';
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
  GenerateRecoveryKeyResponseDto,
} from '../types/auth.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { AUTH_CONFIG } from '../config/auth.config';

/**
 * 认证服务接口
 * 定义所有认证相关的业务逻辑方法
 */
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
  generateRecoveryKey(userId: string): Promise<GenerateRecoveryKeyResponseDto>;
  getRecoveryKey(userId: string): Promise<string | null>;
}

/**
 * 认证服务实现
 * 处理用户注册、登录、密码管理等认证相关业务逻辑
 */
export class AuthService implements IAuthService {
  constructor(
    private userRepository: IUserRepository,
    private refreshTokenRepository: IRefreshTokenRepository,
    private verificationService: IVerificationService,
    private jwtService: JwtService,
    private passwordHasher: IPasswordHasher
  ) {}

  /**
   * 邮箱注册
   * @param data - 注册数据（邮箱、密码）
   * @returns 认证响应（用户信息、Token、恢复密钥）
   * @throws {AppError} 邮箱已存在
   */
  async registerEmail(data: RegisterEmailDto): Promise<AuthResponseDto> {
    // Fail Fast：参数验证
    this.validateRegisterData(data.email, data.password);

    // 检查邮箱是否已存在
    const existingUser = await this.userRepository.findByEmail(data.email);
    if (existingUser) {
      throw new AppError('邮箱已存在', ErrorCode.EMAIL_ALREADY_EXISTS);
    }

    // 哈希密码
    const passwordHash = await this.passwordHasher.hash(data.password);

    // 创建用户
    const user = await this.userRepository.create({
      email: data.email,
      passwordHash,
    });

    // 自动生成恢复密钥
    const recoveryKey = this.generateRecoveryKeyString();
    await this.userRepository.updateRecoveryKey(user.id, recoveryKey);

    // 生成 Token 并附带恢复密钥
    return this.generateAuthResponseWithRecoveryKey(user, recoveryKey);
  }

  /**
   * 手机号注册
   * @param data - 注册数据（手机号、密码）
   * @returns 认证响应（用户信息、Token、恢复密钥）
   * @throws {AppError} 手机号已存在
   */
  async registerPhone(data: RegisterPhoneDto): Promise<AuthResponseDto> {
    // Fail Fast：参数验证
    this.validateRegisterData(data.phoneNumber, data.password);

    // 检查手机号是否已存在
    const existingUser = await this.userRepository.findByPhone(data.phoneNumber);
    if (existingUser) {
      throw new AppError(
        '手机号已存在',
        ErrorCode.PHONE_ALREADY_EXISTS
      );
    }

    // 哈希密码
    const passwordHash = await this.passwordHasher.hash(data.password);

    // 创建用户
    const user = await this.userRepository.create({
      phoneNumber: data.phoneNumber,
      passwordHash,
    });

    // 自动生成恢复密钥
    const recoveryKey = this.generateRecoveryKeyString();
    await this.userRepository.updateRecoveryKey(user.id, recoveryKey);

    // 生成 Token 并附带恢复密钥
    return this.generateAuthResponseWithRecoveryKey(user, recoveryKey);
  }

  /**
   * 邮箱登录
   * @param data - 登录数据（邮箱、密码）
   * @returns 认证响应（用户信息、Token）
   * @throws {AppError} 邮箱或密码错误
   */
  async loginEmail(data: LoginEmailDto): Promise<AuthResponseDto> {
    // Fail Fast：参数验证
    this.validateLoginData(data.email, data.password);

    // 查找用户并验证密码
    const user = await this.userRepository.findByEmail(data.email);
    const validatedUser = await this.validateUserCredentials(user, data.password, '邮箱或密码错误');

    // 更新最后登录时间
    await this.userRepository.updateLastLogin(validatedUser.id);

    // 生成 Token
    return this.generateAuthResponse(validatedUser);
  }

  /**
   * 手机号登录
   * @param data - 登录数据（手机号、密码）
   * @returns 认证响应（用户信息、Token）
   * @throws {AppError} 手机号或密码错误
   */
  async loginPhone(data: LoginPhoneDto): Promise<AuthResponseDto> {
    // Fail Fast：参数验证
    this.validateLoginData(data.phoneNumber, data.password);

    // 查找用户并验证密码
    const user = await this.userRepository.findByPhone(data.phoneNumber);
    const validatedUser = await this.validateUserCredentials(user, data.password, '手机号或密码错误');

    // 更新最后登录时间
    await this.userRepository.updateLastLogin(validatedUser.id);

    // 生成 Token
    return this.generateAuthResponse(validatedUser);
  }

  /**
   * 重置密码
   * @param data - 重置密码数据（邮箱、恢复密钥、新密码）
   * @throws {AppError} 邮箱或恢复密钥错误
   */
  async resetPassword(data: ResetPasswordDto): Promise<void> {
    // Fail Fast：参数验证
    if (!data.email) {
      throw new AppError('邮箱不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.recoveryKey) {
      throw new AppError('恢复密钥不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.newPassword || data.newPassword.length < 6) {
      throw new AppError('新密码长度必须至少 6 位', ErrorCode.INVALID_CREDENTIALS);
    }

    // 查找用户
    const user = await this.userRepository.findByEmail(data.email);
    if (!user) {
      throw new AppError('邮箱或恢复密钥错误', ErrorCode.INVALID_CREDENTIALS);
    }

    // 验证恢复密钥（直接比对明文）
    if (!user.recoveryKey) {
      throw new AppError('该账户未设置恢复密钥', ErrorCode.INVALID_CREDENTIALS);
    }

    if (data.recoveryKey !== user.recoveryKey) {
      throw new AppError('邮箱或恢复密钥错误', ErrorCode.INVALID_CREDENTIALS);
    }

    // 哈希新密码
    const passwordHash = await this.passwordHasher.hash(data.newPassword);

    // 更新密码
    await this.userRepository.updatePassword(user.id, passwordHash);

    // 删除所有刷新令牌（强制重新登录）
    await this.refreshTokenRepository.deleteByUserId(user.id);
  }

  /**
   * 修改密码
   * @param userId - 用户 ID
   * @param data - 修改密码数据（当前密码、新密码）
   * @throws {AppError} 用户不存在或当前密码错误
   */
  async changePassword(
    userId: string,
    data: ChangePasswordDto
  ): Promise<void> {
    // Fail Fast：参数验证
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.currentPassword) {
      throw new AppError('当前密码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.newPassword || data.newPassword.length < 6) {
      throw new AppError('新密码长度必须至少 6 位', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('用户不存在', ErrorCode.USER_NOT_FOUND);
    }

    // 验证当前密码
    const isPasswordValid = await this.passwordHasher.compare(
      data.currentPassword,
      user.passwordHash
    );

    if (!isPasswordValid) {
      throw new AppError(
        '当前密码错误',
        ErrorCode.INVALID_CREDENTIALS
      );
    }

    // 哈希新密码
    const passwordHash = await this.passwordHasher.hash(data.newPassword);

    // 更新密码
    await this.userRepository.updatePassword(userId, passwordHash);

    // 删除所有刷新令牌（强制重新登录）
    await this.refreshTokenRepository.deleteByUserId(userId);
  }

  /**
   * 更换邮箱
   * @param userId - 用户 ID
   * @param data - 更换邮箱数据（新邮箱、密码、验证码）
   * @throws {AppError} 用户不存在、密码错误或邮箱已被使用
   */
  async changeEmail(userId: string, data: ChangeEmailDto): Promise<void> {
    // Fail Fast：参数验证
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.newEmail) {
      throw new AppError('新邮箱不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.password) {
      throw new AppError('密码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.verificationCode) {
      throw new AppError('验证码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('用户不存在', ErrorCode.USER_NOT_FOUND);
    }

    // 验证密码
    const isPasswordValid = await this.passwordHasher.compare(
      data.password,
      user.passwordHash
    );

    if (!isPasswordValid) {
      throw new AppError('密码错误', ErrorCode.INVALID_CREDENTIALS);
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
      throw new AppError('邮箱已被使用', ErrorCode.EMAIL_ALREADY_EXISTS);
    }

    // 更新邮箱
    await this.userRepository.bindEmail(userId, data.newEmail);
  }

  /**
   * 更换手机号
   * @param userId - 用户 ID
   * @param data - 更换手机号数据（新手机号、验证码）
   * @throws {AppError} 用户不存在或手机号已被使用
   */
  async changePhone(userId: string, data: ChangePhoneDto): Promise<void> {
    // Fail Fast：参数验证
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.newPhoneNumber) {
      throw new AppError('新手机号不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!data.verificationCode) {
      throw new AppError('验证码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('用户不存在', ErrorCode.USER_NOT_FOUND);
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
        '手机号已被使用',
        ErrorCode.PHONE_ALREADY_EXISTS
      );
    }

    // 更新手机号
    await this.userRepository.bindPhone(userId, data.newPhoneNumber);
  }

  /**
   * 获取当前用户信息
   * @param userId - 用户 ID
   * @returns 用户信息（包含会员状态）
   * @throws {AppError} 用户不存在
   */
  async getMe(userId: string): Promise<UserMeDto> {
    // Fail Fast：参数验证
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('用户不存在', ErrorCode.USER_NOT_FOUND);
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

  /**
   * 刷新访问令牌
   * @param refreshToken - 刷新令牌
   * @returns 新的认证响应（用户信息、新 Token）
   * @throws {AppError} 刷新令牌无效或已过期
   */
  async refreshToken(refreshToken: string): Promise<AuthResponseDto> {
    // Fail Fast：参数验证
    if (!refreshToken) {
      throw new AppError('刷新令牌不能为空', ErrorCode.INVALID_TOKEN);
    }

    // 查找刷新令牌
    const tokenRecord =
      await this.refreshTokenRepository.findByToken(refreshToken);

    if (!tokenRecord) {
      throw new AppError('刷新令牌无效', ErrorCode.INVALID_TOKEN);
    }

    // 检查是否过期
    if (tokenRecord.expiresAt < new Date()) {
      await this.refreshTokenRepository.deleteByToken(refreshToken);
      throw new AppError('刷新令牌已过期', ErrorCode.TOKEN_EXPIRED);
    }

    // 查找用户
    const user = await this.userRepository.findById(tokenRecord.userId);

    if (!user) {
      throw new AppError('用户不存在', ErrorCode.USER_NOT_FOUND);
    }

    // 删除旧的刷新令牌
    await this.refreshTokenRepository.deleteByToken(refreshToken);

    // 生成新的 Token
    return this.generateAuthResponse(user);
  }

  /**
   * 登出
   * @param userId - 用户 ID
   */
  async logout(userId: string): Promise<void> {
    // Fail Fast：参数验证
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    await this.refreshTokenRepository.deleteByUserId(userId);
  }

  /**
   * 生成恢复密钥
   * @param userId - 用户 ID
   * @returns 恢复密钥响应
   * @throws {AppError} 用户不存在
   */
  async generateRecoveryKey(userId: string): Promise<GenerateRecoveryKeyResponseDto> {
    // Fail Fast：参数验证
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    // 查找用户
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new AppError('用户不存在', ErrorCode.USER_NOT_FOUND);
    }

    // 生成恢复密钥
    const recoveryKey = this.generateRecoveryKeyString();

    // 直接存储明文（不哈希）
    await this.userRepository.updateRecoveryKey(userId, recoveryKey);

    return {
      recoveryKey,
      message: '请妥善保管恢复密钥，丢失后无法找回',
    };
  }

  /**
   * 获取恢复密钥
   * @param userId - 用户 ID
   * @returns 恢复密钥（可能为 null）
   * @throws {AppError} 用户不存在
   */
  async getRecoveryKey(userId: string): Promise<string | null> {
    // Fail Fast：参数验证
    if (!userId) {
      throw new AppError('用户ID不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    // 查找用户
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new AppError('用户不存在', ErrorCode.USER_NOT_FOUND);
    }

    // 返回恢复密钥（可能为 null）
    return user.recoveryKey;
  }

  /**
   * 生成认证响应（不含恢复密钥）
   * @param user - 用户对象
   * @returns 认证响应（用户信息、Token）
   */
  private async generateAuthResponse(user: User): Promise<AuthResponseDto> {
    const payload: JwtPayload = {
      userId: user.id,
      email: user.email || undefined,
      phone: user.phoneNumber || undefined,
    };

    const accessToken = this.jwtService.generateToken(payload);
    const refreshToken = this.jwtService.generateRefreshToken(payload);

    // 保存刷新令牌（允许多设备登录）
    const expiresAt = new Date(
      Date.now() + AUTH_CONFIG.REFRESH_TOKEN_EXPIRY_DAYS * 24 * 60 * 60 * 1000
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
        expiresIn: AUTH_CONFIG.ACCESS_TOKEN_EXPIRY_SECONDS,
        expiresAt: new Date(Date.now() + AUTH_CONFIG.ACCESS_TOKEN_EXPIRY_SECONDS * 1000).toISOString(),
      },
    };
  }

  /**
   * 生成认证响应（含恢复密钥）
   * @param user - 用户对象
   * @param recoveryKey - 恢复密钥
   * @returns 认证响应（用户信息、Token、恢复密钥）
   */
  private async generateAuthResponseWithRecoveryKey(
    user: User,
    recoveryKey: string
  ): Promise<AuthResponseDto> {
    const payload: JwtPayload = {
      userId: user.id,
      email: user.email || undefined,
      phone: user.phoneNumber || undefined,
    };

    const accessToken = this.jwtService.generateToken(payload);
    const refreshToken = this.jwtService.generateRefreshToken(payload);

    // 保存刷新令牌（允许多设备登录）
    const expiresAt = new Date(
      Date.now() + AUTH_CONFIG.REFRESH_TOKEN_EXPIRY_DAYS * 24 * 60 * 60 * 1000
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
        expiresIn: AUTH_CONFIG.ACCESS_TOKEN_EXPIRY_SECONDS,
        expiresAt: new Date(Date.now() + AUTH_CONFIG.ACCESS_TOKEN_EXPIRY_SECONDS * 1000).toISOString(),
      },
      recoveryKey, // 仅在注册时返回一次
    };
  }

  /**
   * 生成恢复密钥字符串
   * @returns 格式化的恢复密钥（xxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxx）
   */
  private generateRecoveryKeyString(): string {
    const recoveryKey = crypto.randomBytes(AUTH_CONFIG.RECOVERY_KEY_BYTES).toString('hex');
    const regex = new RegExp(`.{1,${AUTH_CONFIG.RECOVERY_KEY_GROUP_LENGTH}}`, 'g');
    return recoveryKey.match(regex)?.join('-') || recoveryKey;
  }

  /**
   * 验证用户凭证
   * @param user - 用户对象（可能为 null）
   * @param password - 明文密码
   * @param errorMessage - 错误消息
   * @returns 验证通过的用户对象
   * @throws {AppError} 用户不存在或密码错误
   */
  private async validateUserCredentials(
    user: User | null,
    password: string,
    errorMessage: string
  ): Promise<User> {
    if (!user) {
      throw new AppError(errorMessage, ErrorCode.INVALID_CREDENTIALS);
    }

    const isPasswordValid = await this.passwordHasher.compare(
      password,
      user.passwordHash
    );

    if (!isPasswordValid) {
      throw new AppError(errorMessage, ErrorCode.INVALID_CREDENTIALS);
    }

    return user;
  }

  /**
   * 验证注册数据
   * @param identifier - 邮箱或手机号
   * @param password - 密码
   * @throws {AppError} 参数为空或密码长度不足
   */
  private validateRegisterData(identifier: string, password: string): void {
    if (!identifier) {
      throw new AppError('邮箱或手机号不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!password || password.length < 6) {
      throw new AppError('密码长度必须至少 6 位', ErrorCode.INVALID_CREDENTIALS);
    }
  }

  /**
   * 验证登录数据
   * @param identifier - 邮箱或手机号
   * @param password - 密码
   * @throws {AppError} 参数为空
   */
  private validateLoginData(identifier: string, password: string): void {
    if (!identifier) {
      throw new AppError('邮箱或手机号不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!password) {
      throw new AppError('密码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
  }
}
