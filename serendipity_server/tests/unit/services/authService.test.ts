import { AuthService } from '../../../src/services/authService';
import { IUserRepository } from '../../../src/repositories/userRepository';
import { IRefreshTokenRepository } from '../../../src/repositories/refreshTokenRepository';
import { IPasswordHasher } from '../../../src/services/passwordHasher';
import { JwtService } from '../../../src/services/jwtService';
import { createMockUser } from '../../helpers/factories';
import { AppError } from '../../../src/middlewares/errorHandler';
import { ErrorCode } from '../../../src/types/errors';

describe('AuthService', () => {
  let authService: AuthService;
  let mockUserRepository: jest.Mocked<IUserRepository>;
  let mockRefreshTokenRepository: jest.Mocked<IRefreshTokenRepository>;
  let mockJwtService: jest.Mocked<JwtService>;
  let mockPasswordHasher: jest.Mocked<IPasswordHasher>;

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
      updateRecoveryKey: jest.fn(),
      findByEmailAndRecoveryKey: jest.fn(),
      deleteById: jest.fn(),
    };

    mockRefreshTokenRepository = {
      createOrReplace: jest.fn(),
      findByToken: jest.fn(),
      findByTokenAndDeviceId: jest.fn(),
      deleteByToken: jest.fn(),
      deleteByUserId: jest.fn(),
      deleteExpired: jest.fn(),
      deleteAllExceptNewest: jest.fn().mockResolvedValue(0),
    };

    mockPasswordHasher = {
      hash: jest.fn(),
      compare: jest.fn(),
    };

    mockJwtService = {
      generateToken: jest.fn().mockReturnValue('access-token'),
      generateRefreshToken: jest.fn().mockReturnValue('refresh-token'),
      verify: jest.fn(),
    } as any;

    authService = new AuthService(
      mockUserRepository,
      mockRefreshTokenRepository,
      {} as any,
      mockJwtService,
      mockPasswordHasher
    );
  });

  describe('registerEmail', () => {
    it('应该成功注册新用户', async () => {
      const registerData = {
        email: 'test@example.com',
        password: 'password123',
        deviceId: 'device-test',
      };

      const mockUser = createMockUser({
        lastLoginAt: new Date('2026-02-01T08:00:00.000Z'),
      });
      
      mockUserRepository.findByEmail.mockResolvedValue(null);
      mockPasswordHasher.hash.mockResolvedValue('hashed-password');
      mockUserRepository.create.mockResolvedValue(mockUser);
      mockUserRepository.updateRecoveryKey.mockResolvedValue(mockUser);
      mockRefreshTokenRepository.createOrReplace.mockResolvedValue({} as any);

      const result = await authService.registerEmail(registerData);

      expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(registerData.email);
      expect(mockPasswordHasher.hash).toHaveBeenCalledWith(registerData.password);
      expect(mockUserRepository.create).toHaveBeenCalled();
      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('tokens');
      expect(result).toHaveProperty('recoveryKey');
      expect(result.user).toMatchObject({
        id: mockUser.id,
        email: mockUser.email ?? undefined,
        displayName: mockUser.displayName ?? undefined,
        authProvider: 'email',
        isEmailVerified: true,
        isPhoneVerified: false,
        lastLoginAt: mockUser.lastLoginAt ?? undefined,
        updatedAt: mockUser.updatedAt,
      });
    });

    it('邮箱已存在时应该抛出错误', async () => {
      const registerData = {
        email: 'existing@example.com',
        password: 'password123',
        deviceId: 'device-test',
      };

      mockUserRepository.findByEmail.mockResolvedValue(createMockUser());

      await expect(authService.registerEmail(registerData)).rejects.toThrow(AppError);
      await expect(authService.registerEmail(registerData)).rejects.toMatchObject({
        code: ErrorCode.EMAIL_ALREADY_EXISTS,
      });
    });
  });

  describe('loginEmail', () => {
    it('应该成功登录', async () => {
      const loginData = {
        email: 'test@example.com',
        password: 'password123',
        deviceId: 'device-test',
      };

      const mockUser = createMockUser();
      
      mockUserRepository.findByEmail.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.updateLastLogin.mockResolvedValue(mockUser);
      mockRefreshTokenRepository.createOrReplace.mockResolvedValue({} as any);

      const result = await authService.loginEmail(loginData);

      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('tokens');
      expect(mockUserRepository.updateLastLogin).toHaveBeenCalledWith(mockUser.id);
      expect(result.user).toMatchObject({
        id: mockUser.id,
        email: mockUser.email ?? undefined,
        displayName: mockUser.displayName ?? undefined,
        authProvider: 'email',
        isEmailVerified: true,
        isPhoneVerified: false,
        lastLoginAt: mockUser.lastLoginAt ?? undefined,
        updatedAt: mockUser.updatedAt,
      });
    });

    it('用户不存在时应该抛出错误', async () => {
      const loginData = {
        email: 'nonexistent@example.com',
        password: 'password123',
        deviceId: 'device-test',
      };

      mockUserRepository.findByEmail.mockResolvedValue(null);

      await expect(authService.loginEmail(loginData)).rejects.toThrow(AppError);
      await expect(authService.loginEmail(loginData)).rejects.toMatchObject({
        code: ErrorCode.INVALID_CREDENTIALS,
      });
    });

    it('密码错误时应该抛出错误', async () => {
      const loginData = {
        email: 'test@example.com',
        password: 'wrong-password',
        deviceId: 'device-test',
      };

      const mockUser = createMockUser();
      
      mockUserRepository.findByEmail.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(false);

      await expect(authService.loginEmail(loginData)).rejects.toThrow(AppError);
      await expect(authService.loginEmail(loginData)).rejects.toMatchObject({
        code: ErrorCode.INVALID_CREDENTIALS,
      });
    });
  });

  describe('resetPassword', () => {
    it('应该成功重置密码', async () => {
      const resetData = {
        email: 'test@example.com',
        recoveryKey: 'xxxx-xxxx-xxxx-xxxx',
        newPassword: 'new-password123',
      };

      const mockUser = createMockUser({ recoveryKey: 'xxxx-xxxx-xxxx-xxxx' });
      
      mockUserRepository.findByEmail.mockResolvedValue(mockUser);
      mockPasswordHasher.hash.mockResolvedValue('new-hashed-password');
      mockUserRepository.updatePassword.mockResolvedValue(mockUser);
      mockRefreshTokenRepository.deleteByUserId.mockResolvedValue(1);

      await authService.resetPassword(resetData);

      expect(mockUserRepository.updatePassword).toHaveBeenCalledWith(
        mockUser.id,
        'new-hashed-password'
      );
      expect(mockRefreshTokenRepository.deleteByUserId).toHaveBeenCalledWith(mockUser.id);
    });

    it('用户不存在时应该抛出错误', async () => {
      const resetData = {
        email: 'nonexistent@example.com',
        recoveryKey: 'xxxx-xxxx-xxxx-xxxx',
        newPassword: 'new-password123',
      };

      mockUserRepository.findByEmail.mockResolvedValue(null);

      await expect(authService.resetPassword(resetData)).rejects.toThrow(AppError);
      await expect(authService.resetPassword(resetData)).rejects.toMatchObject({
        code: ErrorCode.INVALID_CREDENTIALS,
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

      const mockUser = createMockUser();
      
      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockPasswordHasher.hash.mockResolvedValue('new-hashed-password');
      mockUserRepository.updatePassword.mockResolvedValue(mockUser);
      mockRefreshTokenRepository.deleteByUserId.mockResolvedValue(1);

      await authService.changePassword(userId, changeData);

      expect(mockUserRepository.updatePassword).toHaveBeenCalledWith(
        userId,
        'new-hashed-password'
      );
      expect(mockRefreshTokenRepository.deleteByUserId).not.toHaveBeenCalled();
    });

    it('当前密码错误时应该抛出错误', async () => {
      const userId = 'test-user-id';
      const changeData = {
        currentPassword: 'wrong-password',
        newPassword: 'new-password123',
      };

      const mockUser = createMockUser();
      
      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(false);

      await expect(authService.changePassword(userId, changeData)).rejects.toThrow(AppError);
      await expect(authService.changePassword(userId, changeData)).rejects.toMatchObject({
        code: ErrorCode.INVALID_CREDENTIALS,
      });
    });
  });

  describe('changeEmail', () => {
    it('应该成功更换邮箱并返回完整用户契约字段', async () => {
      const userId = 'test-user-id';
      const changeData = {
        newEmail: 'new@example.com',
        password: 'password123',
      };
      const mockUser = createMockUser();
      const updatedUser = createMockUser({
        id: userId,
        email: changeData.newEmail,
        updatedAt: new Date('2026-04-12T12:00:00.000Z'),
      });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.findByEmail.mockResolvedValue(null);
      mockUserRepository.bindEmail.mockResolvedValue(updatedUser);

      const result = await authService.changeEmail(userId, changeData);

      expect(mockUserRepository.bindEmail).toHaveBeenCalledWith(userId, changeData.newEmail);
      expect(result).toMatchObject({
        id: userId,
        email: changeData.newEmail,
        isEmailVerified: true,
        isPhoneVerified: false,
        updatedAt: updatedUser.updatedAt,
      });
    });
  });

  describe('changePhone', () => {
    it('应该成功更换手机号并返回完整用户契约字段', async () => {
      const userId = 'test-user-id';
      const changeData = {
        newPhoneNumber: '+8613800138000',
        password: 'password123',
      };
      const mockUser = createMockUser({ phoneNumber: '+8613800000000', authProvider: 'phone' });
      const updatedUser = createMockUser({
        id: userId,
        phoneNumber: changeData.newPhoneNumber,
        authProvider: 'phone',
        updatedAt: new Date('2026-04-12T12:30:00.000Z'),
      });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.findByPhone.mockResolvedValue(null);
      mockUserRepository.bindPhone.mockResolvedValue(updatedUser);

      const result = await authService.changePhone(userId, changeData);

      expect(mockUserRepository.bindPhone).toHaveBeenCalledWith(userId, changeData.newPhoneNumber);
      expect(result).toMatchObject({
        id: userId,
        phoneNumber: changeData.newPhoneNumber,
        isEmailVerified: true,
        isPhoneVerified: true,
        updatedAt: updatedUser.updatedAt,
      });
    });
  });

  describe('refreshToken', () => {
    it('应该成功刷新 Token', async () => {
      const refreshToken = 'valid-refresh-token';
      const deviceId = 'device-test';
      const mockUser = createMockUser();
      const mockTokenRecord = {
        id: 'token-id',
        userId: mockUser.id,
        token: refreshToken,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        createdAt: new Date(),
      };

      mockRefreshTokenRepository.findByTokenAndDeviceId.mockResolvedValue(mockTokenRecord as any);
      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockRefreshTokenRepository.deleteByToken.mockResolvedValue(undefined as any);
      mockRefreshTokenRepository.createOrReplace.mockResolvedValue({} as any);

      const result = await authService.refreshToken(refreshToken, deviceId);

      expect(result.tokens.accessToken).toBe('access-token');
      expect(result.tokens.refreshToken).toBe('refresh-token');
      expect(mockRefreshTokenRepository.deleteByToken).toHaveBeenCalledWith(refreshToken);
    });

    it('无效的 Refresh Token 应该抛出错误', async () => {
      const refreshToken = 'invalid-refresh-token';
      const deviceId = 'device-test';

      mockRefreshTokenRepository.findByTokenAndDeviceId.mockResolvedValue(null);

      await expect(authService.refreshToken(refreshToken, deviceId)).rejects.toThrow(AppError);
      await expect(authService.refreshToken(refreshToken, deviceId)).rejects.toMatchObject({
        code: ErrorCode.INVALID_TOKEN,
      });
    });

    it('过期的 Refresh Token 应该抛出错误', async () => {
      const refreshToken = 'expired-refresh-token';
      const deviceId = 'device-test';
      const mockTokenRecord = {
        id: 'token-id',
        userId: 'user-id',
        token: refreshToken,
        expiresAt: new Date(Date.now() - 1000), // 已过期
        createdAt: new Date(),
      };

      mockRefreshTokenRepository.findByTokenAndDeviceId.mockResolvedValue(mockTokenRecord as any);
      mockRefreshTokenRepository.deleteByToken.mockResolvedValue(undefined as any);

      await expect(authService.refreshToken(refreshToken, deviceId)).rejects.toThrow(AppError);
      await expect(authService.refreshToken(refreshToken, deviceId)).rejects.toMatchObject({
        code: ErrorCode.TOKEN_EXPIRED,
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
