import { PrismaClient, User } from '@prisma/client';

/**
 * 用户创建数据
 */
export interface CreateUserData {
  email?: string;
  phoneNumber?: string;
  passwordHash: string;
  displayName?: string;
  authProvider?: string;
}

/**
 * 更新用户数据
 */
export interface UpdateUserData {
  displayName?: string;
  avatarUrl?: string;
}

/**
 * 用户仓储接口
 * 提供用户数据的 CRUD 操作
 */
export interface IUserRepository {
  // 查询方法
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  findByPhone(phoneNumber: string): Promise<User | null>;
  findByEmailAndRecoveryKey(email: string, recoveryKeyHash: string): Promise<User | null>;
  
  // 创建方法
  create(data: CreateUserData): Promise<User>;
  
  // 更新方法
  updateLastLogin(id: string): Promise<User>;
  updateUser(id: string, data: UpdateUserData): Promise<User>;
  updateDisplayName(id: string, displayName: string): Promise<User>;
  updateAvatarUrl(id: string, avatarUrl: string): Promise<User>;
  
  // 认证相关方法
  bindEmail(id: string, email: string): Promise<User>;
  bindPhone(id: string, phoneNumber: string): Promise<User>;
  updatePassword(id: string, passwordHash: string): Promise<User>;
  updateRecoveryKey(id: string, recoveryKeyHash: string): Promise<User>;

  // 删除方法
  deleteById(id: string): Promise<void>;
}

/**
 * 用户仓储实现
 * 使用 Prisma ORM 操作用户数据
 */
export class UserRepository implements IUserRepository {
  constructor(private prisma: PrismaClient) {}

  /**
   * 根据 ID 查找用户
   * @param id - 用户 ID
   * @returns 用户对象或 null
   */
  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  /**
   * 根据邮箱查找用户
   * @param email - 邮箱地址
   * @returns 用户对象或 null
   */
  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { email },
    });
  }

  /**
   * 根据手机号查找用户
   * @param phoneNumber - 手机号
   * @returns 用户对象或 null
   */
  async findByPhone(phoneNumber: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { phoneNumber },
    });
  }

  /**
   * 创建新用户
   * @param data - 用户创建数据
   * @returns 创建的用户对象
   */
  async create(data: CreateUserData): Promise<User> {
    return this.prisma.user.create({
      data: {
        email: data.email,
        phoneNumber: data.phoneNumber,
        passwordHash: data.passwordHash,
        displayName: data.displayName,
        authProvider: data.authProvider || 'email',
      },
    });
  }

  /**
   * 更新最后登录时间
   * @param id - 用户 ID
   * @returns 更新后的用户对象
   */
  async updateLastLogin(id: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { lastLoginAt: new Date() },
    });
  }

  /**
   * 更新用户信息
   * @param id - 用户 ID
   * @param data - 更新数据
   * @returns 更新后的用户对象
   */
  async updateUser(id: string, data: UpdateUserData): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: {
        ...(data.displayName !== undefined && { displayName: data.displayName }),
        ...(data.avatarUrl !== undefined && { avatarUrl: data.avatarUrl }),
        updatedAt: new Date(),
      },
    });
  }

  /**
   * 更新用户昵称
   * @param id - 用户 ID
   * @param displayName - 新昵称
   * @returns 更新后的用户对象
   */
  async updateDisplayName(id: string, displayName: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { displayName },
    });
  }

  /**
   * 更新用户头像
   * @param id - 用户 ID
   * @param avatarUrl - 新头像 URL
   * @returns 更新后的用户对象
   */
  async updateAvatarUrl(id: string, avatarUrl: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { avatarUrl },
    });
  }

  /**
   * 绑定邮箱
   * @param id - 用户 ID
   * @param email - 邮箱地址
   * @returns 更新后的用户对象
   */
  async bindEmail(id: string, email: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { email },
    });
  }

  /**
   * 绑定手机号
   * @param id - 用户 ID
   * @param phoneNumber - 手机号
   * @returns 更新后的用户对象
   */
  async bindPhone(id: string, phoneNumber: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { phoneNumber },
    });
  }

  /**
   * 更新密码
   * @param id - 用户 ID
   * @param passwordHash - 密码哈希
   * @returns 更新后的用户对象
   */
  async updatePassword(id: string, passwordHash: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { passwordHash },
    });
  }

  /**
   * 更新恢复密钥
   * @param id - 用户 ID
   * @param recoveryKeyHash - 恢复密钥（明文存储）
   * @returns 更新后的用户对象
   */
  async updateRecoveryKey(id: string, recoveryKeyHash: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { recoveryKey: recoveryKeyHash },
    });
  }

  /**
   * 根据邮箱和恢复密钥查找用户
   * @param email - 邮箱地址
   * @param recoveryKeyHash - 恢复密钥
   * @returns 用户对象或 null
   */
  async findByEmailAndRecoveryKey(email: string, recoveryKeyHash: string): Promise<User | null> {
    return this.prisma.user.findFirst({
      where: {
        email,
        recoveryKey: recoveryKeyHash,
      },
    });
  }

  /**
   * 删除用户
   * @param id - 用户 ID
   */
  async deleteById(id: string): Promise<void> {
    await this.prisma.user.delete({
      where: { id },
    });
  }
}

