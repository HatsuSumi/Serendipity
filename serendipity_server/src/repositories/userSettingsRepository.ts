/**
 * 用户设置 Repository
 * 
 * 职责：用户设置数据访问层
 */

import { PrismaClient, UserSettings, Prisma } from '@prisma/client';

/**
 * 用户设置 Repository 接口
 */
export interface IUserSettingsRepository {
  findByUserId(userId: string): Promise<UserSettings | null>;
  create(userId: string): Promise<UserSettings>;
  update(userId: string, data: Partial<UserSettings>): Promise<UserSettings>;
  upsert(userId: string, data: Partial<UserSettings>): Promise<UserSettings>;
}

export class UserSettingsRepository implements IUserSettingsRepository {
  constructor(private prisma: PrismaClient) {}

  /**
   * 根据用户 ID 查询设置
   * @param userId - 用户 ID
   * @returns 用户设置对象，不存在则返回 null
   */
  async findByUserId(userId: string): Promise<UserSettings | null> {
    return this.prisma.userSettings.findUnique({
      where: { userId },
    });
  }

  /**
   * 创建默认用户设置
   * @param userId - 用户 ID
   * @returns 创建的用户设置对象
   */
  async create(userId: string): Promise<UserSettings> {
    return this.prisma.userSettings.create({
      data: {
        userId,
        theme: 'system',
        pageTransition: 'random',
        dialogAnimation: 'random',
        notifications: {
          checkInReminder: true,
          checkInReminderTime: '20:00',
          achievementUnlocked: true,
        },
        checkIn: {
          vibrationEnabled: true,
          confettiEnabled: true,
        },
        hasSeenCommunityIntro: false,
      },
    });
  }

  /**
   * 更新用户设置
   * @param userId - 用户 ID
   * @param data - 更新数据
   * @returns 更新后的用户设置对象
   */
  async update(userId: string, data: Partial<UserSettings>): Promise<UserSettings> {
    return this.prisma.userSettings.update({
      where: { userId },
      data: {
        theme: data.theme,
        pageTransition: data.pageTransition,
        dialogAnimation: data.dialogAnimation,
        notifications: data.notifications as Prisma.InputJsonValue | undefined,
        checkIn: data.checkIn as Prisma.InputJsonValue | undefined,
        hasSeenCommunityIntro: data.hasSeenCommunityIntro,
        updatedAt: new Date(),
      },
    });
  }

  /**
   * 创建或更新用户设置（upsert）
   * @param userId - 用户 ID
   * @param data - 更新数据
   * @returns 用户设置对象
   */
  async upsert(userId: string, data: Partial<UserSettings>): Promise<UserSettings> {
    return this.prisma.userSettings.upsert({
      where: { userId },
      update: {
        theme: data.theme,
        pageTransition: data.pageTransition,
        dialogAnimation: data.dialogAnimation,
        notifications: data.notifications as Prisma.InputJsonValue | undefined,
        checkIn: data.checkIn as Prisma.InputJsonValue | undefined,
        hasSeenCommunityIntro: data.hasSeenCommunityIntro,
        updatedAt: new Date(),
      },
      create: {
        userId,
        theme: data.theme || 'system',
        pageTransition: data.pageTransition || 'random',
        dialogAnimation: data.dialogAnimation || 'random',
        notifications: (data.notifications || {
          checkInReminder: true,
          checkInReminderTime: '20:00',
          achievementUnlocked: true,
        }) as Prisma.InputJsonValue,
        checkIn: (data.checkIn || {
          vibrationEnabled: true,
          confettiEnabled: true,
        }) as Prisma.InputJsonValue,
        hasSeenCommunityIntro: data.hasSeenCommunityIntro ?? false,
      },
    });
  }
}

