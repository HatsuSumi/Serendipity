import { CheckIn } from '@prisma/client';
import { ICheckInRepository } from '../repositories/checkInRepository';
import { CreateCheckInDto } from '../types/checkIn.dto';

/**
 * 签到服务接口
 * 
 * 定义签到业务逻辑的抽象接口，遵循依赖倒置原则（DIP）
 * 
 * 调用者：
 * - CheckInController：控制器层
 */
export interface ICheckInService {
  /**
   * 创建签到记录
   * 
   * 业务规则：
   * - 如果该日期已存在签到记录，根据 updatedAt 决定是否覆盖
   * - updatedAt 更新的记录会覆盖旧记录（用于同步冲突解决）
   * 
   * Fail Fast：
   * - userId 为空：抛出 Error
   * - data 无效：抛出 Error
   * 
   * 调用者：CheckInController.createCheckIn()
   */
  createCheckIn(userId: string, data: CreateCheckInDto): Promise<CheckIn>;

  /**
   * 批量创建签到记录
   * 
   * 调用者：CheckInController.batchCreateCheckIns()
   */
  batchCreateCheckIns(userId: string, checkIns: CreateCheckInDto[]): Promise<void>;

  /**
   * 获取用户所有签到记录
   * 
   * Fail Fast：
   * - userId 为空：抛出 Error
   * 
   * 调用者：CheckInController.getCheckIns()
   */
  getCheckIns(userId: string): Promise<CheckIn[]>;

  /**
   * 删除签到记录
   * 
   * Fail Fast：
   * - checkInId 为空：抛出 Error
   * - userId 为空：抛出 Error
   * 
   * 调用者：CheckInController.deleteCheckIn()
   */
  deleteCheckIn(checkInId: string, userId: string): Promise<void>;
}

/**
 * 签到服务实现
 * 
 * 负责签到业务逻辑，遵循单一职责原则（SRP）
 * 
 * 调用者：
 * - CheckInController：通过依赖注入
 */
export class CheckInService implements ICheckInService {
  constructor(private checkInRepository: ICheckInRepository) {
    // Fail Fast：依赖检查
    if (!checkInRepository) {
      throw new Error('CheckInRepository is required');
    }
  }

  async createCheckIn(userId: string, data: CreateCheckInDto): Promise<CheckIn> {
    // Fail Fast：参数验证
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!data || !data.id || !data.date || !data.checkedAt) {
      throw new Error('Invalid check-in data');
    }

    // 检查是否已经签到
    const date = new Date(data.date);
    const existing = await this.checkInRepository.findByUserAndDate(userId, date);

    if (existing) {
      // 如果已存在，根据 updatedAt 决定是否覆盖
      const existingUpdatedAt = new Date(existing.updatedAt);
      const newUpdatedAt = new Date(data.updatedAt);

      if (newUpdatedAt > existingUpdatedAt) {
        // 新数据更新，覆盖旧记录
        await this.checkInRepository.deleteById(existing.id, userId);
        return await this.checkInRepository.create(userId, data);
      } else {
        // 旧数据，返回现有记录
        return existing;
      }
    }

    // 创建新记录
    return await this.checkInRepository.create(userId, data);
  }

  async batchCreateCheckIns(userId: string, checkIns: CreateCheckInDto[]): Promise<void> {
    // Fail Fast：参数验证
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!Array.isArray(checkIns)) {
      throw new Error('checkIns must be an array');
    }

    // 空数组直接返回（允许空列表）
    if (checkIns.length === 0) {
      return;
    }

    // 逐个创建（利用 createCheckIn 的冲突解决逻辑）
    for (const checkIn of checkIns) {
      await this.createCheckIn(userId, checkIn);
    }
  }

  async getCheckIns(userId: string): Promise<CheckIn[]> {
    // Fail Fast：参数验证
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    return await this.checkInRepository.findByUserId(userId);
  }

  async deleteCheckIn(checkInId: string, userId: string): Promise<void> {
    // Fail Fast：参数验证
    if (!checkInId || checkInId.trim() === '') {
      throw new Error('checkInId is required');
    }
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    await this.checkInRepository.deleteById(checkInId, userId);
  }
}

