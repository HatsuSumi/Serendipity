import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import winston from 'winston';
import { JwtService } from '../services/jwtService';
import { AuthService } from '../services/authService';
import { VerificationService } from '../services/verificationService';
import { BcryptPasswordHasher } from '../services/passwordHasher';
import { UserRepository } from '../repositories/userRepository';
import { RefreshTokenRepository } from '../repositories/refreshTokenRepository';
import { VerificationCodeRepository } from '../repositories/verificationCodeRepository';
import { RecordRepository } from '../repositories/recordRepository';
import { StoryLineRepository } from '../repositories/storyLineRepository';
import { CommunityPostRepository } from '../repositories/communityPostRepository';
import { UserSettingsRepository } from '../repositories/userSettingsRepository';
import { MembershipRepository } from '../repositories/membershipRepository';
import { CheckInRepository } from '../repositories/checkInRepository';
import { AchievementUnlockRepository } from '../repositories/achievementUnlockRepository';
import { AuthController } from '../controllers/authController';
import { RecordController } from '../controllers/recordController';
import { StoryLineController } from '../controllers/storyLineController';
import { CommunityPostController } from '../controllers/communityPostController';
import { UserController } from '../controllers/userController';
import { CheckInController } from '../controllers/checkInController';
import { AchievementUnlockController } from '../controllers/achievementUnlockController';
import { FavoriteRepository } from '../repositories/favoriteRepository';
import { FavoriteService } from '../services/favoriteService';
import { FavoriteController } from '../controllers/favoriteController';
import { StatisticsRepository } from '../repositories/statisticsRepository';
import { StatisticsService } from '../services/statisticsService';
import { StatisticsController } from '../controllers/statisticsController';
import { RecordService } from '../services/recordService';
import { StoryLineService } from '../services/storyLineService';
import { CommunityPostService } from '../services/communityPostService';
import { UserService } from '../services/userService';
import { CheckInService } from '../services/checkInService';
import { AchievementUnlockService } from '../services/achievementUnlockService';
import { config } from '../config';
import { AUTH_CONFIG } from '../config/auth.config';
import { TYPES } from '../config/types';
import path from 'path';

// 依赖容器
class Container {
  private static instance: Container;
  private services: Map<symbol, unknown> = new Map();

  private constructor() {}

  static getInstance(): Container {
    if (!Container.instance) {
      Container.instance = new Container();
    }
    return Container.instance;
  }

  register<T>(key: symbol, service: T): void {
    this.services.set(key, service);
  }

  get<T>(key: symbol): T {
    const service = this.services.get(key);
    if (!service) {
      throw new Error(`Service ${String(key)} not found in container`);
    }
    return service as T;
  }

  has(key: symbol): boolean {
    return this.services.has(key);
  }
}

// 初始化所有服务
export const initializeContainer = (): Container => {
  const container = Container.getInstance();

  // 初始化 Logger
  const logFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  );

  const consoleFormat = winston.format.combine(
    winston.format.colorize(),
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message, ...meta }) => {
      let msg = `${timestamp} [${level}]: ${message}`;
      if (Object.keys(meta).length > 0) {
        msg += ` ${JSON.stringify(meta)}`;
      }
      return msg;
    })
  );

  const logger = winston.createLogger({
    level: config.nodeEnv === 'production' ? 'info' : 'debug',
    format: logFormat,
    transports: [
      new winston.transports.File({
        filename: path.join('logs', 'error.log'),
        level: 'error',
        maxsize: 5242880,
        maxFiles: 5,
      }),
      new winston.transports.File({
        filename: path.join('logs', 'combined.log'),
        maxsize: 5242880,
        maxFiles: 5,
      }),
    ],
  });

  if (config.nodeEnv !== 'production') {
    logger.add(new winston.transports.Console({ format: consoleFormat }));
  }

  container.register(TYPES.Logger, logger);

  // 初始化 Database
  const pool = new Pool({
    connectionString: config.database.url,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  });

  const adapter = new PrismaPg(pool);
  const prisma = new PrismaClient({
    adapter,
    log: [
      { level: 'query', emit: 'event' },
      { level: 'error', emit: 'event' },
      { level: 'warn', emit: 'event' },
    ],
  });

  // 日志记录
  prisma.$on('query', (e: { query: string; params: string; duration: number }) => {
    logger.debug('Query:', { query: e.query, params: e.params, duration: e.duration });
  });

  prisma.$on('error', (e: { message: string; target?: string }) => {
    logger.error('Prisma error:', e);
  });

  prisma.$on('warn', (e: { message: string; target?: string }) => {
    logger.warn('Prisma warning:', e);
  });

  container.register(TYPES.Database, prisma);
  container.register(TYPES.Pool, pool);

  // 初始化 JWT Service
  const jwtService = new JwtService();
  container.register(TYPES.JwtService, jwtService);

  // 初始化 Password Hasher
  const passwordHasher = new BcryptPasswordHasher(AUTH_CONFIG.SALT_ROUNDS);
  container.register(TYPES.PasswordHasher, passwordHasher);

  // 初始化 Repositories
  const userRepository = new UserRepository(prisma);
  const refreshTokenRepository = new RefreshTokenRepository(prisma);
  const verificationCodeRepository = new VerificationCodeRepository(prisma);
  const recordRepository = new RecordRepository(prisma);
  const storyLineRepository = new StoryLineRepository(prisma);
  const communityPostRepository = new CommunityPostRepository(prisma);
  const membershipRepository = new MembershipRepository(prisma);
  const userSettingsRepository = new UserSettingsRepository(prisma);
  const checkInRepository = new CheckInRepository(prisma);
  const achievementUnlockRepository = new AchievementUnlockRepository(prisma);
  const favoriteRepository = new FavoriteRepository(prisma);
  const statisticsRepository = new StatisticsRepository(prisma);

  container.register(TYPES.UserRepository, userRepository);
  container.register(TYPES.RefreshTokenRepository, refreshTokenRepository);
  container.register(TYPES.VerificationCodeRepository, verificationCodeRepository);
  container.register(TYPES.RecordRepository, recordRepository);
  container.register(TYPES.StoryLineRepository, storyLineRepository);
  container.register(TYPES.CommunityPostRepository, communityPostRepository);
  container.register(TYPES.MembershipRepository, membershipRepository);
  container.register(TYPES.UserSettingsRepository, userSettingsRepository);
  container.register(TYPES.CheckInRepository, checkInRepository);
  container.register(TYPES.AchievementUnlockRepository, achievementUnlockRepository);
  container.register(TYPES.FavoriteRepository, favoriteRepository);
  container.register(TYPES.StatisticsRepository, statisticsRepository);

  // 初始化 Services
  const verificationService = new VerificationService(verificationCodeRepository);
  const authService = new AuthService(
    userRepository,
    refreshTokenRepository,
    jwtService,
    passwordHasher,
    membershipRepository
  );
  const recordService = new RecordService(recordRepository);
  const storyLineService = new StoryLineService(storyLineRepository);
  const communityPostService = new CommunityPostService(communityPostRepository);
  const userService = new UserService(userRepository, userSettingsRepository);
  const checkInService = new CheckInService(checkInRepository);
  const achievementUnlockService = new AchievementUnlockService(achievementUnlockRepository);
  const favoriteService = new FavoriteService(favoriteRepository, communityPostRepository, recordRepository);
  const statisticsService = new StatisticsService(statisticsRepository);

  container.register(TYPES.VerificationService, verificationService);
  container.register(TYPES.AuthService, authService);
  container.register(TYPES.RecordService, recordService);
  container.register(TYPES.StoryLineService, storyLineService);
  container.register(TYPES.CommunityPostService, communityPostService);
  container.register(TYPES.UserService, userService);
  container.register(TYPES.CheckInService, checkInService);
  container.register(TYPES.AchievementUnlockService, achievementUnlockService);
  container.register(TYPES.FavoriteService, favoriteService);
  container.register(TYPES.StatisticsService, statisticsService);

  // 初始化 Controllers
  const authController = new AuthController(authService, verificationService);
  const recordController = new RecordController(recordService);
  const storyLineController = new StoryLineController(storyLineService);
  const communityPostController = new CommunityPostController(communityPostService);
  const userController = new UserController(userService);
  const checkInController = new CheckInController(checkInService);
  const achievementUnlockController = new AchievementUnlockController(achievementUnlockService);
  const favoriteController = new FavoriteController(favoriteService);
  const statisticsController = new StatisticsController(statisticsService);

  container.register(TYPES.AuthController, authController);
  container.register(TYPES.RecordController, recordController);
  container.register(TYPES.StoryLineController, storyLineController);
  container.register(TYPES.CommunityPostController, communityPostController);
  container.register(TYPES.UserController, userController);
  container.register(TYPES.CheckInController, checkInController);
  container.register(TYPES.AchievementUnlockController, achievementUnlockController);
  container.register(TYPES.FavoriteController, favoriteController);
  container.register(TYPES.StatisticsController, statisticsController);

  return container;
};

// 优雅关闭所有服务
export const shutdownContainer = async (): Promise<void> => {
  const container = Container.getInstance();
  
  if (container.has(TYPES.Database)) {
    const prisma = container.get<PrismaClient>(TYPES.Database);
    await prisma.$disconnect();
  }

  if (container.has(TYPES.Pool)) {
    const pool = container.get<Pool>(TYPES.Pool);
    await pool.end();
  }

  if (container.has(TYPES.Logger)) {
    const logger = container.get<winston.Logger>(TYPES.Logger);
    logger.info('All services shut down');
  }
};

export default Container;

