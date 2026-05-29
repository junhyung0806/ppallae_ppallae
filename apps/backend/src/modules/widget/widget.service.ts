import { Injectable } from '@nestjs/common';
import { LaundryScoreService } from '../laundry-score/laundry-score.service';
import {
  DryingPlace,
  LaundryAmount,
  LaundryTypeCode,
} from '../laundry-score/types';

@Injectable()
export class WidgetService {
  constructor(private readonly scoreService: LaundryScoreService) {}

  async summary(regionCode: string) {
    const result = await this.scoreService.current({
      regionCode,
      laundryTypeCode: LaundryTypeCode.LIGHT,
      dryingPlace: DryingPlace.OUTDOOR,
      laundryAmount: LaundryAmount.MEDIUM,
    });

    return {
      region: result.region.displayName,
      generatedAt: result.generatedAt,
      stale: result.stale,
      overallScore: result.score.overallScore,
      grade: result.score.grade,
      oneLineRecommendation: result.score.recommendationText,
      estimatedDryHoursMin: result.score.estimatedDryHoursMin,
      estimatedDryHoursMax: result.score.estimatedDryHoursMax,
      topWarning: result.score.warningTexts[0] ?? null,
    };
  }
}
