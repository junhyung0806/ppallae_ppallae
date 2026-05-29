import { Module } from '@nestjs/common';
import { JwtModule, JwtModuleOptions } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminAuthController } from './auth/admin-auth.controller';
import { AdminAuthService } from './auth/admin-auth.service';
import { AdminAuthGuard } from './auth/admin-auth.guard';

@Module({
  imports: [
    JwtModule.registerAsync({
      useFactory: (config: ConfigService) =>
        ({
          secret: config.getOrThrow<string>('JWT_SECRET'),
          signOptions: {
            expiresIn: config.get<string>('JWT_EXPIRES_IN', '12h'),
          },
        }) as JwtModuleOptions,
      inject: [ConfigService],
    }),
  ],
  controllers: [AdminController, AdminAuthController],
  providers: [AdminService, AdminAuthService, AdminAuthGuard],
})
export class AdminModule {}
