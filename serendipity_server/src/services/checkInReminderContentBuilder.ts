export interface CheckInReminderContent {
  title: string;
  body: string;
}

export interface CheckInReminderContentContext {
  consecutiveDays: number;
  maxConsecutiveDays: number;
}

const DEFAULT_TITLE = '别忘了今天的签到哦 🌟';
const HABIT_FORMING_STREAK_DAYS = 2;

export function buildCheckInReminderContent(
  context: CheckInReminderContentContext,
): CheckInReminderContent {
  const { consecutiveDays, maxConsecutiveDays } = context;

  if (!Number.isInteger(consecutiveDays) || consecutiveDays < 0) {
    throw new Error('consecutiveDays must be a non-negative integer');
  }
  if (!Number.isInteger(maxConsecutiveDays) || maxConsecutiveDays < 0) {
    throw new Error('maxConsecutiveDays must be a non-negative integer');
  }
  if (maxConsecutiveDays < consecutiveDays) {
    throw new Error('maxConsecutiveDays must be greater than or equal to consecutiveDays');
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

  if (maxConsecutiveDays >= HABIT_FORMING_STREAK_DAYS) {
    return {
      title: DEFAULT_TITLE,
      body: '重新开始签到，加油！',
    };
  }

  return {
    title: DEFAULT_TITLE,
    body: '今天也别忘了签到哦～',
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

export function calculateMaxConsecutiveDays(checkInDates: Date[]): number {
  if (checkInDates.length === 0) {
    return 0;
  }

  const normalizedDates = Array.from(new Set(checkInDates.map((date) => toDateKey(normalizeDate(date))))).sort();

  let maxStreakDays = 1;
  let currentStreakDays = 1;

  for (let index = 1; index < normalizedDates.length; index += 1) {
    const currentDate = new Date(`${normalizedDates[index]}T00:00:00.000Z`);
    const previousDate = new Date(`${normalizedDates[index - 1]}T00:00:00.000Z`);

    if (toDateKey(addDays(previousDate, 1)) === toDateKey(currentDate)) {
      currentStreakDays += 1;
      maxStreakDays = Math.max(maxStreakDays, currentStreakDays);
      continue;
    }

    currentStreakDays = 1;
  }

  return maxStreakDays;
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

