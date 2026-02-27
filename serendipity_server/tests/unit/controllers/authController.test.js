"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const authController_1 = require("../../../src/controllers/authController");
const factories_1 = require("../../helpers/factories");
describe('AuthController', () => {
    let authController;
    let mockAuthService;
    let mockVerificationService;
    beforeEach(() => {
        mockAuthService = {
            registerEmail: jest.fn(),
            registerPhone: jest.fn(),
            loginEmail: jest.fn(),
            loginPhone: jest.fn(),
            resetPassword: jest.fn(),
            changePassword: jest.fn(),
            changeEmail: jest.fn(),
            changePhone: jest.fn(),
            getMe: jest.fn(),
            refreshToken: jest.fn(),
            logout: jest.fn(),
        };
        mockVerificationService = {
            sendVerificationCode: jest.fn(),
            verifyCode: jest.fn(),
            generateCode: jest.fn(),
        };
        authController = new authController_1.AuthController(mockAuthService, mockVerificationService);
    });
    describe('registerEmail', () => {
        it('应该成功注册用户', async () => {
            const req = (0, factories_1.createMockRequest)({
                body: {
                    email: 'test@example.com',
                    password: 'password123',
                    verificationCode: '123456',
                },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            const mockResult = {
                user: { id: 'user-id', email: 'test@example.com', createdAt: new Date() },
                tokens: { accessToken: 'token', refreshToken: 'refresh', expiresIn: 604800 },
            };
            mockAuthService.registerEmail.mockResolvedValue(mockResult);
            await authController.registerEmail(req, res, next);
            expect(mockAuthService.registerEmail).toHaveBeenCalledWith(req.body);
            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalled();
            expect(next).not.toHaveBeenCalled();
        });
        it('错误时应该调用 next', async () => {
            const req = (0, factories_1.createMockRequest)({ body: {} });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            const error = new Error('Test error');
            mockAuthService.registerEmail.mockRejectedValue(error);
            await authController.registerEmail(req, res, next);
            expect(next).toHaveBeenCalledWith(error);
        });
    });
    describe('loginEmail', () => {
        it('应该成功登录', async () => {
            const req = (0, factories_1.createMockRequest)({
                body: {
                    email: 'test@example.com',
                    password: 'password123',
                },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            const mockResult = {
                user: { id: 'user-id', email: 'test@example.com', createdAt: new Date() },
                tokens: { accessToken: 'token', refreshToken: 'refresh', expiresIn: 604800 },
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
            const req = (0, factories_1.createMockRequest)({
                body: {
                    type: 'email',
                    target: 'test@example.com',
                    purpose: 'register',
                },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            mockVerificationService.sendVerificationCode.mockResolvedValue(undefined);
            await authController.sendVerificationCode(req, res, next);
            expect(mockVerificationService.sendVerificationCode).toHaveBeenCalledWith('email', 'test@example.com', 'register');
            expect(res.json).toHaveBeenCalled();
            expect(next).not.toHaveBeenCalled();
        });
    });
    describe('resetPassword', () => {
        it('应该成功重置密码', async () => {
            const req = (0, factories_1.createMockRequest)({
                body: {
                    email: 'test@example.com',
                    verificationCode: '123456',
                    newPassword: 'new-password',
                },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            mockAuthService.resetPassword.mockResolvedValue(undefined);
            await authController.resetPassword(req, res, next);
            expect(mockAuthService.resetPassword).toHaveBeenCalledWith(req.body);
            expect(res.json).toHaveBeenCalled();
            expect(next).not.toHaveBeenCalled();
        });
    });
    describe('refreshToken', () => {
        it('应该成功刷新 Token', async () => {
            const req = (0, factories_1.createMockRequest)({
                body: { refreshToken: 'refresh-token' },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            const mockResult = {
                user: { id: 'user-id', email: 'test@example.com', createdAt: new Date() },
                tokens: { accessToken: 'new-token', refreshToken: 'new-refresh', expiresIn: 604800 },
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
            const req = (0, factories_1.createMockRequest)({
                user: { userId: 'test-user-id', email: 'test@example.com' },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            const mockResult = {
                id: 'test-user-id',
                email: 'test@example.com',
                createdAt: new Date(),
                membership: { tier: 'free', status: 'inactive' },
            };
            mockAuthService.getMe.mockResolvedValue(mockResult);
            await authController.getMe(req, res, next);
            expect(mockAuthService.getMe).toHaveBeenCalledWith('test-user-id');
            expect(res.json).toHaveBeenCalled();
            expect(next).not.toHaveBeenCalled();
        });
    });
    describe('logout', () => {
        it('应该成功登出', async () => {
            const req = (0, factories_1.createMockRequest)({
                user: { userId: 'test-user-id' },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            mockAuthService.logout.mockResolvedValue(undefined);
            await authController.logout(req, res, next);
            expect(mockAuthService.logout).toHaveBeenCalledWith('test-user-id');
            expect(res.json).toHaveBeenCalled();
            expect(next).not.toHaveBeenCalled();
        });
    });
    describe('changePassword', () => {
        it('应该成功修改密码', async () => {
            const req = (0, factories_1.createMockRequest)({
                user: { userId: 'test-user-id' },
                body: {
                    currentPassword: 'old-password',
                    newPassword: 'new-password',
                },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            mockAuthService.changePassword.mockResolvedValue(undefined);
            await authController.changePassword(req, res, next);
            expect(mockAuthService.changePassword).toHaveBeenCalledWith('test-user-id', req.body);
            expect(res.json).toHaveBeenCalled();
            expect(next).not.toHaveBeenCalled();
        });
    });
    describe('changeEmail', () => {
        it('应该成功更换邮箱', async () => {
            const req = (0, factories_1.createMockRequest)({
                user: { userId: 'test-user-id' },
                body: {
                    newEmail: 'new@example.com',
                    password: 'password123',
                    verificationCode: '123456',
                },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            mockAuthService.changeEmail.mockResolvedValue(undefined);
            await authController.changeEmail(req, res, next);
            expect(mockAuthService.changeEmail).toHaveBeenCalledWith('test-user-id', req.body);
            expect(res.json).toHaveBeenCalled();
            expect(next).not.toHaveBeenCalled();
        });
    });
    describe('changePhone', () => {
        it('应该成功更换手机号', async () => {
            const req = (0, factories_1.createMockRequest)({
                user: { userId: 'test-user-id' },
                body: {
                    newPhoneNumber: '+8613800138000',
                    verificationCode: '123456',
                },
            });
            const res = (0, factories_1.createMockResponse)();
            const next = (0, factories_1.createMockNext)();
            mockAuthService.changePhone.mockResolvedValue(undefined);
            await authController.changePhone(req, res, next);
            expect(mockAuthService.changePhone).toHaveBeenCalledWith('test-user-id', req.body);
            expect(res.json).toHaveBeenCalled();
            expect(next).not.toHaveBeenCalled();
        });
    });
});
//# sourceMappingURL=authController.test.js.map