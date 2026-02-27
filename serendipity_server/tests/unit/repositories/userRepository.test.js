"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const userRepository_1 = require("../../../src/repositories/userRepository");
const prisma_mock_1 = require("../../mocks/prisma.mock");
const factories_1 = require("../../helpers/factories");
describe('UserRepository', () => {
    let userRepository;
    beforeEach(() => {
        userRepository = new userRepository_1.UserRepository(prisma_mock_1.prismaMock);
    });
    describe('findById', () => {
        it('应该根据 ID 查找用户', async () => {
            const mockUser = (0, factories_1.createMockUser)();
            prisma_mock_1.prismaMock.user.findUnique.mockResolvedValue(mockUser);
            const result = await userRepository.findById('test-user-id');
            expect(result).toEqual(mockUser);
            expect(prisma_mock_1.prismaMock.user.findUnique).toHaveBeenCalledWith({
                where: { id: 'test-user-id' },
            });
        });
        it('用户不存在时应该返回 null', async () => {
            prisma_mock_1.prismaMock.user.findUnique.mockResolvedValue(null);
            const result = await userRepository.findById('non-existent-id');
            expect(result).toBeNull();
        });
    });
    describe('findByEmail', () => {
        it('应该根据邮箱查找用户', async () => {
            const mockUser = (0, factories_1.createMockUser)();
            prisma_mock_1.prismaMock.user.findUnique.mockResolvedValue(mockUser);
            const result = await userRepository.findByEmail('test@example.com');
            expect(result).toEqual(mockUser);
            expect(prisma_mock_1.prismaMock.user.findUnique).toHaveBeenCalledWith({
                where: { email: 'test@example.com' },
            });
        });
    });
    describe('findByPhone', () => {
        it('应该根据手机号查找用户', async () => {
            const mockUser = (0, factories_1.createMockUser)({ phoneNumber: '+8613800138000' });
            prisma_mock_1.prismaMock.user.findUnique.mockResolvedValue(mockUser);
            const result = await userRepository.findByPhone('+8613800138000');
            expect(result).toEqual(mockUser);
            expect(prisma_mock_1.prismaMock.user.findUnique).toHaveBeenCalledWith({
                where: { phoneNumber: '+8613800138000' },
            });
        });
    });
    describe('create', () => {
        it('应该创建新用户', async () => {
            const mockUser = (0, factories_1.createMockUser)();
            const createData = {
                email: 'test@example.com',
                passwordHash: 'hashed-password',
            };
            prisma_mock_1.prismaMock.user.create.mockResolvedValue(mockUser);
            const result = await userRepository.create(createData);
            expect(result).toEqual(mockUser);
            expect(prisma_mock_1.prismaMock.user.create).toHaveBeenCalledWith({
                data: createData,
            });
        });
    });
    describe('updateLastLogin', () => {
        it('应该更新最后登录时间', async () => {
            const mockUser = (0, factories_1.createMockUser)({ lastLoginAt: new Date() });
            prisma_mock_1.prismaMock.user.update.mockResolvedValue(mockUser);
            const result = await userRepository.updateLastLogin('test-user-id');
            expect(result).toEqual(mockUser);
            expect(prisma_mock_1.prismaMock.user.update).toHaveBeenCalledWith({
                where: { id: 'test-user-id' },
                data: { lastLoginAt: expect.any(Date) },
            });
        });
    });
    describe('updatePassword', () => {
        it('应该更新用户密码', async () => {
            const mockUser = (0, factories_1.createMockUser)();
            prisma_mock_1.prismaMock.user.update.mockResolvedValue(mockUser);
            const result = await userRepository.updatePassword('test-user-id', 'new-hashed-password');
            expect(result).toEqual(mockUser);
            expect(prisma_mock_1.prismaMock.user.update).toHaveBeenCalledWith({
                where: { id: 'test-user-id' },
                data: { passwordHash: 'new-hashed-password' },
            });
        });
    });
    describe('bindEmail', () => {
        it('应该绑定邮箱', async () => {
            const mockUser = (0, factories_1.createMockUser)({ email: 'new@example.com' });
            prisma_mock_1.prismaMock.user.update.mockResolvedValue(mockUser);
            const result = await userRepository.bindEmail('test-user-id', 'new@example.com');
            expect(result).toEqual(mockUser);
            expect(prisma_mock_1.prismaMock.user.update).toHaveBeenCalledWith({
                where: { id: 'test-user-id' },
                data: { email: 'new@example.com' },
            });
        });
    });
    describe('bindPhone', () => {
        it('应该绑定手机号', async () => {
            const mockUser = (0, factories_1.createMockUser)({ phoneNumber: '+8613800138000' });
            prisma_mock_1.prismaMock.user.update.mockResolvedValue(mockUser);
            const result = await userRepository.bindPhone('test-user-id', '+8613800138000');
            expect(result).toEqual(mockUser);
            expect(prisma_mock_1.prismaMock.user.update).toHaveBeenCalledWith({
                where: { id: 'test-user-id' },
                data: { phoneNumber: '+8613800138000' },
            });
        });
    });
});
//# sourceMappingURL=userRepository.test.js.map