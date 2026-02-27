"use strict";
/**
 * UserService 单元测试
 */
Object.defineProperty(exports, "__esModule", { value: true });
const userService_1 = require("../../../src/services/userService");
const factories_1 = require("../../helpers/factories");
const errorHandler_1 = require("../../../src/middlewares/errorHandler");
const errors_1 = require("../../../src/types/errors");
describe('UserService', () => {
    let userService;
    let mockUserRepository;
    let mockUserSettingsRepository;
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
        };
        mockUserSettingsRepository = {
            findByUserId: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
            upsert: jest.fn(),
        };
        userService = new userService_1.UserService(mockUserRepository, mockUserSettingsRepository);
    });
    describe('updateUser', () => {
        it('应该成功更新用户信息', async () => {
            const userId = 'test-user-id';
            const updateData = {
                displayName: 'New Name',
                avatarUrl: 'https://example.com/avatar.jpg',
            };
            const mockUser = (0, factories_1.createMockUser)({ id: userId });
            const updatedUser = (0, factories_1.createMockUser)({
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
            const mockUser = (0, factories_1.createMockUser)({ id: userId });
            const updatedUser = (0, factories_1.createMockUser)({
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
            await expect(userService.updateUser(userId, updateData)).rejects.toThrow(errorHandler_1.AppError);
            await expect(userService.updateUser(userId, updateData)).rejects.toMatchObject({
                code: errors_1.ErrorCode.USER_NOT_FOUND,
            });
        });
    });
    describe('getUserSettings', () => {
        it('应该成功获取用户设置', async () => {
            const userId = 'test-user-id';
            const mockUser = (0, factories_1.createMockUser)({ id: userId });
            const mockSettings = (0, factories_1.createMockUserSettings)({ userId });
            mockUserRepository.findById.mockResolvedValue(mockUser);
            mockUserSettingsRepository.findByUserId.mockResolvedValue(mockSettings);
            const result = await userService.getUserSettings(userId);
            expect(result.theme).toBe(mockSettings.theme);
            expect(result.pageTransition).toBe(mockSettings.pageTransition);
            expect(result.dialogAnimation).toBe(mockSettings.dialogAnimation);
            expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
            expect(mockUserSettingsRepository.findByUserId).toHaveBeenCalledWith(userId);
        });
        it('设置不存在时应该创建默认设置', async () => {
            const userId = 'test-user-id';
            const mockUser = (0, factories_1.createMockUser)({ id: userId });
            const mockSettings = (0, factories_1.createMockUserSettings)({ userId });
            mockUserRepository.findById.mockResolvedValue(mockUser);
            mockUserSettingsRepository.findByUserId.mockResolvedValue(null);
            mockUserSettingsRepository.create.mockResolvedValue(mockSettings);
            const result = await userService.getUserSettings(userId);
            expect(result.theme).toBe(mockSettings.theme);
            expect(mockUserSettingsRepository.create).toHaveBeenCalledWith(userId);
        });
        it('用户不存在时应该抛出错误', async () => {
            const userId = 'nonexistent-user-id';
            mockUserRepository.findById.mockResolvedValue(null);
            await expect(userService.getUserSettings(userId)).rejects.toThrow(errorHandler_1.AppError);
            await expect(userService.getUserSettings(userId)).rejects.toMatchObject({
                code: errors_1.ErrorCode.USER_NOT_FOUND,
            });
        });
    });
    describe('updateUserSettings', () => {
        it('应该成功更新用户设置', async () => {
            const userId = 'test-user-id';
            const updateData = {
                theme: 'dark',
                notifications: {
                    checkInReminder: true,
                    checkInReminderTime: '21:00',
                    achievementUnlocked: true,
                },
            };
            const mockUser = (0, factories_1.createMockUser)({ id: userId });
            const updatedSettings = (0, factories_1.createMockUserSettings)({
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
                theme: 'midnight',
            };
            const mockUser = (0, factories_1.createMockUser)({ id: userId });
            const updatedSettings = (0, factories_1.createMockUserSettings)({
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
                theme: 'dark',
            };
            mockUserRepository.findById.mockResolvedValue(null);
            await expect(userService.updateUserSettings(userId, updateData)).rejects.toThrow(errorHandler_1.AppError);
            await expect(userService.updateUserSettings(userId, updateData)).rejects.toMatchObject({
                code: errors_1.ErrorCode.USER_NOT_FOUND,
            });
        });
    });
});
//# sourceMappingURL=userService.test.js.map