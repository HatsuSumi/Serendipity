import { PrismaClient } from '@prisma/client';

/**
 * 统计总览原始数据
 *
 * 从数据库聚合查询的中间结果，由 StatisticsService 进一步处理。
 */
export interface StatisticsOverviewRaw {
  // 账号信息
  registeredAt: Date;

  // 记录维度
  totalRecords: number;
  pinnedRecordCount: number;
  linkedRecordCount: number;   // storyLineId IS NOT NULL
  statusCounts: Record<string, number>; // { missed: N, met: N, ... }

  // 故事线维度
  storyLineCount: number;
  pinnedStoryLineCount: number;

  // 签到维度
  totalCheckInDays: number;
  checkInStartDate: Date | null;
  checkInEndDate: Date | null;
  longestStreakDays: number;
  longestStreakStart: Date | null;
  longestStreakEnd: Date | null;

  // 收藏维度
  favoritedRecordCount: number;
  favoritedPostCount: number;
}

/**
 * 统计仓储接口
 */
export interface IStatisticsRepository {
  /**
   * 获取用户的统计总览原始数据
   *
   * @param userId - 用户 ID
   */
  getOverviewRaw(userId: string): Promise<StatisticsOverviewRaw>;
}

/**
 * 统计仓储实现
 *
 * 职责：
 * - 从 Prisma 执行所有聚合查询
 * - 只返回原始数据，不做业务逻辑
 *
 * 设计原则：
 * - 并发查询：Promise.all 并行执行所有独立查询，最小化等待时间
 * - 签到连续天数：在应用层计算（避免复杂 SQL 窗口函数），数据量有限
 * - Fail Fast：userId 为空时立即抛出
 */
export class StatisticsRepository implements IStatisticsRepository {
  constructor(private prisma: PrismaClient) {
    if (!prisma) throw new Error('PrismaClient is required');
  }

  async getOverviewRaw(userId: string): Promise<StatisticsOverviewRaw> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    // 并行执行所有独立查询
    const [
      user,
      recordAgg,
      statusRows,
      storyLineAgg,
      checkInRows,
      favoriteAgg,
    ] = await Promise.all([
      // 1. 账号注册时间
      this.prisma.user.findUniqueOrThrow({
        where: { id: userId },
        select: { createdAt: true },
      }),

      // 2. 记录聚合（总数、置顶数、已关联故事线数）
      this.prisma.record.aggregate({
        where: { userId },
        _count: { id: true },
      }).then(async (agg) => {
        const [pinned, linked] = await Promise.all([
          this.prisma.record.count({ where: { userId, isPinned: true } }),
          this.prisma.record.count({
            where: { userId, storyLineId: { not: null } },
          }),
        ]);
        return {
          total: agg._count.id,
          pinned,
          linked,
        };
      }),

      // 3. 各状态计数
      this.prisma.record.groupBy({
        by: ['status'],
        where: { userId },
        _count: { id: true },
      }),

      // 4. 故事线聚合
      Promise.all([
        this.prisma.storyLine.count({ where: { userId } }),
        this.prisma.storyLine.count({ where: { userId, isPinned: true } }),
      ] as const),

      // 5. 所有签到日期（用于应用层计算连续天数）
      this.prisma.checkIn.findMany({
        where: { userId },
        select: { date: true },
        orderBy: { date: 'asc' },
      }),

      // 6. 收藏统计
      Promise.all([
        this.prisma.favorite.count({
          where: { userId, recordId: { not: null } },
        }),
        this.prisma.favorite.count({
          where: { userId, postId: { not: null } },
        }),
      ] as const),
    ]);

    // 状态计数映射
    const statusCounts: Record<string, number> = {};
    for (const row of statusRows) {
      statusCounts[row.status] = row._count.id;
    }

    // 签到统计
    const dates = checkInRows.map((r) => r.date);
    const checkInStats = this._calcCheckInStats(dates);

    const [storyLineCount, pinnedStoryLineCount] = storyLineAgg;
    const [favoritedRecordCount, favoritedPostCount] = favoriteAgg;

    return {
      registeredAt: user.createdAt,
      totalRecords: recordAgg.total,
      pinnedRecordCount: recordAgg.pinned,
      linkedRecordCount: recordAgg.linked,
      statusCounts,
      storyLineCount,
      pinnedStoryLineCount,
      totalCheckInDays: dates.length,
      checkInStartDate: checkInStats.startDate,
      checkInEndDate: checkInStats.endDate,
      longestStreakDays: checkInStats.longestDays,
      longestStreakStart: checkInStats.longestStart,
      longestStreakEnd: checkInStats.longestEnd,
      favoritedRecordCount,
      favoritedPostCount,
    };
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /**
   * 从有序日期列表计算签到统计
   *
   * 计算内容：
   * - 起止日期
   * - 最长连续签到天数及其时间段
   *
   * 时间复杂度：O(n)，n 为签到记录数
   */
  private _calcCheckInStats(sortedDates: Date[]): {
    startDate: Date | null;
    endDate: Date | null;
    longestDays: number;
    longestStart: Date | null;
    longestEnd: Date | null;
  } {
    if (sortedDates.length === 0) {
      return {
        startDate: null,
        endDate: null,
        longestDays: 0,
        longestStart: null,
        longestEnd: null,
      };
    }

    const startDate = sortedDates[0];
    const endDate = sortedDates[sortedDates.length - 1];

    // 去重（同一天多条记录只算一次）
    const unique = Array.from(
      new Set(sortedDates.map((d) => d.toISOString().slice(0, 10)))
    ).map((s) => new Date(s));

    let longestDays = 1;
    let longestStart = unique[0];
    let longestEnd = unique[0];
    let curDays = 1;
    let curStart = unique[0];

    for (let i = 1; i < unique.length; i++) {
      const diffMs = unique[i].getTime() - unique[i - 1].getTime();
      const diffDays = Math.round(diffMs / 86_400_000);

      if (diffDays === 1) {
        curDays++;
        if (curDays > longestDays) {
          longestDays = curDays;
          longestStart = curStart;
          longestEnd = unique[i];
        }
      } else {
        curDays = 1;
        curStart = unique[i];
      }
    }

    return { startDate, endDate, longestDays, longestStart, longestEnd };
  }
}

