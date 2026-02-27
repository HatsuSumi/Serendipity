import { User, UserSettings } from '@prisma/client';
export declare const createMockUser: (overrides?: Partial<User>) => User;
export declare const createMockUserSettings: (overrides?: Partial<UserSettings>) => UserSettings;
export declare const createMockJwtPayload: (overrides?: any) => any;
export declare const createMockRequest: (overrides?: any) => any;
export declare const createMockResponse: () => any;
export declare const createMockNext: () => jest.Mock<any, any, any>;
//# sourceMappingURL=factories.d.ts.map