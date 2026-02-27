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
    .withMessage('Display name must be a string')
    .isLength({ min: 1, max: 100 })
    .withMessage('Display name must be between 1 and 100 characters'),
  body('avatarUrl')
    .optional()
    .isURL()
    .withMessage('Avatar URL must be a valid URL'),
];

/**
 * 更新用户设置验证规则
 */
export const updateUserSettingsValidation = [
  body('theme')
    .optional()
    .isString()
    .withMessage('Theme must be a string')
    .isIn(['light', 'dark', 'system', 'misty', 'midnight', 'warm', 'autumn'])
    .withMessage('Invalid theme value'),
  body('pageTransition')
    .optional()
    .isString()
    .withMessage('Page transition must be a string'),
  body('dialogAnimation')
    .optional()
    .isString()
    .withMessage('Dialog animation must be a string'),
  body('notifications')
    .optional()
    .isObject()
    .withMessage('Notifications must be an object'),
  body('notifications.checkInReminder')
    .optional()
    .isBoolean()
    .withMessage('Check-in reminder must be a boolean'),
  body('notifications.checkInReminderTime')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('Check-in reminder time must be in HH:mm format'),
  body('notifications.achievementUnlocked')
    .optional()
    .isBoolean()
    .withMessage('Achievement unlocked must be a boolean'),
  body('checkIn')
    .optional()
    .isObject()
    .withMessage('Check-in must be an object'),
  body('checkIn.vibrationEnabled')
    .optional()
    .isBoolean()
    .withMessage('Vibration enabled must be a boolean'),
  body('checkIn.confettiEnabled')
    .optional()
    .isBoolean()
    .withMessage('Confetti enabled must be a boolean'),
];

