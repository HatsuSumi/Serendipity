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
    mockUserRepository = {
      findById: jest.fn(),
      findByEmail: jest.fn(),
      findByPhone: jest.fn(),
      findByEmailAndRecoveryKey: jest.fn(),
      create: jest.fn(),
      updateLastLogin: jest.fn(),
      updateUser: jest.fn(),
      updateDisplayName: jest.fn(),
      updateAvatarUrl: jest.fn(),
      incrementTokenVersion: jest.fn(),
      bindEmail: jest.fn(),
      bindPhone: jest.fn(),
      updatePassword: jest.fn(),
      updateRecoveryKey: jest.fn(),
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
      mockPasswordHasher,
    );
  });

  describe('registerEmail', () => {
    it('registers a new user', async () => {
      const data = { email: 'test@example.com', password: 'password123', deviceId: 'device-test' };
      const user = createMockUser({ lastLoginAt: new Date('2026-02-01T08:00:00.000Z') });

      mockUserRepository.findByEmail.mockResolvedValue(null);
      mockPasswordHasher.hash.mockResolvedValue('hashed-password');
      mockUserRepository.create.mockResolvedValue(user);
      mockUserRepository.updateRecoveryKey.mockResolvedValue(user);
      mockRefreshTokenRepository.createOrReplace.mockResolvedValue({} as any);

      const result = await authService.registerEmail(data);

      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('tokens');
      expect(result).toHaveProperty('recoveryKey');
      expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(data.email);
    });
  });

  describe('loginEmail', () => {
    it('logs in successfully', async () => {
      const loginData = { email: 'test@example.com', password: 'password123', deviceId: 'device-test' };
      const user = createMockUser();

      mockUserRepository.findByEmail.mockResolvedValue(user);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.updateLastLogin.mockResolvedValue(user);
      mockRefreshTokenRepository.createOrReplace.mockResolvedValue({} as any);

      const result = await authService.loginEmail(loginData);

      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('tokens');
      expect(mockUserRepository.updateLastLogin).toHaveBeenCalledWith(user.id);
    });

    it('throws when user does not exist', async () => {
      const loginData = { email: 'nonexistent@example.com', password: 'password123', deviceId: 'device-test' };
      mockUserRepository.findByEmail.mockResolvedValue(null);

      await expect(authService.loginEmail(loginData)).rejects.toThrow(AppError);
      await expect(authService.loginEmail(loginData)).rejects.toMatchObject({
        code: ErrorCode.INVALID_CREDENTIALS,
      });
    });
  });

  describe('resetPassword', () => {
    it('resets password successfully', async () => {
      const resetData = {
        accountType: 'email' as const,
        account: 'test@example.com',
        recoveryKey: 'xxxx-xxxx-xxxx-xxxx',
        newPassword: 'new-password123',
      };
      const user = createMockUser({ recoveryKey: 'xxxx-xxxx-xxxx-xxxx' });

      mockUserRepository.findByEmail.mockResolvedValue(user);
      mockPasswordHasher.hash.mockResolvedValue('new-hashed-password');
      mockUserRepository.updatePassword.mockResolvedValue(user);
      mockRefreshTokenRepository.deleteByUserId.mockResolvedValue(1);

      await authService.resetPassword(resetData);

      expect(mockUserRepository.updatePassword).toHaveBeenCalledWith(user.id, 'new-hashed-password');
      expect(mockRefreshTokenRepository.deleteByUserId).toHaveBeenCalledWith(user.id);
    });
  });

  describe('changePassword', () => {
    it('changes password successfully', async () => {
      const userId = 'test-user-id';
      const data = { currentPassword: 'old-password', newPassword: 'new-password123' };
      const user = createMockUser();

      mockUserRepository.findById.mockResolvedValue(user);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockPasswordHasher.hash.mockResolvedValue('new-hashed-password');
      mockUserRepository.updatePassword.mockResolvedValue(user);
      mockRefreshTokenRepository.deleteByUserId.mockResolvedValue(1);

      await authService.changePassword(userId, data);

      expect(mockUserRepository.updatePassword).toHaveBeenCalledWith(userId, 'new-hashed-password');
      expect(mockRefreshTokenRepository.deleteByUserId).not.toHaveBeenCalled();
    });
  });

  describe('changeEmail', () => {
    it('changes email successfully', async () => {
      const userId = 'test-user-id';
      const data = { newEmail: 'new@example.com', password: 'password123' };
      const user = createMockUser();
      const updatedUser = createMockUser({ id: userId, email: data.newEmail, updatedAt: new Date('2026-04-12T12:00:00.000Z') });

      mockUserRepository.findById.mockResolvedValue(user);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.findByEmail.mockResolvedValue(null);
      mockUserRepository.bindEmail.mockResolvedValue(updatedUser);

      const result = await authService.changeEmail(userId, data);
      expect(result.email).toBe(data.newEmail);
    });
  });

  describe('changePhone', () => {
    it('changes phone successfully', async () => {
      const userId = 'test-user-id';
      const data = { newPhoneNumber: '+8613800138000', password: 'password123' };
      const user = createMockUser({ phoneNumber: '+8613800000000', authProvider: 'phone' });
      const updatedUser = createMockUser({ id: userId, phoneNumber: data.newPhoneNumber, authProvider: 'phone' });

      mockUserRepository.findById.mockResolvedValue(user);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.findByPhone.mockResolvedValue(null);
      mockUserRepository.bindPhone.mockResolvedValue(updatedUser);

      const result = await authService.changePhone(userId, data);
      expect(result.phoneNumber).toBe(data.newPhoneNumber);
    });
  });

  describe('refreshToken', () => {
    it('refreshes token successfully', async () => {
      const refreshToken = 'valid-refresh-token';
      const deviceId = 'device-test';
      const user = createMockUser();
      const tokenRecord = {
        id: 'token-id',
        userId: user.id,
        token: refreshToken,
        deviceId,
        expiresAt: new Date(Date.now() + 100000),
        createdAt: new Date(),
      };

      mockRefreshTokenRepository.findByTokenAndDeviceId.mockResolvedValue(tokenRecord as any);
      mockUserRepository.findById.mockResolvedValue(user);
      mockRefreshTokenRepository.deleteByToken.mockResolvedValue(undefined as any);
      mockRefreshTokenRepository.createOrReplace.mockResolvedValue({} as any);

      const result = await authService.refreshToken(refreshToken, deviceId);
      expect(result.tokens.accessToken).toBe('access-token');
    });
  });

  describe('logout', () => {
    it('logs out successfully', async () => {
      const userId = 'test-user-id';
      mockRefreshTokenRepository.deleteByUserId.mockResolvedValue(1);

      await authService.logout(userId);

      expect(mockRefreshTokenRepository.deleteByUserId).toHaveBeenCalledWith(userId);
    });
  });
});
