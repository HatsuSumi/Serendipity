import { AuthRecoveryService } from '../../../src/services/authRecoveryService';
import { IUserRepository } from '../../../src/repositories/userRepository';
import { IRefreshTokenRepository } from '../../../src/repositories/refreshTokenRepository';
import { IPasswordHasher } from '../../../src/services/passwordHasher';
import { AuthServiceSupport } from '../../../src/services/authServiceSupport';
import { createMockUser } from '../../helpers/factories';
import { ErrorCode } from '../../../src/types/errors';

describe('AuthRecoveryService', () => {
  let authRecoveryService: AuthRecoveryService;
  let mockUserRepository: jest.Mocked<IUserRepository>;
  let mockRefreshTokenRepository: jest.Mocked<IRefreshTokenRepository>;
  let mockPasswordHasher: jest.Mocked<IPasswordHasher>;
  let authServiceSupport: AuthServiceSupport;

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

    mockRefreshTokenRepository = {
      createOrReplace: jest.fn(),
      findByToken: jest.fn(),
      findByTokenAndDeviceId: jest.fn(),
      deleteByToken: jest.fn(),
      deleteByUserId: jest.fn(),
      deleteExpired: jest.fn(),
      deleteAllExceptNewest: jest.fn(),
    };

    mockPasswordHasher = {
      hash: jest.fn(),
      compare: jest.fn(),
    };

    authServiceSupport = new AuthServiceSupport(mockUserRepository, mockPasswordHasher);
    authRecoveryService = new AuthRecoveryService(
      mockUserRepository,
      mockRefreshTokenRepository,
      mockPasswordHasher,
      authServiceSupport,
    );
  });

  describe('resetPassword', () => {
    it('应该成功重置密码并删除所有刷新令牌', async () => {
      const mockUser = createMockUser({ recoveryKey: 'xxxx-xxxx-xxxx-xxxx' });

      mockUserRepository.findByEmail.mockResolvedValue(mockUser);
      mockPasswordHasher.hash.mockResolvedValue('new-hashed-password');
      mockUserRepository.updatePassword.mockResolvedValue(mockUser);
      mockRefreshTokenRepository.deleteByUserId.mockResolvedValue(1);

      await authRecoveryService.resetPassword({
        email: 'test@example.com',
        recoveryKey: 'xxxx-xxxx-xxxx-xxxx',
        newPassword: 'new-password123',
      });

      expect(mockUserRepository.updatePassword).toHaveBeenCalledWith(mockUser.id, 'new-hashed-password');
      expect(mockRefreshTokenRepository.deleteByUserId).toHaveBeenCalledWith(mockUser.id);
    });

    it('用户不存在时应该抛出错误', async () => {
      mockUserRepository.findByEmail.mockResolvedValue(null);

      await expect(
        authRecoveryService.resetPassword({
          email: 'missing@example.com',
          recoveryKey: 'xxxx-xxxx-xxxx-xxxx',
          newPassword: 'new-password123',
        }),
      ).rejects.toMatchObject({
        code: ErrorCode.INVALID_CREDENTIALS,
      });
    });

    it('恢复密钥错误时应该抛出错误', async () => {
      const mockUser = createMockUser({ recoveryKey: 'correct-recovery-key' });

      mockUserRepository.findByEmail.mockResolvedValue(mockUser);

      await expect(
        authRecoveryService.resetPassword({
          email: 'test@example.com',
          recoveryKey: 'wrong-recovery-key',
          newPassword: 'new-password123',
        }),
      ).rejects.toMatchObject({
        code: ErrorCode.INVALID_CREDENTIALS,
      });
    });
  });

  describe('generateRecoveryKey', () => {
    it('应该成功生成恢复密钥并持久化', async () => {
      const mockUser = createMockUser();

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockUserRepository.updateRecoveryKey.mockResolvedValue(mockUser);

      const result = await authRecoveryService.generateRecoveryKey(mockUser.id);

      expect(mockUserRepository.updateRecoveryKey).toHaveBeenCalledWith(
        mockUser.id,
        expect.any(String),
      );
      expect(result).toMatchObject({
        recoveryKey: expect.any(String),
        message: '请妥善保管恢复密钥，丢失后无法找回',
      });
    });
  });

  describe('getRecoveryKey', () => {
    it('应该返回用户当前恢复密钥', async () => {
      const mockUser = createMockUser({ recoveryKey: 'stored-recovery-key' });

      mockUserRepository.findById.mockResolvedValue(mockUser);

      await expect(authRecoveryService.getRecoveryKey(mockUser.id)).resolves.toBe('stored-recovery-key');
    });

    it('用户不存在时应该抛出错误', async () => {
      mockUserRepository.findById.mockResolvedValue(null);

      await expect(authRecoveryService.getRecoveryKey('missing-user-id')).rejects.toMatchObject({
        code: ErrorCode.USER_NOT_FOUND,
      });
    });
  });
});

