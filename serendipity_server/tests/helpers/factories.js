"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createMockNext = exports.createMockResponse = exports.createMockRequest = exports.createMockJwtPayload = exports.createMockUserSettings = exports.createMockUser = void 0;
// Mock 用户工厂
const createMockUser = (overrides) => ({
    id: 'test-user-id',
    email: 'test@example.com',
    phoneNumber: null,
    passwordHash: '$2b$10$hashedpassword',
    displayName: 'Test User',
    avatarUrl: null,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    lastLoginAt: null,
    ...overrides,
});
exports.createMockUser = createMockUser;
// Mock 用户设置工厂
const createMockUserSettings = (overrides) => ({
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
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
});
exports.createMockUserSettings = createMockUserSettings;
// Mock JWT Payload
const createMockJwtPayload = (overrides) => ({
    userId: 'test-user-id',
    email: 'test@example.com',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60,
    ...overrides,
});
exports.createMockJwtPayload = createMockJwtPayload;
// Mock Request
const createMockRequest = (overrides) => ({
    body: {},
    params: {},
    query: {},
    headers: {},
    user: undefined,
    ...overrides,
});
exports.createMockRequest = createMockRequest;
// Mock Response
const createMockResponse = () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    res.send = jest.fn().mockReturnValue(res);
    return res;
};
exports.createMockResponse = createMockResponse;
// Mock Next Function
const createMockNext = () => jest.fn();
exports.createMockNext = createMockNext;
//# sourceMappingURL=factories.js.map