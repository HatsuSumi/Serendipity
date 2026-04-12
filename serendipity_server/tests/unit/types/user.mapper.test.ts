import { createMockUser } from '../../helpers/factories';
import { toAuthUserDto, toUserProfileDto } from '../../../src/types/user.mapper';

describe('user.mapper', () => {
  it('应该让认证 DTO 与资料 DTO 共享同一套用户契约字段', () => {
    const user = createMockUser({
      phoneNumber: '+8613800138000',
      authProvider: 'phone',
      avatarUrl: 'https://example.com/avatar.png',
      lastLoginAt: new Date('2026-04-12T10:00:00.000Z'),
      createdAt: new Date('2026-04-12T08:00:00.000Z'),
      updatedAt: new Date('2026-04-12T12:00:00.000Z'),
    });

    const authDto = toAuthUserDto(user);
    const profileDto = toUserProfileDto(user);

    expect(profileDto).toMatchObject({
      id: authDto.id,
      email: authDto.email,
      phoneNumber: authDto.phoneNumber,
      displayName: authDto.displayName,
      avatarUrl: authDto.avatarUrl,
      authProvider: authDto.authProvider,
      isEmailVerified: authDto.isEmailVerified,
      isPhoneVerified: authDto.isPhoneVerified,
      lastLoginAt: authDto.lastLoginAt?.toISOString(),
      createdAt: authDto.createdAt.toISOString(),
      updatedAt: authDto.updatedAt.toISOString(),
    });
  });

  it('应该把未知 authProvider 收敛为 email，避免契约漂移', () => {
    const user = createMockUser({
      authProvider: 'weixin' as never,
      phoneNumber: null,
    });

    const authDto = toAuthUserDto(user);
    const profileDto = toUserProfileDto(user);

    expect(authDto.authProvider).toBe('email');
    expect(profileDto.authProvider).toBe('email');
  });
});

