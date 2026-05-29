import { plainToInstance, Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Min, validateSync } from 'class-validator';

enum Environment {
  Development = 'development',
  Production = 'production',
  Test = 'test',
}

class EnvironmentVariables {
  @IsEnum(Environment)
  @IsOptional()
  NODE_ENV: Environment = Environment.Development;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  PORT: number = 3000;

  @IsString()
  DATABASE_URL!: string;

  @IsString()
  REDIS_URL!: string;

  @IsString()
  @IsOptional()
  CORS_ORIGINS: string = 'http://localhost:8080';

  @IsString()
  @IsOptional()
  KMA_API_KEY?: string;

  @IsString()
  @IsOptional()
  AIRKOREA_API_KEY?: string;

  @IsString()
  @IsOptional()
  KAKAO_REST_API_KEY?: string;

  @IsString()
  @IsOptional()
  JWT_SECRET: string = 'dev-insecure-secret-change-me';

  @IsString()
  @IsOptional()
  JWT_EXPIRES_IN: string = '12h';
}

export function envValidationSchema(config: Record<string, unknown>) {
  const validated = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validated, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(`Environment validation failed:\n${errors.toString()}`);
  }

  // 운영 환경에서는 안전한 시크릿을 강제 (개발 기본값/약한 값 거부)
  if (validated.NODE_ENV === Environment.Production) {
    const weak =
      !validated.JWT_SECRET ||
      validated.JWT_SECRET.includes('dev-insecure') ||
      validated.JWT_SECRET.length < 32;
    if (weak) {
      throw new Error(
        'JWT_SECRET must be a strong value (32+ chars, not the dev default) in production.',
      );
    }
  }

  return validated;
}
