import jwt, { SignOptions } from 'jsonwebtoken';
import { config } from '../config/env';

export interface TokenPayload {
  userId: string;
  email: string;
}

export class JWTService {
  static generateAccessToken(payload: TokenPayload): string {
    const expiresIn = config.jwt.accessExpiresIn;
    return jwt.sign(payload, config.jwt.accessSecret, {
      expiresIn: expiresIn,
    } as SignOptions);
  }

  static generateRefreshToken(payload: TokenPayload): string {
    const expiresIn = config.jwt.refreshExpiresIn;
    return jwt.sign(payload, config.jwt.refreshSecret, {
      expiresIn: expiresIn,
    } as SignOptions);
  }

  static verifyAccessToken(token: string): TokenPayload {
    try {
      return jwt.verify(token, config.jwt.accessSecret) as TokenPayload;
    } catch (error) {
      throw new Error('Invalid or expired access token');
    }
  }

  static verifyRefreshToken(token: string): TokenPayload {
    try {
      return jwt.verify(token, config.jwt.refreshSecret) as TokenPayload;
    } catch (error) {
      throw new Error('Invalid or expired refresh token');
    }
  }
}

