/**
 * 签到相关 DTO
 *
 * 调用者：
 * - CheckInController：控制器层
 * - CheckInService：业务逻辑层
 */

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

/**
 * 登录用户签到状态 DTO
 *
 * 调用者：
 * - CheckInController.getCheckInStatus()
 */
export interface CheckInStatusResponseDto {
  hasCheckedInToday: boolean;
  consecutiveDays: number;
  totalDays: number;
  currentMonthDays: number;
  recentCheckIns: CheckInResponseDto[];
  checkedInDatesInMonth: string[];
}
