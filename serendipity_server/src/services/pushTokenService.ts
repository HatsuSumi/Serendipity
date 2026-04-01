import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import {
  IPushTokenRepository,
  RegisterPushTokenData,
  ReminderCandidate,
} from '../repositories/pushTokenRepository';
import {
  IReminderPushSender,
  ReminderDispatchStatus,
  ReminderSendPayload,
  ReminderSendResult,
} from './reminderPushSender';
import { ICheckInRepository } from '../repositories/checkInRepository';
import { IUserRepository } from '../repositories/userRepository';
import { PushToken } from '@prisma/client';
import { config } from '../config';

const DEFAULT_TIME_WINDOW_MINUTES = 1;
const HOURS_PER_DAY = 24;
const MINUTES_PER_HOUR = 60;

interface ReminderClock {
  hour: number;
  minute: number;
}

export interface ReminderDispatchCandidate {
  userId: string;
  pushTokenId: string;
  token: string;
  platform: string;
  timezone: string;
  reminderDate: Date;
  reminderTime: string;
}

export interface ReminderDispatchExecution {
  userId: string;
  pushTokenId: string;
  token: string;
  platform: string;
  timezone: string;
  reminderDate: Date;
  reminderTime: string;
  status: ReminderDispatchStatus;
  failureReason?: string;
}

export interface ReminderDispatchSummary {
  scannedCandidates: number;
  sentCount: number;
  failedCount: number;
  executions: ReminderDispatchExecution[];
}

export interface IPushTokenService {
  registerPushToken(userId: string, data: RegisterPushTokenData): Promise<PushToken>;
  unregisterPushToken(userId: string, token: string): Promise<void>;
  markPushTokenInvalid(token: string, reason: string): Promise<void>;
  listPushTokens(userId: string): Promise<PushToken[]>;
  getReminderDispatchCandidates(timezones?: string[], now?: Date): Promise<ReminderDispatchCandidate[]>;
  dispatchReminderNotifications(timezones?: string[], now?: Date): Promise<ReminderDispatchSummary>;
}

export class PushTokenService implements IPushTokenService {
  constructor(
    private pushTokenRepository: IPushTokenRepository,
    private checkInRepository: ICheckInRepository,
    private userRepository: IUserRepository,
    private reminderPushSender: IReminderPushSender,
  ) {
    if (!pushTokenRepository) {
      throw new Error('PushTokenRepository is required');
    }
    if (!checkInRepository) {
      throw new Error('CheckInRepository is required');
    }
    if (!userRepository) {
      throw new Error('UserRepository is required');
    }
    if (!reminderPushSender) {
      throw new Error('ReminderPushSender is required');
    }
  }

  async registerPushToken(userId: string, data: RegisterPushTokenData): Promise<PushToken> {
    await this.ensureUserExists(userId);
    this.validateRegisterData(data);
    return this.pushTokenRepository.register(userId, data);
  }

  async unregisterPushToken(userId: string, token: string): Promise<void> {
    await this.ensureUserExists(userId);
    if (!token || token.trim() === '') {
      throw new AppError('push token is required', ErrorCode.INVALID_REQUEST);
    }

    await this.pushTokenRepository.deactivateByToken(userId, token);
  }

  async markPushTokenInvalid(token: string, reason: string): Promise<void> {
    if (!token || token.trim() === '') {
      throw new AppError('push token is required', ErrorCode.INVALID_REQUEST);
    }
    if (!reason || reason.trim() === '') {
      throw new AppError('invalid reason is required', ErrorCode.INVALID_REQUEST);
    }

    await this.pushTokenRepository.markInvalid(token, reason);
  }

  async listPushTokens(userId: string): Promise<PushToken[]> {
    await this.ensureUserExists(userId);
    return this.pushTokenRepository.findActiveByUserId(userId);
  }

  async getReminderDispatchCandidates(timezones?: string[], now: Date = new Date()): Promise<ReminderDispatchCandidate[]> {
    this.validateNow(now);
    const targetTimezones = this.normalizeTimezones(timezones);
    const repositoryCandidates = await this.pushTokenRepository.findReminderCandidates(targetTimezones);
    if (repositoryCandidates.length === 0) {
      return [];
    }

    const candidates: ReminderDispatchCandidate[] = [];
    for (const repositoryCandidate of repositoryCandidates) {
      const candidate = await this.buildReminderCandidate(repositoryCandidate, now);
      if (candidate) {
        candidates.push(candidate);
      }
    }

    return candidates;
  }

  async dispatchReminderNotifications(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<ReminderDispatchSummary> {
    const candidates = await this.getReminderDispatchCandidates(timezones, now);
    const executions: ReminderDispatchExecution[] = [];

    for (const candidate of candidates) {
      const sendResult = await this.reminderPushSender.send(this.buildReminderPayload(candidate));
      const execution = await this.finalizeDispatch(candidate, sendResult);
      executions.push(execution);
    }

    return {
      scannedCandidates: candidates.length,
      sentCount: executions.filter((execution) => execution.status === ReminderDispatchStatus.Sent).length,
      failedCount: executions.filter((execution) => execution.status === ReminderDispatchStatus.Failed).length,
      executions,
    };
  }

  private async buildReminderCandidate(
    candidate: ReminderCandidate,
    now: Date,
  ): Promise<ReminderDispatchCandidate | null> {
    const reminderClock = this.parseReminderTime(candidate.reminderTime);
    if (!this.isWithinReminderWindow(now, candidate.timezone, reminderClock)) {
      return null;
    }

    const reminderDate = this.getCurrentDateInTimezone(candidate.timezone, now);
    const alreadyDispatched = await this.pushTokenRepository.hasReminderDispatch(
      candidate.pushTokenId,
      reminderDate,
    );
    if (alreadyDispatched) {
      return null;
    }

    const alreadyCheckedIn = await this.checkInRepository.findByUserAndDate(
      candidate.userId,
      reminderDate,
    );
    if (alreadyCheckedIn) {
      return null;
    }

    await this.pushTokenRepository.createReminderDispatch({
      userId: candidate.userId,
      pushTokenId: candidate.pushTokenId,
      reminderDate,
      status: ReminderDispatchStatus.Pending,
      provider: this.getProviderByPlatform(candidate.platform),
    });

    return {
      userId: candidate.userId,
      pushTokenId: candidate.pushTokenId,
      token: candidate.token,
      platform: candidate.platform,
      timezone: candidate.timezone,
      reminderDate,
      reminderTime: candidate.reminderTime,
    };
  }

  private async finalizeDispatch(
    candidate: ReminderDispatchCandidate,
    sendResult: ReminderSendResult,
  ): Promise<ReminderDispatchExecution> {
    if (sendResult.success) {
      await this.pushTokenRepository.markReminderDispatchSent(candidate.pushTokenId, candidate.reminderDate, new Date());
      return {
        ...candidate,
        status: ReminderDispatchStatus.Sent,
      };
    }

    const failureReason = sendResult.failureReason?.trim() || 'push_send_failed';
    await this.pushTokenRepository.markReminderDispatchFailed(
      candidate.pushTokenId,
      candidate.reminderDate,
      failureReason,
    );

    if (sendResult.isInvalidToken) {
      await this.pushTokenRepository.markInvalid(candidate.token, failureReason);
    }

    return {
      ...candidate,
      status: ReminderDispatchStatus.Failed,
      failureReason,
    };
  }

  private buildReminderPayload(candidate: ReminderDispatchCandidate): ReminderSendPayload {
    return {
      token: candidate.token,
      platform: candidate.platform,
      title: config.checkInReminder.notificationTitle,
      body: config.checkInReminder.notificationBody,
      data: {
        type: 'check_in_reminder',
        userId: candidate.userId,
        reminderDate: candidate.reminderDate.toISOString(),
        reminderTime: candidate.reminderTime,
      },
    };
  }

  private async ensureUserExists(userId: string): Promise<void> {
    if (!userId || userId.trim() === '') {
      throw new AppError('userId is required', ErrorCode.INVALID_REQUEST);
    }

    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new AppError('User not found', ErrorCode.USER_NOT_FOUND);
    }
  }

  private validateRegisterData(data: RegisterPushTokenData): void {
    if (!data.token || data.token.trim() === '') {
      throw new AppError('push token is required', ErrorCode.INVALID_REQUEST);
    }
    if (!data.platform || data.platform.trim() === '') {
      throw new AppError('platform is required', ErrorCode.INVALID_REQUEST);
    }
    if (data.platform !== 'android' && data.platform !== 'ios') {
      throw new AppError('platform must be android or ios', ErrorCode.INVALID_REQUEST);
    }
    if (!data.timezone || data.timezone.trim() === '') {
      throw new AppError('timezone is required', ErrorCode.INVALID_REQUEST);
    }

    this.assertValidTimezone(data.timezone);
  }

  private validateNow(now: Date): void {
    if (!(now instanceof Date) || Number.isNaN(now.getTime())) {
      throw new Error('Invalid current time');
    }
  }

  private normalizeTimezones(timezones?: string[]): string[] | undefined {
    if (!timezones) {
      return undefined;
    }

    const normalized = Array.from(
      new Set(
        timezones
          .map((timezone) => timezone.trim())
          .filter((timezone) => timezone.length > 0),
      ),
    );

    normalized.forEach((timezone) => this.assertValidTimezone(timezone));

    return normalized.length > 0 ? normalized : undefined;
  }

  private assertValidTimezone(timezone: string): void {
    try {
      Intl.DateTimeFormat(undefined, { timeZone: timezone });
    } catch {
      throw new AppError('timezone is invalid', ErrorCode.INVALID_REQUEST);
    }
  }

  private parseReminderTime(reminderTime: string): ReminderClock {
    if (!/^\d{2}:\d{2}$/.test(reminderTime)) {
      throw new Error(`Invalid reminder time: ${reminderTime}`);
    }

    const [hourString, minuteString] = reminderTime.split(':');
    const hour = Number(hourString);
    const minute = Number(minuteString);
    if (!Number.isInteger(hour) || hour < 0 || hour >= HOURS_PER_DAY) {
      throw new Error(`Invalid reminder hour: ${reminderTime}`);
    }
    if (!Number.isInteger(minute) || minute < 0 || minute >= MINUTES_PER_HOUR) {
      throw new Error(`Invalid reminder minute: ${reminderTime}`);
    }

    return { hour, minute };
  }

  private isWithinReminderWindow(now: Date, timezone: string, reminderClock: ReminderClock): boolean {
    const currentMinutes = this.getMinutesInDayForTimezone(now, timezone);
    const reminderMinutes = reminderClock.hour * MINUTES_PER_HOUR + reminderClock.minute;
    const minuteDifference = currentMinutes - reminderMinutes;

    return minuteDifference >= 0 && minuteDifference < DEFAULT_TIME_WINDOW_MINUTES;
  }

  private getMinutesInDayForTimezone(now: Date, timezone: string): number {
    const formatter = new Intl.DateTimeFormat('en-GB', {
      timeZone: timezone,
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
    });
    const parts = formatter.formatToParts(now);
    const hour = Number(parts.find((part) => part.type === 'hour')?.value);
    const minute = Number(parts.find((part) => part.type === 'minute')?.value);
    if (!Number.isInteger(hour) || hour < 0 || hour >= HOURS_PER_DAY) {
      throw new Error(`Invalid timezone hour for ${timezone}`);
    }
    if (!Number.isInteger(minute) || minute < 0 || minute >= MINUTES_PER_HOUR) {
      throw new Error(`Invalid timezone minute for ${timezone}`);
    }

    return hour * MINUTES_PER_HOUR + minute;
  }

  private getCurrentDateInTimezone(timezone: string, now: Date): Date {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    const parts = formatter.formatToParts(now);
    const year = Number(parts.find((part) => part.type === 'year')?.value);
    const month = Number(parts.find((part) => part.type === 'month')?.value);
    const day = Number(parts.find((part) => part.type === 'day')?.value);
    if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
      throw new Error(`Invalid timezone date for ${timezone}`);
    }

    return new Date(Date.UTC(year, month - 1, day));
  }

  private getProviderByPlatform(platform: string): string {
    return platform === 'ios' ? 'apns' : 'fcm';
  }
}
