/**
 * PaymentService 单元测试
 */

import { PaymentService } from '../../../src/services/paymentService';
import { PaymentMethod, PaymentStatus, MembershipTier, MembershipStatus } from '../../../src/types/payment.dto';

describe('PaymentService', () => {
  let paymentService: PaymentService;
  let mockPaymentOrderRepository: any;
  let mockMembershipRepository: any;
  let mockLogger: any;

  beforeEach(() => {
    // Mock PaymentOrderRepository
    mockPaymentOrderRepository = {
      create: jest.fn(),
      findById: jest.fn(),
      updateStatus: jest.fn(),
    };

    // Mock MembershipRepository
    mockMembershipRepository = {
      findByUserId: jest.fn(),
      create: jest.fn(),
      updateStatus: jest.fn(),
      activateOrCreate: jest.fn(),
    };

    // Mock Logger
    mockLogger = {
      info: jest.fn(),
      error: jest.fn(),
      warn: jest.fn(),
      debug: jest.fn(),
    };

    paymentService = new PaymentService(
      mockPaymentOrderRepository,
      mockMembershipRepository,
      mockLogger
    );
  });

  describe('createPayment', () => {
    it('应该创建免费支付（¥0，不创建订单）', async () => {
      const userId = 'user123';
      const data = { amount: 0, method: PaymentMethod.FREE };

      mockMembershipRepository.activateOrCreate.mockResolvedValue({});

      const result = await paymentService.createPayment(userId, data);

      expect(result.amount).toBe(0);
      expect(result.method).toBe(PaymentMethod.FREE);
      expect(result.status).toBe(PaymentStatus.SUCCESS);
      expect(result.orderId).toMatch(/^FREE_/); // 虚拟订单ID
      expect(mockPaymentOrderRepository.create).not.toHaveBeenCalled(); // 不创建订单
      expect(mockMembershipRepository.activateOrCreate).toHaveBeenCalled(); // 直接激活会员
    });

    it('应该创建 Mock 支付订单（微信支付）', async () => {
      const userId = 'user123';
      const data = { amount: 100, method: PaymentMethod.WECHAT };

      mockPaymentOrderRepository.create.mockResolvedValue({
        id: 'ORDER_123',
        userId,
        amount: 100,
        method: PaymentMethod.WECHAT,
        status: PaymentStatus.PENDING,
      });

      const result = await paymentService.createPayment(userId, data);

      expect(result.amount).toBe(100);
      expect(result.method).toBe(PaymentMethod.WECHAT);
      expect(result.status).toBe(PaymentStatus.PENDING);
      expect(result.paymentUrl).toContain('mock-payment');
      expect(result.qrCode).toContain('mock-qr');
      expect(mockPaymentOrderRepository.create).toHaveBeenCalled();
    });

    it('应该拒绝超出范围的金额', async () => {
      const userId = 'user123';
      const data = { amount: 1000, method: PaymentMethod.WECHAT };

      await expect(paymentService.createPayment(userId, data)).rejects.toThrow(
        'Payment amount must be between ¥0 and ¥648'
      );
    });

    it('应该拒绝负数金额', async () => {
      const userId = 'user123';
      const data = { amount: -10, method: PaymentMethod.WECHAT };

      await expect(paymentService.createPayment(userId, data)).rejects.toThrow(
        'Payment amount must be between ¥0 and ¥648'
      );
    });
  });

  describe('getPaymentStatus', () => {
    it('应该返回支付订单状态', async () => {
      const orderId = 'ORDER_123';
      const mockOrder = {
        id: orderId,
        userId: 'user123',
        amount: 100,
        method: PaymentMethod.WECHAT,
        status: PaymentStatus.SUCCESS,
        transactionId: 'TXN_123',
        paidAt: new Date(),
        createdAt: new Date(),
      };

      mockPaymentOrderRepository.findById.mockResolvedValue(mockOrder);

      const result = await paymentService.getPaymentStatus(orderId);

      expect(result.orderId).toBe(orderId);
      expect(result.amount).toBe(100);
      expect(result.status).toBe(PaymentStatus.SUCCESS);
      expect(mockPaymentOrderRepository.findById).toHaveBeenCalledWith(orderId);
    });

    it('应该在订单不存在时抛出错误', async () => {
      const orderId = 'INVALID_ORDER';
      mockPaymentOrderRepository.findById.mockResolvedValue(null);

      await expect(paymentService.getPaymentStatus(orderId)).rejects.toThrow('Order not found');
    });
  });

  describe('getMembershipStatus', () => {
    it('应该返回现有会员状态', async () => {
      const userId = 'user123';
      const mockMembership = {
        userId,
        tier: MembershipTier.PREMIUM,
        status: MembershipStatus.ACTIVE,
        startedAt: new Date(),
        expiresAt: new Date(),
        autoRenew: false,
        monthlyAmount: 100,
      };

      mockMembershipRepository.findByUserId.mockResolvedValue(mockMembership);

      const result = await paymentService.getMembershipStatus(userId);

      expect(result.tier).toBe(MembershipTier.PREMIUM);
      expect(result.status).toBe(MembershipStatus.ACTIVE);
      expect(mockMembershipRepository.findByUserId).toHaveBeenCalledWith(userId);
    });

    it('应该为新用户创建免费会员记录', async () => {
      const userId = 'user123';
      mockMembershipRepository.findByUserId.mockResolvedValue(null);
      mockMembershipRepository.create.mockResolvedValue({
        userId,
        tier: MembershipTier.FREE,
        status: MembershipStatus.INACTIVE,
        autoRenew: false,
      });

      const result = await paymentService.getMembershipStatus(userId);

      expect(result.tier).toBe(MembershipTier.FREE);
      expect(result.status).toBe(MembershipStatus.INACTIVE);
      expect(mockMembershipRepository.create).toHaveBeenCalled();
    });
  });

  describe('handleWechatCallback', () => {
    it('应该处理微信支付回调', async () => {
      const callbackData = {
        orderId: 'ORDER_123',
        transactionId: 'TXN_123',
        amount: 100,
        status: PaymentStatus.SUCCESS,
        paidAt: new Date(),
      };

      const mockOrder = {
        id: 'ORDER_123',
        userId: 'user123',
        amount: 100,
        method: PaymentMethod.WECHAT,
        status: PaymentStatus.PENDING,
      };

      mockPaymentOrderRepository.findById.mockResolvedValue(mockOrder);
      mockPaymentOrderRepository.updateStatus.mockResolvedValue({});
      mockMembershipRepository.activateOrCreate.mockResolvedValue({});

      await paymentService.handleWechatCallback(callbackData);

      expect(mockPaymentOrderRepository.updateStatus).toHaveBeenCalledWith(
        'ORDER_123',
        PaymentStatus.SUCCESS,
        'TXN_123',
        callbackData.paidAt
      );
      expect(mockMembershipRepository.activateOrCreate).toHaveBeenCalled();
    });

    it('应该忽略已处理的订单', async () => {
      const callbackData = {
        orderId: 'ORDER_123',
        transactionId: 'TXN_123',
        amount: 100,
        status: PaymentStatus.SUCCESS,
        paidAt: new Date(),
      };

      const mockOrder = {
        id: 'ORDER_123',
        userId: 'user123',
        amount: 100,
        method: PaymentMethod.WECHAT,
        status: PaymentStatus.SUCCESS, // 已经成功
      };

      mockPaymentOrderRepository.findById.mockResolvedValue(mockOrder);

      await paymentService.handleWechatCallback(callbackData);

      expect(mockPaymentOrderRepository.updateStatus).not.toHaveBeenCalled();
      expect(mockLogger.warn).toHaveBeenCalledWith('Order already processed', { orderId: 'ORDER_123' });
    });
  });

  describe('handleAlipayCallback', () => {
    it('应该处理支付宝回调', async () => {
      const callbackData = {
        orderId: 'ORDER_123',
        transactionId: 'ALIPAY_TXN_123',
        amount: 100,
        status: PaymentStatus.SUCCESS,
        paidAt: new Date(),
      };

      const mockOrder = {
        id: 'ORDER_123',
        userId: 'user123',
        amount: 100,
        method: PaymentMethod.ALIPAY,
        status: PaymentStatus.PENDING,
      };

      mockPaymentOrderRepository.findById.mockResolvedValue(mockOrder);
      mockPaymentOrderRepository.updateStatus.mockResolvedValue({});
      mockMembershipRepository.activateOrCreate.mockResolvedValue({});

      await paymentService.handleAlipayCallback(callbackData);

      expect(mockPaymentOrderRepository.updateStatus).toHaveBeenCalledWith(
        'ORDER_123',
        PaymentStatus.SUCCESS,
        'ALIPAY_TXN_123',
        callbackData.paidAt
      );
      expect(mockMembershipRepository.activateOrCreate).toHaveBeenCalled();
    });
  });
});

