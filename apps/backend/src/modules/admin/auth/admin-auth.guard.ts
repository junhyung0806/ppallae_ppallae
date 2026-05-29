import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { AdminJwtPayload } from './admin-auth.service';

export interface AdminRequest extends Request {
  admin?: AdminJwtPayload;
}

@Injectable()
export class AdminAuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AdminRequest>();
    const token = this.extractToken(request);
    if (!token) {
      throw new UnauthorizedException('인증 토큰이 필요합니다.');
    }
    try {
      request.admin = await this.jwt.verifyAsync<AdminJwtPayload>(token);
      return true;
    } catch {
      throw new UnauthorizedException('유효하지 않은 토큰입니다.');
    }
  }

  private extractToken(request: AdminRequest): string | null {
    const header = request.headers.authorization;
    if (!header) return null;
    const [type, token] = header.split(' ');
    return type === 'Bearer' && token ? token : null;
  }
}
