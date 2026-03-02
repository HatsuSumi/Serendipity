/**
 * 支付相关的验证规则
 */

import { body } from 'express-validator';
import { PaymentMethod } from '../types/payment.dto';

/**
 * 创建支付订单验证规则
 */
export const createPaymentSchema = [
  body('amount')
    .isNumeric()
    .withMessage('金额必须是数字')
    .isFloat({ min: 0, max: 648 })
    .withMessage('金额必须在¥0到¥648之间'),
  
  body('method')
    .isString()
    .withMessage('支付方式必须是字符串')
    .isIn([PaymentMethod.FREE, PaymentMethod.WECHAT, PaymentMethod.ALIPAY])
    .withMessage('支付方式必须是以下之一：free、wechat、alipay'),
];

/**
 * 支付回调验证规则
 */
export const paymentCallbackSchema = [
  body('orderId')
    .isString()
    .withMessage('订单ID必须是字符串')
    .notEmpty()
    .withMessage('订单ID不能为空'),
  
  body('transactionId')
    .isString()
    .withMessage('交易ID必须是字符串')
    .notEmpty()
    .withMessage('交易ID不能为空'),
  
  body('amount')
    .isNumeric()
    .withMessage('金额必须是数字')
    .isFloat({ min: 0 })
    .withMessage('金额必须至少为0'),
  
  body('status')
    .isString()
    .withMessage('状态必须是字符串')
    .notEmpty()
    .withMessage('状态不能为空'),
  
  body('paidAt')
    .isISO8601()
    .withMessage('支付时间必须是有效的日期'),
  
  body('signature')
    .optional()
    .isString()
    .withMessage('签名必须是字符串'),
];

