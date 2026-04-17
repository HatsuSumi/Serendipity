import { PushToken } from '@prisma/client';
import {
  IPushTokenRepository,
  RegisterPushTokenData,
} from '../repositories/pushTokenRepository';
import { ICheckInRepository } from '../repositories/checkInRepository';
import { IUserRepository } from '../repositories/userRepository';
import { IReminderPushSender } from './reminderPushSender';
import { AnniversaryReminderTestPayload } from '../types/pushToken.dto';
import {
  PushReminderSchedulingSupport,
  ReminderDispatchCandidate,
  ReminderDispatchSummary,
} from './pushReminderSchedulingSupport';
import { PushTokenManagementService } from './pushTokenManagementService';
import { CheckInReminderDispatchService } from './checkInReminderDispatchService';
import { AnniversaryReminderDispatchService } from './anniversaryReminderDispatchService';

export type {
  ReminderDispatchCandidate,
  ReminderDispatchExecution,
  ReminderDispatchSummary,
} from './pushReminderSchedulingSupport';

export interface IPushTokenService {
  registerPushToken(userId: string, data: RegisterPushTokenData): Promise<PushToken>;
  unregisterPushToken(userId: string, token: string): Promise<void>;
  markPushTokenInvalid(token: string, reason: string): Promise<void>;
  listPushTokens(userId: string): Promise<PushToken[]>;
  getReminderDispatchCandidates(timezones?: string[], now?: Date): Promise<ReminderDispatchCandidate[]>;
  dispatchReminderNotifications(timezones?: string[], now?: Date): Promise<ReminderDispatchSummary>;
  dispatchAnniversaryReminderNotifications(timezones?: string[], now?: Date): Promise<ReminderDispatchSummary>;
  dispatchReminderNotificationsForUser(
    userId: string,
    now?: Date,
    overridePayload?: AnniversaryReminderTestPayload,
  ): Promise<ReminderDispatchSummary>;
}

export class PushTokenService implements IPushTokenService {
  private readonly managementService: PushTokenManagementService;
  private readonly checkInDispatchService: CheckInReminderDispatchService;
  private readonly anniversaryDispatchService: AnniversaryReminderDispatchService;

  constructor(
    private readonly pushTokenRepository: IPushTokenRepository,
    checkInRepository: ICheckInRepository,
    userRepository: IUserRepository,
    reminderPushSender: IReminderPushSender,
  ) {
    if (!pushTokenRepository) {
      throw new Error('PushTokenRepository is required');
    }
    if (!checkInRepository) {
      throw new Error('CheckInRepository is required');
    }
    if (!userRepository) {
      throw new Error('UserRepository is required');
    }
    if (!reminderPushSender) {
      throw new Error('ReminderPushSender is required');
    }

    const schedulingSupport = new PushReminderSchedulingSupport();
    this.managementService = new PushTokenManagementService(pushTokenRepository, userRepository);
    this.checkInDispatchService = new CheckInReminderDispatchService(
      pushTokenRepository,
      checkInRepository,
      reminderPushSender,
      schedulingSupport,
    );
    this.anniversaryDispatchService = new AnniversaryReminderDispatchService(
      pushTokenRepository,
      reminderPushSender,
      schedulingSupport,
    );
  }

  registerPushToken(userId: string, data: RegisterPushTokenData): Promise<PushToken> {
    return this.managementService.registerPushToken(userId, data);
  }

  unregisterPushToken(userId: string, token: string): Promise<void> {
    return this.managementService.unregisterPushToken(userId, token);
  }

  markPushTokenInvalid(token: string, reason: string): Promise<void> {
    return this.managementService.markPushTokenInvalid(token, reason);
  }

  listPushTokens(userId: string): Promise<PushToken[]> {
    return this.managementService.listPushTokens(userId);
  }

  getReminderDispatchCandidates(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<ReminderDispatchCandidate[]> {
    return this.checkInDispatchService.getReminderDispatchCandidates(timezones, now);
  }

  dispatchReminderNotifications(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<ReminderDispatchSummary> {
    return this.checkInDispatchService.dispatchReminderNotifications(timezones, now);
  }

  dispatchAnniversaryReminderNotifications(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<ReminderDispatchSummary> {
    return this.anniversaryDispatchService.dispatchAnniversaryReminderNotifications(timezones, now);
  }

  async dispatchReminderNotificationsForUser(
    userId: string,
    now: Date = new Date(),
    overridePayload?: AnniversaryReminderTestPayload,
  ): Promise<ReminderDispatchSummary> {
    await this.managementService.ensureUserExists(userId);
    const pushTokens = await this.pushTokenRepository.findActiveByUserId(userId);
    return this.checkInDispatchService.dispatchReminderNotificationsForUser(
      userId,
      pushTokens,
      now,
      overridePayload,
    );
  }
}
