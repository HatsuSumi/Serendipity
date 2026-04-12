/**
 * 用户服务
 * 
 * 职责：用户信息和设置的业务逻辑
 */

import path from 'path';
import fs from 'fs';
import { UserSettings } from '@prisma/client';
import { IUserRepository } from '../repositories/userRepository';
import { IUserSettingsRepository } from '../repositories/userSettingsRepository';
import { IMembershipRepository, Membership } from '../repositories/membershipRepository';
import { 
  UpdateUserDto, 
  UserProfileDto, 
  UserSettingsDto, 
  UpdateUserSettingsDto,
  MembershipDto,
} from '../types/user.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { toUserProfileDto } from '../types/user.mapper';

/**
 * 用户服务接口
 */
export interface IUserService {
  updateUser(userId: string, data: UpdateUserDto): Promise<UserProfileDto>;
  uploadAvatar(userId: string, file: Express.Multer.File, baseUrl: string): Promise<UserProfileDto>;
  getUserSettings(userId: string): Promise<UserSettingsDto>;
  updateUserSettings(userId: string, data: UpdateUserSettingsDto): Promise<UserSettingsDto>;
  getMembership(userId: string): Promise<MembershipDto | null>;
  activateMembership(userId: string, monthlyAmount: number): Promise<MembershipDto>;
}

/**
 * 用户服务实现
 */
export class UserService implements IUserService {
  constructor(
    private userRepository: IUserRepository,
    private userSettingsRepository: IUserSettingsRepository,
    private membershipRepository: IMembershipRepository,
  ) {}

  /**
   * 更新用户信息
   * @param userId - 用户 ID
   * @param data - 更新数据
   * @returns 更新后的用户信息
   */
  async updateUser(userId: string, data: UpdateUserDto): Promise<UserProfileDto> {
    const user = await this.userRepository.findById(userId);
    
    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    const updatedUser = await this.userRepository.updateUser(userId, data);

    return toUserProfileDto(updatedUser);
  }

  /**
   * 上传头像并更新用户 avatarUrl
   * @param userId - 用户 ID
   * @param file - multer 上传的文件
   * @param baseUrl - 服务器基础 URL（用于拼接静态资源地址）
   * @returns 更新后的用户信息
   */
  async uploadAvatar(userId: string, file: Express.Multer.File, baseUrl: string): Promise<UserProfileDto> {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    // 删除旧头像文件（仅删除本服务器托管的文件，忽略外部 URL）
    if (user.avatarUrl) {
      const oldFilename = path.basename(user.avatarUrl);
      const oldFilePath = path.join(process.cwd(), 'uploads', 'avatars', oldFilename);
      // 确认路径在 avatars 目录内，防止路径穿越
      const avatarsDir = path.join(process.cwd(), 'uploads', 'avatars');
      if (oldFilePath.startsWith(avatarsDir) && fs.existsSync(oldFilePath)) {
        fs.unlinkSync(oldFilePath);
      }
    }

    const avatarUrl = `${baseUrl}/uploads/avatars/${file.filename}`;
    const updatedUser = await this.userRepository.updateAvatarUrl(userId, avatarUrl);
    return toUserProfileDto(updatedUser);
  }

  /**
   * 获取用户设置
   * @param userId - 用户 ID
   * @returns 用户设置
   */
  async getUserSettings(userId: string): Promise<UserSettingsDto> {
    const user = await this.userRepository.findById(userId);
    
    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    const settings = await this.userSettingsRepository.findByUserId(userId);

    if (!settings) {
      throw new AppError('User settings not found', ErrorCode.NOT_FOUND);
    }

    return this.mapSettingsToDto(settings);
  }

  /**
   * 更新用户设置
   * @param userId - 用户 ID
   * @param data - 更新数据
   * @returns 更新后的用户设置
   */
  async updateUserSettings(
    userId: string, 
    data: UpdateUserSettingsDto
  ): Promise<UserSettingsDto> {
    const user = await this.userRepository.findById(userId);
    
    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    const updatedSettings = await this.userSettingsRepository.upsert(userId, {
      ...data,
      themeUpdatedAt: data.themeUpdatedAt ? new Date(data.themeUpdatedAt) : undefined,
      notificationsUpdatedAt: data.notificationsUpdatedAt ? new Date(data.notificationsUpdatedAt) : undefined,
      checkInUpdatedAt: data.checkInUpdatedAt ? new Date(data.checkInUpdatedAt) : undefined,
      communityUpdatedAt: data.communityUpdatedAt ? new Date(data.communityUpdatedAt) : undefined,
    });

    return this.mapSettingsToDto(updatedSettings);
  }

  /**
   * 获取用户会员信息
   */
  async getMembership(userId: string): Promise<MembershipDto | null> {
    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    const membership = await this.membershipRepository.findByUserId(userId);
    if (!membership) {
      return null;
    }

    return this.mapMembershipToDto(membership);
  }

  /**
   * 开通会员
   */
  async activateMembership(
    userId: string,
    monthlyAmount: number,
  ): Promise<MembershipDto> {
    const user = await this.userRepository.findById(userId);

    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    if (!Number.isFinite(monthlyAmount) || monthlyAmount < 0 || monthlyAmount > 648) {
      throw new AppError('monthlyAmount must be between 0 and 648', ErrorCode.INVALID_REQUEST);
    }

    const now = new Date();
    const expiresAt = new Date(now);
    expiresAt.setDate(expiresAt.getDate() + 30);

    const membership = await this.membershipRepository.activateOrCreate(
      userId,
      monthlyAmount,
      expiresAt,
    );

    return this.mapMembershipToDto(membership);
  }

  /**
   * 将 UserSettings 实体映射为 DTO
   */
  private mapSettingsToDto(settings: UserSettings): UserSettingsDto {
    const fallbackTimestamp = settings.updatedAt;

    return {
      theme: settings.theme,
      pageTransition: settings.pageTransition,
      dialogAnimation: settings.dialogAnimation,
      notifications: settings.notifications as {
        checkInReminder: boolean;
        checkInReminderTime: string;
        achievementUnlocked: boolean;
        anniversaryReminder: boolean;
      },
      checkIn: settings.checkIn as {
        vibrationEnabled: boolean;
        confettiEnabled: boolean;
      },
      hasSeenCommunityIntro: settings.hasSeenCommunityIntro,
      hasSeenPublishWarning: settings.hasSeenPublishWarning,
      hasSeenFavoritesIntro: settings.hasSeenFavoritesIntro,
      hidePublishWarning: settings.hidePublishWarning,
      themeUpdatedAt: (settings.themeUpdatedAt ?? fallbackTimestamp).toISOString(),
      notificationsUpdatedAt: (settings.notificationsUpdatedAt ?? fallbackTimestamp).toISOString(),
      checkInUpdatedAt: (settings.checkInUpdatedAt ?? fallbackTimestamp).toISOString(),
      communityUpdatedAt: (settings.communityUpdatedAt ?? fallbackTimestamp).toISOString(),
      updatedAt: settings.updatedAt.toISOString(),
    };
  }

  private mapMembershipToDto(membership: Membership): MembershipDto {
    const tierMap: Record<string, number> = {
      free: 1,
      premium: 2,
    };
    const statusMap: Record<string, number> = {
      inactive: 1,
      active: 2,
      expired: 3,
      cancelled: 4,
    };

    return {
      id: membership.id,
      userId: membership.userId,
      tier: tierMap[membership.tier] ?? 1,
      status: statusMap[membership.status] ?? 1,
      startedAt: membership.startedAt?.toISOString(),
      expiresAt: membership.expiresAt?.toISOString(),
      monthlyAmount: membership.monthlyAmount ?? undefined,
      autoRenew: membership.autoRenew,
      createdAt: membership.createdAt.toISOString(),
      updatedAt: membership.updatedAt.toISOString(),
    };
  }
}
