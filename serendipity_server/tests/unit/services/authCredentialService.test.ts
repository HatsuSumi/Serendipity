import { AuthCredentialService } from '../../../src/services/authCredentialService';
import { IUserRepository } from '../../../src/repositories/userRepository';
import { IPasswordHasher } from '../../../src/services/passwordHasher';
import { AuthServiceSupport } from '../../../src/services/authServiceSupport';
import { createMockUser } from '../../helpers/factories';
import { ErrorCode } from '../../../src/types/errors';

describe('AuthCredentialService', () => {
  let authCredentialService: AuthCredentialService;
  let mockUserRepository: jest.Mocked<IUserRepository>;
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

    mockPasswordHasher = {
      hash: jest.fn(),
      compare: jest.fn(),
    };

    authServiceSupport = new AuthServiceSupport(mockUserRepository, mockPasswordHasher);
    authCredentialService = new AuthCredentialService(
      mockUserRepository,
      mockPasswordHasher,
      authServiceSupport,
    );
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

      await authCredentialService.changePassword(userId, changeData);

      expect(mockUserRepository.updatePassword).toHaveBeenCalledWith(userId, 'new-hashed-password');
    });

    it('当前密码为空时应该抛出错误', async () => {
      await expect(
        authCredentialService.changePassword('test-user-id', {
          currentPassword: '',
          newPassword: 'new-password123',
        }),
      ).rejects.toMatchObject({
        code: ErrorCode.INVALID_CREDENTIALS,
      });
    });

    it('当前密码错误时应该抛出错误', async () => {
      const mockUser = createMockUser();

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(false);

      await expect(
        authCredentialService.changePassword('test-user-id', {
          currentPassword: 'wrong-password',
          newPassword: 'new-password123',
        }),
      ).rejects.toMatchObject({
        code: ErrorCode.INVALID_CREDENTIALS,
      });
    });
  });

  describe('changeEmail', () => {
    it('应该成功更换邮箱并返回完整用户契约字段', async () => {
      const userId = 'test-user-id';
      const mockUser = createMockUser();
      const updatedUser = createMockUser({
        id: userId,
        email: 'new@example.com',
        updatedAt: new Date('2026-04-12T12:00:00.000Z'),
      });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.findByEmail.mockResolvedValue(null);
      mockUserRepository.bindEmail.mockResolvedValue(updatedUser);

      const result = await authCredentialService.changeEmail(userId, {
        newEmail: 'new@example.com',
        password: 'password123',
      });

      expect(mockUserRepository.bindEmail).toHaveBeenCalledWith(userId, 'new@example.com');
      expect(result).toMatchObject({
        id: userId,
        email: 'new@example.com',
        isEmailVerified: true,
        isPhoneVerified: false,
        updatedAt: updatedUser.updatedAt,
      });
    });

    it('当前未绑定邮箱时应该抛出错误', async () => {
      const mockUser = createMockUser({ email: null, phoneNumber: '+8613800000000' });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);

      await expect(
        authCredentialService.changeEmail('test-user-id', {
          newEmail: 'new@example.com',
          password: 'password123',
        }),
      ).rejects.toMatchObject({
        code: ErrorCode.VALIDATION_ERROR,
      });
    });

    it('新邮箱已被其他用户使用时应该抛出错误', async () => {
      const mockUser = createMockUser();
      const existingUser = createMockUser({ id: 'another-user-id', email: 'new@example.com' });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.findByEmail.mockResolvedValue(existingUser);

      await expect(
        authCredentialService.changeEmail('test-user-id', {
          newEmail: 'new@example.com',
          password: 'password123',
        }),
      ).rejects.toMatchObject({
        code: ErrorCode.EMAIL_ALREADY_EXISTS,
      });
    });
  });

  describe('changePhone', () => {
    it('应该成功更换手机号并返回完整用户契约字段', async () => {
      const userId = 'test-user-id';
      const mockUser = createMockUser({ phoneNumber: '+8613800000000', authProvider: 'phone' });
      const updatedUser = createMockUser({
        id: userId,
        phoneNumber: '+8613800138000',
        authProvider: 'phone',
        updatedAt: new Date('2026-04-12T12:30:00.000Z'),
      });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.findByPhone.mockResolvedValue(null);
      mockUserRepository.bindPhone.mockResolvedValue(updatedUser);

      const result = await authCredentialService.changePhone(userId, {
        newPhoneNumber: '+8613800138000',
        password: 'password123',
      });

      expect(mockUserRepository.bindPhone).toHaveBeenCalledWith(userId, '+8613800138000');
      expect(result).toMatchObject({
        id: userId,
        phoneNumber: '+8613800138000',
        isEmailVerified: true,
        isPhoneVerified: true,
        updatedAt: updatedUser.updatedAt,
      });
    });

    it('当前未绑定手机号时应该抛出错误', async () => {
      const mockUser = createMockUser({ phoneNumber: null });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);

      await expect(
        authCredentialService.changePhone('test-user-id', {
          newPhoneNumber: '+8613800138000',
          password: 'password123',
        }),
      ).rejects.toMatchObject({
        code: ErrorCode.VALIDATION_ERROR,
      });
    });

    it('新手机号已被其他用户使用时应该抛出错误', async () => {
      const mockUser = createMockUser({ phoneNumber: '+8613800000000', authProvider: 'phone' });
      const existingUser = createMockUser({
        id: 'another-user-id',
        phoneNumber: '+8613800138000',
        authProvider: 'phone',
      });

      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockPasswordHasher.compare.mockResolvedValue(true);
      mockUserRepository.findByPhone.mockResolvedValue(existingUser);

      await expect(
        authCredentialService.changePhone('test-user-id', {
          newPhoneNumber: '+8613800138000',
          password: 'password123',
        }),
      ).rejects.toMatchObject({
        code: ErrorCode.PHONE_ALREADY_EXISTS,
      });
    });
  });
});

