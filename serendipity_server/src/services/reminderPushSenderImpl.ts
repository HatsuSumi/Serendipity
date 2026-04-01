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

const APNS_PRODUCTION_URL = 'https://api.push.apple.com';
const APNS_SANDBOX_URL = 'https://api.sandbox.push.apple.com';

interface FcmResponseBody {
  success?: number;
  results?: Array<{ message_id?: string; error?: string }>;
}

interface ApnsResponseBody {
  reason?: string;
}

interface RuntimeReminderConfig {
  fcmServerKey: string;
  fcmEndpoint: string;
  apnsKeyId: string;
  apnsTeamId: string;
  apnsPrivateKey: string;
  apnsBundleId: string;
  apnsProduction: boolean;
}

export class ReminderPushSender implements IReminderPushSender {
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
    if (runtimeConfig.fcmServerKey === '') {
      return {
        success: false,
        failureReason: 'fcm_server_key_missing',
      };
    }

    const response = await fetch(runtimeConfig.fcmEndpoint, {
      method: 'POST',
      headers: {
        ...JSON_HEADERS,
        Authorization: `key=${runtimeConfig.fcmServerKey}`,
      },
      body: JSON.stringify({
        to: payload.token,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data,
        priority: 'high',
      }),
    });

    if (!response.ok) {
      return {
        success: false,
        failureReason: `fcm_http_${response.status}`,
      };
    }

    const body = (await response.json()) as FcmResponseBody;
    const result = body.results?.[0];
    if (!result) {
      return {
        success: false,
        failureReason: 'fcm_empty_result',
      };
    }

    if (result.error) {
      return {
        success: false,
        failureReason: result.error,
        isInvalidToken: this.isFcmInvalidTokenError(result.error),
      };
    }

    if ((body.success ?? 0) < 1 || !result.message_id) {
      return {
        success: false,
        failureReason: 'fcm_unknown_failure',
      };
    }

    return {
      success: true,
      providerMessageId: result.message_id,
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
      fcmServerKey: process.env.FCM_SERVER_KEY?.trim() || config.checkInReminder.fcm.serverKey.trim(),
      fcmEndpoint: process.env.FCM_ENDPOINT?.trim() || config.checkInReminder.fcm.endpoint,
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

  private isFcmInvalidTokenError(errorCode: string): boolean {
    return errorCode === 'InvalidRegistration' || errorCode === 'NotRegistered';
  }

  private isApnsInvalidTokenError(errorCode?: string): boolean {
    return (
      errorCode === 'BadDeviceToken' ||
      errorCode === 'DeviceTokenNotForTopic' ||
      errorCode === 'Unregistered'
    );
  }
}
