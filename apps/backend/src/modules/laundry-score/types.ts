export enum PrecipType {
  NONE = 'NONE',
  RAIN = 'RAIN',
  SNOW = 'SNOW',
  SLEET = 'SLEET',
}

export enum SkyCondition {
  CLEAR = 'CLEAR',
  PARTLY_CLOUDY = 'PARTLY_CLOUDY',
  CLOUDY = 'CLOUDY',
  OVERCAST = 'OVERCAST',
}

export enum DryingPlace {
  OUTDOOR = 'OUTDOOR',
  BALCONY = 'BALCONY',
  INDOOR = 'INDOOR',
  INDOOR_DEHUMIDIFIER = 'INDOOR_DEHUMIDIFIER',
  DRYER = 'DRYER',
}

export enum LaundryAmount {
  SMALL = 'SMALL',
  MEDIUM = 'MEDIUM',
  LARGE = 'LARGE',
  EXTRA_LARGE = 'EXTRA_LARGE',
}

export enum LaundryGrade {
  EXCELLENT = 'EXCELLENT',
  GOOD = 'GOOD',
  NORMAL = 'NORMAL',
  BAD = 'BAD',
  VERY_BAD = 'VERY_BAD',
}

export enum LaundryTypeCode {
  LIGHT = 'LIGHT',
  MEDIUM = 'MEDIUM',
  HEAVY = 'HEAVY',
}

export interface WeatherInput {
  temperatureC: number;
  humidityPercent: number;
  precipType: PrecipType;
  precipitationProbability: number;
  windSpeedMps: number;
  skyCondition: SkyCondition;
  pm10Grade: number | null;
  pm25Grade: number | null;
}

export interface ScoreInput {
  weather: WeatherInput;
  hourOfDay: number;
  dryingPlace: DryingPlace;
  laundryTypeCode: LaundryTypeCode;
  laundryAmount: LaundryAmount;
  baseDryHoursMin: number;
  baseDryHoursMax: number;
}

export interface ScoreResult {
  overallScore: number;
  outdoorScore: number;
  indoorScore: number;
  estimatedDryHoursMin: number;
  estimatedDryHoursMax: number;
  grade: LaundryGrade;
  recommendationText: string;
  warningTexts: string[];
  bestStartTimeRange: string | null;
}
