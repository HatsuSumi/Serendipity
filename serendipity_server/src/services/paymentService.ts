/**
 * 支付服务
 * 
 * 职责：处理支付业务逻辑，支持 Mock 模式和真实支付模式切换
 */

import { 
  CreatePaymentDto, 
  CreatePaymentResponseDto, 
  PaymentCallbackDto, 
  PaymentStatusDto,
  MembershipStatusDto,
  PaymentMethod,
  PaymentStatus,
  MembershipTier,
  MembershipStatus
} from '../types/payment.dto';
import { IPaymentOrderRepository } from '../repositories/paymentOrderRepository';
import { IMembershipRepository } from '../repositories/membershipRepository';
import { config } from '../config';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';
import { ILogger } from '../types/interfaces';

/**
 * 业务常量
 */
const MEMBERSHIP_DURATION_DAYS = 30;  // 会员有效期（天）
const ORDER_EXPIRATION_MINUTES = 15;  // 订单过期时间（分钟）
const MOCK_PAYMENT_DELAY_MS = 3000;   // Mock 支付延迟（毫秒）

/**
 * 支付服务接口
 */
export interface IPaymentService {
  createPayment(userId: string, data: CreatePaymentDto): Promise<CreatePaymentResponseDto>;
  handleWechatCallback(data: PaymentCallbackDto): Promise<void>;
  handleAlipayCallback(data: PaymentCallbackDto): Promise<void>;
  getPaymentStatus(orderId: string): Promise<PaymentStatusDto>;
  getMembershipStatus(userId: string): Promise<MembershipStatusDto>;
}

export class PaymentService implements IPaymentService {
  private isMockMode: boolean;

  constructor(
    private paymentOrderRepository: IPaymentOrderRepository,
    private membershipRepository: IMembershipRepository,
    private logger: ILogger
  ) {
    // 从配置读取是否启用 Mock 模式
    this.isMockMode = config.payment.enableMockMode;
    this.logger.info(`Payment service initialized in ${this.isMockMode ? 'MOCK' : 'REAL'} mode`);
  }

  /**
   * 创建支付订单
   */
  async createPayment(userId: string, data: CreatePaymentDto): Promise<CreatePaymentResponseDto> {
    // 验证金额范围（¥0-648）
    if (data.amount < 0 || data.amount > 648) {
      throw new AppError('Payment amount must be between ¥0 and ¥648', ErrorCode.VALIDATION_ERROR);
    }

    // 如果金额为 0，直接激活会员（免费解锁，不创建订单）
    if (data.amount === 0) {
      return this.handleFreePayment(userId);
    }

    // 生成订单 ID
    const orderId = this.generateOrderId();

    // Mock 模式：返回模拟数据
    if (this.isMockMode) {
      return this.createMockPayment(userId, orderId, data);
    }

    // 真实支付模式：调用 YunGouOS SDK
    return this.createRealPayment(userId, orderId, data);
  }

  /**
   * 处理免费支付（¥0）
   * 不创建订单，直接激活会员
   */
  private async handleFreePayment(userId: string): Promise<CreatePaymentResponseDto> {
    this.logger.info('Processing free payment (no order created)', { userId });

    const expiresAt = this.calculateMembershipExpiration();
    await this.activateMembership(userId, 0, expiresAt);

    return {
      orderId: 'FREE_' + Date.now(), // 返回一个虚拟订单ID，但不存储到数据库
      amount: 0,
      method: PaymentMethod.FREE,
      status: PaymentStatus.SUCCESS,
      expiresAt,
      createdAt: new Date(),
    };
  }

  /**
   * 创建 Mock 支付订单
   */
  private async createMockPayment(
    userId: string, 
    orderId: string, 
    data: CreatePaymentDto
  ): Promise<CreatePaymentResponseDto> {
    this.logger.info('Creating MOCK payment', { userId, orderId, amount: data.amount });

    // 创建支付订单
    await this.paymentOrderRepository.create({
      id: orderId,
      userId,
      amount: data.amount,
      paymentMethod: data.method,
      status: PaymentStatus.PENDING,
    });

    // Mock 支付链接
    const mockPaymentUrl = `https://mock-payment.serendipity.com/pay?orderId=${orderId}&amount=${data.amount}`;
    const mockQrCode = `https://mock-qr.serendipity.com/qr?orderId=${orderId}`;

    const expiresAt = this.calculateOrderExpiration();

    // Mock 模式：自动模拟支付成功
    setTimeout(() => {
      this.simulatePaymentSuccess(orderId, userId, data.amount).catch(err => {
        this.logger.error('Failed to simulate payment success', { error: err, orderId, userId });
      });
    }, MOCK_PAYMENT_DELAY_MS);

    return {
      orderId,
      amount: data.amount,
      method: data.method,
      status: PaymentStatus.PENDING,
      paymentUrl: mockPaymentUrl,
      qrCode: mockQrCode,
      expiresAt,
      createdAt: new Date(),
    };
  }

  /**
   * 模拟支付成功（Mock 模式）
   */
  private async simulatePaymentSuccess(orderId: string, userId: string, amount: number): Promise<void> {
    this.logger.info('Simulating payment success', { orderId, userId, amount });

    await this.paymentOrderRepository.updateStatus(
      orderId,
      PaymentStatus.SUCCESS,
      `MOCK_TXN_${Date.now()}`,
      new Date()
    );

    const expiresAt = this.calculateMembershipExpiration();
    await this.activateMembership(userId, amount, expiresAt);

    this.logger.info('Mock payment completed successfully', { orderId, userId });
  }

  /**
   * 创建真实支付订单（YunGouOS）
   * TODO: Phase 2 实现真实支付集成
   */
  private async createRealPayment(
    userId: string, 
    orderId: string, 
    data: CreatePaymentDto
  ): Promise<CreatePaymentResponseDto> {
    this.logger.info('Creating REAL payment', { userId, orderId, amount: data.amount });
    
    // TODO: Phase 2 实现 YunGouOS SDK 集成
    // 1. 调用 YunGouOS API 创建支付订单
    // 2. 验证签名
    // 3. 返回支付链接和二维码
    
    throw new AppError('Real payment not implemented yet', ErrorCode.SERVICE_UNAVAILABLE);
  }

  /**
   * 处理微信支付回调
   */
  async handleWechatCallback(data: PaymentCallbackDto): Promise<void> {
    this.logger.info('Handling WeChat payment callback', { orderId: data.orderId });
    
    // TODO: Phase 2 真实模式下验证微信签名
    // if (!this.isMockMode && !this.verifyWechatSignature(data)) {
    //   throw new AppError('Invalid WeChat signature', ErrorCode.INVALID_SIGNATURE);
    // }
    
    await this.processPaymentCallback(data);
  }

  /**
   * 处理支付宝回调
   */
  async handleAlipayCallback(data: PaymentCallbackDto): Promise<void> {
    this.logger.info('Handling Alipay payment callback', { orderId: data.orderId });
    
    // TODO: Phase 2 真实模式下验证支付宝签名
    // if (!this.isMockMode && !this.verifyAlipaySignature(data)) {
    //   throw new AppError('Invalid Alipay signature', ErrorCode.INVALID_SIGNATURE);
    // }
    
    await this.processPaymentCallback(data);
  }

  /**
   * 处理支付回调（通用逻辑）
   */
  private async processPaymentCallback(data: PaymentCallbackDto): Promise<void> {
    // 查询订单
    const order = await this.paymentOrderRepository.findById(data.orderId);
    if (!order) {
      throw new AppError('Order not found', ErrorCode.NOT_FOUND);
    }

    // 检查订单状态
    if (order.status === PaymentStatus.SUCCESS) {
      this.logger.warn('Order already processed', { orderId: data.orderId });
      return;
    }

    // 更新订单状态
    await this.paymentOrderRepository.updateStatus(
      data.orderId,
      data.status,
      data.transactionId,
      data.paidAt
    );

    // 如果支付成功，激活会员
    if (data.status === PaymentStatus.SUCCESS) {
      const expiresAt = this.calculateMembershipExpiration();
      await this.activateMembership(order.userId, data.amount, expiresAt);
    }
  }

  /**
   * 查询支付状态
   */
  async getPaymentStatus(orderId: string): Promise<PaymentStatusDto> {
    const order = await this.paymentOrderRepository.findById(orderId);
    if (!order) {
      throw new AppError('Order not found', ErrorCode.NOT_FOUND);
    }

    return {
      orderId: order.id,
      amount: order.amount,
      method: order.paymentMethod as PaymentMethod,
      status: order.status as PaymentStatus,
      transactionId: order.transactionId ?? undefined,
      paidAt: order.paidAt ?? undefined,
      createdAt: order.createdAt,
    };
  }

  /**
   * 查询会员状态
   */
  async getMembershipStatus(userId: string): Promise<MembershipStatusDto> {
    let membership = await this.membershipRepository.findByUserId(userId);

    // 如果没有会员记录，创建一个（免费版）
    if (!membership) {
      membership = await this.membershipRepository.create({
        userId,
        tier: MembershipTier.FREE,
        status: MembershipStatus.INACTIVE,
      });
    }

    return {
      tier: membership.tier as MembershipTier,
      status: membership.status as MembershipStatus,
      startedAt: membership.startedAt ?? undefined,
      expiresAt: membership.expiresAt ?? undefined,
      autoRenew: membership.autoRenew,
      monthlyAmount: membership.monthlyAmount ?? undefined,
    };
  }

  /**
   * 激活会员（简化版，使用 upsert）
   */
  private async activateMembership(userId: string, monthlyAmount: number, expiresAt: Date): Promise<void> {
    await this.membershipRepository.activateOrCreate(userId, monthlyAmount, expiresAt);
    this.logger.info('Membership activated', { userId, monthlyAmount, expiresAt });
  }

  /**
   * 生成订单 ID
   */
  private generateOrderId(): string {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    return `ORDER_${timestamp}_${random}`;
  }

  /**
   * 计算会员到期时间
   */
  private calculateMembershipExpiration(): Date {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + MEMBERSHIP_DURATION_DAYS);
    return expiresAt;
  }

  /**
   * 计算订单过期时间
   */
  private calculateOrderExpiration(): Date {
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + ORDER_EXPIRATION_MINUTES);
    return expiresAt;
  }
}

