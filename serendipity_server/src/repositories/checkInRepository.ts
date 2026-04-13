import { PrismaClient, CheckIn } from '@prisma/client';

/**
 * 创建签到数据
 */
export interface CreateCheckInData {
  id: string;
  date: Date;
  checkedAt: Date;
}

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
   * 调用者：CheckInService.createTodayCheckIn()
   */
  create(userId: string, data: CreateCheckInData): Promise<CheckIn>;

  /**
   * 根据 ID 查找签到记录
   *
   * 调用者：CheckInService（内部使用）
   */
  findById(id: string): Promise<CheckIn | null>;

  /**
   * 根据 ID 查找未删除签到记录
   *
   * 调用者：CheckInService.deleteCheckIn()
   */
  findActiveById(id: string): Promise<CheckIn | null>;

  /**
   * 获取用户所有签到记录（支持增量同步）
   *
   * 调用者：CheckInService.getCheckIns()
   */
  findByUserId(userId: string, lastSyncTime?: Date): Promise<CheckIn[]>;

  /**
   * 根据用户和日期查找签到记录
   *
   * 调用者：CheckInService.createTodayCheckIn()
   */
  findByUserAndDate(userId: string, date: Date): Promise<CheckIn | null>;

  /**
   * 删除签到记录（墓碑化）
   *
   * 调用者：CheckInService.deleteCheckIn()
   */
  deleteById(id: string, deletedAt: Date): Promise<void>;
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
    if (!prisma) {
      throw new Error('PrismaClient is required');
    }
  }

  async create(userId: string, data: CreateCheckInData): Promise<CheckIn> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!data.id || data.id.trim() === '') {
      throw new Error('CheckIn id is required');
    }
    if (!(data.date instanceof Date) || Number.isNaN(data.date.getTime())) {
      throw new Error('Invalid check-in date');
    }
    if (!(data.checkedAt instanceof Date) || Number.isNaN(data.checkedAt.getTime())) {
      throw new Error('Invalid checkedAt');
    }

    return this.prisma.checkIn.create({
      data: {
        id: data.id,
        userId,
        date: data.date,
        checkedAt: data.checkedAt,
      },
    });
  }

  async findById(id: string): Promise<CheckIn | null> {
    if (!id || id.trim() === '') {
      throw new Error('CheckIn id is required');
    }

    return this.prisma.checkIn.findUnique({
      where: { id },
    });
  }

  async findActiveById(id: string): Promise<CheckIn | null> {
    if (!id || id.trim() === '') {
      throw new Error('CheckIn id is required');
    }

    return this.prisma.checkIn.findFirst({
      where: { id, deletedAt: null },
    });
  }

  async findByUserId(userId: string, lastSyncTime?: Date): Promise<CheckIn[]> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    return this.prisma.checkIn.findMany({
      where: {
        userId,
        ...(lastSyncTime ? { updatedAt: { gt: lastSyncTime } } : {}),
      },
      orderBy: { date: 'desc' },
    });
  }

  async findByUserAndDate(userId: string, date: Date): Promise<CheckIn | null> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
      throw new Error('Invalid date');
    }

    return this.prisma.checkIn.findFirst({
      where: {
        userId,
        date,
        deletedAt: null,
      },
    });
  }

  async deleteById(id: string, deletedAt: Date): Promise<void> {
    if (!id || id.trim() === '') {
      throw new Error('CheckIn id is required');
    }
    if (!(deletedAt instanceof Date) || Number.isNaN(deletedAt.getTime())) {
      throw new Error('Invalid deletedAt');
    }

    await this.prisma.checkIn.update({
      where: { id },
      data: {
        deletedAt,
        updatedAt: deletedAt,
      },
    });
  }
}
