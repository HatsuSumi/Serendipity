export enum ReminderDispatchStatus {
  Pending = 'pending',
  Sent = 'sent',
  Failed = 'failed',
}

export interface ReminderSendResult {
  success: boolean;
  providerMessageId?: string;
  failureReason?: string;
  isInvalidToken?: boolean;
}

export interface ReminderSendPayload {
  token: string;
  platform: string;
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface IReminderPushSender {
  send(payload: ReminderSendPayload): Promise<ReminderSendResult>;
}

