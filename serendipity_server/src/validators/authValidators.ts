import { body } from 'express-validator';

// 邮箱注册验证规则
export const registerEmailValidation = [
  body('email')
    .isEmail()
    .withMessage('邮箱格式不正确'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('密码长度必须至少6位'),
];

// 手机号注册验证规则
export const registerPhoneValidation = [
  body('phoneNumber')
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('手机号格式不正确'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('密码长度必须至少6位'),
];

// 邮箱登录验证规则
export const loginEmailValidation = [
  body('email')
    .isEmail()
    .withMessage('邮箱格式不正确'),
  body('password')
    .notEmpty()
    .withMessage('密码不能为空'),
];

// 手机号登录验证规则
export const loginPhoneValidation = [
  body('phoneNumber')
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('手机号格式不正确'),
  body('password')
    .notEmpty()
    .withMessage('密码不能为空'),
];

// 发送验证码验证规则
export const sendVerificationCodeValidation = [
  body('type')
    .isIn(['email', 'phone'])
    .withMessage('类型必须是邮箱或手机号'),
  body('target')
    .notEmpty()
    .withMessage('目标不能为空'),
  body('purpose')
    .isIn(['register', 'login', 'reset_password'])
    .withMessage('用途不正确'),
];

// 重置密码验证规则
export const resetPasswordValidation = [
  body('email')
    .isEmail()
    .withMessage('邮箱格式不正确'),
  body('recoveryKey')
    .isLength({ min: 32, max: 64 })
    .withMessage('恢复密钥长度必须在32到64个字符之间'),
  body('newPassword')
    .isLength({ min: 6 })
    .withMessage('密码长度必须至少6位'),
];

// 刷新 Token 验证规则
export const refreshTokenValidation = [
  body('refreshToken')
    .notEmpty()
    .withMessage('刷新令牌不能为空'),
];

// 修改密码验证规则
export const changePasswordValidation = [
  body('currentPassword')
    .notEmpty()
    .withMessage('当前密码不能为空'),
  body('newPassword')
    .isLength({ min: 6 })
    .withMessage('新密码长度必须至少6位'),
];

// 更换邮箱验证规则
export const changeEmailValidation = [
  body('newEmail')
    .isEmail()
    .withMessage('邮箱格式不正确'),
  body('password')
    .notEmpty()
    .withMessage('密码不能为空'),
];

// 更换手机号验证规则
export const changePhoneValidation = [
  body('newPhoneNumber')
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('手机号格式不正确'),
  body('password')
    .notEmpty()
    .withMessage('密码不能为空'),
];
