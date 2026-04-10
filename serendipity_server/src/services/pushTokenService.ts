import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import {
  AnniversaryReminderCandidate,
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
import {
  buildCheckInReminderContent,
  calculateMaxConsecutiveDays,
  calculateReminderConsecutiveDays,
} from './checkInReminderContentBuilder';
import {
  AnniversaryReminderTestPayload,
  ReminderDispatchSource,
  ReminderDispatchType,
} from '../types/pushToken.dto';
import { logger } from '../utils/logger';

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
  dispatchType: ReminderDispatchType;
  dispatchSource: ReminderDispatchSource;
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
  dispatchAnniversaryReminderNotifications(timezones?: string[], now?: Date): Promise<ReminderDispatchSummary>;
  dispatchReminderNotificationsForUser(
    userId: string,
    now?: Date,
    overridePayload?: AnniversaryReminderTestPayload,
  ): Promise<ReminderDispatchSummary>;
}

interface DispatchExecutionOptions {
  persistDispatch: boolean;
  dispatchSource: ReminderDispatchSource;
  dispatchType: ReminderDispatchType;
}

interface AnniversaryDispatchExecutionContext {
  pushTokenId: string;
  recordId: string;
  reminderDate: Date;
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

  async getReminderDispatchCandidates(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<ReminderDispatchCandidate[]> {
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
    return this.dispatchReminderNotificationsForCandidates(candidates, undefined, {
      persistDispatch: true,
      dispatchSource: 'scheduler',
      dispatchType: 'check_in',
    });
  }

  async dispatchAnniversaryReminderNotifications(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<ReminderDispatchSummary> {
    this.validateNow(now);
    const targetTimezones = this.normalizeTimezones(timezones);
    const repositoryCandidates = await this.pushTokenRepository.findAnniversaryReminderCandidates(
      targetTimezones,
      now,
    );
    if (repositoryCandidates.length === 0) {
      return {
        dispatchType: 'anniversary',
        dispatchSource: 'scheduler',
        scannedCandidates: 0,
        sentCount: 0,
        failedCount: 0,
        executions: [],
      };
    }

    const candidates = repositoryCandidates.filter((candidate) =>
      this.shouldDispatchAnniversaryReminder(candidate, now),
    );

    return this.dispatchAnniversaryReminderCandidates(candidates, {
      persistDispatch: true,
      dispatchSource: 'scheduler',
      dispatchType: 'anniversary',
    });
  }

  async dispatchReminderNotificationsForUser(
    userId: string,
    now: Date = new Date(),
    overridePayload?: AnniversaryReminderTestPayload,
  ): Promise<ReminderDispatchSummary> {
    await this.ensureUserExists(userId);
    this.validateNow(now);

    const repositoryCandidates = await this.pushTokenRepository.findActiveByUserId(userId);
    if (repositoryCandidates.length === 0) {
      const emptySummary: ReminderDispatchSummary = {
        dispatchType: overridePayload == null ? 'check_in' : 'anniversary',
        dispatchSource: 'manual_test',
        scannedCandidates: 0,
        sentCount: 0,
        failedCount: 0,
        executions: [],
      };
      this.logDispatchSummary(userId, emptySummary);
      return emptySummary;
    }

    const candidates = repositoryCandidates.map((pushToken) => ({
      userId,
      pushTokenId: pushToken.id,
      token: pushToken.token,
      platform: pushToken.platform,
      timezone: pushToken.timezone,
      reminderDate: now,
      reminderTime: 'manual_test',
    }));

    return this.dispatchReminderNotificationsForCandidates(candidates, overridePayload, {
      persistDispatch: false,
      dispatchSource: 'manual_test',
      dispatchType: overridePayload == null ? 'check_in' : 'anniversary',
    });
  }

  private async dispatchReminderNotificationsForCandidates(
    candidates: ReminderDispatchCandidate[],
    overridePayload: AnniversaryReminderTestPayload | undefined,
    options: DispatchExecutionOptions,
  ): Promise<ReminderDispatchSummary> {
    const executions: ReminderDispatchExecution[] = [];

    for (const candidate of candidates) {
      const payload = overridePayload != null
        ? this.buildOverrideReminderPayload(candidate, overridePayload)
        : await this.buildReminderPayload(candidate);
      const sendResult = await this.reminderPushSender.send(payload);
      const execution = await this.finalizeCheckInDispatch(candidate, sendResult, options);
      executions.push(execution);
    }

    return this.buildDispatchSummary(candidates.length, executions, options);
  }

  private async dispatchAnniversaryReminderCandidates(
    candidates: AnniversaryReminderCandidate[],
    options: DispatchExecutionOptions,
  ): Promise<ReminderDispatchSummary> {
    const executions: ReminderDispatchExecution[] = [];

    for (const candidate of candidates) {
      const reminderDate = this.getCurrentDateInTimezone(candidate.timezone, candidate.reminderDate);
      const alreadyDispatched = await this.pushTokenRepository.hasAnniversaryReminderDispatch(
        candidate.pushTokenId,
        candidate.record.id,
        reminderDate,
      );
      if (alreadyDispatched) {
        continue;
      }

      await this.pushTokenRepository.createAnniversaryReminderDispatch({
        userId: candidate.userId,
        pushTokenId: candidate.pushTokenId,
        recordId: candidate.record.id,
        reminderDate,
        status: ReminderDispatchStatus.Pending,
        provider: this.getProviderByPlatform(candidate.platform),
      });

      const sendResult = await this.reminderPushSender.send(
        this.buildAnniversaryReminderPayload(candidate, reminderDate),
      );
      const execution = await this.finalizeAnniversaryDispatch(
        {
          userId: candidate.userId,
          pushTokenId: candidate.pushTokenId,
          token: candidate.token,
          platform: candidate.platform,
          timezone: candidate.timezone,
          reminderDate,
          reminderTime: 'anniversary',
        },
        sendResult,
        {
          pushTokenId: candidate.pushTokenId,
          recordId: candidate.record.id,
          reminderDate,
        },
        options,
      );
      executions.push(execution);
    }

    return this.buildDispatchSummary(candidates.length, executions, options);
  }

  private buildDispatchSummary(
    scannedCandidates: number,
    executions: ReminderDispatchExecution[],
    options: DispatchExecutionOptions,
  ): ReminderDispatchSummary {
    const summary: ReminderDispatchSummary = {
      dispatchType: options.dispatchType,
      dispatchSource: options.dispatchSource,
      scannedCandidates,
      sentCount: executions.filter((execution) => execution.status === ReminderDispatchStatus.Sent).length,
      failedCount: executions.filter((execution) => execution.status === ReminderDispatchStatus.Failed).length,
      executions,
    };
    this.logDispatchSummary(executions[0]?.userId, summary);
    return summary;
  }

  private buildAnniversaryReminderPayload(
    candidate: AnniversaryReminderCandidate,
    reminderDate: Date,
  ): ReminderSendPayload {
    return {
      token: candidate.token,
      platform: candidate.platform,
      title: '今天是一个特别的纪念日 🌸',
      body: this.buildAnniversaryReminderBody(candidate.record.timestamp, reminderDate),
      data: {
        type: 'anniversary_reminder',
        userId: candidate.userId,
        reminderDate: reminderDate.toISOString(),
        recordId: candidate.record.id,
      },
    };
  }

  private buildAnniversaryReminderBody(timestamp: Date, reminderDate: Date): string {
    const years = Math.max(reminderDate.getUTCFullYear() - timestamp.getUTCFullYear(), 1);
    return `${years}年前的今天，你在某个地方邂逅了TA`;
  }

  private shouldDispatchAnniversaryReminder(
    candidate: AnniversaryReminderCandidate,
    now: Date,
  ): boolean {
    const localizedNow = this.getLocalizedNow(now, candidate.timezone);
    const localizedTimestamp = this.getLocalizedNow(candidate.record.timestamp, candidate.timezone);

    return localizedTimestamp.getUTCMonth() === localizedNow.getUTCMonth()
      && localizedTimestamp.getUTCDate() === localizedNow.getUTCDate();
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

  private async finalizeCheckInDispatch(
    candidate: ReminderDispatchCandidate,
    sendResult: ReminderSendResult,
    options: DispatchExecutionOptions,
  ): Promise<ReminderDispatchExecution> {
    if (sendResult.success) {
      if (options.persistDispatch) {
        await this.pushTokenRepository.markReminderDispatchSent(
          candidate.pushTokenId,
          candidate.reminderDate,
          new Date(),
        );
      }
      return {
        ...candidate,
        status: ReminderDispatchStatus.Sent,
      };
    }

    const failureReason = sendResult.failureReason?.trim() || 'push_send_failed';
    if (options.persistDispatch) {
    await this.pushTokenRepository.markReminderDispatchFailed(
      candidate.pushTokenId,
      candidate.reminderDate,
      failureReason,
    );
    }

    if (sendResult.isInvalidToken) {
      await this.pushTokenRepository.markInvalid(candidate.token, failureReason);
    }

    return {
      ...candidate,
      status: ReminderDispatchStatus.Failed,
      failureReason,
    };
  }

  private async finalizeAnniversaryDispatch(
    candidate: ReminderDispatchCandidate,
    sendResult: ReminderSendResult,
    context: AnniversaryDispatchExecutionContext,
    options: DispatchExecutionOptions,
  ): Promise<ReminderDispatchExecution> {
    if (sendResult.success) {
      if (options.persistDispatch) {
        await this.pushTokenRepository.markAnniversaryReminderDispatchSent(
          context.pushTokenId,
          context.recordId,
          context.reminderDate,
          new Date(),
        );
      }
      return {
        ...candidate,
        status: ReminderDispatchStatus.Sent,
      };
    }

    const failureReason = sendResult.failureReason?.trim() || 'push_send_failed';
    if (options.persistDispatch) {
      await this.pushTokenRepository.markAnniversaryReminderDispatchFailed(
        context.pushTokenId,
        context.recordId,
        context.reminderDate,
        failureReason,
      );
    }

    if (sendResult.isInvalidToken) {
      await this.pushTokenRepository.markInvalid(candidate.token, failureReason);
    }

    return {
      ...candidate,
      status: ReminderDispatchStatus.Failed,
      failureReason,
    };
  }

  private buildOverrideReminderPayload(
    candidate: ReminderDispatchCandidate,
    overridePayload: AnniversaryReminderTestPayload,
  ): ReminderSendPayload {
    if (overridePayload.title.trim() === '') {
      throw new Error('Reminder title is required');
    }
    if (overridePayload.body.trim() === '') {
      throw new Error('Reminder body is required');
    }

    return {
      token: candidate.token,
      platform: candidate.platform,
      title: overridePayload.title,
      body: overridePayload.body,
      data: {
        type: 'anniversary_reminder_test',
        userId: candidate.userId,
        reminderDate: candidate.reminderDate.toISOString(),
      },
    };
  }

  private async buildReminderPayload(candidate: ReminderDispatchCandidate): Promise<ReminderSendPayload> {
    const consecutiveDays = await this.getConsecutiveDays(candidate.userId, candidate.reminderDate);
    const maxConsecutiveDays = await this.getMaxConsecutiveDays(candidate.userId);
    const content = buildCheckInReminderContent({
      consecutiveDays,
      maxConsecutiveDays,
    });

    return {
      token: candidate.token,
      platform: candidate.platform,
      title: content.title,
      body: content.body,
      data: {
        type: 'check_in_reminder',
        userId: candidate.userId,
        reminderDate: candidate.reminderDate.toISOString(),
      },
    };
  }

  private async getConsecutiveDays(userId: string, reminderDate: Date): Promise<number> {
    const checkIns = await this.checkInRepository.findByUserId(userId);
    return calculateReminderConsecutiveDays(
      checkIns.map((checkIn) => checkIn.date),
      reminderDate,
    );
  }

  private async getMaxConsecutiveDays(userId: string): Promise<number> {
    const checkIns = await this.checkInRepository.findByUserId(userId);
    return calculateMaxConsecutiveDays(checkIns.map((checkIn) => checkIn.date));
  }

  private parseReminderTime(reminderTime: string): ReminderClock {
    const match = reminderTime.match(/^(\d{2}):(\d{2})$/);
    if (!match) {
      throw new AppError('invalid reminder time format', ErrorCode.INVALID_REQUEST);
    }

    const hour = Number(match[1]);
    const minute = Number(match[2]);
    if (hour < 0 || hour >= HOURS_PER_DAY || minute < 0 || minute >= MINUTES_PER_HOUR) {
      throw new AppError('invalid reminder time value', ErrorCode.INVALID_REQUEST);
    }

    return { hour, minute };
  }

  private isWithinReminderWindow(now: Date, timezone: string, reminderClock: ReminderClock): boolean {
    const localizedNow = this.getLocalizedNow(now, timezone);
    const reminderMinutes = reminderClock.hour * MINUTES_PER_HOUR + reminderClock.minute;
    const nowMinutes = localizedNow.getHours() * MINUTES_PER_HOUR + localizedNow.getMinutes();
    const diffMinutes = Math.abs(nowMinutes - reminderMinutes);
    return diffMinutes <= DEFAULT_TIME_WINDOW_MINUTES;
  }

  private getLocalizedNow(now: Date, timezone: string): Date {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    });

    const parts = formatter.formatToParts(now);
    const getPart = (type: string): string => {
      const value = parts.find((part) => part.type === type)?.value;
      if (!value) {
        throw new AppError('invalid timezone conversion result', ErrorCode.INTERNAL_ERROR);
      }
      return value;
    };

    const year = Number(getPart('year'));
    const month = Number(getPart('month'));
    const day = Number(getPart('day'));
    const hour = Number(getPart('hour'));
    const minute = Number(getPart('minute'));
    const second = Number(getPart('second'));

    return new Date(Date.UTC(year, month - 1, day, hour, minute, second));
  }

  private getCurrentDateInTimezone(timezone: string, now: Date): Date {
    const localizedNow = this.getLocalizedNow(now, timezone);
    return new Date(Date.UTC(
      localizedNow.getUTCFullYear(),
      localizedNow.getUTCMonth(),
      localizedNow.getUTCDate(),
      0,
      0,
      0,
      0,
    ));
  }

  private normalizeTimezones(timezones?: string[]): string[] | undefined {
    if (timezones === undefined) {
      return undefined;
    }
    if (!Array.isArray(timezones)) {
      throw new AppError('timezones must be an array', ErrorCode.INVALID_REQUEST);
    }

    const trimmed = timezones.map((timezone) => {
      if (typeof timezone !== 'string') {
        throw new AppError('timezone must be a string', ErrorCode.INVALID_REQUEST);
      }
      return timezone.trim();
    });

    const invalid = trimmed.find((timezone) => timezone === '');
    if (invalid !== undefined) {
      throw new AppError('timezone is required', ErrorCode.INVALID_REQUEST);
    }

    return trimmed;
  }

  private validateRegisterData(data: RegisterPushTokenData): void {
    if (!data.token || data.token.trim() === '') {
      throw new AppError('push token is required', ErrorCode.INVALID_REQUEST);
    }
    if (!data.platform || data.platform.trim() === '') {
      throw new AppError('platform is required', ErrorCode.INVALID_REQUEST);
    }
    if (!data.timezone || data.timezone.trim() === '') {
      throw new AppError('timezone is required', ErrorCode.INVALID_REQUEST);
    }
  }

  private validateNow(now: Date): void {
    if (!(now instanceof Date) || Number.isNaN(now.getTime())) {
      throw new AppError('invalid now parameter', ErrorCode.INVALID_REQUEST);
    }
  }

  private getProviderByPlatform(platform: string): string {
    switch (platform) {
      case 'ios':
        return 'apns';
      case 'android':
      default:
        return 'fcm';
    }
  }

  private async ensureUserExists(userId: string): Promise<void> {
    if (!userId || userId.trim() === '') {
      throw new AppError('user id is required', ErrorCode.INVALID_REQUEST);
    }

    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new AppError('user not found', ErrorCode.USER_NOT_FOUND);
    }
  }

  private logDispatchSummary(userId: string | undefined, summary: ReminderDispatchSummary): void {
    const failureReasons = summary.executions
      .filter((execution) => execution.failureReason != null)
      .reduce<Record<string, number>>((acc, execution) => {
        const key = execution.failureReason!;
        acc[key] = (acc[key] ?? 0) + 1;
        return acc;
      }, {});

    logger.info('Reminder dispatch summary', {
      userId,
      dispatchType: summary.dispatchType,
      dispatchSource: summary.dispatchSource,
      scannedCandidates: summary.scannedCandidates,
      sentCount: summary.sentCount,
      failedCount: summary.failedCount,
      failureReasons,
    });
  }
}
