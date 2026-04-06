import { config } from './config';
import { logger } from './utils/logger';
import { initializeContainer, shutdownContainer } from './config/container';
import { createApp } from './app';
import Container from './config/container';
import { TYPES } from './config/types';
import { IPushTokenService } from './services/pushTokenService';

const container = initializeContainer();
const app = createApp(container);
const PORT = config.port;

let reminderScanTimer: NodeJS.Timeout | null = null;
let isReminderScanRunning = false;

function startReminderScheduler(currentContainer: Container): void {
  if (!config.checkInReminder.enabled) {
    logger.info('Reminder scheduler disabled');
    return;
  }

  const pushTokenService = currentContainer.get<IPushTokenService>(TYPES.PushTokenService);
  reminderScanTimer = setInterval(() => {
    void runReminderScan(pushTokenService);
  }, config.checkInReminder.scanIntervalMs);

  logger.info('Reminder scheduler started', {
    scanIntervalMs: config.checkInReminder.scanIntervalMs,
  });
}

async function runReminderScan(pushTokenService: IPushTokenService): Promise<void> {
  if (isReminderScanRunning) {
    logger.warn('Reminder scan skipped because previous run is still active');
    return;
  }

  isReminderScanRunning = true;
  try {
    const [checkInSummary, anniversarySummary] = await Promise.all([
      pushTokenService.dispatchReminderNotifications(),
      pushTokenService.dispatchAnniversaryReminderNotifications(),
    ]);
    logger.info('Check-in reminder scan completed', checkInSummary);
    logger.info('Anniversary reminder scan completed', anniversarySummary);
  } catch (error) {
    logger.error('Reminder scan failed', error);
  } finally {
    isReminderScanRunning = false;
  }
}

const server = app.listen(PORT, () => {
  logger.info(`Server is running on port ${PORT}`);
  logger.info(`Environment: ${config.nodeEnv}`);
  logger.info(`Health check: http://localhost:${PORT}/api/v1/health`);
  startReminderScheduler(container);
});

const gracefulShutdown = async (signal: string) => {
  logger.info(`${signal} received, shutting down gracefully`);

  if (reminderScanTimer) {
    clearInterval(reminderScanTimer);
    reminderScanTimer = null;
  }

  server.close(async () => {
    logger.info('HTTP server closed');

    try {
      await shutdownContainer();
      logger.info('Graceful shutdown completed');
      process.exit(0);
    } catch (error) {
      logger.error('Error during shutdown:', error);
      process.exit(1);
    }
  });

  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => void gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => void gracefulShutdown('SIGINT'));

process.on('uncaughtException', (error: Error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason: unknown) => {
  logger.error('Unhandled Rejection:', reason);
  process.exit(1);
});
