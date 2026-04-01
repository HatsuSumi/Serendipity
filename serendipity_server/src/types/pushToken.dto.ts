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
