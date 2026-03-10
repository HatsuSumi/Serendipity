/**
 * 用户服务
 * 
 * 职责：用户信息和设置的业务逻辑
 */

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
   * 获取用户设置
   * @param userId - 用户 ID
   * @returns 用户设置
   */
  async getUserSettings(userId: string): Promise<UserSettingsDto> {
    const user = await this.userRepository.findById(userId);
    
    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }

    let settings = await this.userSettingsRepository.findByUserId(userId);

    if (!settings) {
      settings = await this.userSettingsRepository.create(userId);
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

    const updatedSettings = await this.userSettingsRepository.upsert(userId, data);

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
      },
      checkIn: settings.checkIn as {
        vibrationEnabled: boolean;
        confettiEnabled: boolean;
      },
      hasSeenCommunityIntro: settings.hasSeenCommunityIntro,
      hasSeenPublishWarning: settings.hasSeenPublishWarning,
      hidePublishWarning: settings.hidePublishWarning,
      updatedAt: settings.updatedAt.toISOString(),
    };
  }
}

