import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { logger } from './logger';
import { config } from '../config';

const pool = new Pool({
  connectionString: config.database.url,
  max: 20, // 最大连接数
  idleTimeoutMillis: 30000, // 空闲连接超时
  connectionTimeoutMillis: 2000, // 连接超时
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
prisma.$on('query', (e) => {
  logger.debug('Query:', { query: e.query, params: e.params, duration: e.duration });
});

prisma.$on('error', (e) => {
  logger.error('Prisma error:', e);
});

prisma.$on('warn', (e) => {
  logger.warn('Prisma warning:', e);
});

// 优雅关闭
export const disconnectPrisma = async (): Promise<void> => {
  await prisma.$disconnect();
  await pool.end();
  logger.info('Database connections closed');
};

export default prisma;

