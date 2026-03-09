/**
 * 会员 Repository
 * 
 * 职责：会员数据访问层
 */

import { PrismaClient } from '@prisma/client';

/**
 * 创建会员 DTO
 */
export interface CreateMembershipDto {
  userId: string;
  tier: string;
  status: string;
}

/**
 * 会员实体类型
 */
export interface Membership {
  userId: string;
  tier: string;
  status: string;
  startedAt: Date | null;
  expiresAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * 会员 Repository 接口
 */
export interface IMembershipRepository {
  findByUserId(userId: string): Promise<Membership | null>;
  create(data: CreateMembershipDto): Promise<Membership>;
  updateStatus(userId: string, status: string, expiresAt?: Date): Promise<Membership>;
  activateOrCreate(userId: string, expiresAt: Date): Promise<Membership>;
}

export class MembershipRepository implements IMembershipRepository {
  constructor(private prisma: PrismaClient) {}

  /**
   * 根据用户 ID 查询会员信息
   * @param userId - 用户 ID
   * @returns 会员对象，不存在则返回 null
   */
  async findByUserId(userId: string) {
    return this.prisma.membership.findUnique({
      where: { userId },
    });
  }

  /**
   * 创建会员记录
   * @param data - 会员数据
   * @returns 创建的会员对象
   */
  async create(data: CreateMembershipDto) {
    return this.prisma.membership.create({
      data: {
        userId: data.userId,
        tier: data.tier,
        status: data.status,
      },
    });
  }

  /**
   * 更新会员状态
   * @param userId - 用户 ID
   * @param status - 新状态
   * @param expiresAt - 到期时间（可选）
   * @returns 更新后的会员对象
   */
  async updateStatus(userId: string, status: string, expiresAt?: Date) {
    return this.prisma.membership.update({
      where: { userId },
      data: {
        status,
        expiresAt,
        updatedAt: new Date(),
      },
    });
  }

  /**
   * 激活会员（如果不存在则创建）
   * 使用 upsert 避免多次数据库操作
   * @param userId - 用户 ID
   * @param expiresAt - 到期时间
   * @returns 会员对象
   */
  async activateOrCreate(userId: string, expiresAt: Date) {
    return this.prisma.membership.upsert({
      where: { userId },
      update: {
        tier: 'premium',
        status: 'active',
        startedAt: new Date(),
        expiresAt,
        updatedAt: new Date(),
      },
      create: {
        userId,
        tier: 'premium',
        status: 'active',
        startedAt: new Date(),
        expiresAt,
      },
    });
  }
}

