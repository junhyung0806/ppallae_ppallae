# 빨래빨래 모바일 앱 (Flutter)

날씨와 현재 위치를 바탕으로 **언제 빨래를 널면 가장 잘 마를지** 알려주는 Flutter 앱입니다 (Android / iOS / Web).

이 저장소는 **모바일 앱 전용**입니다. 백엔드 API, 관리자 페이지, 고객센터, 정책 문서, 인프라는 형제 저장소에서 관리합니다.

## 관련 저장소

| 저장소 | 역할 |
|---|---|
| **ppallae_ppallae** (이 저장소) | Flutter 모바일 앱 |
| `ppallae_ppallae_api_server` | 백엔드 API (이 앱이 호출) |
| `ppallae_ppallae_admin_web` | 관리자 (앱과 무관, 같은 백엔드 사용) |
| `ppallae_ppallae_customer_web` | 고객센터 / 약관 / 공지 / FAQ |
| `ppallae_ppallae_docs` | 정책·약관·운영 문서 |
| `ppallae_ppallae_infra` | docker-compose / 배포 / CI/CD |

## 주요 기능

- 앱 시작 시 GPS로 현재 위치를 받아 그 지역의 빨래지수를 즉시 표시
- 기온·습도·바람·하늘·강수·미세먼지를 반영한 빨래지수(0~100) + 등급
- 증발 물리 기반 예상 건조시간 (백엔드 알고리즘)
- 빨래 종류(얇음/중간/두꺼움) × 건조 장소(실외/베란다/실내/제습기)별 차등
- 시간별 예보 카드 + 추천 시작 시간
- 카카오맵에서 위치 탭으로 다른 지역 조회 + 지역 검색
- 내 주변 빨래방 (카카오 로컬)
- 안드로이드 홈 위젯 (등급별 배경색 + 점수 + 추천시간)

## 사전 준비

- Flutter SDK 3.11.5+
- Android Studio / Xcode (실기기 빌드 시)
- `ppallae_ppallae_api_server`가 실행 중이어야 함 (로컬 또는 원격)

## 실행

### 웹 (개발 기본)

```powershell
flutter pub get
flutter run -d chrome --web-port 8080 `
  --dart-define=PPALLAE_API_BASE_URL=http://localhost:4000/api/v1
```

### Android 실기기 (PC와 같은 Wi-Fi)

```powershell
flutter devices
flutter run -d <deviceId> `
  --dart-define=PPALLAE_API_BASE_URL=http://<PC-Wi-Fi-IP>:4000/api/v1
```

PC의 Wi-Fi IP는 `ipconfig`로 확인.

### Release 빌드

```powershell
# APK (테스트 / 사이드로드)
flutter build apk --release `
  --dart-define=PPALLAE_API_BASE_URL=https://<prod-domain>/api/v1

# AAB (Google Play 제출)
flutter build appbundle --release `
  --dart-define=PPALLAE_API_BASE_URL=https://<prod-domain>/api/v1
```

출시용 서명은 `android/key.properties` + `android/app/build.gradle.kts` release 설정 필요 (현재 미설정 — 디버그 키로 빌드됨).

## API Base URL

앱이 백엔드를 가리키는 방식은 **단 하나**입니다.

- 정의: [lib/api/ppallae_api_client.dart](lib/api/ppallae_api_client.dart) 의 `String.fromEnvironment('PPALLAE_API_BASE_URL', defaultValue: 'http://localhost:4000/api/v1')`
- 주입: 빌드 시 `--dart-define=PPALLAE_API_BASE_URL=<url>`
- 환경별 예시
  - 로컬 웹: `http://localhost:4000/api/v1`
  - 로컬 실기 (Android): `http://<PC-Wi-Fi-IP>:4000/api/v1`
  - dev: `https://api-dev.ppallae.example/api/v1`
  - prod: `https://api.ppallae.example/api/v1`

앱 내부에 API 키 / JWT / DB 자격 / 관리자 시크릿은 **일체 두지 않습니다**. 모든 비밀값은 백엔드만 다룹니다.

## 카카오맵

- 웹: `web/index.html` (Kakao JS SDK 로드)
- 모바일: `lib/features/laundry/map/kakao_map_view_mobile.dart` (`kakao_map_plugin` WebView)
- 현재 **테스트 JS 키** 사용 중. 출시 전 비즈니스 키로 교체 + 카카오 콘솔에 운영 도메인 등록 필요.
- 갱신 지점은 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) 부록 B 참조.

## 안드로이드 권한 / 네트워크

- `INTERNET`, `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`
- 개발용 `usesCleartextTraffic="true"` 설정. 백엔드 HTTPS 전환 후 제거 (RELEASE_CHECKLIST 참조).

## 정적 분석 / 테스트

```powershell
flutter analyze
flutter test
```

## 디렉토리 구조

```
lib/
  main.dart
  api/
    ppallae_api_client.dart      ← 백엔드 base URL 정의 (단일 지점)
    models/                      ← Region / Score / Weather / Timeline / Laundromat
  core/
    error_codes.dart             ← LOC / API / MAP / WGT 코드 카탈로그
    theme/
  features/
    laundry/
      laundry_shell.dart         ← 앱 진입
      laundry_home_screen.dart   ← 홈 (점수 / selector / 추천시간 / 날씨 / 지도+빨래방)
      laundry_home_controller.dart
      settings_screen.dart
      region_search_screen.dart
      map_fullscreen_screen.dart
      data_source_screen.dart
      widget_service.dart        ← Android 홈 위젯 데이터 주입
      map/
        kakao_map_view.dart      ← 웹/모바일 조건부 진입
        kakao_map_view_web.dart
        kakao_map_view_mobile.dart  ← Kakao JS 키 사용처

android/
  app/src/main/
    AndroidManifest.xml          ← 권한 / cleartext
    res/layout/ppallae_widget.xml          ← 위젯 레이아웃
    res/drawable/widget_bg_*.xml           ← 등급별 배경
    kotlin/.../PpallaeWidgetProvider.kt    ← 위젯 Provider

web/
  index.html                     ← Kakao SDK 로드 (JS 키 사용처)
```

## 에러 코드

진단 편의를 위해 표준 에러 코드를 부여합니다 ([lib/core/error_codes.dart](lib/core/error_codes.dart)).

| 카테고리 | 코드 | 의미 |
|---|---|---|
| 위치 | LOC-001 | 폰 위치 서비스 꺼짐 |
| 위치 | LOC-002 | 권한 거부 (세션) |
| 위치 | LOC-003 | 권한 영구 거부 |
| 위치 | LOC-004 | 좌표 획득 타임아웃 |
| 위치 | LOC-005 | 기타 위치 실패 |
| 위치 | LOC-006 | 좌표→지역 변환 실패 |
| API | API-001 | 연결 실패 (서버 다운/방화벽) |
| API | API-002 | 응답 타임아웃 |
| API | API-003 | HTTP 비-2xx |
| API | API-004 | JSON 파싱 실패 |
| 지도 | MAP-001~003 | SDK 로드 / 인증 / 인스턴스 실패 |
| 위젯 | WGT-001 | 위젯 데이터 푸시 실패 |

UI에 `[CODE] 메시지` 형태로 노출되어 어느 단계에서 실패했는지 즉시 식별 가능합니다.

## 더 보기

- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) — 출시 준비 추적표
- 약관 / 정책 / 운영 문서: `ppallae_ppallae_docs` 저장소
