import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import {
  ReminderDispatchSource,
  ReminderDispatchType,
} from '../types/pushToken.dto';
import { ReminderDispatchStatus } from './reminderPushSender';
import { config } from '../config';
import { logger } from '../utils/logger';

const DEFAULT_TIME_WINDOW_MINUTES = 1;
const REMINDER_TIME_WINDOW_MINUTES = config.checkInReminder.scanIntervalMs / (1000 * 60);
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

export interface DispatchExecutionOptions {
  persistDispatch: boolean;
  dispatchSource: ReminderDispatchSource;
  dispatchType: ReminderDispatchType;
}

export class PushReminderSchedulingSupport {
  validateNow(now: Date): void {
    if (!(now instanceof Date) || Number.isNaN(now.getTime())) {
      throw new AppError('Invalid current time', ErrorCode.INVALID_REQUEST);
    }
  }

  normalizeTimezones(timezones?: string[]): string[] | undefined {
    if (timezones === undefined) {
      return undefined;
    }
    if (!Array.isArray(timezones)) {
      throw new AppError('timezones must be an array', ErrorCode.INVALID_REQUEST);
    }

    const normalized = timezones.flatMap((timezone) => {
      if (typeof timezone !== 'string') {
        throw new AppError('timezone must be a string', ErrorCode.INVALID_REQUEST);
      }

      const trimmedTimezone = timezone.trim();
      if (trimmedTimezone !== '') {
        this.assertValidTimezone(trimmedTimezone);
      }

      return trimmedTimezone === '' ? [] : [trimmedTimezone];
    });

    return normalized.length === 0 ? undefined : normalized;
  }

  parseReminderTime(reminderTime: string): { hour: number; minute: number } {
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

  isWithinReminderWindow(now: Date, timezone: string, reminderClock: ReminderClock): boolean {
    const localizedNow = this.getLocalizedNow(now, timezone);
    const reminderMinutes = reminderClock.hour * MINUTES_PER_HOUR + reminderClock.minute;
    const nowMinutes = localizedNow.getUTCHours() * MINUTES_PER_HOUR + localizedNow.getUTCMinutes();
    const diffMinutes = Math.abs(nowMinutes - reminderMinutes);
    return diffMinutes < this.getReminderWindowMinutes();
  }

  getCurrentDateInTimezone(timezone: string, now: Date): Date {
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

  getLocalizedNow(now: Date, timezone: string): Date {
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

  getProviderByPlatform(platform: string): string {
    switch (platform) {
      case 'ios':
        return 'apns';
      case 'android':
      default:
        return 'fcm';
    }
  }

  buildDispatchSummary(
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

  createEmptyDispatchSummary(
    options: DispatchExecutionOptions,
    userId?: string,
  ): ReminderDispatchSummary {
    const summary: ReminderDispatchSummary = {
      dispatchType: options.dispatchType,
      dispatchSource: options.dispatchSource,
      scannedCandidates: 0,
      sentCount: 0,
      failedCount: 0,
      executions: [],
    };
    this.logDispatchSummary(userId, summary);
    return summary;
  }

  private getReminderWindowMinutes(): number {
    return Number.isFinite(REMINDER_TIME_WINDOW_MINUTES) && REMINDER_TIME_WINDOW_MINUTES > 0
      ? REMINDER_TIME_WINDOW_MINUTES
      : DEFAULT_TIME_WINDOW_MINUTES;
  }

  private assertValidTimezone(timezone: string): void {
    try {
      Intl.DateTimeFormat('en-CA', { timeZone: timezone }).format(new Date());
    } catch {
      throw new AppError(`Invalid timezone: ${timezone}`, ErrorCode.INVALID_REQUEST);
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

