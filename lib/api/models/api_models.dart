// 새 NestJS 백엔드 응답 모델
//
// NOTE(2026-07-09): NoticeModel 은 공지가 고객센터 웹으로 일원화되며 제거.

/// `GET /app-config/public` 응답.
/// 강제 업데이트, 점검 모드, 정책 URL을 한 번에 전달.
/// 시작 시 1회 fetch 해 캐시하여 화면들이 참조.
/// (featureFlags 는 앱에서 분기하는 곳이 없어 파싱 제거 — 2026-07-09.
///  킬스위치가 필요해지면 백엔드 응답은 그대로이니 파싱만 되살리면 됨)
class AppConfigModel {
  const AppConfigModel({
    required this.versions,
    required this.maintenance,
    required this.urls,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      versions: AppVersionsModel.fromJson(
          (json['versions'] as Map<String, dynamic>?) ?? const {}),
      maintenance: AppMaintenanceModel.fromJson(
          (json['maintenance'] as Map<String, dynamic>?) ?? const {}),
      urls:
          AppUrlsModel.fromJson((json['urls'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  final AppVersionsModel versions;
  final AppMaintenanceModel maintenance;
  final AppUrlsModel urls;
}

class AppVersionsModel {
  const AppVersionsModel({
    required this.minimumSupported,
    required this.latest,
    required this.forceUpdate,
  });

  factory AppVersionsModel.fromJson(Map<String, dynamic> json) {
    return AppVersionsModel(
      minimumSupported: json['minimumSupported'] as String? ?? '0.0.0',
      latest: json['latest'] as String? ?? '0.0.0',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
    );
  }

  final String minimumSupported;
  final String latest;
  final bool forceUpdate;
}

class AppMaintenanceModel {
  const AppMaintenanceModel({required this.enabled, required this.message});

  factory AppMaintenanceModel.fromJson(Map<String, dynamic> json) {
    return AppMaintenanceModel(
      enabled: json['enabled'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  final bool enabled;
  final String message;
}

class AppUrlsModel {
  const AppUrlsModel({
    required this.privacyPolicy,
    required this.terms,
    required this.locationTerms,
    required this.openSource,
    required this.dataSource,
    required this.support,
    required this.customerCenter,
  });

  factory AppUrlsModel.fromJson(Map<String, dynamic> json) {
    return AppUrlsModel(
      privacyPolicy: json['privacyPolicy'] as String? ?? '',
      terms: json['terms'] as String? ?? '',
      locationTerms: json['locationTerms'] as String? ?? '',
      openSource: json['openSource'] as String? ?? '',
      dataSource: json['dataSource'] as String? ?? '',
      support: json['support'] as String? ?? '',
      customerCenter: json['customerCenter'] as String? ?? '',
    );
  }

  final String privacyPolicy;
  final String terms;
  final String locationTerms;
  final String openSource;
  final String dataSource;
  final String support;
  final String customerCenter;
}

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

/// 주변 빨래방 응답 묶음 — source 보존.
/// 백엔드가 카카오 REST 키 없거나 실패하면 `source: 'mock'` 또는 `'mock_fallback'`
/// 으로 응답할 수 있음. UI에서 사용자에게 명시해야 진짜 주변 빨래방으로 오해 안 함.
class LaundromatsEnvelopeModel {
  const LaundromatsEnvelopeModel({
    required this.items,
    required this.source,
  });

  factory LaundromatsEnvelopeModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => LaundromatModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return LaundromatsEnvelopeModel(
      items: items,
      source: json['source'] as String? ?? '',
    );
  }

  final List<LaundromatModel> items;
  final String source;

  bool get isMock =>
      source.contains('mock') || source.toLowerCase().contains('fallback');
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
    required this.cautionText,
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
      cautionText: json['cautionText'] as String? ?? '',
    );
  }

  final String code;
  final String nameKo;
  final String description;
  final List<String> examples;
  final double baseDryHoursMin;
  final double baseDryHoursMax;
  final String cautionText;
}

class LaundryScoreModel {
  const LaundryScoreModel({
    required this.overallScore,
    required this.outdoorScore,
    required this.indoorScore,
    required this.estimatedDryHoursMin,
    required this.estimatedDryHoursMax,
    required this.grade,
    required this.warningTexts,
    this.estimatedCompletionAt,
  });

  factory LaundryScoreModel.fromJson(Map<String, dynamic> json) {
    return LaundryScoreModel(
      overallScore: json['overallScore'] as int,
      outdoorScore: json['outdoorScore'] as int,
      indoorScore: json['indoorScore'] as int,
      estimatedDryHoursMin: (json['estimatedDryHoursMin'] as num).toDouble(),
      estimatedDryHoursMax: (json['estimatedDryHoursMax'] as num).toDouble(),
      grade: json['grade'] as String,
      warningTexts: (json['warningTexts'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      // "몇 시에 다 마른다" 절대 완료시각 (ISO). 백엔드 V2 산출, 못 마르면 null.
      estimatedCompletionAt: json['estimatedCompletionAt'] == null
          ? null
          : DateTime.parse(json['estimatedCompletionAt'] as String),
    );
  }

  final int overallScore;
  final int outdoorScore;
  final int indoorScore;
  final double estimatedDryHoursMin;
  final double estimatedDryHoursMax;
  final String grade;
  final List<String> warningTexts;

  /// 예상 건조 완료 시각. null = 건조창 내 못 마름 or 미제공.
  final DateTime? estimatedCompletionAt;
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
    required this.displayTime,
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
      displayTime: json['displayTime'] as String?,
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
  final String? displayTime;
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

/// `GET /laundry-score/home` 응답 — 홈 화면 번들 (4콜→1콜).
/// current + 선택 장소 timeline + 실외/실내 비교용 timeline.
class HomeBundleModel {
  const HomeBundleModel({
    required this.current,
    required this.timeline,
    required this.outdoorTimeline,
    required this.indoorTimeline,
  });

  factory HomeBundleModel.fromJson(Map<String, dynamic> json) {
    return HomeBundleModel(
      current: ScoreEnvelopeModel.fromJson(
          json['current'] as Map<String, dynamic>),
      timeline: TimelineEnvelopeModel.fromJson(
          json['timeline'] as Map<String, dynamic>),
      outdoorTimeline: TimelineEnvelopeModel.fromJson(
          json['outdoorTimeline'] as Map<String, dynamic>),
      indoorTimeline: TimelineEnvelopeModel.fromJson(
          json['indoorTimeline'] as Map<String, dynamic>),
    );
  }

  final ScoreEnvelopeModel current;
  final TimelineEnvelopeModel timeline;
  final TimelineEnvelopeModel outdoorTimeline;
  final TimelineEnvelopeModel indoorTimeline;
}

// NOTE(2026-07-06): Inquiry 모델은 고객센터 웹으로 일원화되며 앱에서 제거.
// 백엔드 API(POST /inquiries, GET /inquiries/:id)는 웹이 동일하게 사용한다.
