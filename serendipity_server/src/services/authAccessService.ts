import { IUserRepository, CreateUserData } from '../repositories/userRepository';
import { IPasswordHasher } from './passwordHasher';
import { AuthSessionService } from './authSessionService';
import { AuthServiceSupport } from './authServiceSupport';
import {
  AuthResponseDto,
  LoginEmailDto,
  LoginPhoneDto,
  RegisterEmailDto,
  RegisterPhoneDto,
} from '../types/auth.dto';
import { AppError } from '../middlewares/errorHandler';
import { ErrorCode } from '../types/errors';

export class AuthAccessService {
  constructor(
    private readonly userRepository: IUserRepository,
    private readonly passwordHasher: IPasswordHasher,
    private readonly authSessionService: AuthSessionService,
    private readonly authServiceSupport: AuthServiceSupport,
  ) {
    if (!userRepository) {
      throw new Error('UserRepository is required');
    }
    if (!passwordHasher) {
      throw new Error('PasswordHasher is required');
    }
    if (!authSessionService) {
      throw new Error('AuthSessionService is required');
    }
    if (!authServiceSupport) {
      throw new Error('AuthServiceSupport is required');
    }
  }

  registerEmail(data: RegisterEmailDto): Promise<AuthResponseDto> {
    return this.registerWithPassword(
      data,
      () => this.userRepository.findByEmail(data.email),
      () => ({
        email: data.email,
        passwordHash: '',
        authProvider: 'email',
      }),
      ErrorCode.EMAIL_ALREADY_EXISTS,
      '邮箱已存在',
    );
  }

  registerPhonePassword(data: RegisterPhoneDto): Promise<AuthResponseDto> {
    return this.registerPhoneLike(data);
  }

  registerPhone(data: RegisterPhoneDto): Promise<AuthResponseDto> {
    return this.registerPhoneLike(data);
  }

  async loginEmail(data: LoginEmailDto): Promise<AuthResponseDto> {
    this.authServiceSupport.validateLoginData(data.email, data.password, data.deviceId);
    const user = await this.userRepository.findByEmail(data.email);
    const validatedUser = await this.authServiceSupport.validateUserCredentials(
      user,
      data.password,
      '邮箱或密码错误',
    );
    await this.userRepository.updateLastLogin(validatedUser.id);
    return this.authSessionService.generateAuthResponse(validatedUser, data.deviceId);
  }

  async loginPhonePassword(data: LoginPhoneDto): Promise<AuthResponseDto> {
    return this.loginWithPhone(data, '手机号或密码错误');
  }

  async loginPhone(data: LoginPhoneDto): Promise<AuthResponseDto> {
    return this.loginWithPhone(data, '手机号或密码错误');
  }

  private registerPhoneLike(data: RegisterPhoneDto): Promise<AuthResponseDto> {
    return this.registerWithPassword(
      data,
      () => this.userRepository.findByPhone(data.phoneNumber),
      () => ({
        phoneNumber: data.phoneNumber,
        passwordHash: '',
        authProvider: 'phone',
      }),
      ErrorCode.PHONE_ALREADY_EXISTS,
      '手机号已存在',
    );
  }

  private async registerWithPassword(
    data: RegisterEmailDto | RegisterPhoneDto,
    findExisting: () => Promise<Awaited<ReturnType<IUserRepository['findByEmail']>>>,
    buildCreateData: () => CreateUserData,
    duplicateErrorCode: ErrorCode,
    duplicateMessage: string,
  ): Promise<AuthResponseDto> {
    const identifier = 'email' in data ? data.email : data.phoneNumber;
    this.authServiceSupport.validateRegisterData(identifier, data.password, data.deviceId);

    const existingUser = await findExisting();
    if (existingUser) {
      throw new AppError(duplicateMessage, duplicateErrorCode);
    }

    const passwordHash = await this.passwordHasher.hash(data.password);
    const user = await this.userRepository.create({
      ...buildCreateData(),
      passwordHash,
    });
    const recoveryKey = this.authServiceSupport.generateRecoveryKeyString();
    await this.userRepository.updateRecoveryKey(user.id, recoveryKey);

    return this.authSessionService.generateAuthResponseWithRecoveryKey(user, recoveryKey, data.deviceId);
  }

  private async loginWithPhone(data: LoginPhoneDto, errorMessage: string): Promise<AuthResponseDto> {
    this.authServiceSupport.validateLoginData(data.phoneNumber, data.password, data.deviceId);
    const user = await this.userRepository.findByPhone(data.phoneNumber);
    const validatedUser = await this.authServiceSupport.validateUserCredentials(user, data.password, errorMessage);
    await this.userRepository.updateLastLogin(validatedUser.id);
    return this.authSessionService.generateAuthResponse(validatedUser, data.deviceId);
  }
}

