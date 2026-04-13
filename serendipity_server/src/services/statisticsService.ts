import { IStatisticsRepository, StatisticsOverviewRaw } from '../repositories/statisticsRepository';

// ---------------------------------------------------------------------------
// DTOs
// ---------------------------------------------------------------------------

/**
 * 统计总览响应 DTO
 *
 * 与 docs/Statistics_Refactoring_Plan.md 中约定的响应格式一致。
 * Flutter 客户端 RemoteStatisticsDataSource._mapOverviewDto() 按此字段解析。
 */
export interface StatisticsOverviewDto {
  // 账号信息
  registeredAt: string;            // ISO 8601

  // 记录维度
  totalRecords: number;
  pinnedRecordCount: number;
  linkedRecordCount: number;
  unlinkedRecordCount: number;
  linkedRecordPercentage: number;  // 0-100, 保留1位小数
  unlinkedRecordPercentage: number;

  // 状态计数
  statusCounts: {
    missed: number;
    avoid: number;
    reencounter: number;
    met: number;
    reunion: number;
    farewell: number;
    lost: number;
  };

  // 成功率
  successRate: number;             // 0-100, 保留1位小数

  // 故事线维度
  storyLineCount: number;
  pinnedStoryLineCount: number;

  // 签到维度
  totalCheckInDays: number;
  totalCheckInStartDate: string | null;
  totalCheckInEndDate: string | null;
  longestCheckInStreakDays: number;
  longestCheckInStreakStartDate: string | null;
  longestCheckInStreakEndDate: string | null;

  // 收藏维度
  favoritedRecordCount: number;
  favoritedPostCount: number;

  // 元信息
  sourceVersion: number;           // DTO 版本号，用于客户端兼容性检测
  computedAt: string;              // 服务端计算时间戳
}

/**
 * 统计服务接口
 */
export interface IStatisticsService {
  /**
   * 获取账号全局统计总览
   *
   * @param userId - 当前用户 ID
   */
  getOverview(userId: string): Promise<StatisticsOverviewDto>;
}

/**
 * 统计服务实现
 *
 * 职责：
 * - 从 StatisticsRepository 获取原始聚合数据
 * - 计算派生字段（成功率、百分比、未关联数）
 * - 映射为客户端约定的 DTO
 *
 * 设计原则：
 * - 单一职责：只负责 DTO 映射与派生计算，不做数据库操作
 * - 统计结果属于派生展示数据，不与核心内容主资产迁移规则混用
 * - Fail Fast：userId 为空时立即抛出
 * - 不可变输入：不修改 Repository 返回的原始数据
 */
export class StatisticsService implements IStatisticsService {
  // 当前 DTO 版本，客户端可据此检测兼容性
  private static readonly DTO_VERSION = 1;

  // 成功状态定义：与 Flutter StatisticsService 保持一致
  // 注：successRate 在 _mapToDto 中直接使用 statusCounts 计算，此常量暂未启用
  // private static readonly SUCCESS_STATUSES = new Set(['met', 'reunion']);

  constructor(
    private statisticsRepository: IStatisticsRepository,
  ) {
    if (!statisticsRepository) throw new Error('StatisticsRepository is required');
  }

  async getOverview(userId: string): Promise<StatisticsOverviewDto> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    const raw = await this.statisticsRepository.getOverviewRaw(userId);
    return this._mapToDto(raw);
  }

  // ---------------------------------------------------------------------------
  // Private: mapping
  // ---------------------------------------------------------------------------

  private _mapToDto(raw: StatisticsOverviewRaw): StatisticsOverviewDto {
    const total = raw.totalRecords;
    const linked = raw.linkedRecordCount;
    const unlinked = total - linked;
    const linkedPct = total === 0 ? 0 : this._round1(linked / total * 100);
    const unlinkedPct = total === 0 ? 0 : this._round1(unlinked / total * 100);

    // 成功率
    const successCount =
      (raw.statusCounts['met'] ?? 0) + (raw.statusCounts['reunion'] ?? 0);
    const successRate = total === 0 ? 0 : this._round1(successCount / total * 100);

    // 状态计数（确保所有枚举值都有默认 0）
    const statusCounts = {
      missed:      raw.statusCounts['missed']      ?? 0,
      avoid:       raw.statusCounts['avoid']       ?? 0,
      reencounter: raw.statusCounts['reencounter'] ?? 0,
      met:         raw.statusCounts['met']         ?? 0,
      reunion:     raw.statusCounts['reunion']     ?? 0,
      farewell:    raw.statusCounts['farewell']    ?? 0,
      lost:        raw.statusCounts['lost']        ?? 0,
    };

    return {
      registeredAt: raw.registeredAt.toISOString(),
      totalRecords: total,
      pinnedRecordCount: raw.pinnedRecordCount,
      linkedRecordCount: linked,
      unlinkedRecordCount: unlinked,
      linkedRecordPercentage: linkedPct,
      unlinkedRecordPercentage: unlinkedPct,
      statusCounts,
      successRate,
      storyLineCount: raw.storyLineCount,
      pinnedStoryLineCount: raw.pinnedStoryLineCount,
      totalCheckInDays: raw.totalCheckInDays,
      totalCheckInStartDate: raw.checkInStartDate?.toISOString() ?? null,
      totalCheckInEndDate: raw.checkInEndDate?.toISOString() ?? null,
      longestCheckInStreakDays: raw.longestStreakDays,
      longestCheckInStreakStartDate: raw.longestStreakStart?.toISOString() ?? null,
      longestCheckInStreakEndDate: raw.longestStreakEnd?.toISOString() ?? null,
      favoritedRecordCount: raw.favoritedRecordCount,
      favoritedPostCount: raw.favoritedPostCount,
      sourceVersion: StatisticsService.DTO_VERSION,
      computedAt: new Date().toISOString(),
    };
  }

  /** 保留1位小数 */
  private _round1(n: number): number {
    return Math.round(n * 10) / 10;
  }
}

