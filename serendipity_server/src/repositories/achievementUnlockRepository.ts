import { PrismaClient, AchievementUnlock } from '@prisma/client';
import { CreateAchievementUnlockDto } from '../types/achievementUnlock.dto';

/**
 * 成就解锁仓储接口
 * 
 * 定义成就解锁数据访问的抽象接口，遵循依赖倒置原则（DIP）
 * 
 * 调用者：
 * - AchievementUnlockService：业务逻辑层
 */
export interface IAchievementUnlockRepository {
  /**
   * 创建或更新成就解锁记录
   * 
   * 使用 upsert 确保幂等性：
   * - 如果记录已存在，更新 unlockedAt（使用最早的解锁时间）
   * - 如果记录不存在，创建新记录
   * 
   * Fail Fast：
   * - data 缺少必填字段：抛出错误（由 Prisma 处理）
   * 
   * 调用者：AchievementUnlockService.createAchievementUnlock()
   */
  upsert(data: CreateAchievementUnlockDto): Promise<AchievementUnlock>;

  /**
   * 获取用户所有成就解锁记录
   * 
   * Fail Fast：
   * - userId 为空：抛出 Error
   * 
   * 调用者：AchievementUnlockService.getAchievementUnlocks()
   */
  findByUserId(userId: string): Promise<AchievementUnlock[]>;

  /**
   * 查找特定用户的特定成就解锁记录
   * 
   * Fail Fast：
   * - userId 为空：抛出 Error
   * - achievementId 为空：抛出 Error
   * 
   * 调用者：AchievementUnlockService（内部使用）
   */
  findByUserAndAchievement(userId: string, achievementId: string): Promise<AchievementUnlock | null>;
}

/**
 * 成就解锁仓储实现
 * 
 * 负责成就解锁数据的持久化操作，遵循单一职责原则（SRP）
 * 
 * 调用者：
 * - AchievementUnlockService：通过依赖注入
 */
export class AchievementUnlockRepository implements IAchievementUnlockRepository {
  constructor(private prisma: PrismaClient) {
    // Fail Fast：依赖检查
    if (!prisma) {
      throw new Error('PrismaClient is required');
    }
  }

  async upsert(data: CreateAchievementUnlockDto): Promise<AchievementUnlock> {
    // Fail Fast：参数验证
    if (!data.userId || data.userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!data.achievementId || data.achievementId.trim() === '') {
      throw new Error('achievementId is required');
    }
    if (!data.unlockedAt) {
      throw new Error('unlockedAt is required');
    }

    const unlockedAt = new Date(data.unlockedAt);
    if (isNaN(unlockedAt.getTime())) {
      throw new Error('Invalid unlockedAt date');
    }

    return this.prisma.achievementUnlock.upsert({
      where: {
        userId_achievementId: {
          userId: data.userId,
          achievementId: data.achievementId,
        },
      },
      update: {
        // 如果已存在，使用最早的解锁时间
        unlockedAt: {
          set: unlockedAt,
        },
      },
      create: {
        userId: data.userId,
        achievementId: data.achievementId,
        unlockedAt,
      },
    });
  }

  async findByUserId(userId: string): Promise<AchievementUnlock[]> {
    // Fail Fast：参数验证
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    return this.prisma.achievementUnlock.findMany({
      where: { userId },
      orderBy: { unlockedAt: 'desc' },
    });
  }

  async findByUserAndAchievement(userId: string, achievementId: string): Promise<AchievementUnlock | null> {
    // Fail Fast：参数验证
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!achievementId || achievementId.trim() === '') {
      throw new Error('achievementId is required');
    }

    return this.prisma.achievementUnlock.findUnique({
      where: {
        userId_achievementId: {
          userId,
          achievementId,
        },
      },
    });
  }
}

