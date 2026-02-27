import dotenv from 'dotenv';

dotenv.config();

// 验证必需的环境变量
function getRequiredEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

// 获取可选的环境变量
function getOptionalEnv(key: string, defaultValue: string): string {
  return process.env[key] || defaultValue;
}

// 生产环境必须配置的变量
const isProduction = process.env.NODE_ENV === 'production';

// 配置对象（不可变）
export const config = Object.freeze({
  // 服务器配置
  port: parseInt(getOptionalEnv('PORT', '3000'), 10),
  nodeEnv: getOptionalEnv('NODE_ENV', 'development'),

  // 数据库配置（必需）
  database: Object.freeze({
    url: getRequiredEnv('DATABASE_URL'),
  }),

  // Redis 配置
  redis: Object.freeze({
    host: getOptionalEnv('REDIS_HOST', 'localhost'),
    port: parseInt(getOptionalEnv('REDIS_PORT', '6379'), 10),
    db: parseInt(getOptionalEnv('REDIS_DB', '0'), 10),
  }),

  // JWT 配置
  jwt: Object.freeze({
    // 生产环境必须配置 JWT_SECRET
    secret: isProduction
      ? getRequiredEnv('JWT_SECRET')
      : getOptionalEnv('JWT_SECRET', 'dev_jwt_secret_not_for_production'),
    expiresIn: getOptionalEnv('JWT_EXPIRES_IN', '7d'),
    refreshTokenExpiresIn: getOptionalEnv('REFRESH_TOKEN_EXPIRES_IN', '30d'),
  }),

  // CORS 配置
  cors: Object.freeze({
    origin: getOptionalEnv('CORS_ORIGIN', '*'),
  }),

  // 支付配置
  payment: Object.freeze({
    // 是否启用 Mock 支付（开发/测试环境使用）
    enableMockMode: getOptionalEnv('PAYMENT_MOCK_MODE', 'true') === 'true',
    
    // YunGouOS 配置（真实支付时使用）
    yungouos: Object.freeze({
      mchId: getOptionalEnv('YUNGOUOS_MCH_ID', ''),
      payKey: getOptionalEnv('YUNGOUOS_PAY_KEY', ''),
      appId: getOptionalEnv('YUNGOUOS_APP_ID', ''),
      notifyUrl: getOptionalEnv('YUNGOUOS_NOTIFY_URL', ''),
    }),
  }),
});

