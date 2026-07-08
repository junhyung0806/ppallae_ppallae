import 'package:flutter/foundation.dart';

/// 표준 에러 코드 카탈로그.
///
/// 형식: <카테고리 3자>-<번호 3자리>. 사용자에게 보이는 메시지에 함께 표시되어
/// 버그 리포트 시 어느 단계에서 실패했는지 즉시 식별할 수 있다.
class ErrorCodes {
  // ── 위치 (Location) ──
  static const String locServiceDisabled = 'LOC-001'; // 폰의 위치 서비스 자체가 꺼짐
  static const String locPermissionDenied = 'LOC-002'; // 권한 요청 거부 (이번 세션)
  static const String locPermissionForever = 'LOC-003'; // 권한 영구 거부
  static const String locTimeout = 'LOC-004'; // getCurrentPosition 타임아웃
  static const String locRegionLookup = 'LOC-006'; // 좌표→지역 변환 실패

  // ── 백엔드 API ──
  static const String apiNetwork = 'API-001'; // 연결 실패 (서버 다운/방화벽)
  static const String apiTimeout = 'API-002'; // 응답 시간 초과
  static const String apiHttp = 'API-003'; // HTTP 비-2xx
  static const String apiParse = 'API-004'; // JSON 파싱 실패
  static const String apiRateLimited = 'API-005'; // HTTP 429 (요청 과다 제한)

  // ── 위젯 (Home Widget) ──
  static const String wgtSaveData = 'WGT-001'; // SharedPreferences 저장 실패
  static const String wgtUpdate = 'WGT-002'; // updateWidget 호출 실패 (RemoteViews 렌더 실패 포함)
  static const String wgtDisable = 'WGT-003'; // 위젯 비활성화 처리 실패
  static const String wgtUnsupported = 'WGT-005'; // 플랫폼 미지원 (웹/iOS 등)
  static const String wgtBackgroundRefresh = 'WGT-006'; // 백그라운드 주기 갱신 실패
  static const String wgtPinRequest = 'WGT-007'; // 홈에 위젯 추가(requestPin) 실패

  // ── 지도 (Kakao Map) ──
  static const String mapInit = 'MAP-001'; // 카카오 SDK/JS 초기화 실패
  static const String mapMarker = 'MAP-002'; // 마커 렌더/갱신 실패

  // ── 앱 설정 / 원격 구성 (Config) ──
  static const String cfgAppConfig = 'CFG-001'; // 공개 앱 설정(app-config) 조회 실패
  static const String cfgLaundryTypes = 'CFG-002'; // 빨래 종류 목록 조회 실패

  // ── 로컬 저장 (Preferences) ──
  static const String prfRead = 'PRF-001'; // SharedPreferences 읽기 실패
  static const String prfWrite = 'PRF-002'; // SharedPreferences 쓰기 실패

  // (INQ-001/002 는 문의가 고객센터 웹으로 일원화되며 제거 — 2026-07-06)

  // ── 배터리 최적화 (Battery) ──
  static const String batOptCheck = 'BAT-001'; // 배터리 최적화 예외 상태 조회/전환 실패

  // ── 기타 ──
  static const String generic = 'GEN-001';
}

/// 사용자에게 노출 가능한 표준 에러 래퍼.
///
/// `_locationNotice`, API 예외 메시지 등에 그대로 토스트/스낵으로 사용.
class PpallaeError {
  const PpallaeError(this.code, this.userMessage, [this.detail]);

  final String code;
  final String userMessage;
  final String? detail;

  /// 사용자 노출용 (코드 prefix 포함).
  String get displayText => '[$code] $userMessage';

  /// 콘솔/로그용 (detail 포함).
  String get logText =>
      '[$code] $userMessage${detail != null ? ' — $detail' : ''}';

  void log() {
    debugPrint('PpallaeError $logText');
  }
}
