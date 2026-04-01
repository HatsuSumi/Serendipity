import { PushTokenService } from '../../../src/services/pushTokenService';
import { IPushTokenRepository } from '../../../src/repositories/pushTokenRepository';
import { ICheckInRepository } from '../../../src/repositories/checkInRepository';
import { IUserRepository } from '../../../src/repositories/userRepository';
import { createMockUser } from '../../helpers/factories';
import { ErrorCode } from '../../../src/types/errors';
import {
  IReminderPushSender,
  ReminderDispatchStatus,
} from '../../../src/services/reminderPushSender';

describe('PushTokenService', () => {
  let pushTokenService: PushTokenService;
  let mockPushTokenRepository: jest.Mocked<IPushTokenRepository>;
  let mockCheckInRepository: jest.Mocked<ICheckInRepository>;
  let mockUserRepository: jest.Mocked<IUserRepository>;
  let mockReminderPushSender: jest.Mocked<IReminderPushSender>;

  beforeEach(() => {
    mockPushTokenRepository = {
      register: jest.fn(),
      deactivateByToken: jest.fn(),
      markInvalid: jest.fn(),
      findActiveByUserId: jest.fn(),
      findReminderCandidates: jest.fn(),
      hasReminderDispatch: jest.fn(),
      createReminderDispatch: jest.fn(),
      markReminderDispatchSent: jest.fn(),
      markReminderDispatchFailed: jest.fn(),
    };

    mockCheckInRepository = {
      create: jest.fn(),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByUserAndDate: jest.fn(),
      deleteById: jest.fn(),
    };

    mockUserRepository = {
      findById: jest.fn(),
      findByEmail: jest.fn(),
      findByPhone: jest.fn(),
      findByEmailAndRecoveryKey: jest.fn(),
      create: jest.fn(),
      updateLastLogin: jest.fn(),
      updateUser: jest.fn(),
      updateDisplayName: jest.fn(),
      updateAvatarUrl: jest.fn(),
      bindEmail: jest.fn(),
      bindPhone: jest.fn(),
      updatePassword: jest.fn(),
      updateRecoveryKey: jest.fn(),
      deleteById: jest.fn(),
    };

    mockReminderPushSender = {
      send: jest.fn(),
    };

    pushTokenService = new PushTokenService(
      mockPushTokenRepository,
      mockCheckInRepository,
      mockUserRepository,
      mockReminderPushSender,
    );
  });

  describe('registerPushToken', () => {
    it('应该成功注册推送令牌', async () => {
      const user = createMockUser();
      const data = {
        token: 'test-token',
        platform: 'android',
        timezone: 'Asia/Shanghai',
      };
      const pushToken = {
        id: 'push-token-id',
        userId: user.id,
        token: data.token,
        platform: data.platform,
        timezone: data.timezone,
        isActive: true,
        lastUsedAt: new Date('2026-04-01T12:00:00.000Z'),
        invalidatedAt: null,
        invalidReason: null,
        createdAt: new Date('2026-04-01T12:00:00.000Z'),
        updatedAt: new Date('2026-04-01T12:00:00.000Z'),
      };

      mockUserRepository.findById.mockResolvedValue(user);
      mockPushTokenRepository.register.mockResolvedValue(pushToken as any);

      const result = await pushTokenService.registerPushToken(user.id, data);

      expect(mockPushTokenRepository.register).toHaveBeenCalledWith(user.id, data);
      expect(result.token).toBe(data.token);
    });

    it('时区非法时应该快速失败', async () => {
      mockUserRepository.findById.mockResolvedValue(createMockUser());

      await expect(
        pushTokenService.registerPushToken('test-user-id', {
          token: 'test-token',
          platform: 'android',
          timezone: 'Invalid/Timezone',
        }),
      ).rejects.toMatchObject({
        code: ErrorCode.INVALID_REQUEST,
      });
    });
  });

  describe('getReminderDispatchCandidates', () => {
    it('应该只返回命中提醒时间窗口且未签到未派发的候选项', async () => {
      const now = new Date('2026-04-01T12:00:00.000Z');
      mockPushTokenRepository.findReminderCandidates.mockResolvedValue([
        {
          userId: 'user-1',
          pushTokenId: 'token-1',
          token: 'push-token-1',
          platform: 'android',
          timezone: 'Asia/Shanghai',
          reminderTime: '20:00',
        },
        {
          userId: 'user-2',
          pushTokenId: 'token-2',
          token: 'push-token-2',
          platform: 'ios',
          timezone: 'Asia/Shanghai',
          reminderTime: '20:01',
        },
      ]);
      mockPushTokenRepository.hasReminderDispatch.mockResolvedValue(false);
      mockCheckInRepository.findByUserAndDate.mockResolvedValue(null);
      mockPushTokenRepository.createReminderDispatch.mockResolvedValue({} as any);

      const result = await pushTokenService.getReminderDispatchCandidates(['Asia/Shanghai'], now);

      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        userId: 'user-1',
        pushTokenId: 'token-1',
        platform: 'android',
        timezone: 'Asia/Shanghai',
        reminderTime: '20:00',
      });
      expect(result[0].reminderDate.toISOString()).toBe('2026-04-01T00:00:00.000Z');
      expect(mockPushTokenRepository.createReminderDispatch).toHaveBeenCalledTimes(1);
      expect(mockPushTokenRepository.findReminderCandidates).toHaveBeenCalledWith(['Asia/Shanghai']);
    });

    it('未传时区过滤时应该扫描所有启用提醒的设备', async () => {
      const now = new Date('2026-04-01T12:00:00.000Z');
      mockPushTokenRepository.findReminderCandidates.mockResolvedValue([]);

      const result = await pushTokenService.getReminderDispatchCandidates(undefined, now);

      expect(result).toEqual([]);
      expect(mockPushTokenRepository.findReminderCandidates).toHaveBeenCalledWith(undefined);
    });

    it('同一设备当天已派发时不应重复返回', async () => {
      const now = new Date('2026-04-01T12:00:00.000Z');
      mockPushTokenRepository.findReminderCandidates.mockResolvedValue([
        {
          userId: 'user-1',
          pushTokenId: 'token-1',
          token: 'push-token-1',
          platform: 'android',
          timezone: 'Asia/Shanghai',
          reminderTime: '20:00',
        },
      ]);
      mockPushTokenRepository.hasReminderDispatch.mockResolvedValue(true);

      const result = await pushTokenService.getReminderDispatchCandidates(['Asia/Shanghai'], now);

      expect(result).toEqual([]);
      expect(mockCheckInRepository.findByUserAndDate).not.toHaveBeenCalled();
      expect(mockPushTokenRepository.createReminderDispatch).not.toHaveBeenCalled();
    });

    it('用户今日已签到时不应返回提醒候选项', async () => {
      const now = new Date('2026-04-01T12:00:00.000Z');
      mockPushTokenRepository.findReminderCandidates.mockResolvedValue([
        {
          userId: 'user-1',
          pushTokenId: 'token-1',
          token: 'push-token-1',
          platform: 'android',
          timezone: 'Asia/Shanghai',
          reminderTime: '20:00',
        },
      ]);
      mockPushTokenRepository.hasReminderDispatch.mockResolvedValue(false);
      mockCheckInRepository.findByUserAndDate.mockResolvedValue({ id: 'check-in-id' } as any);

      const result = await pushTokenService.getReminderDispatchCandidates(['Asia/Shanghai'], now);

      expect(result).toEqual([]);
      expect(mockPushTokenRepository.createReminderDispatch).not.toHaveBeenCalled();
    });

    it('时区过滤为空数组时应该退化为全量时区扫描', async () => {
      mockPushTokenRepository.findReminderCandidates.mockResolvedValue([]);

      const result = await pushTokenService.getReminderDispatchCandidates([]);

      expect(result).toEqual([]);
      expect(mockPushTokenRepository.findReminderCandidates).toHaveBeenCalledWith(undefined);
    });

    it('时区过滤包含空白项时应该清洗后再查询', async () => {
      mockPushTokenRepository.findReminderCandidates.mockResolvedValue([]);

      const result = await pushTokenService.getReminderDispatchCandidates([' Asia/Shanghai ', '', 'Asia/Tokyo']);

      expect(result).toEqual([]);
      expect(mockPushTokenRepository.findReminderCandidates).toHaveBeenCalledWith(['Asia/Shanghai', 'Asia/Tokyo']);
    });

    it('当前时间非法时应该快速失败', async () => {
      await expect(
        pushTokenService.getReminderDispatchCandidates(undefined, new Date('invalid')),
      ).rejects.toThrow('Invalid current time');
    });

    it('提醒时间格式非法时应该快速失败', async () => {
      const now = new Date('2026-04-01T12:00:00.000Z');
      mockPushTokenRepository.findReminderCandidates.mockResolvedValue([
        {
          userId: 'user-1',
          pushTokenId: 'token-1',
          token: 'push-token-1',
          platform: 'android',
          timezone: 'Asia/Shanghai',
          reminderTime: '8pm',
        },
      ]);

      await expect(
        pushTokenService.getReminderDispatchCandidates(['Asia/Shanghai'], now),
      ).rejects.toThrow('Invalid reminder time: 8pm');
    });
  });

  describe('dispatchReminderNotifications', () => {
    it('发送成功后应该更新为 sent', async () => {
      const now = new Date('2026-04-01T12:00:00.000Z');
      mockPushTokenRepository.findReminderCandidates.mockResolvedValue([
        {
          userId: 'user-1',
          pushTokenId: 'token-1',
          token: 'push-token-1',
          platform: 'android',
          timezone: 'Asia/Shanghai',
          reminderTime: '20:00',
        },
      ]);
      mockPushTokenRepository.hasReminderDispatch.mockResolvedValue(false);
      mockCheckInRepository.findByUserAndDate.mockResolvedValue(null);
      mockPushTokenRepository.createReminderDispatch.mockResolvedValue({} as any);
      mockReminderPushSender.send.mockResolvedValue({
        success: true,
        providerMessageId: 'fcm-1',
      });

      const result = await pushTokenService.dispatchReminderNotifications(['Asia/Shanghai'], now);

      expect(mockPushTokenRepository.markReminderDispatchSent).toHaveBeenCalledTimes(1);
      expect(mockPushTokenRepository.markReminderDispatchFailed).not.toHaveBeenCalled();
      expect(result.sentCount).toBe(1);
      expect(result.failedCount).toBe(0);
      expect(result.executions[0].status).toBe(ReminderDispatchStatus.Sent);
    });

    it('发送失败后应该更新为 failed 并失效无效 token', async () => {
      const now = new Date('2026-04-01T12:00:00.000Z');
      mockPushTokenRepository.findReminderCandidates.mockResolvedValue([
        {
          userId: 'user-1',
          pushTokenId: 'token-1',
          token: 'push-token-1',
          platform: 'android',
          timezone: 'Asia/Shanghai',
          reminderTime: '20:00',
        },
      ]);
      mockPushTokenRepository.hasReminderDispatch.mockResolvedValue(false);
      mockCheckInRepository.findByUserAndDate.mockResolvedValue(null);
      mockPushTokenRepository.createReminderDispatch.mockResolvedValue({} as any);
      mockReminderPushSender.send.mockResolvedValue({
        success: false,
        failureReason: 'NotRegistered',
        isInvalidToken: true,
      });

      const result = await pushTokenService.dispatchReminderNotifications(['Asia/Shanghai'], now);

      expect(mockPushTokenRepository.markReminderDispatchFailed).toHaveBeenCalledWith(
        'token-1',
        new Date('2026-04-01T00:00:00.000Z'),
        'NotRegistered',
      );
      expect(mockPushTokenRepository.markInvalid).toHaveBeenCalledWith('push-token-1', 'NotRegistered');
      expect(result.sentCount).toBe(0);
      expect(result.failedCount).toBe(1);
      expect(result.executions[0].status).toBe(ReminderDispatchStatus.Failed);
      expect(result.executions[0].failureReason).toBe('NotRegistered');
    });
  });
});
