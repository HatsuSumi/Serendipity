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
    .withMessage('Amount must be a number')
    .isFloat({ min: 0, max: 648 })
    .withMessage('Amount must be between ¥0 and ¥648'),
  
  body('method')
    .isString()
    .withMessage('Payment method must be a string')
    .isIn([PaymentMethod.FREE, PaymentMethod.WECHAT, PaymentMethod.ALIPAY])
    .withMessage('Payment method must be one of: free, wechat, alipay'),
];

/**
 * 支付回调验证规则
 */
export const paymentCallbackSchema = [
  body('orderId')
    .isString()
    .withMessage('Order ID must be a string')
    .notEmpty()
    .withMessage('Order ID is required'),
  
  body('transactionId')
    .isString()
    .withMessage('Transaction ID must be a string')
    .notEmpty()
    .withMessage('Transaction ID is required'),
  
  body('amount')
    .isNumeric()
    .withMessage('Amount must be a number')
    .isFloat({ min: 0 })
    .withMessage('Amount must be at least 0'),
  
  body('status')
    .isString()
    .withMessage('Status must be a string')
    .notEmpty()
    .withMessage('Status is required'),
  
  body('paidAt')
    .isISO8601()
    .withMessage('Paid at must be a valid date'),
  
  body('signature')
    .optional()
    .isString()
    .withMessage('Signature must be a string'),
];

