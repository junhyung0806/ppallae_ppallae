import { ApiProperty } from '@nestjs/swagger';

export class RegionDto {
  @ApiProperty({ example: '1168010100' })
  admCode!: string;

  @ApiProperty({ example: '서울특별시' })
  sido!: string;

  @ApiProperty({ example: '강남구' })
  sigungu!: string;

  @ApiProperty({ example: '역삼동' })
  eupmyeondong!: string;

  @ApiProperty({ example: 61 })
  nx!: number;

  @ApiProperty({ example: 126 })
  ny!: number;

  @ApiProperty({ example: '서울특별시 강남구 역삼동' })
  displayName!: string;
}
