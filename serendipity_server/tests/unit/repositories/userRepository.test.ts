import { UserRepository } from '../../../src/repositories/userRepository';
import { prismaMock } from '../../mocks/prisma.mock';
import { createMockUser } from '../../helpers/factories';

describe('UserRepository', () => {
  let userRepository: UserRepository;

  beforeEach(() => {
    userRepository = new UserRepository(prismaMock as any);
  });

  describe('findById', () => {
    it('应该根据 ID 查找用户', async () => {
      const mockUser = createMockUser();
      prismaMock.user.findUnique.mockResolvedValue(mockUser);

      const result = await userRepository.findById('test-user-id');

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'test-user-id' },
      });
    });

    it('用户不存在时应该返回 null', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      const result = await userRepository.findById('non-existent-id');

      expect(result).toBeNull();
    });
  });

  describe('findByEmail', () => {
    it('应该根据邮箱查找用户', async () => {
      const mockUser = createMockUser();
      prismaMock.user.findUnique.mockResolvedValue(mockUser);

      const result = await userRepository.findByEmail('test@example.com');

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({
        where: { email: 'test@example.com' },
      });
    });
  });

  describe('findByPhone', () => {
    it('应该根据手机号查找用户', async () => {
      const mockUser = createMockUser({ phoneNumber: '+8613800138000' });
      prismaMock.user.findUnique.mockResolvedValue(mockUser);

      const result = await userRepository.findByPhone('+8613800138000');

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({
        where: { phoneNumber: '+8613800138000' },
      });
    });
  });

  describe('create', () => {
    it('应该创建新用户', async () => {
      const mockUser = createMockUser();
      const createData = {
        email: 'test@example.com',
        passwordHash: 'hashed-password',
      };

      prismaMock.user.create.mockResolvedValue(mockUser);

      const result = await userRepository.create(createData);

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.create).toHaveBeenCalledWith({
        data: {
          email: 'test@example.com',
          phoneNumber: undefined,
          passwordHash: 'hashed-password',
          displayName: undefined,
          authProvider: 'email',
        },
      });
    });
  });

  describe('updateLastLogin', () => {
    it('应该更新最后登录时间', async () => {
      const mockUser = createMockUser({ lastLoginAt: new Date() });
      prismaMock.user.update.mockResolvedValue(mockUser);

      const result = await userRepository.updateLastLogin('test-user-id');

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'test-user-id' },
        data: { lastLoginAt: expect.any(Date) },
      });
    });
  });

  describe('updatePassword', () => {
    it('应该更新用户密码', async () => {
      const mockUser = createMockUser();
      prismaMock.user.update.mockResolvedValue(mockUser);

      const result = await userRepository.updatePassword(
        'test-user-id',
        'new-hashed-password'
      );

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'test-user-id' },
        data: { passwordHash: 'new-hashed-password' },
      });
    });
  });

  describe('bindEmail', () => {
    it('应该绑定邮箱', async () => {
      const mockUser = createMockUser({ email: 'new@example.com' });
      prismaMock.user.update.mockResolvedValue(mockUser);

      const result = await userRepository.bindEmail(
        'test-user-id',
        'new@example.com'
      );

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'test-user-id' },
        data: { email: 'new@example.com' },
      });
    });
  });

  describe('bindPhone', () => {
    it('应该绑定手机号', async () => {
      const mockUser = createMockUser({ phoneNumber: '+8613800138000' });
      prismaMock.user.update.mockResolvedValue(mockUser);

      const result = await userRepository.bindPhone(
        'test-user-id',
        '+8613800138000'
      );

      expect(result).toEqual(mockUser);
      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'test-user-id' },
        data: { phoneNumber: '+8613800138000' },
      });
    });
  });
});

