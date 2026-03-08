import { IVerificationCodeRepository } from '../repositories/verificationCodeRepository';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { AUTH_CONFIG } from '../config/auth.config';

/**
 * 验证码服务接口
 * 定义验证码生成、发送和验证的方法
 */
export interface IVerificationService {
  generateCode(): string;
  sendVerificationCode(
    type: 'email' | 'phone',
    target: string,
    purpose: string
  ): Promise<void>;
  verifyCode(target: string, code: string, purpose: string): Promise<boolean>;
}

/**
 * 验证码服务实现
 * 处理验证码的生成、发送和验证逻辑
 */
export class VerificationService implements IVerificationService {
  constructor(
    private verificationCodeRepository: IVerificationCodeRepository
  ) {}

  /**
   * 生成验证码
   * @returns 6位数字验证码
   */
  generateCode(): string {
    const min = Math.pow(10, AUTH_CONFIG.VERIFICATION_CODE_LENGTH - 1);
    const max = Math.pow(10, AUTH_CONFIG.VERIFICATION_CODE_LENGTH) - 1;
    return Math.floor(min + Math.random() * (max - min + 1)).toString();
  }

  /**
   * 发送验证码
   * @param type - 验证码类型（email 或 phone）
   * @param target - 目标邮箱或手机号
   * @param purpose - 用途（register、login、reset_password）
   * @throws {AppError} 参数为空
   */
  async sendVerificationCode(
    type: 'email' | 'phone',
    target: string,
    purpose: string
  ): Promise<void> {
    // Fail Fast：参数验证
    if (!type) {
      throw new AppError('验证码类型不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!target) {
      throw new AppError('目标不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!purpose) {
      throw new AppError('用途不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    const code = this.generateCode();
    const expiresAt = new Date(
      Date.now() + AUTH_CONFIG.VERIFICATION_CODE_EXPIRY_MINUTES * 60 * 1000
    );

    await this.verificationCodeRepository.create(
      type,
      target,
      code,
      purpose,
      expiresAt
    );

    // TODO: 实际发送验证码（邮件/短信）
    // 开发环境下打印到控制台
    if (process.env.NODE_ENV !== 'production') {
      console.log(`[DEV] Verification code for ${target}: ${code}`);
    }

    // 生产环境需要集成邮件服务（如 SendGrid）或短信服务（如阿里云短信）
    if (type === 'email') {
      // await this.emailService.sendVerificationCode(target, code);
    } else {
      // await this.smsService.sendVerificationCode(target, code);
    }
  }

  /**
   * 验证验证码
   * @param target - 目标邮箱或手机号
   * @param code - 验证码
   * @param purpose - 用途
   * @returns 验证是否成功
   * @throws {AppError} 验证码无效或已过期
   */
  async verifyCode(
    target: string,
    code: string,
    purpose: string
  ): Promise<boolean> {
    // Fail Fast：参数验证
    if (!target) {
      throw new AppError('目标不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!code) {
      throw new AppError('验证码不能为空', ErrorCode.INVALID_CREDENTIALS);
    }
    if (!purpose) {
      throw new AppError('用途不能为空', ErrorCode.INVALID_CREDENTIALS);
    }

    const verificationCode =
      await this.verificationCodeRepository.findValidCode(
        target,
        code,
        purpose
      );

    if (!verificationCode) {
      throw new AppError(
        'Invalid or expired verification code',
        ErrorCode.INVALID_VERIFICATION_CODE
      );
    }

    await this.verificationCodeRepository.markAsUsed(verificationCode.id);
    return true;
  }
}

