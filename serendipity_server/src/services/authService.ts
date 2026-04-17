import { IUserRepository } from '../repositories/userRepository';
import { IRefreshTokenRepository } from '../repositories/refreshTokenRepository';
import { IMembershipRepository } from '../repositories/membershipRepository';
import { IPasswordHasher } from './passwordHasher';
import { JwtService } from './jwtService';
import { AuthSessionService } from './authSessionService';
import { AuthServiceSupport } from './authServiceSupport';
import { AuthAccessService } from './authAccessService';
import { AuthCredentialService } from './authCredentialService';
import { AuthRecoveryService } from './authRecoveryService';
import { AuthAccountService } from './authAccountService';
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
import { toAuthUserDto } from '../types/user.mapper';

/**
 * 认证服务接口
 * 定义所有认证相关的业务逻辑方法
 */
export interface IAuthService {
  registerEmail(data: RegisterEmailDto): Promise<AuthResponseDto>;
  registerPhonePassword(data: RegisterPhoneDto): Promise<AuthResponseDto>;
  registerPhone(data: RegisterPhoneDto): Promise<AuthResponseDto>;
  loginEmail(data: LoginEmailDto): Promise<AuthResponseDto>;
  loginPhonePassword(data: LoginPhoneDto): Promise<AuthResponseDto>;
  loginPhone(data: LoginPhoneDto): Promise<AuthResponseDto>;
  resetPassword(data: ResetPasswordDto): Promise<void>;
  changePassword(userId: string, data: ChangePasswordDto): Promise<void>;
  changeEmail(userId: string, data: ChangeEmailDto): Promise<AuthResponseDto['user']>;
  changePhone(userId: string, data: ChangePhoneDto): Promise<AuthResponseDto['user']>;
  getMe(userId: string): Promise<UserMeDto>;
  refreshToken(refreshToken: string, deviceId: string): Promise<AuthResponseDto>;
  logout(userId: string): Promise<void>;
  generateRecoveryKey(userId: string): Promise<GenerateRecoveryKeyResponseDto>;
  getRecoveryKey(userId: string): Promise<string | null>;
  deleteAccount(userId: string, password: string): Promise<void>;
}

/**
 * 认证服务实现
 * 处理用户注册、登录、密码管理等认证相关业务逻辑
 */
export class AuthService implements IAuthService {
  private readonly authServiceSupport: AuthServiceSupport;
  private readonly authSessionService: AuthSessionService;
  private readonly authAccessService: AuthAccessService;
  private readonly authCredentialService: AuthCredentialService;
  private readonly authRecoveryService: AuthRecoveryService;
  private readonly authAccountService: AuthAccountService;

  constructor(
    private userRepository: IUserRepository,
    private refreshTokenRepository: IRefreshTokenRepository,
    private membershipRepository: IMembershipRepository,
    private jwtService: JwtService,
    private passwordHasher: IPasswordHasher
  ) {
    this.authServiceSupport = new AuthServiceSupport(this.userRepository, this.passwordHasher);
    this.authSessionService = new AuthSessionService(this.refreshTokenRepository, this.jwtService);
    this.authAccessService = new AuthAccessService(
      this.userRepository,
      this.passwordHasher,
      this.authSessionService,
      this.authServiceSupport,
    );
    this.authCredentialService = new AuthCredentialService(
      this.userRepository,
      this.passwordHasher,
      this.authServiceSupport,
    );
    this.authRecoveryService = new AuthRecoveryService(
      this.userRepository,
      this.refreshTokenRepository,
      this.passwordHasher,
      this.authServiceSupport,
    );
    this.authAccountService = new AuthAccountService(
      this.userRepository,
      this.refreshTokenRepository,
      this.authServiceSupport,
    );
  }

  /**
   * 邮箱注册
   * @param data - 注册数据（邮箱、密码）
   * @returns 认证响应（用户信息、Token、恢复密钥）
   * @throws {AppError} 邮箱已存在
   */
  async registerEmail(data: RegisterEmailDto): Promise<AuthResponseDto> {
    return this.authAccessService.registerEmail(data);
  }

  /**
   * 手机号密码注册
   * @param data - 注册数据（手机号、密码）
   * @returns 认证响应（用户信息、Token、恢复密钥）
   * @throws {AppError} 手机号已存在
   */
  async registerPhonePassword(data: RegisterPhoneDto): Promise<AuthResponseDto> {
    return this.authAccessService.registerPhonePassword(data);
  }

  /**
   * 手机号注册（验证码方式）
   * @param data - 注册数据（手机号、密码）
   * @returns 认证响应（用户信息、Token、恢复密钥）
   * @throws {AppError} 手机号已存在
   */
  async registerPhone(data: RegisterPhoneDto): Promise<AuthResponseDto> {
    return this.authAccessService.registerPhone(data);
  }

  /**
   * 邮箱登录
   * @param data - 登录数据（邮箱、密码）
   * @returns 认证响应（用户信息、Token）
   * @throws {AppError} 邮箱或密码错误
   */
  async loginEmail(data: LoginEmailDto): Promise<AuthResponseDto> {
    return this.authAccessService.loginEmail(data);
  }

  /**
   * 手机号密码登录
   * @param data - 登录数据（手机号、密码）
   * @returns 认证响应（用户信息、Token）
   * @throws {AppError} 手机号或密码错误
   */
  async loginPhonePassword(data: LoginPhoneDto): Promise<AuthResponseDto> {
    return this.authAccessService.loginPhonePassword(data);
  }

  /**
   * 手机号登录（验证码方式）
   * @param data - 登录数据（手机号、密码）
   * @returns 认证响应（用户信息、Token）
   * @throws {AppError} 手机号或密码错误
   */
  async loginPhone(data: LoginPhoneDto): Promise<AuthResponseDto> {
    return this.authAccessService.loginPhone(data);
  }

  /**
   * 重置密码
   * @param data - 重置密码数据（邮箱、恢复密钥、新密码）
   * @throws {AppError} 邮箱或恢复密钥错误
   */
  async resetPassword(data: ResetPasswordDto): Promise<void> {
    return this.authRecoveryService.resetPassword(data);
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
    return this.authCredentialService.changePassword(userId, data);
  }

  /**
   * 更换邮箱（不支持绑定）
   * @param userId - 用户 ID
   * @param data - 更换邮箱数据（新邮箱、密码）
   * @throws {AppError} 用户不存在、密码错误、未绑定邮箱或邮箱已被使用
   */
  async changeEmail(userId: string, data: ChangeEmailDto): Promise<AuthResponseDto['user']> {
    return this.authCredentialService.changeEmail(userId, data);
  }

  /**
   * 更换手机号（不支持绑定）
   * @param userId - 用户 ID
   * @param data - 更换手机号数据（新手机号、密码）
   * @throws {AppError} 用户不存在、密码错误、未绑定手机号或手机号已被使用
   */
  async changePhone(userId: string, data: ChangePhoneDto): Promise<AuthResponseDto['user']> {
    return this.authCredentialService.changePhone(userId, data);
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

    const user = await this.authServiceSupport.ensureUserExists(userId);

    const membership = await this.membershipRepository.findByUserId(userId);
    const membershipTier = membership?.tier === 'premium' ? 'premium' : 'free';
    const membershipStatus = this.resolveMembershipStatus(membership);

    return {
      ...toAuthUserDto(user),
      membership: {
        tier: membershipTier,
        status: membershipStatus,
      },
    };
  }

  /**
   * 刷新访问令牌
   * @param refreshToken - 刷新令牌
   * @returns 新的认证响应（用户信息、新 Token）
   * @throws {AppError} 刷新令牌无效或已过期
   */
  async refreshToken(refreshToken: string, deviceId: string): Promise<AuthResponseDto> {
    // Fail Fast：参数验证
    if (!refreshToken) {
      throw new AppError('刷新令牌不能为空', ErrorCode.INVALID_TOKEN);
    }
    if (!deviceId) {
      throw new AppError('设备ID不能为空', ErrorCode.INVALID_TOKEN);
    }

    // 查找刷新令牌
    const tokenRecord =
      await this.refreshTokenRepository.findByTokenAndDeviceId(refreshToken, deviceId);

    if (!tokenRecord) {
      throw new AppError('刷新令牌无效', ErrorCode.INVALID_TOKEN);
    }

    // 检查是否过期
    if (tokenRecord.expiresAt < new Date()) {
      await this.refreshTokenRepository.deleteByToken(refreshToken);
      throw new AppError('刷新令牌已过期', ErrorCode.TOKEN_EXPIRED);
    }

    const user = await this.authServiceSupport.ensureUserExists(tokenRecord.userId);
    return this.authSessionService.refreshToken(user, refreshToken, deviceId);
  }

  /**
   * 登出
   * @param userId - 用户 ID
   */
  async logout(userId: string): Promise<void> {
    return this.authSessionService.logout(userId);
  }

  /**
   * 注销账号
   *
   * 调用者：authController.deleteAccount()
   *
   * 注销流程：
   * 1. 验证密码
   * 2. 删除所有 Refresh Token
   * 3. 删除用户记录（级联删除由数据库外键约束处理）
   *
   * @param userId - 用户 ID
   * @param password - 当前密码（身份验证）
   * @throws {AppError} 用户不存在或密码错误
   */
  async deleteAccount(userId: string, password: string): Promise<void> {
    return this.authAccountService.deleteAccount(userId, password);
  }

  /**
   * 生成恢复密钥
   * @param userId - 用户 ID
   * @returns 恢复密钥响应
   * @throws {AppError} 用户不存在
   */
  async generateRecoveryKey(userId: string): Promise<GenerateRecoveryKeyResponseDto> {
    return this.authRecoveryService.generateRecoveryKey(userId);
  }

  /**
   * 获取恢复密钥
   * @param userId - 用户 ID
   * @returns 恢复密钥（可能为 null）
   * @throws {AppError} 用户不存在
   */
  async getRecoveryKey(userId: string): Promise<string | null> {
    return this.authRecoveryService.getRecoveryKey(userId);
  }

  private resolveMembershipStatus(
    membership: Awaited<ReturnType<IMembershipRepository['findByUserId']>>
  ): 'inactive' | 'active' | 'expired' | 'cancelled' {
    if (!membership) {
      return 'inactive';
    }
    if (membership.status !== 'active') {
      return membership.status as 'inactive' | 'active' | 'expired' | 'cancelled';
    }
    if (!membership.expiresAt || membership.expiresAt > new Date()) {
      return 'active';
    }
    return 'expired';
  }
}
