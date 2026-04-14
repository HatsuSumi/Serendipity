import { PrismaClient, RefreshToken } from '@prisma/client';

// 刷新令牌仓储接口
export interface IRefreshTokenRepository {
  create(userId: string, token: string, expiresAt: Date, deviceId: string): Promise<RefreshToken>;
  findByToken(token: string): Promise<RefreshToken | null>;
  findByTokenAndDeviceId(token: string, deviceId: string): Promise<RefreshToken | null>;
  deleteByToken(token: string): Promise<void>;
  deleteByUserId(userId: string): Promise<number>;
  deleteExpired(): Promise<number>;
  /**
   * 删除该用户除最新一条以外的所有 Token（免费版单设备策略）
   * 调用者：AuthService.generateAuthResponse()（免费版登录时）
   */
  deleteAllExceptNewest(userId: string): Promise<number>;
}

// 刷新令牌仓储实现
export class RefreshTokenRepository implements IRefreshTokenRepository {
  constructor(private prisma: PrismaClient) {}

  async create(
    userId: string,
    token: string,
    expiresAt: Date,
    deviceId: string
  ): Promise<RefreshToken> {
    return this.prisma.refreshToken.create({
      data: {
        userId,
        token,
        expiresAt,
        deviceId,
      },
    });
  }

  async findByToken(token: string): Promise<RefreshToken | null> {
    return this.prisma.refreshToken.findUnique({
      where: { token },
    });
  }

  async findByTokenAndDeviceId(
    token: string,
    deviceId: string
  ): Promise<RefreshToken | null> {
    return this.prisma.refreshToken.findFirst({
      where: { token, deviceId },
    });
  }

  async deleteByToken(token: string): Promise<void> {
    await this.prisma.refreshToken.deleteMany({
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

  /**
   * 删除该用户除最新一条以外的所有 Token（免费版单设备策略）
   *
   * 策略：保留 createdAt 最新的一条，删除其余所有 Token。
   * 这样新设备登录后，旧设备的 Token 立即失效。
   *
   * 调用者：AuthService.generateAuthResponse()（免费版登录时）
   *
   * @param userId - 用户 ID
   * @returns 被删除的 Token 数量
   */
  async deleteAllExceptNewest(userId: string): Promise<number> {
    // 查出该用户最新的一条 Token 的 ID
    const newest = await this.prisma.refreshToken.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: { id: true },
    });

    // 该用户没有任何 Token，无需操作
    if (!newest) return 0;

    const result = await this.prisma.refreshToken.deleteMany({
      where: {
        userId,
        id: { not: newest.id },
      },
    });
    return result.count;
  }
}

