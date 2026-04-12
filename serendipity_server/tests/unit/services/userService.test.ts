/**
 * UserService 单元测试
 */

import { UserService } from '../../../src/services/userService';
import { IUserRepository } from '../../../src/repositories/userRepository';
import { IUserSettingsRepository } from '../../../src/repositories/userSettingsRepository';
import { IMembershipRepository } from '../../../src/repositories/membershipRepository';
import { createMockUser, createMockUserSettings } from '../../helpers/factories';
import { AppError } from '../../../src/middlewares/errorHandler';
import { ErrorCode } from '../../../src/types/errors';

describe('UserService', () => {
  let userService: UserService;
  let mockUserRepository: jest.Mocked<IUserRepository>;
  let mockUserSettingsRepository: jest.Mocked<IUserSettingsRepository>;
  let mockMembershipRepository: jest.Mocked<IMembershipRepository>;

  beforeEach(() => {
    mockUserRepository = {
      findById: jest.fn(),
      findByEmail: jest.fn(),
      findByPhone: jest.fn(),
      create: jest.fn(),
      updateLastLogin: jest.fn(),
      updateUser: jest.fn(),
      updateDisplayName: jest.fn(),
      updateAvatarUrl: jest.fn(),
      bindEmail: jest.fn(),
      bindPhone: jest.fn(),
      updatePassword: jest.fn(),
      updateRecoveryKey: jest.fn(),
      findByEmailAndRecoveryKey: jest.fn(),
      deleteById: jest.fn(),
    };

    mockUserSettingsRepository = {
      findByUserId: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      upsert: jest.fn(),
    };

    mockMembershipRepository = {
      findByUserId: jest.fn(),
      create: jest.fn(),
      updateStatus: jest.fn(),
      activateOrCreate: jest.fn(),
      isUserPremium: jest.fn(),
    };

    userService = new UserService(mockUserRepository, mockUserSettingsRepository, mockMembershipRepository);
  });

  describe('updateUser', () => {
    it('应该成功更新用户信息', async () => {
      const userId = 'test-user-id';
      const updateData = {
        displayName: 'New Name',
        avatarUrl: 'https://example.com/avatar.jpg',
      };

      const mockUser = createMockUser({ id: userId });
      const updatedUser = createMockUser({
        id: userId,
        displayName: updateData.displayName,
        avatarUrl: updateData.avatarUrl,
      });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockUserRepository.updateUser.mockResolvedValue(updatedUser);

      const result = await userService.updateUser(userId, updateData);

      expect(result.displayName).toBe(updateData.displayName);
      expect(result.avatarUrl).toBe(updateData.avatarUrl);
      expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
      expect(mockUserRepository.updateUser).toHaveBeenCalledWith(userId, updateData);
    });

    it('应该成功更新部分字段', async () => {
      const userId = 'test-user-id';
      const updateData = {
        displayName: 'New Name',
      };

      const mockUser = createMockUser({ id: userId });
      const updatedUser = createMockUser({
        id: userId,
        displayName: updateData.displayName,
      });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockUserRepository.updateUser.mockResolvedValue(updatedUser);

      const result = await userService.updateUser(userId, updateData);

      expect(result.displayName).toBe(updateData.displayName);
      expect(mockUserRepository.updateUser).toHaveBeenCalledWith(userId, updateData);
    });

    it('用户不存在时应该抛出错误', async () => {
      const userId = 'nonexistent-user-id';
      const updateData = {
        displayName: 'New Name',
      };

      mockUserRepository.findById.mockResolvedValue(null);

      await expect(userService.updateUser(userId, updateData)).rejects.toThrow(AppError);
      await expect(userService.updateUser(userId, updateData)).rejects.toMatchObject({
        code: ErrorCode.USER_NOT_FOUND,
      });
    });
  });

  describe('getUserSettings', () => {
    it('应该成功获取用户设置', async () => {
      const userId = 'test-user-id';
      const mockUser = createMockUser({ id: userId });
      const mockSettings = createMockUserSettings({ userId });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockUserSettingsRepository.findByUserId.mockResolvedValue(mockSettings);

      const result = await userService.getUserSettings(userId);

      expect(result.theme).toBe(mockSettings.theme);
      expect(result.pageTransition).toBe(mockSettings.pageTransition);
      expect(result.dialogAnimation).toBe(mockSettings.dialogAnimation);
      expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
      expect(mockUserSettingsRepository.findByUserId).toHaveBeenCalledWith(userId);
    });

    it('设置不存在时应该抛出 not found 错误', async () => {
      const userId = 'test-user-id';
      const mockUser = createMockUser({ id: userId });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockUserSettingsRepository.findByUserId.mockResolvedValue(null);

      await expect(userService.getUserSettings(userId)).rejects.toThrow(AppError);
      await expect(userService.getUserSettings(userId)).rejects.toMatchObject({
        code: ErrorCode.NOT_FOUND,
      });
      expect(mockUserSettingsRepository.create).not.toHaveBeenCalled();
    });

    it('用户不存在时应该抛出错误', async () => {
      const userId = 'nonexistent-user-id';

      mockUserRepository.findById.mockResolvedValue(null);

      await expect(userService.getUserSettings(userId)).rejects.toThrow(AppError);
      await expect(userService.getUserSettings(userId)).rejects.toMatchObject({
        code: ErrorCode.USER_NOT_FOUND,
      });
    });
  });

  describe('updateUserSettings', () => {
    it('应该成功更新用户设置', async () => {
      const userId = 'test-user-id';
      const updateData = {
        theme: 'dark' as const,
        notifications: {
          checkInReminder: true,
          checkInReminderTime: '21:00',
          achievementUnlocked: true,
        },
      };

      const mockUser = createMockUser({ id: userId });
      const updatedSettings = createMockUserSettings({
        userId,
        theme: updateData.theme,
        notifications: updateData.notifications,
      });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockUserSettingsRepository.upsert.mockResolvedValue(updatedSettings);

      const result = await userService.updateUserSettings(userId, updateData);

      expect(result.theme).toBe(updateData.theme);
      expect(result.notifications.checkInReminder).toBe(true);
      expect(result.notifications.checkInReminderTime).toBe('21:00');
      expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
      expect(mockUserSettingsRepository.upsert).toHaveBeenCalledWith(userId, updateData);
    });

    it('应该成功更新部分设置', async () => {
      const userId = 'test-user-id';
      const updateData = {
        theme: 'midnight' as const,
      };

      const mockUser = createMockUser({ id: userId });
      const updatedSettings = createMockUserSettings({
        userId,
        theme: updateData.theme,
      });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockUserSettingsRepository.upsert.mockResolvedValue(updatedSettings);

      const result = await userService.updateUserSettings(userId, updateData);

      expect(result.theme).toBe(updateData.theme);
      expect(mockUserSettingsRepository.upsert).toHaveBeenCalledWith(userId, updateData);
    });

    it('用户不存在时应该抛出错误', async () => {
      const userId = 'nonexistent-user-id';
      const updateData = {
        theme: 'dark' as const,
      };

      mockUserRepository.findById.mockResolvedValue(null);

      await expect(userService.updateUserSettings(userId, updateData)).rejects.toThrow(AppError);
      await expect(userService.updateUserSettings(userId, updateData)).rejects.toMatchObject({
        code: ErrorCode.USER_NOT_FOUND,
      });
    });
  });
});

