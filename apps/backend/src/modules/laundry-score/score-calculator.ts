import {
  WeatherInput,
  PrecipType,
  SkyCondition,
  DryingPlace,
  LaundryAmount,
  LaundryGrade,
  LaundryTypeCode,
  ScoreInput,
  ScoreResult,
} from './types';

const BASE_SCORE = 100;

// ── 개별 감점 계산 (순수 함수) ──

export function calcTemperatureScore(tempC: number): number {
  if (tempC >= 25) return 0;
  if (tempC >= 20) return -5;
  if (tempC >= 15) return -10;
  if (tempC >= 10) return -20;
  if (tempC >= 5) return -30;
  return -40;
}

export function calcHumidityScore(humidityPercent: number): number {
  if (humidityPercent <= 40) return 0;
  if (humidityPercent <= 50) return -5;
  if (humidityPercent <= 60) return -10;
  if (humidityPercent <= 70) return -20;
  if (humidityPercent <= 80) return -30;
  if (humidityPercent <= 90) return -40;
  return -50;
}

export function calcWindScore(windSpeedMps: number): number {
  if (windSpeedMps >= 4) return 5;
  if (windSpeedMps >= 2) return 0;
  if (windSpeedMps >= 1) return -5;
  return -10;
}

export function calcPrecipScore(
  precipType: PrecipType,
  probability: number,
): number {
  if (precipType === PrecipType.RAIN) return -50;
  if (precipType === PrecipType.SNOW) return -50;
  if (precipType === PrecipType.SLEET) return -50;

  if (probability >= 70) return -30;
  if (probability >= 50) return -20;
  if (probability >= 30) return -10;
  return 0;
}

export function calcSkyScore(sky: SkyCondition): number {
  switch (sky) {
    case SkyCondition.CLEAR:
      return 5;
    case SkyCondition.PARTLY_CLOUDY:
      return 0;
    case SkyCondition.CLOUDY:
      return -5;
    case SkyCondition.OVERCAST:
      return -10;
  }
}

export function calcAirQualityScore(
  pm10Grade: number | null,
  pm25Grade: number | null,
): number {
  const worst = Math.max(pm10Grade ?? 1, pm25Grade ?? 1);
  if (worst <= 1) return 0;
  if (worst === 2) return -5;
  if (worst === 3) return -15;
  return -25;
}

// ── 건조 장소별 보정 ──

export function applyDryingPlaceModifier(
  outdoorRawScore: number,
  weather: WeatherInput,
  dryingPlace: DryingPlace,
): number {
  switch (dryingPlace) {
    case DryingPlace.OUTDOOR:
      return outdoorRawScore;

    case DryingPlace.BALCONY: {
      const windReduction = Math.abs(calcWindScore(weather.windSpeedMps)) * 0.5;
      const precipReduction =
        Math.abs(
          calcPrecipScore(weather.precipType, weather.precipitationProbability),
        ) * 0.5;
      return outdoorRawScore + windReduction + precipReduction;
    }

    case DryingPlace.INDOOR: {
      const airQPenalty = calcAirQualityScore(
        weather.pm10Grade,
        weather.pm25Grade,
      );
      const precipPenalty = calcPrecipScore(
        weather.precipType,
        weather.precipitationProbability,
      );
      return outdoorRawScore - airQPenalty - precipPenalty;
    }

    case DryingPlace.INDOOR_DEHUMIDIFIER: {
      const humidityPenalty = calcHumidityScore(weather.humidityPercent);
      const airQPenalty = calcAirQualityScore(
        weather.pm10Grade,
        weather.pm25Grade,
      );
      const precipPenalty = calcPrecipScore(
        weather.precipType,
        weather.precipitationProbability,
      );
      return (
        outdoorRawScore -
        humidityPenalty * 0.7 -
        airQPenalty -
        precipPenalty
      );
    }

    case DryingPlace.DRYER:
      return 90;
  }
}

// ── 건조 시간 추정 (증발 물리 기반) ──
//
// 빨래 건조 속도는 표면에서의 물 증발 속도에 비례한다. 증발 속도의 주된 추진력은
// 수증기압 부족분(VPD = 포화수증기압 - 실제수증기압)이며, 바람(포화된 경계층 공기를
// 제거)과 일사(증발에 필요한 잠열 공급 + 옷감 온도 상승)가 이를 가속한다.
//   증발지수 ∝ VPD × 바람계수 × 일사계수
// 건조시간 = 기준시간 × (기준증발지수 / 현재증발지수) × 빨래양계수

// 포화수증기압 [kPa] — Magnus(Tetens) 공식
export function saturationVaporPressureKpa(tempC: number): number {
  return 0.6108 * Math.exp((17.27 * tempC) / (tempC + 237.3));
}

// 상대 증발지수 (클수록 빨리 마름)
export function evaporationIndex(
  tempC: number,
  humidityPercent: number,
  windSpeedMps: number,
  solarFactor: number,
): number {
  const es = saturationVaporPressureKpa(tempC);
  const vpd = Math.max(0.05, es * (1 - humidityPercent / 100)); // kPa
  const windFactor = 1 + 0.4 * Math.max(0, windSpeedMps); // 경계층 제거 효과
  return vpd * windFactor * solarFactor;
}

// 기준 조건: 맑은 날 실외 (22°C, 습도 50%, 바람 2m/s) → 배율 1.0
const REFERENCE_EVAP = evaporationIndex(22, 50, 2, 1.3);

function skySolarFactor(sky: SkyCondition): number {
  switch (sky) {
    case SkyCondition.CLEAR:
      return 1.3;
    case SkyCondition.PARTLY_CLOUDY:
      return 1.1;
    case SkyCondition.CLOUDY:
      return 0.95;
    case SkyCondition.OVERCAST:
      return 0.85;
  }
}

export function estimateDryHours(
  baseDryHoursMin: number,
  baseDryHoursMax: number,
  weather: WeatherInput,
  dryingPlace: DryingPlace,
  laundryAmount: LaundryAmount,
): { min: number; max: number } {
  const amountMultiplier =
    laundryAmount === LaundryAmount.SMALL
      ? 0.9
      : laundryAmount === LaundryAmount.MEDIUM
        ? 1.0
        : laundryAmount === LaundryAmount.LARGE
          ? 1.2
          : 1.4;

  // 종류의 기준 시간은 중앙값 하나로 사용 (양 끝을 각각 곱하면 폭이 비현실적으로 커짐)
  const baseMid = (baseDryHoursMin + baseDryHoursMax) / 2;

  // 건조기는 날씨와 무관하게 빠름
  if (dryingPlace === DryingPlace.DRYER) {
    return band(baseMid * 0.3 * amountMultiplier);
  }

  // 건조 장소별 유효 환경 (바람/일사/습도 보정)
  let wind = weather.windSpeedMps;
  let humidity = weather.humidityPercent;
  let solar: number;
  const sky = skySolarFactor(weather.skyCondition);

  switch (dryingPlace) {
    case DryingPlace.OUTDOOR:
      solar = sky;
      break;
    case DryingPlace.BALCONY:
      wind *= 0.5; // 바람 차단 일부
      solar = 0.6 * sky + 0.4; // 간접 햇빛
      break;
    case DryingPlace.INDOOR:
      wind = 0.3; // 거의 정지 공기
      solar = 0.9; // 햇빛 없음
      break;
    case DryingPlace.INDOOR_DEHUMIDIFIER:
      wind = 0.6;
      solar = 0.95;
      humidity = Math.min(humidity, 45); // 제습기가 습도 낮춤
      break;
  }

  const evap = evaporationIndex(weather.temperatureC, humidity, wind, solar);
  let multiplier = clamp(REFERENCE_EVAP / evap, 0.5, 6);

  // 비/눈 + 실외/베란다: 사실상 마르지 않음
  if (
    weather.precipType !== PrecipType.NONE &&
    (dryingPlace === DryingPlace.OUTDOOR || dryingPlace === DryingPlace.BALCONY)
  ) {
    multiplier *= 2.5;
  }

  const estimate = baseMid * clamp(multiplier, 0.5, 8) * amountMultiplier;
  return band(estimate);
}

// 단일 추정값 주변의 좁은 밴드(±12%)를 0.5시간 단위로 반환
function band(estimateHours: number): { min: number; max: number } {
  return {
    min: roundHalf(estimateHours * 0.88),
    max: roundHalf(estimateHours * 1.12),
  };
}

function roundHalf(v: number): number {
  return Math.round(v * 2) / 2;
}

// ── 등급 판정 ──

export function scoreToGrade(score: number): LaundryGrade {
  if (score >= 80) return LaundryGrade.EXCELLENT;
  if (score >= 60) return LaundryGrade.GOOD;
  if (score >= 40) return LaundryGrade.NORMAL;
  if (score >= 20) return LaundryGrade.BAD;
  return LaundryGrade.VERY_BAD;
}

// ── 경고 메시지 ──

export function buildWarnings(
  weather: WeatherInput,
  dryingPlace: DryingPlace,
): string[] {
  const warnings: string[] = [];

  if (weather.precipType !== PrecipType.NONE) {
    warnings.push('현재 강수 중이에요. 실외 건조는 피해주세요.');
  } else if (weather.precipitationProbability >= 50) {
    warnings.push(
      `강수 확률이 ${weather.precipitationProbability}%에요. 갑자기 비가 올 수 있어요.`,
    );
  }

  if (weather.humidityPercent >= 80) {
    warnings.push('습도가 매우 높아 건조가 느려질 수 있어요.');
  }

  if (weather.temperatureC < 5) {
    warnings.push('기온이 낮아 건조 시간이 많이 늘어납니다.');
  }

  const worstAir = Math.max(
    weather.pm10Grade ?? 1,
    weather.pm25Grade ?? 1,
  );
  if (worstAir >= 3 && dryingPlace === DryingPlace.OUTDOOR) {
    warnings.push('미세먼지가 나쁨이에요. 실내 건조를 추천합니다.');
  }

  if (weather.windSpeedMps >= 8 && dryingPlace === DryingPlace.OUTDOOR) {
    warnings.push('바람이 매우 강해요. 빨래가 날릴 수 있으니 고정해주세요.');
  }

  return warnings;
}

// ── 추천 문구 ──

export function buildRecommendationText(
  grade: LaundryGrade,
  laundryTypeCode: LaundryTypeCode,
  dryingPlace: DryingPlace,
): string {
  const typeLabel =
    laundryTypeCode === LaundryTypeCode.LIGHT
      ? '얇은 빨래'
      : laundryTypeCode === LaundryTypeCode.MEDIUM
        ? '일반 빨래'
        : '두꺼운 빨래';

  const placeLabel =
    dryingPlace === DryingPlace.OUTDOOR
      ? '실외'
      : dryingPlace === DryingPlace.BALCONY
        ? '베란다'
        : dryingPlace === DryingPlace.INDOOR
          ? '실내'
          : dryingPlace === DryingPlace.INDOOR_DEHUMIDIFIER
            ? '제습기'
            : '건조기';

  const gradeTexts: Record<LaundryGrade, string> = {
    [LaundryGrade.EXCELLENT]: `${typeLabel} ${placeLabel} 건조 최고의 날이에요!`,
    [LaundryGrade.GOOD]: `${typeLabel} ${placeLabel} 건조하기 좋은 날이에요.`,
    [LaundryGrade.NORMAL]: `${typeLabel} ${placeLabel} 건조 무난한 날이에요.`,
    [LaundryGrade.BAD]: `${typeLabel} ${placeLabel} 건조가 어려울 수 있어요.`,
    [LaundryGrade.VERY_BAD]: `${typeLabel} ${placeLabel} 건조는 비추천이에요. 건조기를 고려해보세요.`,
  };

  return gradeTexts[grade];
}

// ── 메인 계산 함수 ──

export function calculateLaundryScore(input: ScoreInput): ScoreResult {
  const { weather, dryingPlace, laundryTypeCode, laundryAmount } = input;

  const tempScore = calcTemperatureScore(weather.temperatureC);
  const humidScore = calcHumidityScore(weather.humidityPercent);
  const windScore = calcWindScore(weather.windSpeedMps);
  const precipScore = calcPrecipScore(
    weather.precipType,
    weather.precipitationProbability,
  );
  const skyScore = calcSkyScore(weather.skyCondition);
  const airScore = calcAirQualityScore(weather.pm10Grade, weather.pm25Grade);

  const outdoorRaw = clamp(
    BASE_SCORE + tempScore + humidScore + windScore + precipScore + skyScore + airScore,
    0,
    100,
  );

  const indoorRaw = clamp(
    BASE_SCORE + tempScore + humidScore + skyScore,
    0,
    100,
  );

  const adjustedScore = clamp(
    applyDryingPlaceModifier(outdoorRaw, weather, dryingPlace),
    0,
    100,
  );

  const grade = scoreToGrade(adjustedScore);

  const dryHours = estimateDryHours(
    input.baseDryHoursMin,
    input.baseDryHoursMax,
    weather,
    dryingPlace,
    laundryAmount,
  );

  return {
    overallScore: Math.round(adjustedScore),
    outdoorScore: Math.round(outdoorRaw),
    indoorScore: Math.round(indoorRaw),
    estimatedDryHoursMin: dryHours.min,
    estimatedDryHoursMax: dryHours.max,
    grade,
    recommendationText: buildRecommendationText(
      grade,
      laundryTypeCode,
      dryingPlace,
    ),
    warningTexts: buildWarnings(weather, dryingPlace),
    bestStartTimeRange: null,
  };
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}
