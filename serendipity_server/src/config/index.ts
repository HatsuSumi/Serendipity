import dotenv from 'dotenv';

dotenv.config();

function getRequiredEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

function getOptionalEnv(key: string, defaultValue: string): string {
  return process.env[key] || defaultValue;
}

function getOptionalIntEnv(key: string, defaultValue: number): number {
  const raw = process.env[key];
  if (!raw) {
    return defaultValue;
  }

  const parsed = Number.parseInt(raw, 10);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`Invalid integer environment variable: ${key}`);
  }

  return parsed;
}

const isProduction = process.env.NODE_ENV === 'production';

export const config = Object.freeze({
  port: parseInt(getOptionalEnv('PORT', '3000'), 10),
  nodeEnv: getOptionalEnv('NODE_ENV', 'development'),

  database: Object.freeze({
    url: getRequiredEnv('DATABASE_URL'),
  }),

  jwt: Object.freeze({
    secret: isProduction
      ? getRequiredEnv('JWT_SECRET')
      : getOptionalEnv('JWT_SECRET', 'dev_jwt_secret_not_for_production'),
    expiresIn: getOptionalEnv('JWT_EXPIRES_IN', '7d'),
    refreshTokenExpiresIn: getOptionalEnv('REFRESH_TOKEN_EXPIRES_IN', '30d'),
  }),

  cors: Object.freeze({
    origin: getOptionalEnv('CORS_ORIGIN', '*'),
  }),

  payment: Object.freeze({
    enableMockMode: getOptionalEnv('PAYMENT_MOCK_MODE', 'true') === 'true',
    yungouos: Object.freeze({
      mchId: getOptionalEnv('YUNGOUOS_MCH_ID', ''),
      payKey: getOptionalEnv('YUNGOUOS_PAY_KEY', ''),
      appId: getOptionalEnv('YUNGOUOS_APP_ID', ''),
      notifyUrl: getOptionalEnv('YUNGOUOS_NOTIFY_URL', ''),
    }),
  }),

  checkInReminder: Object.freeze({
    enabled: getOptionalEnv('CHECKIN_REMINDER_ENABLED', 'true') === 'true',
    scanIntervalMs: getOptionalIntEnv('CHECKIN_REMINDER_SCAN_INTERVAL_MS', 60000),
    notificationTitle: getOptionalEnv('CHECKIN_REMINDER_NOTIFICATION_TITLE', '今晚别忘了签到'),
    notificationBody: getOptionalEnv('CHECKIN_REMINDER_NOTIFICATION_BODY', '打开 Serendipity 完成今日签到。'),
    fcm: Object.freeze({
      projectId: getOptionalEnv('FCM_PROJECT_ID', ''),
      clientEmail: getOptionalEnv('FCM_CLIENT_EMAIL', ''),
      privateKey: getOptionalEnv('FCM_PRIVATE_KEY', ''),
    }),
    apns: Object.freeze({
      keyId: getOptionalEnv('APNS_KEY_ID', ''),
      teamId: getOptionalEnv('APNS_TEAM_ID', ''),
      privateKey: getOptionalEnv('APNS_PRIVATE_KEY', ''),
      bundleId: getOptionalEnv('APNS_BUNDLE_ID', ''),
      production: getOptionalEnv('APNS_PRODUCTION', 'false') === 'true',
    }),
  }),
});
