/**
 * 签到相关 DTO
 * 
 * 调用者：
 * - CheckInController：控制器层
 * - CheckInService：业务逻辑层
 */

/**
 * 创建签到记录 DTO
 * 
 * 调用者：
 * - CheckInController.createCheckIn()
 * - CheckInController.batchCreateCheckIns()
 */
export interface CreateCheckInDto {
  id: string;
  date: string; // ISO 8601 格式
  checkedAt: string; // ISO 8601 格式
  createdAt: string; // ISO 8601 格式
  updatedAt: string; // ISO 8601 格式
}

/**
 * 批量创建签到记录 DTO
 * 
 * 调用者：
 * - CheckInController.batchCreateCheckIns()
 */
export interface BatchCreateCheckInsDto {
  checkIns: CreateCheckInDto[];
}

/**
 * 签到记录响应 DTO
 * 
 * 调用者：
 * - CheckInController（所有方法）
 */
export interface CheckInResponseDto {
  id: string;
  userId: string;
  date: string; // ISO 8601 格式
  checkedAt: string; // ISO 8601 格式
  createdAt: string; // ISO 8601 格式
  updatedAt: string; // ISO 8601 格式
}

