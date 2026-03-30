import { User, UserSettings } from '@prisma/client';

// Mock 用户工厂
export const createMockUser = (overrides?: Partial<User>): User => ({
  id: 'test-user-id',
  email: 'test@example.com',
  phoneNumber: null,
  passwordHash: '$2b$10$hashedpassword',
  authProvider: 'email',
  recoveryKey: null,
  displayName: 'Test User',
  avatarUrl: null,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
  lastLoginAt: null,
  ...overrides,
});

// Mock 用户设置工厂
export const createMockUserSettings = (overrides?: Partial<UserSettings>): UserSettings => ({
  id: 'test-settings-id',
  userId: 'test-user-id',
  theme: 'system',
  pageTransition: 'slide_from_right',
  dialogAnimation: 'fade_in',
  notifications: {
    checkInReminder: false,
    checkInReminderTime: '20:00',
    achievementUnlocked: true,
  },
  checkIn: {
    vibrationEnabled: true,
    confettiEnabled: true,
  },
  hasSeenCommunityIntro: false,
  hasSeenPublishWarning: false,
  hasSeenFavoritesIntro: false,
  hidePublishWarning: false,
  themeUpdatedAt: new Date('2026-01-01'),
  notificationsUpdatedAt: new Date('2026-01-01'),
  checkInUpdatedAt: new Date('2026-01-01'),
  communityUpdatedAt: new Date('2026-01-01'),
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
  ...overrides,
});

// Mock JWT Payload
export const createMockJwtPayload = (overrides?: any) => ({
  userId: 'test-user-id',
  email: 'test@example.com',
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60,
  ...overrides,
});

// Mock Request
export const createMockRequest = (overrides?: any) => ({
  body: {},
  params: {},
  query: {},
  headers: {},
  user: undefined,
  ...overrides,
});

// Mock Response
export const createMockResponse = () => {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  return res;
};

// Mock Next Function
export const createMockNext = () => jest.fn();

