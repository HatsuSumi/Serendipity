import {
  PrismaClient,
  AnniversaryReminderDispatch,
  CheckInReminderDispatch,
  PushToken,
} from '@prisma/client';
import { ReminderDispatchStatus } from '../services/reminderPushSender';

export interface RegisterPushTokenData {
  token: string;
  platform: string;
  timezone: string;
}

export interface CreateReminderDispatchData {
  userId: string;
  pushTokenId: string;
  reminderDate: Date;
  status: string;
  provider: string;
  failureReason?: string;
  sentAt?: Date;
}

export interface CreateAnniversaryReminderDispatchData {
  userId: string;
  pushTokenId: string;
  recordId: string;
  reminderDate: Date;
  status: string;
  provider: string;
  failureReason?: string;
  sentAt?: Date;
}

export interface ReminderCandidate {
  userId: string;
  pushTokenId: string;
  token: string;
  platform: string;
  timezone: string;
  reminderTime: string;
}

interface ReminderNotificationsConfig {
  checkInReminderTime?: string;
}

interface AnniversaryReminderRecord {
  id: string;
  timestamp: Date;
}

export interface AnniversaryReminderCandidate {
  userId: string;
  pushTokenId: string;
  token: string;
  platform: string;
  timezone: string;
  reminderDate: Date;
  record: AnniversaryReminderRecord;
}

export interface IPushTokenRepository {
  register(userId: string, data: RegisterPushTokenData): Promise<PushToken>;
  deactivateByToken(userId: string, token: string): Promise<void>;
  markInvalid(token: string, reason: string): Promise<void>;
  findActiveByUserId(userId: string): Promise<PushToken[]>;
  findLatestActiveTimezoneByUserId(userId: string): Promise<string | undefined>;
  findReminderCandidates(timezones?: string[]): Promise<ReminderCandidate[]>;
  findAnniversaryReminderCandidates(timezones?: string[], now?: Date): Promise<AnniversaryReminderCandidate[]>;
  hasReminderDispatch(pushTokenId: string, reminderDate: Date): Promise<boolean>;
  hasAnniversaryReminderDispatch(pushTokenId: string, recordId: string, reminderDate: Date): Promise<boolean>;
  createReminderDispatch(data: CreateReminderDispatchData): Promise<CheckInReminderDispatch>;
  createAnniversaryReminderDispatch(data: CreateAnniversaryReminderDispatchData): Promise<AnniversaryReminderDispatch>;
  markReminderDispatchSent(pushTokenId: string, reminderDate: Date, sentAt: Date): Promise<void>;
  markReminderDispatchFailed(pushTokenId: string, reminderDate: Date, failureReason: string): Promise<void>;
  markAnniversaryReminderDispatchSent(
    pushTokenId: string,
    recordId: string,
    reminderDate: Date,
    sentAt: Date,
  ): Promise<void>;
  markAnniversaryReminderDispatchFailed(
    pushTokenId: string,
    recordId: string,
    reminderDate: Date,
    failureReason: string,
  ): Promise<void>;
}

export class PushTokenRepository implements IPushTokenRepository {
  constructor(private prisma: PrismaClient) {
    if (!prisma) {
      throw new Error('PrismaClient is required');
    }
  }

  async register(userId: string, data: RegisterPushTokenData): Promise<PushToken> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!data.token || data.token.trim() === '') {
      throw new Error('token is required');
    }
    if (!data.platform || data.platform.trim() === '') {
      throw new Error('platform is required');
    }
    if (!data.timezone || data.timezone.trim() === '') {
      throw new Error('timezone is required');
    }

    return this.prisma.pushToken.upsert({
      where: { token: data.token },
      update: {
        userId,
        platform: data.platform,
        timezone: data.timezone,
        isActive: true,
        invalidatedAt: null,
        invalidReason: null,
        lastUsedAt: new Date(),
      },
      create: {
        userId,
        token: data.token,
        platform: data.platform,
        timezone: data.timezone,
        isActive: true,
        lastUsedAt: new Date(),
      },
    });
  }

  async deactivateByToken(userId: string, token: string): Promise<void> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!token || token.trim() === '') {
      throw new Error('token is required');
    }

    await this.prisma.pushToken.updateMany({
      where: {
        userId,
        token,
        isActive: true,
      },
      data: {
        isActive: false,
        invalidatedAt: new Date(),
        invalidReason: 'client_unregistered',
      },
    });
  }

  async markInvalid(token: string, reason: string): Promise<void> {
    if (!token || token.trim() === '') {
      throw new Error('token is required');
    }
    if (!reason || reason.trim() === '') {
      throw new Error('reason is required');
    }

    await this.prisma.pushToken.updateMany({
      where: { token },
      data: {
        isActive: false,
        invalidatedAt: new Date(),
        invalidReason: reason,
      },
    });
  }

  async findActiveByUserId(userId: string): Promise<PushToken[]> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    return this.prisma.pushToken.findMany({
      where: {
        userId,
        isActive: true,
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async findLatestActiveTimezoneByUserId(userId: string): Promise<string | undefined> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    const latestPushToken = await this.prisma.pushToken.findFirst({
      where: {
        userId,
        isActive: true,
      },
      select: {
        timezone: true,
      },
      orderBy: [
        { lastUsedAt: 'desc' },
        { updatedAt: 'desc' },
      ],
    });

    return latestPushToken?.timezone;
  }

  async findReminderCandidates(timezones?: string[]): Promise<ReminderCandidate[]> {
    if (timezones && timezones.length === 0) {
      return [];
    }

    const timezoneFilter = timezones
      ? {
          timezone: {
            in: timezones,
          },
        }
      : {};

    const settings = await this.prisma.userSettings.findMany({
      where: {
        notifications: {
          path: ['checkInReminder'],
          equals: true,
        },
        user: {
          pushTokens: {
            some: {
              isActive: true,
              ...timezoneFilter,
            },
          },
        },
      },
      select: {
        userId: true,
        notifications: true,
        user: {
          select: {
            pushTokens: {
              where: {
                isActive: true,
                ...timezoneFilter,
              },
              select: {
                id: true,
                token: true,
                platform: true,
                timezone: true,
              },
            },
          },
        },
      },
    });

    return settings.flatMap((setting) => {
      const notifications = setting.notifications as ReminderNotificationsConfig;
      const reminderTime = notifications.checkInReminderTime;
      if (!reminderTime) {
        return [];
      }

      return setting.user.pushTokens.map((pushToken) => ({
        userId: setting.userId,
        pushTokenId: pushToken.id,
        token: pushToken.token,
        platform: pushToken.platform,
        timezone: pushToken.timezone,
        reminderTime,
      }));
    });
  }

  async findAnniversaryReminderCandidates(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<AnniversaryReminderCandidate[]> {
    if (timezones && timezones.length === 0) {
      return [];
    }

    const timezoneFilter = timezones
      ? {
          timezone: {
            in: timezones,
          },
        }
      : {};

    const settings = await this.prisma.userSettings.findMany({
      where: {
        notifications: {
          path: ['anniversaryReminder'],
          equals: true,
        },
        user: {
          membership: {
            is: {
              status: 'active',
              OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
            },
          },
          pushTokens: {
            some: {
              isActive: true,
              ...timezoneFilter,
            },
          },
          records: {
            some: {
              status: 'met',
              timestamp: { lt: now },
            },
          },
        },
      },
      select: {
        userId: true,
        user: {
          select: {
            pushTokens: {
              where: {
                isActive: true,
                ...timezoneFilter,
              },
              select: {
                id: true,
                token: true,
                platform: true,
                timezone: true,
              },
            },
            records: {
              where: {
                status: 'met',
                timestamp: { lt: now },
              },
              select: {
                id: true,
                timestamp: true,
              },
              orderBy: { timestamp: 'asc' },
            },
          },
        },
      },
    });

    return settings.flatMap((setting) => {
      if (setting.user.pushTokens.length === 0 || setting.user.records.length === 0) {
        return [];
      }

      return setting.user.pushTokens.flatMap((pushToken) =>
        setting.user.records.map((record) => ({
          userId: setting.userId,
          pushTokenId: pushToken.id,
          token: pushToken.token,
          platform: pushToken.platform,
          timezone: pushToken.timezone,
          reminderDate: now,
          record,
        })),
      );
    });
  }

  async hasReminderDispatch(pushTokenId: string, reminderDate: Date): Promise<boolean> {
    this.validateCheckInDispatchLookup(pushTokenId, reminderDate);

    const existing = await this.prisma.checkInReminderDispatch.findUnique({
      where: {
        pushTokenId_reminderDate: {
          pushTokenId,
          reminderDate,
        },
      },
    });

    return existing !== null;
  }

  async hasAnniversaryReminderDispatch(
    pushTokenId: string,
    recordId: string,
    reminderDate: Date,
  ): Promise<boolean> {
    this.validateAnniversaryDispatchLookup(pushTokenId, recordId, reminderDate);

    const existing = await this.prisma.anniversaryReminderDispatch.findUnique({
      where: {
        pushTokenId_recordId_reminderDate: {
          pushTokenId,
          recordId,
          reminderDate,
        },
      },
    });

    return existing !== null;
  }

  async createReminderDispatch(data: CreateReminderDispatchData): Promise<CheckInReminderDispatch> {
    if (!data.userId || data.userId.trim() === '') {
      throw new Error('userId is required');
    }
    this.validateCheckInDispatchLookup(data.pushTokenId, data.reminderDate);
    if (!data.status || data.status.trim() === '') {
      throw new Error('status is required');
    }
    if (!data.provider || data.provider.trim() === '') {
      throw new Error('provider is required');
    }

    return this.prisma.checkInReminderDispatch.create({
      data: {
        userId: data.userId,
        pushTokenId: data.pushTokenId,
        reminderDate: data.reminderDate,
        status: data.status,
        provider: data.provider,
        failureReason: data.failureReason,
        sentAt: data.sentAt,
      },
    });
  }

  async createAnniversaryReminderDispatch(
    data: CreateAnniversaryReminderDispatchData,
  ): Promise<AnniversaryReminderDispatch> {
    if (!data.userId || data.userId.trim() === '') {
      throw new Error('userId is required');
    }
    this.validateAnniversaryDispatchLookup(data.pushTokenId, data.recordId, data.reminderDate);
    if (!data.status || data.status.trim() === '') {
      throw new Error('status is required');
    }
    if (!data.provider || data.provider.trim() === '') {
      throw new Error('provider is required');
    }

    return this.prisma.anniversaryReminderDispatch.create({
      data: {
        userId: data.userId,
        pushTokenId: data.pushTokenId,
        recordId: data.recordId,
        reminderDate: data.reminderDate,
        status: data.status,
        provider: data.provider,
        failureReason: data.failureReason,
        sentAt: data.sentAt,
      },
    });
  }

  async markReminderDispatchSent(pushTokenId: string, reminderDate: Date, sentAt: Date): Promise<void> {
    this.validateCheckInDispatchLookup(pushTokenId, reminderDate);
    if (!(sentAt instanceof Date) || Number.isNaN(sentAt.getTime())) {
      throw new Error('Invalid sentAt');
    }

    await this.prisma.checkInReminderDispatch.update({
      where: {
        pushTokenId_reminderDate: {
          pushTokenId,
          reminderDate,
        },
      },
      data: {
        status: ReminderDispatchStatus.Sent,
        sentAt,
        failureReason: null,
      },
    });
  }

  async markReminderDispatchFailed(pushTokenId: string, reminderDate: Date, failureReason: string): Promise<void> {
    this.validateCheckInDispatchLookup(pushTokenId, reminderDate);
    if (!failureReason || failureReason.trim() === '') {
      throw new Error('failureReason is required');
    }

    await this.prisma.checkInReminderDispatch.update({
      where: {
        pushTokenId_reminderDate: {
          pushTokenId,
          reminderDate,
        },
      },
      data: {
        status: ReminderDispatchStatus.Failed,
        failureReason,
      },
    });
  }

  async markAnniversaryReminderDispatchSent(
    pushTokenId: string,
    recordId: string,
    reminderDate: Date,
    sentAt: Date,
  ): Promise<void> {
    this.validateAnniversaryDispatchLookup(pushTokenId, recordId, reminderDate);
    if (!(sentAt instanceof Date) || Number.isNaN(sentAt.getTime())) {
      throw new Error('Invalid sentAt');
    }

    await this.prisma.anniversaryReminderDispatch.update({
      where: {
        pushTokenId_recordId_reminderDate: {
          pushTokenId,
          recordId,
          reminderDate,
        },
      },
      data: {
        status: ReminderDispatchStatus.Sent,
        sentAt,
        failureReason: null,
      },
    });
  }

  async markAnniversaryReminderDispatchFailed(
    pushTokenId: string,
    recordId: string,
    reminderDate: Date,
    failureReason: string,
  ): Promise<void> {
    this.validateAnniversaryDispatchLookup(pushTokenId, recordId, reminderDate);
    if (!failureReason || failureReason.trim() === '') {
      throw new Error('failureReason is required');
    }

    await this.prisma.anniversaryReminderDispatch.update({
      where: {
        pushTokenId_recordId_reminderDate: {
          pushTokenId,
          recordId,
          reminderDate,
        },
      },
      data: {
        status: ReminderDispatchStatus.Failed,
        failureReason,
      },
    });
  }

  private validateCheckInDispatchLookup(pushTokenId: string, reminderDate: Date): void {
    if (!pushTokenId || pushTokenId.trim() === '') {
      throw new Error('pushTokenId is required');
    }
    if (!(reminderDate instanceof Date) || Number.isNaN(reminderDate.getTime())) {
      throw new Error('Invalid reminderDate');
    }
  }

  private validateAnniversaryDispatchLookup(
    pushTokenId: string,
    recordId: string,
    reminderDate: Date,
  ): void {
    if (!pushTokenId || pushTokenId.trim() === '') {
      throw new Error('pushTokenId is required');
    }
    if (!recordId || recordId.trim() === '') {
      throw new Error('recordId is required');
    }
    if (!(reminderDate instanceof Date) || Number.isNaN(reminderDate.getTime())) {
      throw new Error('Invalid reminderDate');
    }
  }
}
