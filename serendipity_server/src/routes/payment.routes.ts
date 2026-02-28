/**
 * 支付路由
 * 
 * 职责：定义支付相关的 API 路由
 */

import { Router } from 'express';
import { PaymentController } from '../controllers/paymentController';
import { authMiddleware } from '../middlewares/auth';
import { validateRequest } from '../utils/validation';
import { createPaymentSchema, paymentCallbackSchema } from '../validators/payment.validator';

export function createPaymentRoutes(paymentController: PaymentController): Router {
  const router = Router();

  /**
   * 创建支付订单
   * POST /api/v1/payment/create
   * 需要认证
   */
  router.post(
    '/create',
    authMiddleware,
    createPaymentSchema,
    validateRequest,
    paymentController.createPayment
  );

  /**
   * 处理微信支付回调
   * POST /api/v1/payment/wechat/callback
   * 无需认证（第三方回调）
   */
  router.post(
    '/wechat/callback',
    paymentCallbackSchema,
    validateRequest,
    paymentController.handleWechatCallback
  );

  /**
   * 处理支付宝回调
   * POST /api/v1/payment/alipay/callback
   * 无需认证（第三方回调）
   */
  router.post(
    '/alipay/callback',
    paymentCallbackSchema,
    validateRequest,
    paymentController.handleAlipayCallback
  );

  /**
   * 查询支付状态
   * GET /api/v1/payment/status/:orderId
   * 需要认证
   */
  router.get(
    '/status/:orderId',
    authMiddleware,
    paymentController.getPaymentStatus
  );

  return router;
}

/**
 * 会员路由
 */
export function createMembershipRoutes(paymentController: PaymentController): Router {
  const router = Router();

  /**
   * 查询会员状态
   * GET /api/v1/membership/status
   * 需要认证
   */
  router.get(
    '/status',
    authMiddleware,
    paymentController.getMembershipStatus
  );

  return router;
}

