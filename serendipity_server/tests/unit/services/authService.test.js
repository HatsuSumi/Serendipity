"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const authService_1 = require("../../../src/services/authService");
const factories_1 = require("../../helpers/factories");
const errorHandler_1 = require("../../../src/middlewares/errorHandler");
const errors_1 = require("../../../src/types/errors");
const bcrypt_1 = __importDefault(require("bcrypt"));
// Mock bcrypt
jest.mock('bcrypt');
const mockedBcrypt = bcrypt_1.default;
describe('AuthService', () => {
    let authService;
    let mockUserRepository;
    let mockRefreshTokenRepository;
    let mockVerificationService;
    let mockJwtService;
    beforeEach(() => {
        // 创建 mock 对象
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
        mockRefreshTokenRepository = {
            create: jest.fn(),
            findByToken: jest.fn(),
            deleteByToken: jest.fn(),
            deleteByUserId: jest.fn(),
            deleteExpired: jest.fn(),
        };
        mockVerificationService = {
            sendVerificationCode: jest.fn(),
            verifyCode: jest.fn(),
            generateCode: jest.fn(),
        };
        mockJwtService = {
            generateToken: jest.fn(),
            generateRefreshToken: jest.fn(),
            verifyToken: jest.fn(),
        };
        authService = new authService_1.AuthService(mockUserRepository, mockRefreshTokenRepository, mockVerificationService, mockJwtService);
    });
    describe('registerEmail', () => {
        it('应该成功注册新用户', async () => {
            const registerData = {
                email: 'test@example.com',
                password: 'password123',
                verificationCode: '123456',
            };
            const mockUser = (0, factories_1.createMockUser)();
            mockVerificationService.verifyCode.mockResolvedValue(true);
            mockUserRepository.findByEmail.mockResolvedValue(null);
            mockedBcrypt.hash.mockResolvedValue('hashed-password');
            mockUserRepository.create.mockResolvedValue(mockUser);
            mockJwtService.generateToken.mockReturnValue('access-token');
            mockJwtService.generateRefreshToken.mockReturnValue('refresh-token');
            mockRefreshTokenRepository.create.mockResolvedValue({});
            const result = await authService.registerEmail(registerData);
            expect(result).toHaveProperty('user');
            expect(result).toHaveProperty('tokens');
            expect(result.tokens.accessToken).toBe('access-token');
            expect(mockVerificationService.verifyCode).toHaveBeenCalledWith(registerData.email, registerData.verificationCode, 'register');
            expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(registerData.email);
            expect(mockUserRepository.create).toHaveBeenCalled();
        });
        it('邮箱已存在时应该抛出错误', async () => {
            const registerData = {
                email: 'existing@example.com',
                password: 'password123',
                verificationCode: '123456',
            };
            mockVerificationService.verifyCode.mockResolvedValue(true);
            mockUserRepository.findByEmail.mockResolvedValue((0, factories_1.createMockUser)());
            await expect(authService.registerEmail(registerData)).rejects.toThrow(errorHandler_1.AppError);
            await expect(authService.registerEmail(registerData)).rejects.toMatchObject({
                code: errors_1.ErrorCode.EMAIL_ALREADY_EXISTS,
            });
        });
    });
    describe('loginEmail', () => {
        it('应该成功登录', async () => {
            const loginData = {
                email: 'test@example.com',
                password: 'password123',
            };
            const mockUser = (0, factories_1.createMockUser)();
            mockUserRepository.findByEmail.mockResolvedValue(mockUser);
            mockedBcrypt.compare.mockResolvedValue(true);
            mockUserRepository.updateLastLogin.mockResolvedValue(mockUser);
            mockJwtService.generateToken.mockReturnValue('access-token');
            mockJwtService.generateRefreshToken.mockReturnValue('refresh-token');
            mockRefreshTokenRepository.create.mockResolvedValue({});
            const result = await authService.loginEmail(loginData);
            expect(result).toHaveProperty('user');
            expect(result).toHaveProperty('tokens');
            expect(mockUserRepository.updateLastLogin).toHaveBeenCalledWith(mockUser.id);
        });
        it('用户不存在时应该抛出错误', async () => {
            const loginData = {
                email: 'nonexistent@example.com',
                password: 'password123',
            };
            mockUserRepository.findByEmail.mockResolvedValue(null);
            await expect(authService.loginEmail(loginData)).rejects.toThrow(errorHandler_1.AppError);
            await expect(authService.loginEmail(loginData)).rejects.toMatchObject({
                code: errors_1.ErrorCode.INVALID_CREDENTIALS,
            });
        });
        it('密码错误时应该抛出错误', async () => {
            const loginData = {
                email: 'test@example.com',
                password: 'wrong-password',
            };
            const mockUser = (0, factories_1.createMockUser)();
            mockUserRepository.findByEmail.mockResolvedValue(mockUser);
            mockedBcrypt.compare.mockResolvedValue(false);
            await expect(authService.loginEmail(loginData)).rejects.toThrow(errorHandler_1.AppError);
            await expect(authService.loginEmail(loginData)).rejects.toMatchObject({
                code: errors_1.ErrorCode.INVALID_CREDENTIALS,
            });
        });
    });
    describe('resetPassword', () => {
        it('应该成功重置密码', async () => {
            const resetData = {
                email: 'test@example.com',
                verificationCode: '123456',
                newPassword: 'new-password123',
            };
            const mockUser = (0, factories_1.createMockUser)();
            mockVerificationService.verifyCode.mockResolvedValue(true);
            mockUserRepository.findByEmail.mockResolvedValue(mockUser);
            mockedBcrypt.hash.mockResolvedValue('new-hashed-password');
            mockUserRepository.updatePassword.mockResolvedValue(mockUser);
            mockRefreshTokenRepository.deleteByUserId.mockResolvedValue(1);
            await authService.resetPassword(resetData);
            expect(mockVerificationService.verifyCode).toHaveBeenCalledWith(resetData.email, resetData.verificationCode, 'reset_password');
            expect(mockUserRepository.updatePassword).toHaveBeenCalledWith(mockUser.id, 'new-hashed-password');
            expect(mockRefreshTokenRepository.deleteByUserId).toHaveBeenCalledWith(mockUser.id);
        });
        it('用户不存在时应该抛出错误', async () => {
            const resetData = {
                email: 'nonexistent@example.com',
                verificationCode: '123456',
                newPassword: 'new-password123',
            };
            mockVerificationService.verifyCode.mockResolvedValue(true);
            mockUserRepository.findByEmail.mockResolvedValue(null);
            await expect(authService.resetPassword(resetData)).rejects.toThrow(errorHandler_1.AppError);
            await expect(authService.resetPassword(resetData)).rejects.toMatchObject({
                code: errors_1.ErrorCode.USER_NOT_FOUND,
            });
        });
    });
    describe('changePassword', () => {
        it('应该成功修改密码', async () => {
            const userId = 'test-user-id';
            const changeData = {
                currentPassword: 'old-password',
                newPassword: 'new-password123',
            };
            const mockUser = (0, factories_1.createMockUser)();
            mockUserRepository.findById.mockResolvedValue(mockUser);
            mockedBcrypt.compare.mockResolvedValue(true);
            mockedBcrypt.hash.mockResolvedValue('new-hashed-password');
            mockUserRepository.updatePassword.mockResolvedValue(mockUser);
            mockRefreshTokenRepository.deleteByUserId.mockResolvedValue(1);
            await authService.changePassword(userId, changeData);
            expect(mockUserRepository.updatePassword).toHaveBeenCalledWith(userId, 'new-hashed-password');
            expect(mockRefreshTokenRepository.deleteByUserId).toHaveBeenCalledWith(userId);
        });
        it('当前密码错误时应该抛出错误', async () => {
            const userId = 'test-user-id';
            const changeData = {
                currentPassword: 'wrong-password',
                newPassword: 'new-password123',
            };
            const mockUser = (0, factories_1.createMockUser)();
            mockUserRepository.findById.mockResolvedValue(mockUser);
            mockedBcrypt.compare.mockResolvedValue(false);
            await expect(authService.changePassword(userId, changeData)).rejects.toThrow(errorHandler_1.AppError);
            await expect(authService.changePassword(userId, changeData)).rejects.toMatchObject({
                code: errors_1.ErrorCode.INVALID_CREDENTIALS,
            });
        });
    });
    describe('refreshToken', () => {
        it('应该成功刷新 Token', async () => {
            const refreshToken = 'valid-refresh-token';
            const mockUser = (0, factories_1.createMockUser)();
            const mockTokenRecord = {
                id: 'token-id',
                userId: mockUser.id,
                token: refreshToken,
                expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
                createdAt: new Date(),
            };
            mockRefreshTokenRepository.findByToken.mockResolvedValue(mockTokenRecord);
            mockUserRepository.findById.mockResolvedValue(mockUser);
            mockRefreshTokenRepository.deleteByToken.mockResolvedValue(undefined);
            mockJwtService.generateToken.mockReturnValue('new-access-token');
            mockJwtService.generateRefreshToken.mockReturnValue('new-refresh-token');
            mockRefreshTokenRepository.create.mockResolvedValue({});
            const result = await authService.refreshToken(refreshToken);
            expect(result.tokens.accessToken).toBe('new-access-token');
            expect(result.tokens.refreshToken).toBe('new-refresh-token');
            expect(mockRefreshTokenRepository.deleteByToken).toHaveBeenCalledWith(refreshToken);
        });
        it('无效的 Refresh Token 应该抛出错误', async () => {
            const refreshToken = 'invalid-refresh-token';
            mockRefreshTokenRepository.findByToken.mockResolvedValue(null);
            await expect(authService.refreshToken(refreshToken)).rejects.toThrow(errorHandler_1.AppError);
            await expect(authService.refreshToken(refreshToken)).rejects.toMatchObject({
                code: errors_1.ErrorCode.INVALID_TOKEN,
            });
        });
        it('过期的 Refresh Token 应该抛出错误', async () => {
            const refreshToken = 'expired-refresh-token';
            const mockTokenRecord = {
                id: 'token-id',
                userId: 'user-id',
                token: refreshToken,
                expiresAt: new Date(Date.now() - 1000), // 已过期
                createdAt: new Date(),
            };
            mockRefreshTokenRepository.findByToken.mockResolvedValue(mockTokenRecord);
            mockRefreshTokenRepository.deleteByToken.mockResolvedValue(undefined);
            await expect(authService.refreshToken(refreshToken)).rejects.toThrow(errorHandler_1.AppError);
            await expect(authService.refreshToken(refreshToken)).rejects.toMatchObject({
                code: errors_1.ErrorCode.TOKEN_EXPIRED,
            });
        });
    });
    describe('logout', () => {
        it('应该成功登出', async () => {
            const userId = 'test-user-id';
            mockRefreshTokenRepository.deleteByUserId.mockResolvedValue(1);
            await authService.logout(userId);
            expect(mockRefreshTokenRepository.deleteByUserId).toHaveBeenCalledWith(userId);
        });
    });
});
//# sourceMappingURL=authService.test.js.map