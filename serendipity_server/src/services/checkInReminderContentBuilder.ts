export interface CheckInReminderContent {
  title: string;
  body: string;
}

const DEFAULT_TITLE = '别忘了今天的签到哦 🌟';

export function buildCheckInReminderContent(consecutiveDays: number): CheckInReminderContent {
  if (!Number.isInteger(consecutiveDays) || consecutiveDays < 0) {
    throw new Error('consecutiveDays must be a non-negative integer');
  }

  if (consecutiveDays === 6) {
    return {
      title: DEFAULT_TITLE,
      body: '再签到 1 天就能解锁"连续7天签到"成就啦！',
    };
  }

  if (consecutiveDays === 29) {
    return {
      title: DEFAULT_TITLE,
      body: '再签到 1 天就能解锁"连续30天签到"成就啦！',
    };
  }

  if (consecutiveDays >= 90 && consecutiveDays < 100) {
    return {
      title: DEFAULT_TITLE,
      body: `再签到 ${100 - consecutiveDays} 天就能解锁"签到大师"成就啦！`,
    };
  }

  if (consecutiveDays >= 3) {
    return {
      title: DEFAULT_TITLE,
      body: `已连续签到 ${consecutiveDays} 天，继续保持！`,
    };
  }

  if (consecutiveDays > 0) {
    return {
      title: DEFAULT_TITLE,
      body: '养成每日签到的好习惯吧！',
    };
  }

  return {
    title: DEFAULT_TITLE,
    body: '重新开始签到，加油！',
  };
}

export function calculateReminderConsecutiveDays(checkInDates: Date[], reminderDate: Date): number {
  if (!(reminderDate instanceof Date) || Number.isNaN(reminderDate.getTime())) {
    throw new Error('Invalid reminderDate');
  }

  const normalizedDates = checkInDates.map(normalizeDate);
  const dateSet = new Set(normalizedDates.map(toDateKey));
  const reminderDateOnly = normalizeDate(reminderDate);
  const yesterday = addDays(reminderDateOnly, -1);

  let streakEndDate: Date | null = null;
  if (dateSet.has(toDateKey(reminderDateOnly))) {
    streakEndDate = reminderDateOnly;
  } else if (dateSet.has(toDateKey(yesterday))) {
    streakEndDate = yesterday;
  } else {
    return 0;
  }

  let streakDays = 1;
  let currentDate = streakEndDate;
  while (true) {
    const previousDate = addDays(currentDate, -1);
    if (!dateSet.has(toDateKey(previousDate))) {
      break;
    }

    streakDays += 1;
    currentDate = previousDate;
  }

  return streakDays;
}

function normalizeDate(date: Date): Date {
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
    throw new Error('Invalid check-in date');
  }

  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function addDays(date: Date, days: number): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + days));
}

function toDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

