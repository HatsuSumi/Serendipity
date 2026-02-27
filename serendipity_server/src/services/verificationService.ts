import { IVerificationCodeRepository } from '../repositories/verificationCodeRepository';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';

// 验证码服务接口
export interface IVerificationService {
  generateCode(): string;
  sendVerificationCode(
    type: 'email' | 'phone',
    target: string,
    purpose: string
  ): Promise<void>;
  verifyCode(target: string, code: string, purpose: string): Promise<boolean>;
}

// 验证码服务实现
export class VerificationService implements IVerificationService {
  private readonly CODE_EXPIRY_MINUTES = 10;

  constructor(
    private verificationCodeRepository: IVerificationCodeRepository
  ) {}

  generateCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async sendVerificationCode(
    type: 'email' | 'phone',
    target: string,
    purpose: string
  ): Promise<void> {
    const code = this.generateCode();
    const expiresAt = new Date(
      Date.now() + this.CODE_EXPIRY_MINUTES * 60 * 1000
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

  async verifyCode(
    target: string,
    code: string,
    purpose: string
  ): Promise<boolean> {
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

