/**
 * 认证配置常量
 * 使用 Object.freeze 确保不可变性
 */
export const AUTH_CONFIG = Object.freeze({
  /**
   * 密码哈希盐轮数
   */
  SALT_ROUNDS: 10,

  /**
   * 刷新令牌过期天数
   */
  REFRESH_TOKEN_EXPIRY_DAYS: 30,

  /**
   * 访问令牌过期秒数（7天）
   */
  ACCESS_TOKEN_EXPIRY_SECONDS: 7 * 24 * 60 * 60,

  /**
   * 验证码过期分钟数
   */
  VERIFICATION_CODE_EXPIRY_MINUTES: 10,

  /**
   * 验证码长度
   */
  VERIFICATION_CODE_LENGTH: 6,

  /**
   * 恢复密钥字节数
   */
  RECOVERY_KEY_BYTES: 16,

  /**
   * 恢复密钥分组长度
   */
  RECOVERY_KEY_GROUP_LENGTH: 4,
} as const);

/**
 * 认证配置类型
 */
export type AuthConfig = typeof AUTH_CONFIG;

