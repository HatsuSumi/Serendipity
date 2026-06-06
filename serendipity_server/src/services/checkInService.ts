import { randomUUID } from 'crypto';
import { CheckIn } from '@prisma/client';
import { ICheckInRepository } from '../repositories/checkInRepository';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { IUserTimezoneResolver } from './userTimezoneResolver';
import { ImportCheckInRequestDto } from '../types/checkIn.dto';

export interface CheckInStatus {
  hasCheckedInToday: boolean;
  consecutiveDays: number;
  displayConsecutiveDays: number;
  totalDays: number;
  currentMonthDays: number;
  recentCheckIns: CheckIn[];
  checkedInDatesInMonth: Date[];
}

/**
 * 签到服务接口
 *
 * 定义签到业务逻辑的抽象接口，遵循依赖倒置原则（DIP）
 *
 * 调用者：
 * - CheckInController：控制器层
 */
export interface ICheckInService {
  createTodayCheckIn(userId: string): Promise<CheckIn>;
  importCheckIns(userId: string, checkIns: ImportCheckInRequestDto[]): Promise<CheckIn[]>;
  getCheckInStatus(userId: string, year: number, month: number): Promise<CheckInStatus>;
  getCheckIns(userId: string, lastSyncTime?: string): Promise<CheckIn[]>;
  deleteCheckIn(checkInId: string, userId: string): Promise<void>;
}

/**
 * 签到服务实现
 */
export class CheckInService implements ICheckInService {
  constructor(
    private checkInRepository: ICheckInRepository,
    private userTimezoneResolver: IUserTimezoneResolver,
  ) {
    if (!checkInRepository) {
      throw new Error('CheckInRepository is required');
    }
    if (!userTimezoneResolver) {
      throw new Error('UserTimezoneResolver is required');
    }
  }

  async createTodayCheckIn(userId: string): Promise<CheckIn> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    const now = new Date();
    const timezone = await this.getUserTimezone(userId);
    const today = this.getDateOnlyForTimezone(now, timezone);
    const existing = await this.checkInRepository.findByUserAndDate(userId, today);

    if (existing) {
      throw new AppError('Already checked in today', ErrorCode.CONFLICT);
    }

    return this.checkInRepository.create(userId, {
      id: randomUUID(),
      date: today,
      checkedAt: now,
    });
  }

  async importCheckIns(userId: string, checkIns: ImportCheckInRequestDto[]): Promise<CheckIn[]> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!Array.isArray(checkIns)) {
      throw new Error('checkIns must be an array');
    }
    if (checkIns.length === 0) {
      return [];
    }

    const imported: CheckIn[] = [];
    for (const item of checkIns) {
      const date = this.parseDateOnly(item.date);
      const checkedAt = new Date(item.checkedAt);
      const createdAt = item.createdAt ? new Date(item.createdAt) : checkedAt;
      const updatedAt = item.updatedAt ? new Date(item.updatedAt) : checkedAt;

      if (
        Number.isNaN(date.getTime()) ||
        Number.isNaN(checkedAt.getTime()) ||
        Number.isNaN(createdAt.getTime()) ||
        Number.isNaN(updatedAt.getTime())
      ) {
        throw new Error('Invalid check-in payload');
      }

      const saved = await this.checkInRepository.createIfAbsentByDate(userId, {
        id: item.id && item.id.trim() !== '' ? item.id : randomUUID(),
        date,
        checkedAt,
        createdAt,
        updatedAt,
      });
      imported.push(saved);
    }

    return imported;
  }

  async getCheckInStatus(userId: string, year: number, month: number): Promise<CheckInStatus> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }
    if (!Number.isInteger(year) || year < 2000 || year > 3000) {
      throw new Error('Invalid year');
    }
    if (!Number.isInteger(month) || month < 1 || month > 12) {
      throw new Error('Invalid month');
    }

    const timezone = await this.getUserTimezone(userId);
    const allCheckIns = await this.checkInRepository.findByUserId(userId);
    const today = this.getDateOnlyForTimezone(new Date(), timezone);
    const monthDates = allCheckIns
      .map((checkIn) => this.normalizeStoredDate(checkIn.date))
      .filter((date) => date.getUTCFullYear() === year && date.getUTCMonth() + 1 === month);

    return {
      hasCheckedInToday: allCheckIns.some((checkIn) => this.isSameDateOnly(checkIn.date, today)),
      consecutiveDays: this.calculateConsecutiveDays(allCheckIns, today),
      displayConsecutiveDays: this.calculateDisplayConsecutiveDays(allCheckIns, today),
      totalDays: allCheckIns.length,
      currentMonthDays: monthDates.length,
      recentCheckIns: allCheckIns.slice(0, 7),
      checkedInDatesInMonth: monthDates,
    };
  }

  async getCheckIns(userId: string, lastSyncTime?: string): Promise<CheckIn[]> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    const lastSyncDate = lastSyncTime ? new Date(lastSyncTime) : undefined;
    return this.checkInRepository.findByUserId(userId, lastSyncDate);
  }

  async deleteCheckIn(checkInId: string, userId: string): Promise<void> {
    if (!checkInId || checkInId.trim() === '') {
      throw new Error('checkInId is required');
    }
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    const existingCheckIn = await this.checkInRepository.findActiveById(checkInId);
    if (!existingCheckIn || existingCheckIn.userId !== userId) {
      throw new AppError('CheckIn not found', ErrorCode.NOT_FOUND);
    }

    await this.checkInRepository.deleteById(checkInId, new Date());
  }

  private calculateConsecutiveDays(checkIns: CheckIn[], today: Date): number {
    if (checkIns.length === 0) {
      return 0;
    }

    const dateSet = new Set(checkIns.map((checkIn) => this.toDateKey(checkIn.date)));
    const todayKey = this.toDateKey(today);
    if (!dateSet.has(todayKey)) {
      return 0;
    }

    let consecutiveDays = 1;
    let currentDate = today;
    while (true) {
      currentDate = new Date(Date.UTC(
        currentDate.getUTCFullYear(),
        currentDate.getUTCMonth(),
        currentDate.getUTCDate() - 1,
      ));

      if (!dateSet.has(this.toDateKey(currentDate))) {
        break;
      }

      consecutiveDays++;
    }

    return consecutiveDays;
  }

  private calculateDisplayConsecutiveDays(checkIns: CheckIn[], today: Date): number {
    if (checkIns.length === 0) {
      return 0;
    }

    const dateSet = new Set(checkIns.map((checkIn) => this.toDateKey(checkIn.date)));
    const todayKey = this.toDateKey(today);
    const yesterday = new Date(Date.UTC(
      today.getUTCFullYear(),
      today.getUTCMonth(),
      today.getUTCDate() - 1,
    ));
    const yesterdayKey = this.toDateKey(yesterday);

    let streakEndDate: Date | null = null;
    if (dateSet.has(todayKey)) {
      streakEndDate = today;
    } else if (dateSet.has(yesterdayKey)) {
      streakEndDate = yesterday;
    } else {
      return 0;
    }

    let streakDays = 1;
    let currentDate = streakEndDate;
    while (true) {
      currentDate = new Date(Date.UTC(
        currentDate.getUTCFullYear(),
        currentDate.getUTCMonth(),
        currentDate.getUTCDate() - 1,
      ));

      if (!dateSet.has(this.toDateKey(currentDate))) {
        break;
      }

      streakDays++;
    }

    return streakDays;
  }

  private async getUserTimezone(userId: string): Promise<string | undefined> {
    return this.userTimezoneResolver.resolveTimezone(userId);
  }

  private getDateOnlyForTimezone(date: Date, timezone?: string): Date {
    if (!timezone) {
      return this.normalizeStoredDate(date);
    }

    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    const parts = formatter.formatToParts(date);
    const year = Number(parts.find((part) => part.type === 'year')?.value);
    const month = Number(parts.find((part) => part.type === 'month')?.value);
    const day = Number(parts.find((part) => part.type === 'day')?.value);

    if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
      throw new Error(`Invalid timezone date for ${timezone}`);
    }

    return new Date(Date.UTC(year, month - 1, day));
  }

  private parseDateOnly(value: string): Date {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
    if (match) {
      return new Date(Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3])));
    }

    return this.normalizeStoredDate(new Date(value));
  }

  private isSameDateOnly(left: Date, right: Date): boolean {
    return this.toDateKey(left) === this.toDateKey(right);
  }

  private toDateKey(date: Date): string {
    return this.normalizeStoredDate(date).toISOString().slice(0, 10);
  }

  private normalizeStoredDate(date: Date): Date {
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  }
}
