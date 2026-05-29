// 새 NestJS 백엔드 응답 모델

class RegionModel {
  const RegionModel({
    required this.admCode,
    required this.sido,
    required this.sigungu,
    required this.eupmyeondong,
    required this.nx,
    required this.ny,
    required this.displayName,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      admCode: json['admCode'] as String,
      sido: json['sido'] as String,
      sigungu: json['sigungu'] as String,
      eupmyeondong: json['eupmyeondong'] as String,
      nx: json['nx'] as int,
      ny: json['ny'] as int,
      displayName: json['displayName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'admCode': admCode,
        'sido': sido,
        'sigungu': sigungu,
        'eupmyeondong': eupmyeondong,
        'nx': nx,
        'ny': ny,
        'displayName': displayName,
      };

  final String admCode;
  final String sido;
  final String sigungu;
  final String eupmyeondong;
  final int nx;
  final int ny;
  final String displayName;
}

class LaundromatModel {
  const LaundromatModel({
    required this.name,
    required this.address,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.placeUrl,
  });

  factory LaundromatModel.fromJson(Map<String, dynamic> json) {
    return LaundromatModel(
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String?,
      placeUrl: json['placeUrl'] as String?,
    );
  }

  final String name;
  final String address;
  final int distanceMeters;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? placeUrl;
}

class LaundryTypeModel {
  const LaundryTypeModel({
    required this.code,
    required this.nameKo,
    required this.description,
    required this.examples,
    required this.baseDryHoursMin,
    required this.baseDryHoursMax,
  });

  factory LaundryTypeModel.fromJson(Map<String, dynamic> json) {
    return LaundryTypeModel(
      code: json['code'] as String,
      nameKo: json['nameKo'] as String,
      description: json['description'] as String,
      examples:
          (json['examples'] as List<dynamic>).map((e) => e as String).toList(),
      baseDryHoursMin: (json['baseDryHoursMin'] as num).toDouble(),
      baseDryHoursMax: (json['baseDryHoursMax'] as num).toDouble(),
    );
  }

  final String code;
  final String nameKo;
  final String description;
  final List<String> examples;
  final double baseDryHoursMin;
  final double baseDryHoursMax;
}

class LaundryScoreModel {
  const LaundryScoreModel({
    required this.overallScore,
    required this.outdoorScore,
    required this.indoorScore,
    required this.estimatedDryHoursMin,
    required this.estimatedDryHoursMax,
    required this.grade,
    required this.recommendationText,
    required this.warningTexts,
    this.bestStartTimeRange,
  });

  factory LaundryScoreModel.fromJson(Map<String, dynamic> json) {
    return LaundryScoreModel(
      overallScore: json['overallScore'] as int,
      outdoorScore: json['outdoorScore'] as int,
      indoorScore: json['indoorScore'] as int,
      estimatedDryHoursMin: (json['estimatedDryHoursMin'] as num).toDouble(),
      estimatedDryHoursMax: (json['estimatedDryHoursMax'] as num).toDouble(),
      grade: json['grade'] as String,
      recommendationText: json['recommendationText'] as String,
      warningTexts: (json['warningTexts'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      bestStartTimeRange: json['bestStartTimeRange'] as String?,
    );
  }

  final int overallScore;
  final int outdoorScore;
  final int indoorScore;
  final double estimatedDryHoursMin;
  final double estimatedDryHoursMax;
  final String grade;
  final String recommendationText;
  final List<String> warningTexts;
  final String? bestStartTimeRange;
}

class WeatherSummaryModel {
  const WeatherSummaryModel({
    required this.temperatureC,
    required this.humidityPercent,
    required this.windSpeedMps,
    required this.precipType,
    required this.skyCondition,
    this.pm10Grade,
    this.pm25Grade,
  });

  factory WeatherSummaryModel.fromJson(Map<String, dynamic> json) {
    return WeatherSummaryModel(
      temperatureC: (json['temperatureC'] as num).toDouble(),
      humidityPercent: (json['humidityPercent'] as num).toInt(),
      windSpeedMps: (json['windSpeedMps'] as num).toDouble(),
      precipType: json['precipType'] as String? ?? 'NONE',
      skyCondition: json['skyCondition'] as String? ?? 'CLEAR',
      pm10Grade: (json['pm10Grade'] as num?)?.toInt(),
      pm25Grade: (json['pm25Grade'] as num?)?.toInt(),
    );
  }

  final double temperatureC;
  final int humidityPercent;
  final double windSpeedMps;
  final String precipType;
  final String skyCondition;
  final int? pm10Grade;
  final int? pm25Grade;
}

class ScoreEnvelopeModel {
  const ScoreEnvelopeModel({
    required this.regionDisplayName,
    required this.admCode,
    required this.generatedAt,
    required this.sources,
    required this.stale,
    required this.weather,
    required this.score,
  });

  factory ScoreEnvelopeModel.fromJson(Map<String, dynamic> json) {
    final region = json['region'] as Map<String, dynamic>;
    return ScoreEnvelopeModel(
      regionDisplayName: region['displayName'] as String,
      admCode: region['admCode'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      sources:
          (json['source'] as List<dynamic>).map((e) => e as String).toList(),
      stale: json['stale'] as bool,
      weather:
          WeatherSummaryModel.fromJson(json['weather'] as Map<String, dynamic>),
      score: LaundryScoreModel.fromJson(json['score'] as Map<String, dynamic>),
    );
  }

  final String regionDisplayName;
  final String admCode;
  final DateTime generatedAt;
  final List<String> sources;
  final bool stale;
  final WeatherSummaryModel weather;
  final LaundryScoreModel score;
}

class TimelineEntryModel {
  const TimelineEntryModel({
    required this.forecastAt,
    required this.hourOfDay,
    required this.overallScore,
    required this.grade,
    required this.estimatedDryHoursMin,
    required this.estimatedDryHoursMax,
    required this.temperatureC,
    required this.humidityPercent,
    required this.precipType,
    required this.skyCondition,
  });

  factory TimelineEntryModel.fromJson(Map<String, dynamic> json) {
    return TimelineEntryModel(
      forecastAt: DateTime.parse(json['forecastAt'] as String),
      hourOfDay: json['hourOfDay'] as int,
      overallScore: json['overallScore'] as int,
      grade: json['grade'] as String,
      estimatedDryHoursMin: (json['estimatedDryHoursMin'] as num).toDouble(),
      estimatedDryHoursMax: (json['estimatedDryHoursMax'] as num).toDouble(),
      temperatureC: (json['temperatureC'] as num?)?.toDouble() ?? 0,
      humidityPercent: (json['humidityPercent'] as num?)?.toInt() ?? 0,
      precipType: json['precipType'] as String? ?? 'NONE',
      skyCondition: json['skyCondition'] as String? ?? 'CLEAR',
    );
  }

  final DateTime forecastAt;
  final int hourOfDay;
  final int overallScore;
  final String grade;
  final double estimatedDryHoursMin;
  final double estimatedDryHoursMax;
  final double temperatureC;
  final int humidityPercent;
  final String precipType;
  final String skyCondition;
}

class TimelineEnvelopeModel {
  const TimelineEnvelopeModel({
    required this.bestStartTimeRange,
    required this.timeline,
  });

  factory TimelineEnvelopeModel.fromJson(Map<String, dynamic> json) {
    return TimelineEnvelopeModel(
      bestStartTimeRange: json['bestStartTimeRange'] as String?,
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => TimelineEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String? bestStartTimeRange;
  final List<TimelineEntryModel> timeline;
}
