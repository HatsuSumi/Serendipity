/**
 * 用户相关的验证规则
 */

import { body } from 'express-validator';

/**
 * 更新用户信息验证规则
 */
export const updateUserValidation = [
  body('displayName')
    .optional()
    .isString()
    .withMessage('显示名称必须是字符串')
    .isLength({ min: 1, max: 100 })
    .withMessage('显示名称长度必须在1到100个字符之间'),
  body('avatarUrl')
    .optional()
    .isURL()
    .withMessage('头像URL必须是有效的URL'),
];

/**
 * 更新用户设置验证规则
 */
export const activateMembershipValidation = [
  body('monthlyAmount')
    .exists()
    .withMessage('月支持金额不能为空')
    .isFloat({ min: 0, max: 648 })
    .withMessage('月支持金额必须在0到648之间'),
];

/**
 * 更新用户设置验证规则
 */
export const updateUserSettingsValidation = [
  body('theme')
    .optional()
    .isString()
    .withMessage('主题必须是字符串')
    .isIn(['light', 'dark', 'system', 'misty', 'midnight', 'warm', 'autumn'])
    .withMessage('主题值不正确'),
  body('pageTransition')
    .optional()
    .isString()
    .withMessage('页面跳转动画必须是字符串'),
  body('dialogAnimation')
    .optional()
    .isString()
    .withMessage('对话框动画必须是字符串'),
  body('notifications')
    .optional()
    .isObject()
    .withMessage('通知设置必须是对象'),
  body('notifications.checkInReminder')
    .optional()
    .isBoolean()
    .withMessage('签到提醒必须是布尔值'),
  body('notifications.checkInReminderTime')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('签到提醒时间必须是HH:mm格式'),
  body('notifications.achievementUnlocked')
    .optional()
    .isBoolean()
    .withMessage('成就解锁通知必须是布尔值'),
  body('checkIn')
    .optional()
    .isObject()
    .withMessage('签到设置必须是对象'),
  body('checkIn.vibrationEnabled')
    .optional()
    .isBoolean()
    .withMessage('震动开关必须是布尔值'),
  body('checkIn.confettiEnabled')
    .optional()
    .isBoolean()
    .withMessage('粒子特效开关必须是布尔值'),
];

