import { PrismaClient, Prisma } from '@prisma/client';
import { toJsonValue } from '../utils/prisma-json';
import { FavoritePostSnapshotDto, FavoriteRecordSnapshotDto } from '../types/favorite.dto';

export interface FavoritePostRow {
  postId: string;
  postSnapshot: Prisma.JsonValue | null;
}

export interface FavoriteRecordRow {
  recordId: string;
  recordSnapshot: Prisma.JsonValue | null;
}

export interface IFavoriteRepository {
  favoritePost(userId: string, postId: string, snapshot: FavoritePostSnapshotDto): Promise<void>;
  unfavoritePost(userId: string, postId: string): Promise<void>;
  getFavoritedPosts(userId: string): Promise<FavoritePostRow[]>;
  favoriteRecord(userId: string, recordId: string, snapshot: FavoriteRecordSnapshotDto): Promise<void>;
  unfavoriteRecord(userId: string, recordId: string): Promise<void>;
  getFavoritedRecordIds(userId: string): Promise<FavoriteRecordRow[]>;
}

export class FavoriteRepository implements IFavoriteRepository {
  constructor(private prisma: PrismaClient) {}

  async favoritePost(userId: string, postId: string, snapshot: FavoritePostSnapshotDto): Promise<void> {
    await this.prisma.favorite.upsert({
      where: { userId_postId: { userId, postId } },
      update: {
        postSnapshot: toJsonValue(snapshot),
      },
      create: {
        userId,
        postId,
        postSnapshot: toJsonValue(snapshot),
      },
    });
  }

  async unfavoritePost(userId: string, postId: string): Promise<void> {
    await this.prisma.favorite.deleteMany({
      where: { userId, postId },
    });
  }

  async getFavoritedPosts(userId: string): Promise<FavoritePostRow[]> {
    const rows = await this.prisma.favorite.findMany({
      where: { userId, postId: { not: null } },
      orderBy: { createdAt: 'desc' },
      select: { postId: true, postSnapshot: true },
    });

    return rows.map((row) => ({
      postId: row.postId as string,
      postSnapshot: row.postSnapshot,
    }));
  }

  async favoriteRecord(userId: string, recordId: string, snapshot: FavoriteRecordSnapshotDto): Promise<void> {
    await this.prisma.favorite.upsert({
      where: { userId_recordId: { userId, recordId } },
      update: {
        recordSnapshot: toJsonValue(snapshot),
      },
      create: {
        userId,
        recordId,
        recordSnapshot: toJsonValue(snapshot),
      },
    });
  }

  async unfavoriteRecord(userId: string, recordId: string): Promise<void> {
    await this.prisma.favorite.deleteMany({
      where: { userId, recordId },
    });
  }

  async getFavoritedRecordIds(userId: string): Promise<FavoriteRecordRow[]> {
    const rows = await this.prisma.favorite.findMany({
      where: { userId, recordId: { not: null } },
      orderBy: { createdAt: 'desc' },
      select: { recordId: true, recordSnapshot: true },
    });

    return rows.map((row) => ({
      recordId: row.recordId as string,
      recordSnapshot: row.recordSnapshot,
    }));
  }
}
