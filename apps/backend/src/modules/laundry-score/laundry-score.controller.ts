import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { LaundryScoreService } from './laundry-score.service';
import {
  ScoreCurrentQueryDto,
  ScoreEstimateDto,
  ScoreTimelineQueryDto,
} from './dto/score-query.dto';

@ApiTags('laundry-score')
@Controller({ path: 'laundry-score', version: '1' })
export class LaundryScoreController {
  constructor(private readonly service: LaundryScoreService) {}

  @Get('current')
  @ApiOperation({ summary: '현재 빨래지수 (지역 기준)' })
  current(@Query() query: ScoreCurrentQueryDto) {
    return this.service.current({
      regionCode: query.regionCode,
      laundryTypeCode: query.laundryTypeCode,
      dryingPlace: query.dryingPlace,
      laundryAmount: query.laundryAmount,
    });
  }

  @Get('timeline')
  @ApiOperation({ summary: '시간대별 빨래지수 + 추천 시작 시간' })
  timeline(@Query() query: ScoreTimelineQueryDto) {
    return this.service.timeline({
      regionCode: query.regionCode,
      laundryTypeCode: query.laundryTypeCode,
      dryingPlace: query.dryingPlace,
    });
  }

  @Get('daily')
  @ApiOperation({ summary: '일별/주간 빨래지수 (최대 7일)' })
  daily(@Query() query: ScoreTimelineQueryDto) {
    return this.service.daily({
      regionCode: query.regionCode,
      laundryTypeCode: query.laundryTypeCode,
      dryingPlace: query.dryingPlace,
    });
  }

  @Post('estimate')
  @ApiOperation({ summary: '날씨 값 직접 입력해서 빨래지수 계산' })
  estimate(@Body() body: ScoreEstimateDto) {
    return this.service.estimate({
      weather: {
        temperatureC: body.temperatureC,
        humidityPercent: body.humidityPercent,
        precipType: body.precipType,
        precipitationProbability: body.precipitationProbability,
        windSpeedMps: body.windSpeedMps,
        skyCondition: body.skyCondition,
        pm10Grade: body.pm10Grade ?? null,
        pm25Grade: body.pm25Grade ?? null,
      },
      hourOfDay: body.hourOfDay ?? new Date().getHours(),
      dryingPlace: body.dryingPlace,
      laundryTypeCode: body.laundryTypeCode,
      laundryAmount: body.laundryAmount,
    });
  }
}
