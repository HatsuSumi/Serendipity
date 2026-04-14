import { Request, Response, NextFunction } from 'express';
import { IAuthService } from '../services/authService';
import { IVerificationService } from '../services/verificationService';
import {
  RegisterEmailDto,
  RegisterPhoneDto,
  LoginEmailDto,
  LoginPhoneDto,
  SendVerificationCodeDto,
  ResetPasswordDto,
  RefreshTokenDto,
  ChangePasswordDto,
  ChangeEmailDto,
  ChangePhoneDto,
  DeleteAccountDto,
} from '../types/auth.dto';
import { sendSuccess } from '../utils/response';

// 认证控制器
export class AuthController {
  constructor(
    private authService: IAuthService,
    private verificationService: IVerificationService
  ) {}

  registerEmail = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const data: RegisterEmailDto = req.body;
      const result = await this.authService.registerEmail(data);
      sendSuccess(res, result, 'User registered successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  registerPhone = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const data: RegisterPhoneDto = req.body;
      const result = await this.authService.registerPhone(data);
      sendSuccess(res, result, 'User registered successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  registerPhonePassword = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const data: RegisterPhoneDto = req.body;
      const result = await this.authService.registerPhonePassword(data);
      sendSuccess(res, result, 'User registered successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  loginEmail = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const data: LoginEmailDto = req.body;
      const result = await this.authService.loginEmail(data);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  loginPhone = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const data: LoginPhoneDto = req.body;
      const result = await this.authService.loginPhone(data);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  loginPhonePassword = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const data: LoginPhoneDto = req.body;
      const result = await this.authService.loginPhonePassword(data);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  sendVerificationCode = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const data: SendVerificationCodeDto = req.body;
      await this.verificationService.sendVerificationCode(
        data.type,
        data.target,
        data.purpose
      );
      sendSuccess(res, {
        expiresIn: 300,
        message: 'Verification code sent',
      });
    } catch (error) {
      next(error);
    }
  };

  resetPassword = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const data: ResetPasswordDto = req.body;
      await this.authService.resetPassword(data);
      sendSuccess(res, { message: 'Password reset successfully' });
    } catch (error) {
      next(error);
    }
  };

  refreshToken = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const data: RefreshTokenDto = req.body;
      const result = await this.authService.refreshToken(data.refreshToken, data.deviceId);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  getMe = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const result = await this.authService.getMe(userId);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  logout = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      await this.authService.logout(userId);
      sendSuccess(res, { message: 'Logged out successfully' });
    } catch (error) {
      next(error);
    }
  };

  changePassword = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: ChangePasswordDto = req.body;
      await this.authService.changePassword(userId, data);
      sendSuccess(res, { message: 'Password changed successfully' });
    } catch (error) {
      next(error);
    }
  };

  changeEmail = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: ChangeEmailDto = req.body;
      const result = await this.authService.changeEmail(userId, data);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  changePhone = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: ChangePhoneDto = req.body;
      const result = await this.authService.changePhone(userId, data);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  deleteAccount = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const data: DeleteAccountDto = req.body;
      await this.authService.deleteAccount(userId, data.password);
      sendSuccess(res, { message: 'Account deleted successfully' });
    } catch (error) {
      next(error);
    }
  };

  generateRecoveryKey = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const result = await this.authService.generateRecoveryKey(userId);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  };

  getRecoveryKey = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const recoveryKey = await this.authService.getRecoveryKey(userId);
      sendSuccess(res, { recoveryKey });
    } catch (error) {
      next(error);
    }
  };
}
