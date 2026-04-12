import { AuthController } from '../../../src/controllers/authController';
import { IAuthService } from '../../../src/services/authService';
import { IVerificationService } from '../../../src/services/verificationService';
import { createMockRequest, createMockResponse, createMockNext } from '../../helpers/factories';

describe('AuthController', () => {
  let authController: AuthController;
  let mockAuthService: jest.Mocked<IAuthService>;
  let mockVerificationService: jest.Mocked<IVerificationService>;

  beforeEach(() => {
    mockAuthService = {
      registerEmail: jest.fn(),
      registerPhone: jest.fn(),
      registerPhonePassword: jest.fn(),
      loginEmail: jest.fn(),
      loginPhone: jest.fn(),
      loginPhonePassword: jest.fn(),
      resetPassword: jest.fn(),
      changePassword: jest.fn(),
      changeEmail: jest.fn(),
      changePhone: jest.fn(),
      getMe: jest.fn(),
      refreshToken: jest.fn(),
      logout: jest.fn(),
      generateRecoveryKey: jest.fn(),
      getRecoveryKey: jest.fn(),
      deleteAccount: jest.fn(),
    };

    mockVerificationService = {
      sendVerificationCode: jest.fn(),
      verifyCode: jest.fn(),
      generateCode: jest.fn(),
    };

    authController = new AuthController(mockAuthService, mockVerificationService);
  });

  describe('registerEmail', () => {
    it('应该成功注册用户', async () => {
      const req = createMockRequest({
        body: {
          email: 'test@example.com',
          password: 'password123',
          verificationCode: '123456',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const mockResult = {
        user: {
          id: 'user-id',
          email: 'test@example.com',
          authProvider: 'email' as const,
          isEmailVerified: true,
          isPhoneVerified: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        tokens: { accessToken: 'token', refreshToken: 'refresh', expiresIn: 604800, expiresAt: new Date().toISOString() },
      };

      mockAuthService.registerEmail.mockResolvedValue(mockResult);

      await authController.registerEmail(req, res, next);

      expect(mockAuthService.registerEmail).toHaveBeenCalledWith(req.body);
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalled();
      expect(next).not.toHaveBeenCalled();
    });

    it('错误时应该调用 next', async () => {
      const req = createMockRequest({ body: {} });
      const res = createMockResponse();
      const next = createMockNext();

      const error = new Error('Test error');
      mockAuthService.registerEmail.mockRejectedValue(error);

      await authController.registerEmail(req, res, next);

      expect(next).toHaveBeenCalledWith(error);
    });
  });

  describe('loginEmail', () => {
    it('应该成功登录', async () => {
      const req = createMockRequest({
        body: {
          email: 'test@example.com',
          password: 'password123',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const mockResult = {
        user: {
          id: 'user-id',
          email: 'test@example.com',
          authProvider: 'email' as const,
          isEmailVerified: true,
          isPhoneVerified: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        tokens: { accessToken: 'token', refreshToken: 'refresh', expiresIn: 604800, expiresAt: new Date().toISOString() },
      };

      mockAuthService.loginEmail.mockResolvedValue(mockResult);

      await authController.loginEmail(req, res, next);

      expect(mockAuthService.loginEmail).toHaveBeenCalledWith(req.body);
      expect(res.json).toHaveBeenCalled();
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('sendVerificationCode', () => {
    it('应该成功发送验证码', async () => {
      const req = createMockRequest({
        body: {
          type: 'email',
          target: 'test@example.com',
          purpose: 'register',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      mockVerificationService.sendVerificationCode.mockResolvedValue(undefined);

      await authController.sendVerificationCode(req, res, next);

      expect(mockVerificationService.sendVerificationCode).toHaveBeenCalledWith(
        'email',
        'test@example.com',
        'register'
      );
      expect(res.json).toHaveBeenCalled();
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('resetPassword', () => {
    it('应该成功重置密码', async () => {
      const req = createMockRequest({
        body: {
          email: 'test@example.com',
          verificationCode: '123456',
          newPassword: 'new-password',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      mockAuthService.resetPassword.mockResolvedValue(undefined);

      await authController.resetPassword(req, res, next);

      expect(mockAuthService.resetPassword).toHaveBeenCalledWith(req.body);
      expect(res.json).toHaveBeenCalled();
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('refreshToken', () => {
    it('应该成功刷新 Token', async () => {
      const req = createMockRequest({
        body: { refreshToken: 'refresh-token' },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const mockResult = {
        user: {
          id: 'user-id',
          email: 'test@example.com',
          authProvider: 'email' as const,
          isEmailVerified: true,
          isPhoneVerified: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        tokens: { accessToken: 'new-token', refreshToken: 'new-refresh', expiresIn: 604800, expiresAt: new Date().toISOString() },
      };

      mockAuthService.refreshToken.mockResolvedValue(mockResult);

      await authController.refreshToken(req, res, next);

      expect(mockAuthService.refreshToken).toHaveBeenCalledWith('refresh-token');
      expect(res.json).toHaveBeenCalled();
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('getMe', () => {
    it('应该返回当前用户信息', async () => {
      const req = createMockRequest({
        user: { userId: 'test-user-id', email: 'test@example.com' },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const mockResult = {
        id: 'test-user-id',
        email: 'test@example.com',
        authProvider: 'email' as const,
        isEmailVerified: true,
        isPhoneVerified: false,
        createdAt: new Date(),
        updatedAt: new Date(),
        membership: { tier: 'free', status: 'inactive' },
      };

      mockAuthService.getMe.mockResolvedValue(mockResult as any);

      await authController.getMe(req, res, next);

      expect(mockAuthService.getMe).toHaveBeenCalledWith('test-user-id');
      expect(res.json).toHaveBeenCalled();
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('logout', () => {
    it('应该成功登出', async () => {
      const req = createMockRequest({
        user: { userId: 'test-user-id' },
      });
      const res = createMockResponse();
      const next = createMockNext();

      mockAuthService.logout.mockResolvedValue(undefined);

      await authController.logout(req, res, next);

      expect(mockAuthService.logout).toHaveBeenCalledWith('test-user-id');
      expect(res.json).toHaveBeenCalled();
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('changePassword', () => {
    it('应该成功修改密码', async () => {
      const req = createMockRequest({
        user: { userId: 'test-user-id' },
        body: {
          currentPassword: 'old-password',
          newPassword: 'new-password',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      mockAuthService.changePassword.mockResolvedValue(undefined);

      await authController.changePassword(req, res, next);

      expect(mockAuthService.changePassword).toHaveBeenCalledWith('test-user-id', req.body);
      expect(res.json).toHaveBeenCalled();
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('changeEmail', () => {
    it('应该成功更换邮箱并返回完整用户契约字段', async () => {
      const req = createMockRequest({
        user: { userId: 'test-user-id' },
        body: {
          newEmail: 'new@example.com',
          password: 'password123',
          verificationCode: '123456',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      mockAuthService.changeEmail.mockResolvedValue({
        id: 'test-user-id',
        email: 'new@example.com',
        authProvider: 'email',
        isEmailVerified: true,
        isPhoneVerified: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await authController.changeEmail(req, res, next);

      expect(mockAuthService.changeEmail).toHaveBeenCalledWith('test-user-id', req.body);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            email: 'new@example.com',
            isEmailVerified: true,
            updatedAt: expect.any(Date),
          }),
        }),
      );
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('changePhone', () => {
    it('应该成功更换手机号并返回完整用户契约字段', async () => {
      const req = createMockRequest({
        user: { userId: 'test-user-id' },
        body: {
          newPhoneNumber: '+8613800138000',
          password: 'password123',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      mockAuthService.changePhone.mockResolvedValue({
        id: 'test-user-id',
        phoneNumber: '+8613800138000',
        authProvider: 'phone',
        isEmailVerified: false,
        isPhoneVerified: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await authController.changePhone(req, res, next);

      expect(mockAuthService.changePhone).toHaveBeenCalledWith('test-user-id', req.body);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            phoneNumber: '+8613800138000',
            isPhoneVerified: true,
            updatedAt: expect.any(Date),
          }),
        }),
      );
      expect(next).not.toHaveBeenCalled();
    });
  });
});

