/**
 * 支付控制器
 * 
 * 职责：处理支付相关的 HTTP 请求
 */

import { Request, Response, NextFunction } from 'express';
import { IPaymentService } from '../services/paymentService';
import { CreatePaymentDto, PaymentCallbackDto } from '../types/payment.dto';
import { ILogger } from '../types/interfaces';
import { sendSuccess } from '../utils/response';
import { getParamAsString } from '../utils/request';

export class PaymentController {
  constructor(
    private paymentService: IPaymentService,
    private logger: ILogger
  ) {}

  /**
   * 创建支付订单
   * POST /api/v1/payment/create
   */
  createPayment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: CreatePaymentDto = req.body;
      const result = await this.paymentService.createPayment(userId, data);

      sendSuccess(res, result, 'Payment created successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  /**
   * 处理微信支付回调
   * POST /api/v1/payment/wechat/callback
   */
  handleWechatCallback = async (req: Request, res: Response): Promise<void> => {
    try {
      const data: PaymentCallbackDto = req.body;
      await this.paymentService.handleWechatCallback(data);

      // 返回成功响应（微信要求）
      res.status(200).json({
        code: 'SUCCESS',
        message: 'OK',
      });
    } catch (error) {
      this.logger.error('WeChat callback failed', { 
        error, 
        orderId: req.body?.orderId,
        transactionId: req.body?.transactionId 
      });
      
      // 返回失败响应（微信会重试）
      res.status(200).json({
        code: 'FAIL',
        message: 'Processing failed',
      });
    }
  };

  /**
   * 处理支付宝回调
   * POST /api/v1/payment/alipay/callback
   */
  handleAlipayCallback = async (req: Request, res: Response): Promise<void> => {
    try {
      const data: PaymentCallbackDto = req.body;
      await this.paymentService.handleAlipayCallback(data);

      // 返回成功响应（支付宝要求）
      res.status(200).send('success');
    } catch (error) {
      this.logger.error('Alipay callback failed', { 
        error, 
        orderId: req.body?.orderId,
        transactionId: req.body?.transactionId 
      });
      
      // 返回失败响应（支付宝会重试）
      res.status(200).send('fail');
    }
  };

  /**
   * 查询支付状态
   * GET /api/v1/payment/status/:orderId
   */
  getPaymentStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const orderId = getParamAsString(req.params.orderId);
      const result = await this.paymentService.getPaymentStatus(orderId);

      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  /**
   * 查询会员状态
   * GET /api/v1/membership/status
   */
  getMembershipStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const result = await this.paymentService.getMembershipStatus(userId);

      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };
}

