import http2 from 'node:http2';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import {
  IReminderPushSender,
  ReminderSendPayload,
  ReminderSendResult,
} from './reminderPushSender';

const JSON_HEADERS = {
  'Content-Type': 'application/json',
};

const FCM_OAUTH_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const FCM_TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';
const APNS_PRODUCTION_URL = 'https://api.push.apple.com';
const APNS_SANDBOX_URL = 'https://api.sandbox.push.apple.com';

interface FcmV1SuccessResponseBody {
  name?: string;
}

interface ApnsResponseBody {
  reason?: string;
}

interface GoogleAccessTokenResponseBody {
  access_token?: string;
  expires_in?: number;
}

interface RuntimeReminderConfig {
  fcmProjectId: string;
  fcmClientEmail: string;
  fcmPrivateKey: string;
  apnsKeyId: string;
  apnsTeamId: string;
  apnsPrivateKey: string;
  apnsBundleId: string;
  apnsProduction: boolean;
}

export class ReminderPushSender implements IReminderPushSender {
  private fcmAccessTokenCache:
    | {
        accessToken: string;
        expiresAt: number;
      }
    | null = null;

  async send(payload: ReminderSendPayload): Promise<ReminderSendResult> {
    if (!payload.token || payload.token.trim() === '') {
      throw new Error('Push token is required');
    }
    if (payload.platform !== 'android' && payload.platform !== 'ios') {
      throw new Error(`Unsupported push platform: ${payload.platform}`);
    }

    const runtimeConfig = this.getRuntimeConfig();

    return payload.platform === 'android'
      ? this.sendFcm(payload, runtimeConfig)
      : this.sendApns(payload, runtimeConfig);
  }

  private async sendFcm(
    payload: ReminderSendPayload,
    runtimeConfig: RuntimeReminderConfig,
  ): Promise<ReminderSendResult> {
    if (runtimeConfig.fcmProjectId === '') {
      return {
        success: false,
        failureReason: 'fcm_project_id_missing',
      };
    }
    if (runtimeConfig.fcmClientEmail === '') {
      return {
        success: false,
        failureReason: 'fcm_client_email_missing',
      };
    }
    if (runtimeConfig.fcmPrivateKey === '') {
      return {
        success: false,
        failureReason: 'fcm_private_key_missing',
      };
    }

    const accessToken = await this.getFcmAccessToken(runtimeConfig);
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${runtimeConfig.fcmProjectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          ...JSON_HEADERS,
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: payload.token,
            notification: {
              title: payload.title,
              body: payload.body,
            },
            data: payload.data,
            android: {
              priority: 'high',
              notification: {
                channel_id: 'check_in_reminder',
                sound: 'default',
              },
            },
          },
        }),
      },
    );

    if (!response.ok) {
      const rawBody = await response.text();
      return {
        success: false,
        failureReason: this.parseFcmV1FailureReason(response.status, rawBody),
        isInvalidToken: this.isFcmInvalidTokenResponse(response.status, rawBody),
      };
    }

    const body = (await response.json()) as FcmV1SuccessResponseBody;
    if (!body.name) {
      return {
        success: false,
        failureReason: 'fcm_empty_result',
      };
    }

    return {
      success: true,
      providerMessageId: body.name,
    };
  }

  private async sendApns(
    payload: ReminderSendPayload,
    runtimeConfig: RuntimeReminderConfig,
  ): Promise<ReminderSendResult> {
    if (runtimeConfig.apnsKeyId === '') {
      return {
        success: false,
        failureReason: 'apns_key_id_missing',
      };
    }
    if (runtimeConfig.apnsTeamId === '') {
      return {
        success: false,
        failureReason: 'apns_team_id_missing',
      };
    }
    if (runtimeConfig.apnsBundleId === '') {
      return {
        success: false,
        failureReason: 'apns_bundle_id_missing',
      };
    }
    if (runtimeConfig.apnsPrivateKey === '') {
      return {
        success: false,
        failureReason: 'apns_private_key_missing',
      };
    }

    const providerToken = jwt.sign({}, runtimeConfig.apnsPrivateKey, {
      algorithm: 'ES256',
      issuer: runtimeConfig.apnsTeamId,
      header: {
        alg: 'ES256',
        kid: runtimeConfig.apnsKeyId,
      },
    });

    const url = runtimeConfig.apnsProduction ? APNS_PRODUCTION_URL : APNS_SANDBOX_URL;
    const client = http2.connect(url);

    try {
      return await this.sendApnsRequest(client, providerToken, runtimeConfig.apnsBundleId, payload);
    } finally {
      client.close();
    }
  }

  private sendApnsRequest(
    client: http2.ClientHttp2Session,
    providerToken: string,
    bundleId: string,
    payload: ReminderSendPayload,
  ): Promise<ReminderSendResult> {
    return new Promise((resolve, reject) => {
      const request = client.request({
        ':method': 'POST',
        ':path': `/3/device/${payload.token}`,
        authorization: `bearer ${providerToken}`,
        'apns-topic': bundleId,
        'apns-push-type': 'alert',
        'apns-priority': '10',
        ...JSON_HEADERS,
      });

      let statusCode = 0;
      let apnsId = '';
      let body = '';

      request.setEncoding('utf8');
      request.on('response', (headers) => {
        statusCode = Number(headers[':status'] ?? 0);
        apnsId = this.readHeaderValue(headers['apns-id']);
      });
      request.on('data', (chunk: string) => {
        body += chunk;
      });
      request.on('end', () => {
        resolve(this.buildApnsResult(statusCode, apnsId, body));
      });
      request.on('error', reject);

      request.end(
        JSON.stringify({
          aps: {
            alert: {
              title: payload.title,
              body: payload.body,
            },
            sound: 'default',
          },
          ...payload.data,
        }),
      );
    });
  }

  private buildApnsResult(
    statusCode: number,
    apnsId: string,
    rawBody: string,
  ): ReminderSendResult {
    if (statusCode === 200) {
      return {
        success: true,
        providerMessageId: apnsId || undefined,
      };
    }

    const reason = this.parseApnsReason(rawBody);
    return {
      success: false,
      failureReason: reason || `apns_http_${statusCode}`,
      isInvalidToken: this.isApnsInvalidTokenError(reason),
    };
  }

  private getRuntimeConfig(): RuntimeReminderConfig {
    return {
      fcmProjectId: process.env.FCM_PROJECT_ID?.trim() || config.checkInReminder.fcm.projectId.trim(),
      fcmClientEmail: process.env.FCM_CLIENT_EMAIL?.trim() || config.checkInReminder.fcm.clientEmail.trim(),
      fcmPrivateKey: this.normalizePrivateKey(
        process.env.FCM_PRIVATE_KEY || config.checkInReminder.fcm.privateKey,
      ),
      apnsKeyId: process.env.APNS_KEY_ID?.trim() || config.checkInReminder.apns.keyId.trim(),
      apnsTeamId: process.env.APNS_TEAM_ID?.trim() || config.checkInReminder.apns.teamId.trim(),
      apnsPrivateKey: this.normalizePrivateKey(
        process.env.APNS_PRIVATE_KEY || config.checkInReminder.apns.privateKey,
      ),
      apnsBundleId: process.env.APNS_BUNDLE_ID?.trim() || config.checkInReminder.apns.bundleId.trim(),
      apnsProduction:
        process.env.APNS_PRODUCTION === 'true' ||
        (process.env.APNS_PRODUCTION ? false : config.checkInReminder.apns.production),
    };
  }

  private parseApnsReason(rawBody: string): string | undefined {
    if (rawBody.trim() === '') {
      return undefined;
    }

    try {
      const parsed = JSON.parse(rawBody) as ApnsResponseBody;
      return parsed.reason;
    } catch {
      return undefined;
    }
  }

  private async getFcmAccessToken(runtimeConfig: RuntimeReminderConfig): Promise<string> {
    const now = Date.now();
    if (this.fcmAccessTokenCache && this.fcmAccessTokenCache.expiresAt > now + 60_000) {
      return this.fcmAccessTokenCache.accessToken;
    }

    const issuedAt = Math.floor(now / 1000);
    const expiresAt = issuedAt + 3600;
    const assertion = jwt.sign(
      {
        iss: runtimeConfig.fcmClientEmail,
        sub: runtimeConfig.fcmClientEmail,
        aud: FCM_TOKEN_ENDPOINT,
        scope: FCM_OAUTH_SCOPE,
        iat: issuedAt,
        exp: expiresAt,
      },
      runtimeConfig.fcmPrivateKey,
      {
        algorithm: 'RS256',
      },
    );

    const response = await fetch(FCM_TOKEN_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
    });

    if (!response.ok) {
      throw new Error(`Failed to acquire FCM access token: ${response.status}`);
    }

    const body = (await response.json()) as GoogleAccessTokenResponseBody;
    if (!body.access_token || !body.expires_in) {
      throw new Error('FCM access token response is invalid');
    }

    this.fcmAccessTokenCache = {
      accessToken: body.access_token,
      expiresAt: now + body.expires_in * 1000,
    };

    return body.access_token;
  }

  private parseFcmV1FailureReason(statusCode: number, rawBody: string): string {
    try {
      const parsed = JSON.parse(rawBody) as {
        error?: {
          status?: string;
          message?: string;
          details?: Array<{ errorCode?: string }>;
        };
      };
      const errorCode = parsed.error?.details?.find((detail) => detail.errorCode)?.errorCode;
      if (errorCode) {
        return errorCode;
      }
      if (parsed.error?.status) {
        return parsed.error.status;
      }
      if (parsed.error?.message) {
        return parsed.error.message;
      }
    } catch {
      // ignore parse failure and fallback below
    }

    return `fcm_http_${statusCode}`;
  }

  private isFcmInvalidTokenResponse(statusCode: number, rawBody: string): boolean {
    if (statusCode !== 400 && statusCode !== 404) {
      return false;
    }

    const reason = this.parseFcmV1FailureReason(statusCode, rawBody);
    return reason === 'UNREGISTERED' || reason === 'INVALID_ARGUMENT';
  }

  private readHeaderValue(value: string | string[] | undefined): string {
    if (typeof value === 'string') {
      return value;
    }
    if (Array.isArray(value)) {
      return value[0] ?? '';
    }
    return '';
  }

  private normalizePrivateKey(privateKey: string): string {
    return privateKey.trim().replace(/\\n/g, '\n');
  }

  private isApnsInvalidTokenError(errorCode?: string): boolean {
    return (
      errorCode === 'BadDeviceToken' ||
      errorCode === 'DeviceTokenNotForTopic' ||
      errorCode === 'Unregistered'
    );
  }
}
