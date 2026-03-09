import { PrismaClient, CheckIn } from '@prisma/client';
import { CreateCheckInDto } from '../types/checkIn.dto';

/**
 * 签到仓储接口
 * 
 * 定义签到数据访问的抽象接口，遵循依赖倒置原则（DIP）
 * 
 * 调用者：
 * - CheckInService：业务逻辑层
 */
export interface ICheckInRepository {
  /**
   * 创建签到记录
   * 
   * Fail Fast：
   * - userId 为空：抛出错误（由 Prisma 处理）
   * - data 缺少必填字段：抛出错误（由 Prisma 处理）
   * 
   * 调用者：CheckInService.createCheckIn()
   */
  create(userId: string, data: CreateCheckInDto): Promise<CheckIn>;

  /**
   * 根据 ID 查找签到记录
   * 
   * Fail Fast：
   * - id 为空：抛出 Error
   * 
   * 调用者：CheckInService（内部使用）
   */
  findById(id: string): Promise<CheckIn | null>;

  /**
   * 获取用户所有签到记录（支持增量同步）
   * 
   * Fail Fast：
   * - userId 为空：抛出 Error
   * 
   * 调用者：CheckInService.getCheckIns()
   */
  findByUserId(userId: string, lastSyncTime?: Date): Promise<CheckIn[]>;

  /**
   * 根据用户和日期查找签到记录
   * 
   * Fail Fast：
   * - userId 为空：抛出 Error
   * - date 无效：抛出 Error
   * 
   * 调用者：CheckInService.createCheckIn()
   */
  findByUserAndDate(userId: string, date: Date): Promise<CheckIn | null>;

  /**
   * 删除签到记录
   * 
   * Fail Fast：
   * - id 为空：抛出 Error
   * - userId 为空：抛出 Error
   * 
   * 调用者：CheckInService.deleteCheckIn()
   */
  deleteById(id: string, userId: string): Promise<void>;
}

/**
 * 签到仓储实现
 * 
 * 负责签到数据的持久化操作，遵循单一职责原则（SRP）
 * 
 * 调用者：
 * - CheckInService：通过依赖注入
 */
export class CheckInRepository implements ICheckInRepository {
  constructor(private prisma: PrismaClient) {
    // Fail Fast：依赖检查
    if (!prisma) {
      throw new Error('PrismaClient is required');
    }
  }

  async create(userId: string, data: CreateCheckInDto): Promise<CheckIn> {
    // Fail Fast：参数验证
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!data.id || data.id.trim() === '') {
      throw new Error('CheckIn id is required');
    }

    return this.prisma.checkIn.create({
      data: {
        id: data.id,
        userId,
        date: new Date(data.date),
        checkedAt: new Date(data.checkedAt),
        createdAt: new Date(data.createdAt),
        updatedAt: new Date(data.updatedAt),
      },
    });
  }

  async findById(id: string): Promise<CheckIn | null> {
    // Fail Fast：参数验证
    if (!id || id.trim() === '') {
      throw new Error('CheckIn id is required');
    }

    return this.prisma.checkIn.findUnique({
      where: { id },
    });
  }

  async findByUserId(userId: string, lastSyncTime?: Date): Promise<CheckIn[]> {
    // Fail Fast：参数验证
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    const where = {
      userId,
      ...(lastSyncTime && { updatedAt: { gt: lastSyncTime } }),
    };

    return this.prisma.checkIn.findMany({
      where,
      orderBy: { date: 'desc' },
    });
  }

  async findByUserAndDate(userId: string, date: Date): Promise<CheckIn | null> {
    // Fail Fast：参数验证
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!(date instanceof Date) || isNaN(date.getTime())) {
      throw new Error('Invalid date');
    }

    // 只比较日期部分（忽略时间）
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    return this.prisma.checkIn.findFirst({
      where: {
        userId,
        date: {
          gte: startOfDay,
          lte: endOfDay,
        },
      },
    });
  }

  async deleteById(id: string, userId: string): Promise<void> {
    // Fail Fast：参数验证
    if (!id || id.trim() === '') {
      throw new Error('CheckIn id is required');
    }
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    await this.prisma.checkIn.delete({
      where: {
        id,
        userId, // 确保只能删除自己的签到记录
      },
    });
  }
}

