import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { RegionsService } from './regions.service';
import { RegionDto } from '../../common/dto/region.dto';
import { CoordsQueryDto } from '../../common/dto/coords.dto';

@ApiTags('regions')
@Controller({ path: 'regions', version: '1' })
export class RegionsController {
  constructor(private readonly regions: RegionsService) {}

  @Get('search')
  @ApiOperation({ summary: '지역 검색 (시도/시군구/읍면동 키워드)' })
  @ApiQuery({ name: 'keyword', example: '강남' })
  search(@Query('keyword') keyword: string): Promise<RegionDto[]> {
    return this.regions.search(keyword ?? '');
  }

  @Get('current')
  @ApiOperation({ summary: '좌표로 현재 지역 조회 (lat/lng는 변환에만 사용, 저장 안 함)' })
  current(@Query() query: CoordsQueryDto): Promise<RegionDto> {
    return this.regions.currentByLatLng(query.lat, query.lng);
  }
}
