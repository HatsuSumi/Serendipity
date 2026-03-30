/**
 * 用户服务
 * 
 * 职责：用户信息和设置的业务逻辑
 */

import path from 'path';
import fs from 'fs';
import { User, UserSettings } from '@prisma/client';
import { IUserRepository } from '../repositories/userRepository';
import { IUserSettingsRepository } from '../repositories/userSettingsRepository';
import { 
  UpdateUserDto, 
  UserProfileDto, 
  UserSettingsDto, 
  UpdateUserSettingsDto 
} from '../types/user.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';

/**
 * 用户服务接口
 */
export interface IUserService {
  updateUser(userId: string, data: UpdateUserDto): Promise<UserProfileDto>;
  uploadAvatar(userId: string, file: Express.Multer.File, baseUrl: string): Promise<UserProfileDto>;
  getUserSettings(userId: string): Promise<UserSettingsDto>;
  updateUserSettings(userId: string, data: UpdateUserSettingsDto): Promise<UserSettingsDto>;
}

/**
 * 用户服务实现
 */
export class UserService implements IUserService {
  constructor(
    private userRepository: IUserRepository,
    private userSettingsRepository: IUserSettingsRepository
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

    return this.mapUserToDto(updatedUser);
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
    return this.mapUserToDto(updatedUser);
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
   * 将 User 实体映射为 DTO
   */
  private mapUserToDto(user: User): UserProfileDto {
    return {
      id: user.id,
      email: user.email || undefined,
      phoneNumber: user.phoneNumber || undefined,
      displayName: user.displayName || undefined,
      avatarUrl: user.avatarUrl || undefined,
      authProvider: user.authProvider || 'email',
      createdAt: user.createdAt,
    };
  }

  /**
   * 将 UserSettings 实体映射为 DTO
   */
  private mapSettingsToDto(settings: UserSettings): UserSettingsDto {
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
      themeUpdatedAt: settings.themeUpdatedAt.toISOString(),
      notificationsUpdatedAt: settings.notificationsUpdatedAt.toISOString(),
      checkInUpdatedAt: settings.checkInUpdatedAt.toISOString(),
      communityUpdatedAt: settings.communityUpdatedAt.toISOString(),
      updatedAt: settings.updatedAt.toISOString(),
    };
  }
}

