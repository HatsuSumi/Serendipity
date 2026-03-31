import { randomUUID } from 'crypto';
import { CheckIn } from '@prisma/client';
import { ICheckInRepository } from '../repositories/checkInRepository';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';

export interface CheckInStatus {
  hasCheckedInToday: boolean;
  consecutiveDays: number;
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
  getCheckInStatus(userId: string, year: number, month: number): Promise<CheckInStatus>;
  getCheckIns(userId: string, lastSyncTime?: string): Promise<CheckIn[]>;
  deleteCheckIn(checkInId: string, userId: string): Promise<void>;
}

/**
 * 签到服务实现
 */
export class CheckInService implements ICheckInService {
  constructor(private checkInRepository: ICheckInRepository) {
    if (!checkInRepository) {
      throw new Error('CheckInRepository is required');
    }
  }

  async createTodayCheckIn(userId: string): Promise<CheckIn> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    const now = new Date();
    const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
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

    const allCheckIns = await this.checkInRepository.findByUserId(userId);
    const today = this.toUtcDateOnly(new Date());
    const monthDates = allCheckIns
      .map((checkIn) => this.toUtcDateOnly(checkIn.date))
      .filter((date) => date.getUTCFullYear() === year && date.getUTCMonth() + 1 === month);

    return {
      hasCheckedInToday: allCheckIns.some((checkIn) => this.isSameUtcDate(checkIn.date, today)),
      consecutiveDays: this.calculateConsecutiveDays(allCheckIns, today),
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

    await this.checkInRepository.deleteById(checkInId, userId);
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

  private isSameUtcDate(left: Date, right: Date): boolean {
    return this.toDateKey(left) === this.toDateKey(right);
  }

  private toDateKey(date: Date): string {
    return this.toUtcDateOnly(date).toISOString().slice(0, 10);
  }

  private toUtcDateOnly(date: Date): Date {
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  }
}
