import { AnniversaryReminderCandidate, IPushTokenRepository } from '../repositories/pushTokenRepository';
import {
  IReminderPushSender,
  ReminderDispatchStatus,
  ReminderSendResult,
} from './reminderPushSender';
import {
  DispatchExecutionOptions,
  PushReminderSchedulingSupport,
  ReminderDispatchCandidate,
  ReminderDispatchExecution,
  ReminderDispatchSummary,
} from './pushReminderSchedulingSupport';

interface AnniversaryDispatchExecutionContext {
  pushTokenId: string;
  recordId: string;
  reminderDate: Date;
}

export class AnniversaryReminderDispatchService {
  constructor(
    private readonly pushTokenRepository: IPushTokenRepository,
    private readonly reminderPushSender: IReminderPushSender,
    private readonly schedulingSupport: PushReminderSchedulingSupport,
  ) {
    if (!pushTokenRepository) {
      throw new Error('PushTokenRepository is required');
    }
    if (!reminderPushSender) {
      throw new Error('ReminderPushSender is required');
    }
    if (!schedulingSupport) {
      throw new Error('PushReminderSchedulingSupport is required');
    }
  }

  async dispatchAnniversaryReminderNotifications(
    timezones?: string[],
    now: Date = new Date(),
  ): Promise<ReminderDispatchSummary> {
    this.schedulingSupport.validateNow(now);
    const targetTimezones = this.schedulingSupport.normalizeTimezones(timezones);
    const repositoryCandidates = await this.pushTokenRepository.findAnniversaryReminderCandidates(
      targetTimezones,
      now,
    );
    if (repositoryCandidates.length === 0) {
      return this.schedulingSupport.createEmptyDispatchSummary({
        persistDispatch: true,
        dispatchSource: 'scheduler',
        dispatchType: 'anniversary',
      });
    }

    const candidates = repositoryCandidates.filter((candidate) =>
      this.shouldDispatchAnniversaryReminder(candidate, now),
    );

    return this.dispatchAnniversaryReminderCandidates(candidates, {
      persistDispatch: true,
      dispatchSource: 'scheduler',
      dispatchType: 'anniversary',
    });
  }

  private async dispatchAnniversaryReminderCandidates(
    candidates: AnniversaryReminderCandidate[],
    options: DispatchExecutionOptions,
  ): Promise<ReminderDispatchSummary> {
    const executions: ReminderDispatchExecution[] = [];

    for (const candidate of candidates) {
      const reminderDate = this.schedulingSupport.getCurrentDateInTimezone(
        candidate.timezone,
        candidate.reminderDate,
      );
      const alreadyDispatched = await this.pushTokenRepository.hasAnniversaryReminderDispatch(
        candidate.pushTokenId,
        candidate.record.id,
        reminderDate,
      );
      if (alreadyDispatched) {
        continue;
      }

      await this.pushTokenRepository.createAnniversaryReminderDispatch({
        userId: candidate.userId,
        pushTokenId: candidate.pushTokenId,
        recordId: candidate.record.id,
        reminderDate,
        status: ReminderDispatchStatus.Pending,
        provider: this.schedulingSupport.getProviderByPlatform(candidate.platform),
      });

      const sendResult = await this.reminderPushSender.send(
        this.buildAnniversaryReminderPayload(candidate, reminderDate),
      );
      const execution = await this.finalizeAnniversaryDispatch(
        {
          userId: candidate.userId,
          pushTokenId: candidate.pushTokenId,
          token: candidate.token,
          platform: candidate.platform,
          timezone: candidate.timezone,
          reminderDate,
          reminderTime: 'anniversary',
        },
        sendResult,
        {
          pushTokenId: candidate.pushTokenId,
          recordId: candidate.record.id,
          reminderDate,
        },
        options,
      );
      executions.push(execution);
    }

    return this.schedulingSupport.buildDispatchSummary(candidates.length, executions, options);
  }

  private buildAnniversaryReminderPayload(
    candidate: AnniversaryReminderCandidate,
    reminderDate: Date,
  ) {
    return {
      token: candidate.token,
      platform: candidate.platform,
      title: '今天是一个特别的纪念日 🌸',
      body: this.buildAnniversaryReminderBody(candidate.record.timestamp, reminderDate),
      data: {
        type: 'anniversary_reminder',
        userId: candidate.userId,
        reminderDate: reminderDate.toISOString(),
        recordId: candidate.record.id,
      },
    };
  }

  private buildAnniversaryReminderBody(timestamp: Date, reminderDate: Date): string {
    const years = Math.max(reminderDate.getUTCFullYear() - timestamp.getUTCFullYear(), 1);
    return `${years}年前的今天，你在某个地方邂逅了TA`;
  }

  private shouldDispatchAnniversaryReminder(
    candidate: AnniversaryReminderCandidate,
    now: Date,
  ): boolean {
    const localizedNow = this.schedulingSupport.getLocalizedNow(now, candidate.timezone);
    const localizedTimestamp = this.schedulingSupport.getLocalizedNow(candidate.record.timestamp, candidate.timezone);

    return localizedTimestamp.getUTCMonth() === localizedNow.getUTCMonth()
      && localizedTimestamp.getUTCDate() === localizedNow.getUTCDate();
  }

  private async finalizeAnniversaryDispatch(
    candidate: ReminderDispatchCandidate,
    sendResult: ReminderSendResult,
    context: AnniversaryDispatchExecutionContext,
    options: DispatchExecutionOptions,
  ): Promise<ReminderDispatchExecution> {
    if (sendResult.success) {
      if (options.persistDispatch) {
        await this.pushTokenRepository.markAnniversaryReminderDispatchSent(
          context.pushTokenId,
          context.recordId,
          context.reminderDate,
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
      await this.pushTokenRepository.markAnniversaryReminderDispatchFailed(
        context.pushTokenId,
        context.recordId,
        context.reminderDate,
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
}

