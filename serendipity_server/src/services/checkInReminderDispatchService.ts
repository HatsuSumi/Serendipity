import { PushToken } from '@prisma/client';
import {
  IPushTokenRepository,
  ReminderCandidate,
} from '../repositories/pushTokenRepository';
import { ICheckInRepository } from '../repositories/checkInRepository';
import {
  buildCheckInReminderContent,
  calculateMaxConsecutiveDays,
  calculateReminderConsecutiveDays,
} from './checkInReminderContentBuilder';
import {
  IReminderPushSender,
  ReminderDispatchStatus,
  ReminderSendPayload,
  ReminderSendResult,
} from './reminderPushSender';
import {
  AnniversaryReminderTestPayload,
} from '../types/pushToken.dto';
import {
  DispatchExecutionOptions,
  PushReminderSchedulingSupport,
  ReminderDispatchCandidate,
  ReminderDispatchExecution,
  ReminderDispatchSummary,
} from './pushReminderSchedulingSupport';

export class CheckInReminderDispatchService {
  constructor(
    private readonly pushTokenRepository: IPushTokenRepository,
    private readonly checkInRepository: ICheckInRepository,
    private readonly reminderPushSender: IReminderPushSender,
    private readonly schedulingSupport: PushReminderSchedulingSupport,
  ) {
    if (!pushTokenRepository) {
      throw new Error('PushTokenRepository is required');
    }
    if (!checkInRepository) {
      throw new Error('CheckInRepository is required');
    }
    if (!reminderPushSender) {
      throw new Error('ReminderPushSender is required');
    }
    if (!schedulingSupport) {
      throw new Error('PushReminderSchedulingSupport is required');
    }
  }

  async getReminderDispatchCandidates(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<ReminderDispatchCandidate[]> {
    this.schedulingSupport.validateNow(now);
    const targetTimezones = this.schedulingSupport.normalizeTimezones(timezones);
    const repositoryCandidates = await this.pushTokenRepository.findReminderCandidates(targetTimezones);
    if (repositoryCandidates.length === 0) {
      return [];
    }

    const candidates: ReminderDispatchCandidate[] = [];
    for (const repositoryCandidate of repositoryCandidates) {
      const candidate = await this.buildReminderCandidate(repositoryCandidate, now);
      if (candidate) {
        candidates.push(candidate);
      }
    }

    return candidates;
  }

  async dispatchReminderNotifications(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<ReminderDispatchSummary> {
    const candidates = await this.getReminderDispatchCandidates(timezones, now);
    return this.dispatchReminderNotificationsForCandidates(candidates, undefined, {
      persistDispatch: true,
      dispatchSource: 'scheduler',
      dispatchType: 'check_in',
    });
  }

  async dispatchReminderNotificationsForUser(
    userId: string,
    pushTokens: PushToken[],
    now: Date = new Date(),
    overridePayload?: AnniversaryReminderTestPayload,
  ): Promise<ReminderDispatchSummary> {
    this.schedulingSupport.validateNow(now);

    const options: DispatchExecutionOptions = {
      persistDispatch: false,
      dispatchSource: 'manual_test',
      dispatchType: overridePayload == null ? 'check_in' : 'anniversary',
    };

    if (pushTokens.length === 0) {
      return this.schedulingSupport.createEmptyDispatchSummary(options, userId);
    }

    const candidates = pushTokens.map((pushToken) => ({
      userId,
      pushTokenId: pushToken.id,
      token: pushToken.token,
      platform: pushToken.platform,
      timezone: pushToken.timezone,
      reminderDate: now,
      reminderTime: 'manual_test',
    }));

    return this.dispatchReminderNotificationsForCandidates(candidates, overridePayload, options);
  }

  private async dispatchReminderNotificationsForCandidates(
    candidates: ReminderDispatchCandidate[],
    overridePayload: AnniversaryReminderTestPayload | undefined,
    options: DispatchExecutionOptions,
  ): Promise<ReminderDispatchSummary> {
    const executions: ReminderDispatchExecution[] = [];

    for (const candidate of candidates) {
      const payload = overridePayload != null
        ? this.buildOverrideReminderPayload(candidate, overridePayload)
        : await this.buildReminderPayload(candidate);
      const sendResult = await this.reminderPushSender.send(payload);
      const execution = await this.finalizeCheckInDispatch(candidate, sendResult, options);
      executions.push(execution);
    }

    return this.schedulingSupport.buildDispatchSummary(candidates.length, executions, options);
  }

  private async buildReminderCandidate(
    candidate: ReminderCandidate,
    now: Date,
  ): Promise<ReminderDispatchCandidate | null> {
    const reminderClock = this.schedulingSupport.parseReminderTime(candidate.reminderTime);
    if (!this.schedulingSupport.isWithinReminderWindow(now, candidate.timezone, reminderClock)) {
      return null;
    }

    const reminderDate = this.schedulingSupport.getCurrentDateInTimezone(candidate.timezone, now);
    const alreadyDispatched = await this.pushTokenRepository.hasReminderDispatch(
      candidate.pushTokenId,
      reminderDate,
    );
    if (alreadyDispatched) {
      return null;
    }

    const alreadyCheckedIn = await this.checkInRepository.findByUserAndDate(
      candidate.userId,
      reminderDate,
    );
    if (alreadyCheckedIn) {
      return null;
    }

    await this.pushTokenRepository.createReminderDispatch({
      userId: candidate.userId,
      pushTokenId: candidate.pushTokenId,
      reminderDate,
      status: ReminderDispatchStatus.Pending,
      provider: this.schedulingSupport.getProviderByPlatform(candidate.platform),
    });

    return {
      userId: candidate.userId,
      pushTokenId: candidate.pushTokenId,
      token: candidate.token,
      platform: candidate.platform,
      timezone: candidate.timezone,
      reminderDate,
      reminderTime: candidate.reminderTime,
    };
  }

  private async finalizeCheckInDispatch(
    candidate: ReminderDispatchCandidate,
    sendResult: ReminderSendResult,
    options: DispatchExecutionOptions,
  ): Promise<ReminderDispatchExecution> {
    if (sendResult.success) {
      if (options.persistDispatch) {
        await this.pushTokenRepository.markReminderDispatchSent(
          candidate.pushTokenId,
          candidate.reminderDate,
          new Date(),
        );
      }
      return {
        ...candidate,
        status: ReminderDispatchStatus.Sent,
      };
    }

    const failureReason = sendResult.failureReason?.trim() || 'push_send_failed';
    if (options.persistDispatch) {
      await this.pushTokenRepository.markReminderDispatchFailed(
        candidate.pushTokenId,
        candidate.reminderDate,
        failureReason,
      );
    }

    if (sendResult.isInvalidToken) {
      await this.pushTokenRepository.markInvalid(candidate.token, failureReason);
    }

    return {
      ...candidate,
      status: ReminderDispatchStatus.Failed,
      failureReason,
    };
  }

  private buildOverrideReminderPayload(
    candidate: ReminderDispatchCandidate,
    overridePayload: AnniversaryReminderTestPayload,
  ): ReminderSendPayload {
    if (overridePayload.title.trim() === '') {
      throw new Error('Reminder title is required');
    }
    if (overridePayload.body.trim() === '') {
      throw new Error('Reminder body is required');
    }

    return {
      token: candidate.token,
      platform: candidate.platform,
      title: overridePayload.title,
      body: overridePayload.body,
      data: {
        type: 'anniversary_reminder_test',
        userId: candidate.userId,
        reminderDate: candidate.reminderDate.toISOString(),
      },
    };
  }

  private async buildReminderPayload(candidate: ReminderDispatchCandidate): Promise<ReminderSendPayload> {
    const consecutiveDays = await this.getConsecutiveDays(candidate.userId, candidate.reminderDate);
    const maxConsecutiveDays = await this.getMaxConsecutiveDays(candidate.userId);
    const content = buildCheckInReminderContent({
      consecutiveDays,
      maxConsecutiveDays,
    });

    return {
      token: candidate.token,
      platform: candidate.platform,
      title: content.title,
      body: content.body,
      data: {
        type: 'check_in_reminder',
        userId: candidate.userId,
        reminderDate: candidate.reminderDate.toISOString(),
        reminderTime: candidate.reminderTime,
      },
    };
  }

  private async getConsecutiveDays(userId: string, reminderDate: Date): Promise<number> {
    const checkIns = await this.checkInRepository.findByUserId(userId);
    return calculateReminderConsecutiveDays(
      checkIns.map((checkIn) => checkIn.date),
      reminderDate,
    );
  }

  private async getMaxConsecutiveDays(userId: string): Promise<number> {
    const checkIns = await this.checkInRepository.findByUserId(userId);
    return calculateMaxConsecutiveDays(checkIns.map((checkIn) => checkIn.date));
  }
}

