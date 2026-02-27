/**
 * 支付相关 DTO
 */

export enum PaymentMethod {
  FREE = 'free',
  WECHAT = 'wechat',
  ALIPAY = 'alipay',
}

export enum PaymentStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  SUCCESS = 'success',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

export enum MembershipTier {
  FREE = 'free',
  PREMIUM = 'premium',
}

export enum MembershipStatus {
  INACTIVE = 'inactive',
  ACTIVE = 'active',
  EXPIRED = 'expired',
  CANCELLED = 'cancelled',
}

export interface CreatePaymentDto {
  amount: number;
  method: PaymentMethod;
}

export interface CreatePaymentResponseDto {
  orderId: string;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  paymentUrl?: string;
  qrCode?: string;
  expiresAt: Date;
  createdAt: Date;
}

export interface PaymentCallbackDto {
  orderId: string;
  transactionId: string;
  amount: number;
  status: PaymentStatus;
  paidAt: Date;
  signature?: string;
}

export interface PaymentStatusDto {
  orderId: string;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  transactionId?: string;
  paidAt?: Date;
  createdAt: Date;
}

export interface MembershipStatusDto {
  tier: MembershipTier;
  status: MembershipStatus;
  startedAt?: Date;
  expiresAt?: Date;
  autoRenew: boolean;
  monthlyAmount?: number;
}

