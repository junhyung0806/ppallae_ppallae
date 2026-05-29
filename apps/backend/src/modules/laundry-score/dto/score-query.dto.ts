import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import {
  DryingPlace,
  LaundryAmount,
  LaundryTypeCode,
  PrecipType,
  SkyCondition,
} from '../types';

export class ScoreCurrentQueryDto {
  @ApiProperty({ example: '1168010100', description: '지역 행정코드' })
  @IsString()
  regionCode!: string;

  @ApiPropertyOptional({ enum: LaundryTypeCode, default: LaundryTypeCode.LIGHT })
  @IsEnum(LaundryTypeCode)
  @IsOptional()
  laundryTypeCode: LaundryTypeCode = LaundryTypeCode.LIGHT;

  @ApiPropertyOptional({ enum: DryingPlace, default: DryingPlace.OUTDOOR })
  @IsEnum(DryingPlace)
  @IsOptional()
  dryingPlace: DryingPlace = DryingPlace.OUTDOOR;

  @ApiPropertyOptional({ enum: LaundryAmount, default: LaundryAmount.MEDIUM })
  @IsEnum(LaundryAmount)
  @IsOptional()
  laundryAmount: LaundryAmount = LaundryAmount.MEDIUM;
}

export class ScoreTimelineQueryDto {
  @ApiProperty({ example: '1168010100' })
  @IsString()
  regionCode!: string;

  @ApiPropertyOptional({ enum: LaundryTypeCode, default: LaundryTypeCode.LIGHT })
  @IsEnum(LaundryTypeCode)
  @IsOptional()
  laundryTypeCode: LaundryTypeCode = LaundryTypeCode.LIGHT;

  @ApiPropertyOptional({ enum: DryingPlace, default: DryingPlace.OUTDOOR })
  @IsEnum(DryingPlace)
  @IsOptional()
  dryingPlace: DryingPlace = DryingPlace.OUTDOOR;
}

export class ScoreEstimateDto {
  @ApiProperty({ example: 22 })
  @IsInt()
  @Min(-50)
  @Max(60)
  temperatureC!: number;

  @ApiProperty({ example: 50 })
  @IsInt()
  @Min(0)
  @Max(100)
  humidityPercent!: number;

  @ApiProperty({ enum: PrecipType, default: PrecipType.NONE })
  @IsEnum(PrecipType)
  precipType!: PrecipType;

  @ApiProperty({ example: 10 })
  @IsInt()
  @Min(0)
  @Max(100)
  precipitationProbability!: number;

  @ApiProperty({ example: 2.5 })
  @IsInt()
  @Min(0)
  windSpeedMps!: number;

  @ApiProperty({ enum: SkyCondition, default: SkyCondition.CLEAR })
  @IsEnum(SkyCondition)
  skyCondition!: SkyCondition;

  @ApiPropertyOptional({ example: 1, description: 'PM10 등급(1~4)' })
  @IsInt()
  @IsOptional()
  @Min(1)
  @Max(4)
  pm10Grade?: number;

  @ApiPropertyOptional({ example: 1, description: 'PM2.5 등급(1~4)' })
  @IsInt()
  @IsOptional()
  @Min(1)
  @Max(4)
  pm25Grade?: number;

  @ApiProperty({ enum: LaundryTypeCode })
  @IsEnum(LaundryTypeCode)
  laundryTypeCode!: LaundryTypeCode;

  @ApiProperty({ enum: DryingPlace })
  @IsEnum(DryingPlace)
  dryingPlace!: DryingPlace;

  @ApiProperty({ enum: LaundryAmount, default: LaundryAmount.MEDIUM })
  @IsEnum(LaundryAmount)
  laundryAmount!: LaundryAmount;

  @ApiPropertyOptional({ example: 10, description: '시각(0~23)' })
  @IsInt()
  @IsOptional()
  @Min(0)
  @Max(23)
  hourOfDay?: number;
}
