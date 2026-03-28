/**
 * 用户相关 DTO
 */

export interface UserProfileDto {
  id: string;
  email?: string;
  phoneNumber?: string;
  displayName?: string;
  avatarUrl?: string;
  authProvider?: string;
  createdAt: Date;
}

export interface UpdateProfileDto {
  displayName?: string;
  avatarUrl?: string;
}

export interface UpdateUserDto {
  displayName?: string;
  avatarUrl?: string;
}

export interface BindEmailDto {
  email: string;
  verificationCode: string;
}

export interface BindPhoneDto {
  phoneNumber: string;
  verificationCode: string;
}

export interface UserSettingsDto {
  theme: string;
  pageTransition: string;
  dialogAnimation: string;
  notifications: {
    checkInReminder: boolean;
    checkInReminderTime: string;
    achievementUnlocked: boolean;
    anniversaryReminder: boolean;
  };
  checkIn: {
    vibrationEnabled: boolean;
    confettiEnabled: boolean;
  };
  hasSeenCommunityIntro: boolean;
  hasSeenFavoritesIntro: boolean;
  hasSeenPublishWarning: boolean;
  hidePublishWarning: boolean;
  updatedAt: string; // ISO 8601
}

export interface UpdateUserSettingsDto {
  theme?: string;
  pageTransition?: string;
  dialogAnimation?: string;
  notifications?: {
    checkInReminder?: boolean;
    checkInReminderTime?: string;
    achievementUnlocked?: boolean;
    anniversaryReminder?: boolean;
  };
  checkIn?: {
    vibrationEnabled?: boolean;
    confettiEnabled?: boolean;
  };
  hasSeenCommunityIntro?: boolean;
  hasSeenFavoritesIntro?: boolean;
  hasSeenPublishWarning?: boolean;
  hidePublishWarning?: boolean;
}

