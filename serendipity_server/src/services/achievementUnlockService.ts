import { AchievementUnlock } from '@prisma/client';
import { IAchievementUnlockRepository } from '../repositories/achievementUnlockRepository';
import { CreateAchievementUnlockDto, AchievementUnlockResponseDto } from '../types/achievementUnlock.dto';

/**
 * 成就解锁服务
 * 
 * 负责成就解锁的业务逻辑，遵循单一职责原则（SRP）和依赖倒置原则（DIP）
 * 
 * 调用者：
 * - AchievementUnlockController：HTTP 请求处理层
 */
export class AchievementUnlockService {
  constructor(private achievementUnlockRepository: IAchievementUnlockRepository) {
    // Fail Fast：依赖检查
    if (!achievementUnlockRepository) {
      throw new Error('AchievementUnlockRepository is required');
    }
  }

  /**
   * 创建或更新成就解锁记录
   * 
   * 业务规则：
   * - 使用 upsert 确保幂等性
   * - 如果记录已存在，保持原有的解锁时间（不更新）
   * 
   * Fail Fast：
   * - data 缺少必填字段：抛出 Error
   * - data.unlockedAt 格式错误：抛出 Error
   * 
   * 调用者：AchievementUnlockController.uploadAchievementUnlock()
   */
  async createAchievementUnlock(data: CreateAchievementUnlockDto): Promise<AchievementUnlock> {
    // Fail Fast：参数验证
    if (!data) {
      throw new Error('Achievement unlock data is required');
    }
    if (!data.userId || data.userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!data.achievementId || data.achievementId.trim() === '') {
      throw new Error('achievementId is required');
    }
    if (!data.unlockedAt) {
      throw new Error('unlockedAt is required');
    }

    return this.achievementUnlockRepository.upsert(data);
  }

  /**
   * 获取用户成就解锁记录
   * 
   * 支持增量同步：
   * - 如果提供 since 参数，只返回该时间之后创建的记录
   * - 如果不提供 since，返回所有记录
   * 
   * Fail Fast：
   * - userId 为空：抛出 Error
   * 
   * 调用者：AchievementUnlockController.downloadAchievementUnlocks()
   */
  async getAchievementUnlocks(userId: string, since?: Date): Promise<AchievementUnlockResponseDto[]> {
    // Fail Fast：参数验证
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    const unlocks = await this.achievementUnlockRepository.findByUserId(userId, since);

    // 转换为响应 DTO
    return unlocks.map((unlock) => ({
      userId: unlock.userId,
      achievementId: unlock.achievementId,
      unlockedAt: unlock.unlockedAt.toISOString(),
    }));
  }
}

