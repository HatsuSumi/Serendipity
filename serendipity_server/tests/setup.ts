// Jest 测试环境设置
import '@testing-library/jest-dom';

// 设置环境变量
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing-only';
process.env.JWT_EXPIRES_IN = '7d';
process.env.JWT_REFRESH_TOKEN_EXPIRES_IN = '30d';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test_db';
process.env.PORT = '3000';
process.env.CORS_ORIGIN = 'http://localhost:3000';

// 全局测试超时
jest.setTimeout(10000);

// Mock console 方法（减少测试输出噪音）
const consoleMock = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};

global.console = consoleMock as Console;

