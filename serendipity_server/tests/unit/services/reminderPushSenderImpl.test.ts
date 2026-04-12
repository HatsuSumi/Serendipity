import http2 from 'node:http2';
import jwt from 'jsonwebtoken';
import { ReminderPushSender } from '../../../src/services/reminderPushSenderImpl';

jest.mock('node:http2', () => ({
  __esModule: true,
  default: {
    connect: jest.fn(),
  },
}));

jest.mock('jsonwebtoken', () => ({
  __esModule: true,
  default: {
    sign: jest.fn(),
  },
}));

describe('ReminderPushSender', () => {
  const mockedHttp2 = http2 as jest.Mocked<typeof http2>;
  const mockedJwt = jwt as jest.Mocked<typeof jwt>;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    delete process.env.FCM_PROJECT_ID;
    delete process.env.FCM_CLIENT_EMAIL;
    delete process.env.FCM_PRIVATE_KEY;
    delete process.env.APNS_KEY_ID;
    delete process.env.APNS_TEAM_ID;
    delete process.env.APNS_PRIVATE_KEY;
    delete process.env.APNS_BUNDLE_ID;
    delete process.env.APNS_PRODUCTION;
  });

  it('FCM 未配置项目凭证时应该快速失败', async () => {
    process.env.FCM_PROJECT_ID = '';
    process.env.FCM_CLIENT_EMAIL = '';
    process.env.FCM_PRIVATE_KEY = '';

    const sender = new ReminderPushSender();

    const result = await sender.send({
      token: 'token-1',
      platform: 'android',
      title: 'title',
      body: 'body',
      data: { type: 'check_in_reminder' },
    });

    expect(result).toEqual({
      success: false,
      failureReason: 'fcm_project_id_missing',
    });
  });

  it('FCM 返回 UNREGISTERED 时应该识别为无效 token', async () => {
    process.env.FCM_PROJECT_ID = 'test-project';
    process.env.FCM_CLIENT_EMAIL = 'push@test.iam.gserviceaccount.com';
    process.env.FCM_PRIVATE_KEY = '-----BEGIN PRIVATE KEY-----\\nabc\\n-----END PRIVATE KEY-----';

    const sender = new ReminderPushSender();
    jest.spyOn(sender as any, 'getFcmAccessToken').mockResolvedValue('access-token');
    jest.spyOn(sender as any, 'requestJson').mockResolvedValue({
      statusCode: 404,
      headers: {},
      body: JSON.stringify({
        error: {
          status: 'NOT_FOUND',
          details: [{ errorCode: 'UNREGISTERED' }],
        },
      }),
    });

    const result = await sender.send({
      token: 'token-1',
      platform: 'android',
      title: 'title',
      body: 'body',
      data: { type: 'check_in_reminder' },
    });

    expect(result).toEqual({
      success: false,
      failureReason: 'UNREGISTERED',
      isInvalidToken: true,
    });
  });

  it('APNs 缺少配置时应该快速失败', async () => {
    const sender = new ReminderPushSender();

    const result = await sender.send({
      token: 'ios-token',
      platform: 'ios',
      title: 'title',
      body: 'body',
      data: { type: 'check_in_reminder' },
    });

    expect(result).toEqual({
      success: false,
      failureReason: 'apns_key_id_missing',
    });
  });

  it('APNs 成功发送时应该返回 providerMessageId', async () => {
    process.env.APNS_KEY_ID = 'key-id';
    process.env.APNS_TEAM_ID = 'team-id';
    process.env.APNS_PRIVATE_KEY = '-----BEGIN PRIVATE KEY-----\\nabc\\n-----END PRIVATE KEY-----';
    process.env.APNS_BUNDLE_ID = 'com.test.app';

    const close = jest.fn();
    mockedHttp2.connect.mockReturnValue({ close } as unknown as http2.ClientHttp2Session);
    mockedJwt.sign.mockReturnValue('provider-token' as never);

    const sender = new ReminderPushSender();
    jest
      .spyOn(sender as any, 'sendApnsRequest')
      .mockResolvedValue({ success: true, providerMessageId: 'apns-message-id' });

    const result = await sender.send({
      token: 'ios-token',
      platform: 'ios',
      title: 'title',
      body: 'body',
      data: { type: 'check_in_reminder' },
    });

    expect(mockedJwt.sign).toHaveBeenCalled();
    expect(mockedHttp2.connect).toHaveBeenCalledWith('https://api.sandbox.push.apple.com');
    expect(close).toHaveBeenCalledTimes(1);
    expect(result).toEqual({
      success: true,
      providerMessageId: 'apns-message-id',
    });
  });

  it('APNs 返回 Unregistered 时应该识别为无效 token', async () => {
    const sender = new ReminderPushSender();

    const result = (sender as any).buildApnsResult(410, '', '{"reason":"Unregistered"}');

    expect(result).toEqual({
      success: false,
      failureReason: 'Unregistered',
      isInvalidToken: true,
    });
  });
});
