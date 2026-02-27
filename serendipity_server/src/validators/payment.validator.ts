/**
 * 支付相关的验证规则
 */

import Joi from 'joi';
import { PaymentMethod } from '../types/payment.dto';

/**
 * 创建支付订单验证规则
 */
export const createPaymentSchema = Joi.object({
  amount: Joi.number()
    .min(0)
    .max(648)
    .required()
    .messages({
      'number.base': 'Amount must be a number',
      'number.min': 'Amount must be at least ¥0',
      'number.max': 'Amount must be at most ¥648',
      'any.required': 'Amount is required',
    }),
  method: Joi.string()
    .valid(PaymentMethod.FREE, PaymentMethod.WECHAT, PaymentMethod.ALIPAY)
    .required()
    .messages({
      'string.base': 'Payment method must be a string',
      'any.only': 'Payment method must be one of: free, wechat, alipay',
      'any.required': 'Payment method is required',
    }),
});

/**
 * 支付回调验证规则
 */
export const paymentCallbackSchema = Joi.object({
  orderId: Joi.string()
    .required()
    .messages({
      'string.base': 'Order ID must be a string',
      'any.required': 'Order ID is required',
    }),
  transactionId: Joi.string()
    .required()
    .messages({
      'string.base': 'Transaction ID must be a string',
      'any.required': 'Transaction ID is required',
    }),
  amount: Joi.number()
    .min(0)
    .required()
    .messages({
      'number.base': 'Amount must be a number',
      'number.min': 'Amount must be at least 0',
      'any.required': 'Amount is required',
    }),
  status: Joi.string()
    .required()
    .messages({
      'string.base': 'Status must be a string',
      'any.required': 'Status is required',
    }),
  paidAt: Joi.date()
    .required()
    .messages({
      'date.base': 'Paid at must be a valid date',
      'any.required': 'Paid at is required',
    }),
  signature: Joi.string()
    .optional()
    .messages({
      'string.base': 'Signature must be a string',
    }),
});

