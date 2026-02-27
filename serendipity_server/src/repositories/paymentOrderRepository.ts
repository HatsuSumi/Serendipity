/**
 * 支付订单 Repository
 * 
 * 职责：支付订单数据访问层
 */

import { PrismaClient } from '@prisma/client';

/**
 * 创建订单 DTO
 */
export interface CreatePaymentOrderDto {
  id: string;
  userId: string;
  amount: number;
  paymentMethod: string;
  status: string;
}

/**
 * 支付订单实体类型
 */
export interface PaymentOrder {
  id: string;
  userId: string;
  membershipId: string;
  amount: number;
  paymentMethod: string;
  status: string;
  transactionId: string | null;
  paidAt: Date | null;
  expiresAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * 支付订单 Repository 接口
 */
export interface IPaymentOrderRepository {
  create(data: CreatePaymentOrderDto): Promise<PaymentOrder>;
  findById(orderId: string): Promise<PaymentOrder | null>;
  updateStatus(orderId: string, status: string, transactionId?: string, paidAt?: Date): Promise<PaymentOrder>;
}

export class PaymentOrderRepository implements IPaymentOrderRepository {
  constructor(private prisma: PrismaClient) {}

  /**
   * 创建支付订单
   * @param data - 订单数据
   * @returns 创建的订单对象
   */
  async create(data: CreatePaymentOrderDto) {
    return this.prisma.paymentOrder.create({
      data: {
        id: data.id,
        userId: data.userId,
        membershipId: data.userId, // 临时使用 userId，实际应该传入 membershipId
        amount: data.amount,
        paymentMethod: data.paymentMethod,
        status: data.status,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000), // 30分钟过期
      },
    });
  }

  /**
   * 根据订单 ID 查询
   * @param orderId - 订单 ID
   * @returns 订单对象，不存在则返回 null
   */
  async findById(orderId: string) {
    return this.prisma.paymentOrder.findUnique({
      where: { id: orderId },
    });
  }

  /**
   * 更新订单状态
   * @param orderId - 订单 ID
   * @param status - 新状态
   * @param transactionId - 第三方交易 ID（可选）
   * @param paidAt - 支付时间（可选）
   * @returns 更新后的订单对象
   */
  async updateStatus(
    orderId: string,
    status: string,
    transactionId?: string,
    paidAt?: Date
  ) {
    return this.prisma.paymentOrder.update({
      where: { id: orderId },
      data: {
        status,
        transactionId,
        paidAt,
        updatedAt: new Date(),
      },
    });
  }
}

