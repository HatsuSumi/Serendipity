import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import winston from 'winston';
import { JwtService } from '../services/jwtService';
import { AuthService } from '../services/authService';
import { VerificationService } from '../services/verificationService';
import { UserRepository } from '../repositories/userRepository';
import { RefreshTokenRepository } from '../repositories/refreshTokenRepository';
import { VerificationCodeRepository } from '../repositories/verificationCodeRepository';
import { RecordRepository } from '../repositories/recordRepository';
import { StoryLineRepository } from '../repositories/storyLineRepository';
import { CommunityPostRepository } from '../repositories/communityPostRepository';
import { UserSettingsRepository } from '../repositories/userSettingsRepository';
import { AuthController } from '../controllers/authController';
import { RecordController } from '../controllers/recordController';
import { StoryLineController } from '../controllers/storyLineController';
import { CommunityPostController } from '../controllers/communityPostController';
import { UserController } from '../controllers/userController';
import { RecordService } from '../services/recordService';
import { StoryLineService } from '../services/storyLineService';
import { CommunityPostService } from '../services/communityPostService';
import { UserService } from '../services/userService';
import { PaymentOrderRepository } from '../repositories/paymentOrderRepository';
import { MembershipRepository } from '../repositories/membershipRepository';
import { PaymentService } from '../services/paymentService';
import { PaymentController } from '../controllers/paymentController';
import { config } from '../config';
import path from 'path';

// 依赖容器
class Container {
  private static instance: Container;
  private services: Map<string, unknown> = new Map();

  private constructor() {}

  static getInstance(): Container {
    if (!Container.instance) {
      Container.instance = new Container();
    }
    return Container.instance;
  }

  register<T>(name: string, service: T): void {
    this.services.set(name, service);
  }

  get<T>(name: string): T {
    const service = this.services.get(name);
    if (!service) {
      throw new Error(`Service ${name} not found in container`);
    }
    return service as T;
  }

  has(name: string): boolean {
    return this.services.has(name);
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

  container.register('logger', logger);

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

  container.register('database', prisma);
  container.register('pool', pool);

  // 初始化 JWT Service
  const jwtService = new JwtService();
  container.register('jwtService', jwtService);

  // 初始化 Repositories
  const userRepository = new UserRepository(prisma);
  const refreshTokenRepository = new RefreshTokenRepository(prisma);
  const verificationCodeRepository = new VerificationCodeRepository(prisma);
  const recordRepository = new RecordRepository(prisma);
  const storyLineRepository = new StoryLineRepository(prisma);
  const communityPostRepository = new CommunityPostRepository(prisma);
  const paymentOrderRepository = new PaymentOrderRepository(prisma);
  const membershipRepository = new MembershipRepository(prisma);
  const userSettingsRepository = new UserSettingsRepository(prisma);

  container.register('userRepository', userRepository);
  container.register('refreshTokenRepository', refreshTokenRepository);
  container.register('verificationCodeRepository', verificationCodeRepository);
  container.register('recordRepository', recordRepository);
  container.register('storyLineRepository', storyLineRepository);
  container.register('communityPostRepository', communityPostRepository);
  container.register('paymentOrderRepository', paymentOrderRepository);
  container.register('membershipRepository', membershipRepository);
  container.register('userSettingsRepository', userSettingsRepository);

  // 初始化 Services
  const verificationService = new VerificationService(verificationCodeRepository);
  const authService = new AuthService(
    userRepository,
    refreshTokenRepository,
    verificationService,
    jwtService
  );
  const recordService = new RecordService(recordRepository);
  const storyLineService = new StoryLineService(storyLineRepository);
  const communityPostService = new CommunityPostService(communityPostRepository);
  const paymentService = new PaymentService(
    paymentOrderRepository,
    membershipRepository,
    logger
  );
  const userService = new UserService(userRepository, userSettingsRepository);

  container.register('verificationService', verificationService);
  container.register('authService', authService);
  container.register('recordService', recordService);
  container.register('storyLineService', storyLineService);
  container.register('communityPostService', communityPostService);
  container.register('paymentService', paymentService);
  container.register('userService', userService);

  // 初始化 Controllers
  const authController = new AuthController(authService, verificationService);
  const recordController = new RecordController(recordService);
  const storyLineController = new StoryLineController(storyLineService);
  const communityPostController = new CommunityPostController(communityPostService);
  const paymentController = new PaymentController(paymentService, logger);
  const userController = new UserController(userService);

  container.register('authController', authController);
  container.register('recordController', recordController);
  container.register('storyLineController', storyLineController);
  container.register('communityPostController', communityPostController);
  container.register('paymentController', paymentController);
  container.register('userController', userController);

  return container;
};

// 优雅关闭所有服务
export const shutdownContainer = async (): Promise<void> => {
  const container = Container.getInstance();
  
  if (container.has('database')) {
    const prisma = container.get<PrismaClient>('database');
    await prisma.$disconnect();
  }

  if (container.has('pool')) {
    const pool = container.get<Pool>('pool');
    await pool.end();
  }

  if (container.has('logger')) {
    const logger = container.get<winston.Logger>('logger');
    logger.info('All services shut down');
  }
};

export default Container;

