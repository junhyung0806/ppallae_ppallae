import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, Max, Min } from 'class-validator';

// 대한민국 대략 경계 (제주~강원, 도서 포함 여유). 범위 밖 좌표는 거부.
export class CoordsQueryDto {
  @ApiProperty({ example: 37.5172 })
  @Type(() => Number)
  @IsNumber()
  @Min(33)
  @Max(39)
  lat!: number;

  @ApiProperty({ example: 127.0473 })
  @Type(() => Number)
  @IsNumber()
  @Min(124)
  @Max(132)
  lng!: number;
}
