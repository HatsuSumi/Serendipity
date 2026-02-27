import { PrismaClient, VerificationCode } from '@prisma/client';

// 验证码仓储接口
export interface IVerificationCodeRepository {
  create(
    type: string,
    target: string,
    code: string,
    purpose: string,
    expiresAt: Date
  ): Promise<VerificationCode>;
  findValidCode(
    target: string,
    code: string,
    purpose: string
  ): Promise<VerificationCode | null>;
  markAsUsed(id: string): Promise<VerificationCode>;
  deleteExpired(): Promise<number>;
}

// 验证码仓储实现
export class VerificationCodeRepository implements IVerificationCodeRepository {
  constructor(private prisma: PrismaClient) {}

  async create(
    type: string,
    target: string,
    code: string,
    purpose: string,
    expiresAt: Date
  ): Promise<VerificationCode> {
    return this.prisma.verificationCode.create({
      data: {
        type,
        target,
        code,
        purpose,
        expiresAt,
      },
    });
  }

  async findValidCode(
    target: string,
    code: string,
    purpose: string
  ): Promise<VerificationCode | null> {
    return this.prisma.verificationCode.findFirst({
      where: {
        target,
        code,
        purpose,
        used: false,
        expiresAt: {
          gt: new Date(),
        },
      },
    });
  }

  async markAsUsed(id: string): Promise<VerificationCode> {
    return this.prisma.verificationCode.update({
      where: { id },
      data: { used: true },
    });
  }

  async deleteExpired(): Promise<number> {
    const result = await this.prisma.verificationCode.deleteMany({
      where: {
        expiresAt: {
          lt: new Date(),
        },
      },
    });
    return result.count;
  }
}

