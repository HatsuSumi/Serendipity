import { body } from 'express-validator';

// 邮箱注册验证规则
export const registerEmailValidation = [
  body('email')
    .isEmail()
    .withMessage('Invalid email format'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
  body('verificationCode')
    .isLength({ min: 6, max: 6 })
    .withMessage('Verification code must be 6 digits'),
];

// 手机号注册验证规则
export const registerPhoneValidation = [
  body('phoneNumber')
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('Invalid phone number format'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
  body('verificationCode')
    .isLength({ min: 6, max: 6 })
    .withMessage('Verification code must be 6 digits'),
];

// 邮箱登录验证规则
export const loginEmailValidation = [
  body('email')
    .isEmail()
    .withMessage('Invalid email format'),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
];

// 手机号登录验证规则
export const loginPhoneValidation = [
  body('phoneNumber')
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('Invalid phone number format'),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
];

// 发送验证码验证规则
export const sendVerificationCodeValidation = [
  body('type')
    .isIn(['email', 'phone'])
    .withMessage('Type must be email or phone'),
  body('target')
    .notEmpty()
    .withMessage('Target is required'),
  body('purpose')
    .isIn(['register', 'login', 'reset_password'])
    .withMessage('Invalid purpose'),
];

// 重置密码验证规则
export const resetPasswordValidation = [
  body('email')
    .isEmail()
    .withMessage('Invalid email format'),
  body('verificationCode')
    .isLength({ min: 6, max: 6 })
    .withMessage('Verification code must be 6 digits'),
  body('newPassword')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
];

// 刷新 Token 验证规则
export const refreshTokenValidation = [
  body('refreshToken')
    .notEmpty()
    .withMessage('Refresh token is required'),
];

// 修改密码验证规则
export const changePasswordValidation = [
  body('currentPassword')
    .notEmpty()
    .withMessage('Current password is required'),
  body('newPassword')
    .isLength({ min: 6 })
    .withMessage('New password must be at least 6 characters'),
];

// 更换邮箱验证规则
export const changeEmailValidation = [
  body('newEmail')
    .isEmail()
    .withMessage('Invalid email format'),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
  body('verificationCode')
    .isLength({ min: 6, max: 6 })
    .withMessage('Verification code must be 6 digits'),
];

// 更换手机号验证规则
export const changePhoneValidation = [
  body('newPhoneNumber')
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('Invalid phone number format'),
  body('verificationCode')
    .isLength({ min: 6, max: 6 })
    .withMessage('Verification code must be 6 digits'),
];
