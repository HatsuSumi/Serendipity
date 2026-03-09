import { Request, Response } from 'express';
import { AchievementUnlockService } from '../services/achievementUnlockService';
import { CreateAchievementUnlockDto } from '../types/achievementUnlock.dto';

/**
 * 成就解锁控制器
 * 
 * 负责处理成就解锁相关的 HTTP 请求，遵循单一职责原则（SRP）
 * 
 * 调用者：
 * - Express Router：路由层
 */
export class AchievementUnlockController {
  constructor(private achievementUnlockService: AchievementUnlockService) {
    // Fail Fast：依赖检查
    if (!achievementUnlockService) {
      throw new Error('AchievementUnlockService is required');
    }
  }

  /**
   * 上传成就解锁记录
   * 
   * POST /api/v1/achievement-unlocks
   * 
   * Request Body:
   * {
   *   "userId": "uuid",
   *   "achievementId": "first_met",
   *   "unlockedAt": "2024-01-01T12:00:00.000Z"
   * }
   * 
   * Response:
   * {
   *   "success": true,
   *   "message": "Achievement unlock uploaded successfully"
   * }
   * 
   * Fail Fast：
   * - 请求体缺少必填字段：返回 400
   * - 数据格式错误：返回 400
   * - 服务器错误：返回 500
   * 
   * 调用者：客户端（Flutter App）
   */
  uploadAchievementUnlock = async (req: Request, res: Response): Promise<void> => {
    try {
      const data: CreateAchievementUnlockDto = req.body;

      // Fail Fast：参数验证
      if (!data.userId || !data.achievementId || !data.unlockedAt) {
        res.status(400).json({
          success: false,
          message: 'Missing required fields: userId, achievementId, unlockedAt',
        });
        return;
      }

      await this.achievementUnlockService.createAchievementUnlock(data);

      res.status(201).json({
        success: true,
        message: 'Achievement unlock uploaded successfully',
      });
    } catch (error) {
      console.error('Error uploading achievement unlock:', error);
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Failed to upload achievement unlock',
      });
    }
  };

  /**
   * 下载用户成就解锁记录
   * 
   * GET /api/v1/achievement-unlocks?userId=xxx&since=timestamp
   * 
   * Query Parameters:
   * - userId: 用户ID（必填）
   * - since: 增量同步时间戳（可选，ISO 8601 格式）
   * 
   * Response:
   * {
   *   "success": true,
   *   "data": {
   *     "unlocks": [
   *       {
   *         "userId": "uuid",
   *         "achievementId": "first_met",
   *         "unlockedAt": "2024-01-01T12:00:00.000Z"
   *       }
   *     ]
   *   }
   * }
   * 
   * 增量同步优化：
   * - 不提供 since：返回所有记录（首次同步）
   * - 提供 since：只返回该时间之后创建的记录（增量同步）
   * - 性能：O(n) → O(新增)
   * 
   * Fail Fast：
   * - userId 缺失：返回 400
   * - since 格式错误：返回 400
   * - 服务器错误：返回 500
   * 
   * 调用者：客户端（Flutter App）
   */
  downloadAchievementUnlocks = async (req: Request, res: Response): Promise<void> => {
    try {
      const { userId, since } = req.query;

      // Fail Fast：参数验证
      if (!userId || typeof userId !== 'string') {
        res.status(400).json({
          success: false,
          message: 'userId query parameter is required',
        });
        return;
      }

      // 解析 since 参数（可选）
      let sinceDate: Date | undefined;
      if (since) {
        if (typeof since !== 'string') {
          res.status(400).json({
            success: false,
            message: 'since parameter must be a valid ISO 8601 timestamp',
          });
          return;
        }
        
        sinceDate = new Date(since);
        if (isNaN(sinceDate.getTime())) {
          res.status(400).json({
            success: false,
            message: 'since parameter must be a valid ISO 8601 timestamp',
          });
          return;
        }
      }

      const unlocks = await this.achievementUnlockService.getAchievementUnlocks(userId, sinceDate);

      res.status(200).json({
        success: true,
        data: {
          unlocks,
        },
      });
    } catch (error) {
      console.error('Error downloading achievement unlocks:', error);
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Failed to download achievement unlocks',
      });
    }
  };
}

