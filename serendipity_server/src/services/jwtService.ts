import jwt from 'jsonwebtoken';
import { config } from '../config';

export interface JwtPayload {
  userId: string;
  deviceId: string;
  email?: string;
  phone?: string;
}

export class JwtService {
  private readonly secret: string;
  private readonly expiresIn: string;
  private readonly refreshTokenExpiresIn: string;

  constructor(
    secret: string = config.jwt.secret,
    expiresIn: string = config.jwt.expiresIn,
    refreshTokenExpiresIn: string = config.jwt.refreshTokenExpiresIn
  ) {
    this.secret = secret;
    this.expiresIn = expiresIn;
    this.refreshTokenExpiresIn = refreshTokenExpiresIn;
  }

  generateToken(payload: JwtPayload): string {
    return jwt.sign(payload, this.secret, {
      expiresIn: this.expiresIn,
    } as jwt.SignOptions);
  }

  generateRefreshToken(payload: JwtPayload): string {
    return jwt.sign(payload, this.secret, {
      expiresIn: this.refreshTokenExpiresIn,
    } as jwt.SignOptions);
  }

  verify(token: string): JwtPayload {
    return jwt.verify(token, this.secret) as JwtPayload;
  }
}

// 导出单例实例
export const jwtService = new JwtService();

