import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

export class NoticeDto {
  @ApiProperty()
  @IsString()
  title!: string;

  @ApiProperty()
  @IsString()
  content!: string;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiPropertyOptional()
  @IsInt()
  @IsOptional()
  priority?: number;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  startAt?: string | null;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  endAt?: string | null;
}

export class LaundryTypeUpdateDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  examples?: string[];

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  baseDryHoursMin?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  baseDryHoursMax?: number;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  cautionText?: string | null;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  goodText?: string | null;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  badText?: string | null;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class ConfigDto {
  @ApiProperty()
  @IsString()
  key!: string;

  @ApiProperty()
  @IsString()
  value!: string;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isPublic?: boolean;
}
