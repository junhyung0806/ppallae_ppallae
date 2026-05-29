import {
  calculateLaundryScore,
  calcTemperatureScore,
  calcHumidityScore,
  calcWindScore,
  calcPrecipScore,
  calcSkyScore,
  calcAirQualityScore,
  scoreToGrade,
  estimateDryHours,
  saturationVaporPressureKpa,
  evaporationIndex,
  buildWarnings,
} from './score-calculator';
import {
  PrecipType,
  SkyCondition,
  DryingPlace,
  LaundryAmount,
  LaundryGrade,
  LaundryTypeCode,
  ScoreInput,
  WeatherInput,
} from './types';

// ── Helper ──

function makeWeather(overrides: Partial<WeatherInput> = {}): WeatherInput {
  return {
    temperatureC: 25,
    humidityPercent: 40,
    precipType: PrecipType.NONE,
    precipitationProbability: 0,
    windSpeedMps: 3,
    skyCondition: SkyCondition.CLEAR,
    pm10Grade: 1,
    pm25Grade: 1,
    ...overrides,
  };
}

function makeInput(overrides: Partial<ScoreInput> = {}): ScoreInput {
  return {
    weather: makeWeather(),
    hourOfDay: 10,
    dryingPlace: DryingPlace.OUTDOOR,
    laundryTypeCode: LaundryTypeCode.LIGHT,
    laundryAmount: LaundryAmount.MEDIUM,
    baseDryHoursMin: 1.0,
    baseDryHoursMax: 3.0,
    ...overrides,
  };
}

// ── 개별 점수 함수 테스트 ──

describe('calcTemperatureScore', () => {
  it('25도 이상이면 감점 없음', () => {
    expect(calcTemperatureScore(25)).toBe(0);
    expect(calcTemperatureScore(35)).toBe(0);
  });

  it('5도 미만이면 최대 감점', () => {
    expect(calcTemperatureScore(4)).toBe(-40);
    expect(calcTemperatureScore(-10)).toBe(-40);
  });

  it('경계값 테스트', () => {
    expect(calcTemperatureScore(20)).toBe(-5);
    expect(calcTemperatureScore(15)).toBe(-10);
    expect(calcTemperatureScore(10)).toBe(-20);
    expect(calcTemperatureScore(5)).toBe(-30);
  });
});

describe('calcHumidityScore', () => {
  it('40% 이하면 감점 없음', () => {
    expect(calcHumidityScore(40)).toBe(0);
    expect(calcHumidityScore(10)).toBe(0);
  });

  it('90% 초과면 최대 감점', () => {
    expect(calcHumidityScore(91)).toBe(-50);
    expect(calcHumidityScore(100)).toBe(-50);
  });

  it('경계값 테스트', () => {
    expect(calcHumidityScore(50)).toBe(-5);
    expect(calcHumidityScore(60)).toBe(-10);
    expect(calcHumidityScore(70)).toBe(-20);
    expect(calcHumidityScore(80)).toBe(-30);
    expect(calcHumidityScore(90)).toBe(-40);
  });
});

describe('calcWindScore', () => {
  it('4m/s 이상은 보너스', () => {
    expect(calcWindScore(4)).toBe(5);
    expect(calcWindScore(10)).toBe(5);
  });

  it('1m/s 미만은 감점', () => {
    expect(calcWindScore(0.5)).toBe(-10);
    expect(calcWindScore(0)).toBe(-10);
  });
});

describe('calcPrecipScore', () => {
  it('비/눈/진눈깨비는 -50', () => {
    expect(calcPrecipScore(PrecipType.RAIN, 0)).toBe(-50);
    expect(calcPrecipScore(PrecipType.SNOW, 0)).toBe(-50);
    expect(calcPrecipScore(PrecipType.SLEET, 0)).toBe(-50);
  });

  it('강수 없고 확률 낮으면 감점 없음', () => {
    expect(calcPrecipScore(PrecipType.NONE, 0)).toBe(0);
    expect(calcPrecipScore(PrecipType.NONE, 29)).toBe(0);
  });

  it('강수 확률 높으면 감점', () => {
    expect(calcPrecipScore(PrecipType.NONE, 30)).toBe(-10);
    expect(calcPrecipScore(PrecipType.NONE, 50)).toBe(-20);
    expect(calcPrecipScore(PrecipType.NONE, 70)).toBe(-30);
  });
});

describe('calcSkyScore', () => {
  it('맑음은 보너스, 흐림은 감점', () => {
    expect(calcSkyScore(SkyCondition.CLEAR)).toBe(5);
    expect(calcSkyScore(SkyCondition.OVERCAST)).toBe(-10);
  });
});

describe('calcAirQualityScore', () => {
  it('좋음(1)은 감점 없음', () => {
    expect(calcAirQualityScore(1, 1)).toBe(0);
  });

  it('나쁨(3)은 -15', () => {
    expect(calcAirQualityScore(3, 1)).toBe(-15);
    expect(calcAirQualityScore(1, 3)).toBe(-15);
  });

  it('매우 나쁨(4)은 -25', () => {
    expect(calcAirQualityScore(4, 4)).toBe(-25);
  });

  it('null이면 좋음(1)으로 취급', () => {
    expect(calcAirQualityScore(null, null)).toBe(0);
  });
});

// ── 등급 판정 ──

describe('scoreToGrade', () => {
  it('경계값 테스트', () => {
    expect(scoreToGrade(100)).toBe(LaundryGrade.EXCELLENT);
    expect(scoreToGrade(80)).toBe(LaundryGrade.EXCELLENT);
    expect(scoreToGrade(79)).toBe(LaundryGrade.GOOD);
    expect(scoreToGrade(60)).toBe(LaundryGrade.GOOD);
    expect(scoreToGrade(59)).toBe(LaundryGrade.NORMAL);
    expect(scoreToGrade(40)).toBe(LaundryGrade.NORMAL);
    expect(scoreToGrade(39)).toBe(LaundryGrade.BAD);
    expect(scoreToGrade(20)).toBe(LaundryGrade.BAD);
    expect(scoreToGrade(19)).toBe(LaundryGrade.VERY_BAD);
    expect(scoreToGrade(0)).toBe(LaundryGrade.VERY_BAD);
  });
});

// ── 건조 시간 추정 (증발 물리 기반) ──

describe('saturationVaporPressureKpa', () => {
  it('온도가 높을수록 포화수증기압 증가', () => {
    expect(saturationVaporPressureKpa(30)).toBeGreaterThan(
      saturationVaporPressureKpa(10),
    );
  });

  it('알려진 값 근사 (20°C ≈ 2.34 kPa)', () => {
    expect(saturationVaporPressureKpa(20)).toBeCloseTo(2.34, 1);
  });
});

describe('evaporationIndex', () => {
  it('습도가 낮을수록 증발지수 증가', () => {
    expect(evaporationIndex(22, 30, 2, 1.3)).toBeGreaterThan(
      evaporationIndex(22, 80, 2, 1.3),
    );
  });

  it('바람이 강할수록 증발지수 증가', () => {
    expect(evaporationIndex(22, 50, 6, 1.3)).toBeGreaterThan(
      evaporationIndex(22, 50, 0, 1.3),
    );
  });

  it('기온이 높을수록 증발지수 증가', () => {
    expect(evaporationIndex(30, 50, 2, 1.3)).toBeGreaterThan(
      evaporationIndex(10, 50, 2, 1.3),
    );
  });
});

describe('estimateDryHours (물리 모델)', () => {
  const good = makeWeather({
    temperatureC: 22,
    humidityPercent: 50,
    windSpeedMps: 2,
    skyCondition: SkyCondition.CLEAR,
  });

  it('건조기는 날씨 무관하게 빠름', () => {
    const result = estimateDryHours(
      5,
      14,
      makeWeather({ humidityPercent: 95, temperatureC: 5 }),
      DryingPlace.DRYER,
      LaundryAmount.MEDIUM,
    );
    // 중앙값 9.5 × 0.3 ≈ 2.85시간 (밴드)
    expect(result.min).toBeLessThan(result.max);
    expect(result.max).toBeLessThan(4);
  });

  it('예상 시간 폭(밴드)이 과도하게 넓지 않다', () => {
    const result = estimateDryHours(
      3,
      5,
      makeWeather({
        temperatureC: 10,
        humidityPercent: 88,
        windSpeedMps: 0,
        skyCondition: SkyCondition.OVERCAST,
      }),
      DryingPlace.OUTDOOR,
      LaundryAmount.MEDIUM,
    );
    // 나쁜 조건이어도 min/max 폭은 추정값의 약 30% 이내
    expect(result.max - result.min).toBeLessThan(result.min * 0.5);
  });

  it('기준 조건(맑음 22도 50% 2m/s)은 중앙값(약 4h) 근처', () => {
    const result = estimateDryHours(3, 5, good, DryingPlace.OUTDOOR, LaundryAmount.MEDIUM);
    expect(result.min).toBeGreaterThanOrEqual(3);
    expect(result.max).toBeLessThanOrEqual(5);
    expect(result.min).toBeLessThan(result.max);
  });

  it('덥고 건조하고 바람 불면 더 빨리 마름', () => {
    const fast = estimateDryHours(
      3,
      5,
      makeWeather({
        temperatureC: 30,
        humidityPercent: 30,
        windSpeedMps: 5,
        skyCondition: SkyCondition.CLEAR,
      }),
      DryingPlace.OUTDOOR,
      LaundryAmount.MEDIUM,
    );
    expect(fast.min).toBeLessThan(3);
  });

  it('춥고 습하고 바람 없으면 훨씬 오래 걸림', () => {
    const slow = estimateDryHours(
      3,
      5,
      makeWeather({
        temperatureC: 8,
        humidityPercent: 90,
        windSpeedMps: 0,
        skyCondition: SkyCondition.OVERCAST,
      }),
      DryingPlace.OUTDOOR,
      LaundryAmount.MEDIUM,
    );
    expect(slow.min).toBeGreaterThan(6);
  });

  it('비 오는 날 실외는 건조 시간이 크게 증가', () => {
    const dry = estimateDryHours(3, 5, good, DryingPlace.OUTDOOR, LaundryAmount.MEDIUM);
    const rainy = estimateDryHours(
      3,
      5,
      makeWeather({
        precipType: PrecipType.RAIN,
        humidityPercent: 90,
        skyCondition: SkyCondition.OVERCAST,
      }),
      DryingPlace.OUTDOOR,
      LaundryAmount.MEDIUM,
    );
    expect(rainy.min).toBeGreaterThan(dry.min);
  });

  it('빨래 양 많으면 시간 증가', () => {
    const small = estimateDryHours(3, 5, good, DryingPlace.OUTDOOR, LaundryAmount.SMALL);
    const xl = estimateDryHours(3, 5, good, DryingPlace.OUTDOOR, LaundryAmount.EXTRA_LARGE);
    expect(small.min).toBeLessThan(xl.min);
  });

  it('제습기는 같은 실내라도 일반 실내보다 빠름', () => {
    const humid = makeWeather({ humidityPercent: 85, temperatureC: 20 });
    const indoor = estimateDryHours(3, 5, humid, DryingPlace.INDOOR, LaundryAmount.MEDIUM);
    const dehumid = estimateDryHours(
      3,
      5,
      humid,
      DryingPlace.INDOOR_DEHUMIDIFIER,
      LaundryAmount.MEDIUM,
    );
    expect(dehumid.min).toBeLessThan(indoor.min);
  });
});

// ── 경고 메시지 ──

describe('buildWarnings', () => {
  it('비 오면 경고', () => {
    const warnings = buildWarnings(
      makeWeather({ precipType: PrecipType.RAIN }),
      DryingPlace.OUTDOOR,
    );
    expect(warnings).toContain('현재 강수 중이에요. 실외 건조는 피해주세요.');
  });

  it('습도 80% 이상이면 경고', () => {
    const warnings = buildWarnings(
      makeWeather({ humidityPercent: 85 }),
      DryingPlace.OUTDOOR,
    );
    expect(warnings.some((w) => w.includes('습도'))).toBe(true);
  });

  it('미세먼지 나쁨 + 실외면 경고', () => {
    const warnings = buildWarnings(
      makeWeather({ pm10Grade: 3 }),
      DryingPlace.OUTDOOR,
    );
    expect(warnings.some((w) => w.includes('미세먼지'))).toBe(true);
  });

  it('미세먼지 나쁨이어도 실내면 미세먼지 경고 없음', () => {
    const warnings = buildWarnings(
      makeWeather({ pm10Grade: 3 }),
      DryingPlace.INDOOR,
    );
    expect(warnings.some((w) => w.includes('미세먼지'))).toBe(false);
  });

  it('좋은 날씨면 경고 없음', () => {
    const warnings = buildWarnings(makeWeather(), DryingPlace.OUTDOOR);
    expect(warnings).toHaveLength(0);
  });
});

// ── 메인 함수 통합 테스트 ──

describe('calculateLaundryScore', () => {
  it('완벽한 날씨 + 얇은 빨래 = EXCELLENT', () => {
    const result = calculateLaundryScore(makeInput());
    expect(result.overallScore).toBeGreaterThanOrEqual(80);
    expect(result.grade).toBe(LaundryGrade.EXCELLENT);
    expect(result.warningTexts).toHaveLength(0);
  });

  it('비 오는 날 실외 = 점수 크게 하락', () => {
    const result = calculateLaundryScore(
      makeInput({
        weather: makeWeather({
          precipType: PrecipType.RAIN,
          humidityPercent: 90,
          skyCondition: SkyCondition.OVERCAST,
        }),
      }),
    );
    expect(result.overallScore).toBeLessThanOrEqual(30);
    expect([LaundryGrade.BAD, LaundryGrade.VERY_BAD]).toContain(result.grade);
    expect(result.warningTexts.length).toBeGreaterThan(0);
  });

  it('건조기는 날씨 상관없이 90점', () => {
    const result = calculateLaundryScore(
      makeInput({
        weather: makeWeather({
          precipType: PrecipType.RAIN,
          humidityPercent: 95,
          temperatureC: -5,
        }),
        dryingPlace: DryingPlace.DRYER,
      }),
    );
    expect(result.overallScore).toBe(90);
    expect(result.grade).toBe(LaundryGrade.EXCELLENT);
  });

  it('두꺼운 빨래 + 나쁜 날씨 = 긴 건조시간', () => {
    const result = calculateLaundryScore(
      makeInput({
        weather: makeWeather({ humidityPercent: 80, temperatureC: 10 }),
        laundryTypeCode: LaundryTypeCode.HEAVY,
        baseDryHoursMin: 5.0,
        baseDryHoursMax: 14.0,
      }),
    );
    expect(result.estimatedDryHoursMin).toBeGreaterThan(5);
    expect(result.estimatedDryHoursMax).toBeGreaterThan(14);
  });

  it('점수는 항상 0~100 범위', () => {
    const worst = calculateLaundryScore(
      makeInput({
        weather: makeWeather({
          temperatureC: -20,
          humidityPercent: 100,
          precipType: PrecipType.RAIN,
          windSpeedMps: 0,
          skyCondition: SkyCondition.OVERCAST,
          pm10Grade: 4,
          pm25Grade: 4,
        }),
      }),
    );
    expect(worst.overallScore).toBeGreaterThanOrEqual(0);
    expect(worst.overallScore).toBeLessThanOrEqual(100);

    const best = calculateLaundryScore(makeInput());
    expect(best.overallScore).toBeGreaterThanOrEqual(0);
    expect(best.overallScore).toBeLessThanOrEqual(100);
  });

  it('실내 제습기는 습도 페널티 줄어듦', () => {
    const indoor = calculateLaundryScore(
      makeInput({
        weather: makeWeather({ humidityPercent: 85 }),
        dryingPlace: DryingPlace.INDOOR,
      }),
    );
    const dehumid = calculateLaundryScore(
      makeInput({
        weather: makeWeather({ humidityPercent: 85 }),
        dryingPlace: DryingPlace.INDOOR_DEHUMIDIFIER,
      }),
    );
    expect(dehumid.overallScore).toBeGreaterThan(indoor.overallScore);
  });

  it('추천 문구에 빨래 종류와 건조 장소가 포함됨', () => {
    const result = calculateLaundryScore(
      makeInput({
        laundryTypeCode: LaundryTypeCode.HEAVY,
        dryingPlace: DryingPlace.BALCONY,
      }),
    );
    expect(result.recommendationText).toContain('두꺼운 빨래');
    expect(result.recommendationText).toContain('베란다');
  });
});
