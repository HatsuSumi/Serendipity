import { Request, Response, NextFunction } from 'express';
import { IStatisticsService } from '../services/statisticsService';
import { sendSuccess } from '../utils/response';

/**
 * 统计控制器
 *
 * 职责：
 * - 解析请求参数（userId 从 JWT 中间件注入）
 * - 委托 StatisticsService 处理业务逻辑
 * - 统一响应格式
 *
 * 设计原则：
 * - 无业务逻辑：只负责请求/响应处理
 * - 依赖倒置：依赖 IStatisticsService 接口
 */
export class StatisticsController {
  constructor(private statisticsService: IStatisticsService) {}

  /**
   * GET /statistics/overview
   *
   * 获取账号全局统计总览。
   * 需要 JWT 认证（authMiddleware 已将 userId 注入 req.user）。
   */
  getOverview = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const overview = await this.statisticsService.getOverview(userId);
      sendSuccess(res, overview);
    } catch (error) {
      next(error);
    }
  };
}

