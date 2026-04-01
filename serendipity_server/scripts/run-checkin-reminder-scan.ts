import { initializeContainer, shutdownContainer } from '../src/config/container';
import { TYPES } from '../src/config/types';
import { IPushTokenService } from '../src/services/pushTokenService';
import { logger } from '../src/utils/logger';

function parseTimezonesArg(argv: string[]): string[] | undefined {
  const raw = argv.find((arg) => arg.startsWith('--timezones='));
  if (!raw) {
    return undefined;
  }

  const value = raw.slice('--timezones='.length).trim();
  if (value === '') {
    return undefined;
  }

  return value
    .split(',')
    .map((timezone) => timezone.trim())
    .filter((timezone) => timezone.length > 0);
}

async function main(): Promise<void> {
  const container = initializeContainer();

  try {
    const pushTokenService = container.get<IPushTokenService>(TYPES.PushTokenService);
    const timezones = parseTimezonesArg(process.argv.slice(2));
    const summary = await pushTokenService.dispatchReminderNotifications(timezones);

    logger.info('Check-in reminder dispatch completed', summary);
  } finally {
    await shutdownContainer();
  }
}

main().catch((error) => {
  logger.error('Check-in reminder dispatch failed', error);
  process.exit(1);
});
