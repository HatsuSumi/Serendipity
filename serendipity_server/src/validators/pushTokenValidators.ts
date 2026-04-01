import { body } from 'express-validator';

export const registerPushTokenValidation = [
  body('token')
    .isString()
    .withMessage('推送令牌必须是字符串')
    .notEmpty()
    .withMessage('推送令牌不能为空'),
  body('platform')
    .isString()
    .withMessage('平台必须是字符串')
    .isIn(['android', 'ios'])
    .withMessage('平台必须是 android 或 ios'),
  body('timezone')
    .isString()
    .withMessage('时区必须是字符串')
    .notEmpty()
    .withMessage('时区不能为空'),
];

export const unregisterPushTokenValidation = [
  body('token')
    .isString()
    .withMessage('推送令牌必须是字符串')
    .notEmpty()
    .withMessage('推送令牌不能为空'),
];
