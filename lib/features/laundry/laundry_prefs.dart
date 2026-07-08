/// 홈 컨트롤러와 위젯 백그라운드 워커([widget_refresh.dart])가 공유하는
/// SharedPreferences 키와 고정값.
///
/// 백그라운드 워커는 앱 UI 상태에 접근할 수 없어서, 마지막 선택값을 이 키들로
/// 읽어 같은 조건의 점수를 다시 조회한다. 키 문자열이 어긋나면 위젯이 조용히
/// 기본값으로 계산되므로 반드시 이 파일을 통해서만 접근한다.
library;

/// 백엔드 score API 에 전송하는 laundryAmount 고정값.
/// 제품 결정으로 사용자 선택 UI는 두지 않고 항상 보통(MEDIUM) 기준으로 계산.
/// 즉 점수 카드는 "보통량 빨래를 가정한 점수" 를 보여준다.
const String kFixedLaundryAmount = 'MEDIUM';

const String kWidgetEnabledKey = 'ppallae_widget_enabled';
const String kLaundryTypeCodeKey = 'ppallae_laundry_type_code';
const String kDryingPlaceKey = 'ppallae_drying_place';

/// 마지막으로 확정된 지역(행정동) 코드. GPS/지도/검색으로 지역이 잡힐 때마다 저장.
const String kRegionCodeKey = 'ppallae_region_code';

/// 지역이 한 번도 확정된 적 없을 때의 폴백 (컨트롤러 기본 지역과 동일 — 서울 종로구 청운동).
const String kDefaultRegionCode = '1111010100';

/// 사용자가 동의한 약관 버전. 저장된 값 ≥ [kCurrentConsentVersion] 이면 동의 완료로 본다.
/// 약관 내용이 실질적으로 바뀌면 [kCurrentConsentVersion] 을 올려 재동의를 유도한다.
const String kConsentVersionKey = 'ppallae_consent_version';

/// 현재 약관 버전. 위치·개인정보 처리 방식이 바뀌면 +1.
const int kCurrentConsentVersion = 1;
