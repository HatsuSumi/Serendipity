import { PrismaClient } from '@prisma/client';

export interface IFavoriteRepository {
  favoritePost(userId: string, postId: string): Promise<void>;
  unfavoritePost(userId: string, postId: string): Promise<void>;
  getFavoritedPosts(userId: string): Promise<string[]>;
  favoriteRecord(userId: string, recordId: string): Promise<void>;
  unfavoriteRecord(userId: string, recordId: string): Promise<void>;
  getFavoritedRecordIds(userId: string): Promise<string[]>;
}

export class FavoriteRepository implements IFavoriteRepository {
  constructor(private prisma: PrismaClient) {}

  async favoritePost(userId: string, postId: string): Promise<void> {
    await this.prisma.favorite.upsert({
      where: { userId_postId: { userId, postId } },
      update: {},
      create: { userId, postId },
    });
  }

  async unfavoritePost(userId: string, postId: string): Promise<void> {
    await this.prisma.favorite.deleteMany({
      where: { userId, postId },
    });
  }

  async getFavoritedPosts(userId: string): Promise<string[]> {
    const rows = await this.prisma.favorite.findMany({
      where: { userId, postId: { not: null } },
      orderBy: { createdAt: 'desc' },
      select: { postId: true },
    });
    return rows.map(r => r.postId as string);
  }

  async favoriteRecord(userId: string, recordId: string): Promise<void> {
    await this.prisma.favorite.upsert({
      where: { userId_recordId: { userId, recordId } },
      update: {},
      create: { userId, recordId },
    });
  }

  async unfavoriteRecord(userId: string, recordId: string): Promise<void> {
    await this.prisma.favorite.deleteMany({
      where: { userId, recordId },
    });
  }

  async getFavoritedRecordIds(userId: string): Promise<string[]> {
    const rows = await this.prisma.favorite.findMany({
      where: { userId, recordId: { not: null } },
      orderBy: { createdAt: 'desc' },
      select: { recordId: true },
    });
    return rows.map(r => r.recordId as string);
  }
}

