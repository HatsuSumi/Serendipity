/**
 * 支付路由
 * 
 * 职责：定义支付相关的 API 路由
 */

import { Router } from 'express';
import { PaymentController } from '../controllers/paymentController';
import { authenticate } from '../middlewares/auth';
import { validateBody } from '../middlewares/validation';
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
    authenticate,
    validateBody(createPaymentSchema),
    paymentController.createPayment
  );

  /**
   * 处理微信支付回调
   * POST /api/v1/payment/wechat/callback
   * 无需认证（第三方回调）
   */
  router.post(
    '/wechat/callback',
    validateBody(paymentCallbackSchema),
    paymentController.handleWechatCallback
  );

  /**
   * 处理支付宝回调
   * POST /api/v1/payment/alipay/callback
   * 无需认证（第三方回调）
   */
  router.post(
    '/alipay/callback',
    validateBody(paymentCallbackSchema),
    paymentController.handleAlipayCallback
  );

  /**
   * 查询支付状态
   * GET /api/v1/payment/status/:orderId
   * 需要认证
   */
  router.get(
    '/status/:orderId',
    authenticate,
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
    authenticate,
    paymentController.getMembershipStatus
  );

  return router;
}

