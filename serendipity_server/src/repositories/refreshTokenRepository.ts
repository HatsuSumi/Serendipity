import { PrismaClient, RefreshToken } from '@prisma/client';

// 刷新令牌仓储接口
export interface IRefreshTokenRepository {
  create(userId: string, token: string, expiresAt: Date): Promise<RefreshToken>;
  findByToken(token: string): Promise<RefreshToken | null>;
  deleteByToken(token: string): Promise<void>;
  deleteByUserId(userId: string): Promise<number>;
  deleteExpired(): Promise<number>;
}

// 刷新令牌仓储实现
export class RefreshTokenRepository implements IRefreshTokenRepository {
  constructor(private prisma: PrismaClient) {}

  async create(
    userId: string,
    token: string,
    expiresAt: Date
  ): Promise<RefreshToken> {
    return this.prisma.refreshToken.create({
      data: {
        userId,
        token,
        expiresAt,
      },
    });
  }

  async findByToken(token: string): Promise<RefreshToken | null> {
    return this.prisma.refreshToken.findUnique({
      where: { token },
    });
  }

  async deleteByToken(token: string): Promise<void> {
    await this.prisma.refreshToken.delete({
      where: { token },
    });
  }

  async deleteByUserId(userId: string): Promise<number> {
    const result = await this.prisma.refreshToken.deleteMany({
      where: { userId },
    });
    return result.count;
  }

  async deleteExpired(): Promise<number> {
    const result = await this.prisma.refreshToken.deleteMany({
      where: {
        expiresAt: {
          lt: new Date(),
        },
      },
    });
    return result.count;
  }
}

