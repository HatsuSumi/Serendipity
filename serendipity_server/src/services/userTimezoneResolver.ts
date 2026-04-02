import { IPushTokenRepository } from '../repositories/pushTokenRepository';

export interface IUserTimezoneResolver {
  resolveTimezone(userId: string): Promise<string | undefined>;
}

export class UserTimezoneResolver implements IUserTimezoneResolver {
  constructor(private readonly pushTokenRepository: IPushTokenRepository) {
    if (!pushTokenRepository) {
      throw new Error('PushTokenRepository is required');
    }
  }

  async resolveTimezone(userId: string): Promise<string | undefined> {
    if (!userId || userId.trim() === '') {
      throw new Error('userId is required');
    }

    const timezone = await this.pushTokenRepository.findLatestActiveTimezoneByUserId(userId);
    if (!timezone) {
      return undefined;
    }

    try {
      Intl.DateTimeFormat(undefined, { timeZone: timezone });
      return timezone;
    } catch {
      return undefined;
    }
  }
}

