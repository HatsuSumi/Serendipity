// 认证相关的 DTO（Data Transfer Object）

// 邮箱注册请求
export interface RegisterEmailDto {
  email: string;
  password: string;
  verificationCode?: string;
}

// 手机号注册请求
export interface RegisterPhoneDto {
  phoneNumber: string;
  password: string;
  verificationCode?: string;
}

// 邮箱登录请求
export interface LoginEmailDto {
  email: string;
  password: string;
}

// 手机号登录请求
export interface LoginPhoneDto {
  phoneNumber: string;
  password: string;
}

// 发送验证码请求
export interface SendVerificationCodeDto {
  type: 'email' | 'phone';
  target: string;
  purpose: 'register' | 'login' | 'reset_password';
}

// 重置密码请求
export interface ResetPasswordDto {
  email: string;
  recoveryKey: string;
  newPassword: string;
}

// 生成恢复密钥响应
export interface GenerateRecoveryKeyResponseDto {
  recoveryKey: string;
  message: string;
}

// 刷新 Token 请求
export interface RefreshTokenDto {
  refreshToken: string;
}

// 修改密码请求
export interface ChangePasswordDto {
  currentPassword: string;
  newPassword: string;
}

// 更换邮箱请求
export interface ChangeEmailDto {
  newEmail: string;
  password: string;
  verificationCode: string;
}

// 更换/绑定手机号请求
export interface ChangePhoneDto {
  newPhoneNumber: string;
  verificationCode: string;
}

// 认证响应
export interface AuthResponseDto {
  user: {
    id: string;
    email?: string;
    phoneNumber?: string;
    createdAt: Date;
  };
  tokens: {
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
    expiresAt: string; // ISO 8601 格式
  };
  recoveryKey?: string; // 仅在注册时返回一次
}

// 用户信息响应
export interface UserMeDto {
  id: string;
  email?: string;
  phoneNumber?: string;
  displayName?: string;
  createdAt: Date;
  membership: {
    tier: string;
    status: string;
    expiresAt?: Date;
  };
}

