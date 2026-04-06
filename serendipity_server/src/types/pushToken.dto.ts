export interface PushTokenResponseDto {
  id: string;
  token: string;
  platform: string;
  timezone: string;
  isActive: boolean;
  lastUsedAt: string;
  invalidatedAt?: string;
  invalidReason?: string;
  createdAt: string;
  updatedAt: string;
}

export interface RegisterPushTokenDto {
  token: string;
  platform: string;
  timezone: string;
}

export interface UnregisterPushTokenDto {
  token: string;
}

export interface AnniversaryReminderTestPayload {
  title: string;
  body: string;
}

export type ReminderDispatchSource = 'manual_test' | 'scheduler';

export type ReminderDispatchType = 'check_in' | 'anniversary';

export interface ReminderDispatchExecutionDto {
  userId: string;
  pushTokenId: string;
  platform: string;
  timezone: string;
  reminderDate: string;
  reminderTime: string;
  status: 'pending' | 'sent' | 'failed';
  failureReason?: string;
}

export interface ReminderDispatchSummaryDto {
  dispatchType: ReminderDispatchType;
  dispatchSource: ReminderDispatchSource;
  scannedCandidates: number;
  sentCount: number;
  failedCount: number;
  executions: ReminderDispatchExecutionDto[];
}