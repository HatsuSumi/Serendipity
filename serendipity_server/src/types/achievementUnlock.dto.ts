/**
 * 成就解锁 DTO
 * 
 * 用于客户端和服务端之间的数据传输
 */

/**
 * 创建成就解锁记录 DTO
 * 
 * 调用者：
 * - AchievementUnlockController.uploadAchievementUnlock()
 */
export interface CreateAchievementUnlockDto {
  userId: string;
  achievementId: string;
  unlockedAt: string; // ISO 8601 格式
}

/**
 * 成就解锁响应 DTO
 * 
 * 调用者：
 * - AchievementUnlockController.downloadAchievementUnlocks()
 */
export interface AchievementUnlockResponseDto {
  userId: string;
  achievementId: string;
  unlockedAt: string; // ISO 8601 格式
}

