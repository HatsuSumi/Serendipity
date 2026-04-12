import { User } from '@prisma/client';
import { AuthUserDto } from './auth.dto';
import { UserProfileDto } from './user.dto';

const resolveAuthProvider = (user: User): 'email' | 'phone' => {
  return user.authProvider === 'phone' ? 'phone' : 'email';
};

const createUserContract = (user: User) => ({
  id: user.id,
  email: user.email || undefined,
  phoneNumber: user.phoneNumber || undefined,
  displayName: user.displayName || undefined,
  avatarUrl: user.avatarUrl || undefined,
  authProvider: resolveAuthProvider(user),
  isEmailVerified: Boolean(user.email),
  isPhoneVerified: Boolean(user.phoneNumber),
  lastLoginAt: user.lastLoginAt || undefined,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

export const toAuthUserDto = (user: User): AuthUserDto => {
  return createUserContract(user);
};

export const toUserProfileDto = (user: User): UserProfileDto => {
  const contract = createUserContract(user);

  return {
    ...contract,
    lastLoginAt: contract.lastLoginAt?.toISOString(),
    createdAt: contract.createdAt.toISOString(),
    updatedAt: contract.updatedAt.toISOString(),
  };
};

