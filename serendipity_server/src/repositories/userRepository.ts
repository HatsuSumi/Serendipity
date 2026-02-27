import { PrismaClient, User } from '@prisma/client';

// 用户创建数据
export interface CreateUserData {
  email?: string;
  phoneNumber?: string;
  passwordHash: string;
  displayName?: string;
}

// 更新用户数据
export interface UpdateUserData {
  displayName?: string;
  avatarUrl?: string;
}

// 用户仓储接口
export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  findByPhone(phoneNumber: string): Promise<User | null>;
  create(data: CreateUserData): Promise<User>;
  updateLastLogin(id: string): Promise<User>;
  updateUser(id: string, data: UpdateUserData): Promise<User>;
  updateDisplayName(id: string, displayName: string): Promise<User>;
  updateAvatarUrl(id: string, avatarUrl: string): Promise<User>;
  bindEmail(id: string, email: string): Promise<User>;
  bindPhone(id: string, phoneNumber: string): Promise<User>;
  updatePassword(id: string, passwordHash: string): Promise<User>;
}

// 用户仓储实现
export class UserRepository implements IUserRepository {
  constructor(private prisma: PrismaClient) {}

  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { email },
    });
  }

  async findByPhone(phoneNumber: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { phoneNumber },
    });
  }

  async create(data: CreateUserData): Promise<User> {
    return this.prisma.user.create({
      data: {
        email: data.email,
        phoneNumber: data.phoneNumber,
        passwordHash: data.passwordHash,
        displayName: data.displayName,
      },
    });
  }

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

  async updateDisplayName(id: string, displayName: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { displayName },
    });
  }

  async updateAvatarUrl(id: string, avatarUrl: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { avatarUrl },
    });
  }

  async bindEmail(id: string, email: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { email },
    });
  }

  async bindPhone(id: string, phoneNumber: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { phoneNumber },
    });
  }

  async updatePassword(id: string, passwordHash: string): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: { passwordHash },
    });
  }
}

