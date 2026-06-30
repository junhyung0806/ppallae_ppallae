# 빨래빨래 모바일 앱 — 출시 체크리스트

이 문서는 **모바일 앱(`C:\Users\asdfc\ppallae_ppallae`) 한정** 출시 준비 추적표입니다.
백엔드·관리자·고객센터·문서·인프라는 코덱스 담당이며 형제 저장소에서 별도 추적합니다.

## 범례
- [ ] = 미완료
- [x] = 완료
- ⏸ = 외부(코덱스/사용자) 결정·작업 대기
- 🤝 = 코덱스와 핸드오프 필요

---

## 1. 내가 끝낸 것 (참조)

- [x] 앱 진입 단순화 — 홈만 (하단 네비 제거)
- [x] 홈 화면 UI (점수카드 / selector / 추천시간 / 날씨 / 시간별 / 지도+빨래방)
- [x] 점수 카드 통합 디자인 (이모지 + 등급 + 점수 + 추천시간)
- [x] 빨래종류 / 건조장소 selector — 빨래빨래 전용 pill
- [x] 풀스크린 지도 + 인라인 검색바
- [x] 카카오맵 조건부 import (웹/모바일)
- [x] GPS 단계별 폴백 + 표준 에러 코드 카탈로그 (LOC/API/MAP/WGT)
- [x] `PpallaeApiClient` — `--dart-define=PPALLAE_API_BASE_URL` 단일 진입점
- [x] 응답 모델 (Region / Score / Weather / Timeline / Laundromat)
- [x] 분리 백엔드 자동 검증 (8/8 200 OK + 스키마 호환 + CORS 통과)
- [x] Android 홈 위젯 — 등급별 배경, 동만 표시, 흰 구분선, 점수·시간 세로 스택
- [x] 위젯 서비스 (`_shortRegion`, `_splitRange`, 등급 라벨)
- [x] 설정 화면 (빨래량 / 건조기 제거, 위젯 토글)
- [x] 데이터 출처 화면
- [x] 코덱스 사전검토 P1~P8 반영 (2026-06-03):
  - P1 debug 빌드에서 API base URL 1회 출력 + LAN IP 가이드 주석
  - P2 fallback region 상태 분리 + 화면 배너 + 재시도 버튼 + region API 실패 surface
  - P3 데이터 source/stale/generatedAt 명확 표시 (`_DataSourceFooter`)
  - P4 빨래방 nearby `source` 보존 모델 + mock 시 "예시" 배지
  - P5 grade는 백엔드 `score.grade` 우선, Flutter `gradeFromScore`는 fallback. debug에서 mismatch 경고
  - P6 위치 좌표 debugPrint를 kDebugMode 가드 + 로그에 좌표 원문 미포함 (accuracy만)
  - P7 Kakao 키/origin 교체 지점 TODO 주석 (web/index.html × 2, kakao_map_view_mobile × 2)
  - P8 위치정보 처리 안내 문구 정정 (좌표는 변환 API에 전송되나 저장 X)
- [x] 모노레포 잔재 정리 (2026-06-03): `apps/`, `docker-compose.yml`, `ARCHITECTURE.md` 삭제 + 미사용 의존성 (`geocoding`, `google_maps_flutter`, `cupertino_icons`, `js`) 제거
- [x] 설정 화면 버전 표시 동적 로딩 (`package_info_plus` — pubspec과 자동 일치)
- [x] 정책/약관/문의 허브 화면 (`legal_screen.dart`) 스캐폴드

---

## 2. 출시 전 내가 해야 할 것 (의존성 없음)

### 2.1 문서 / 빌드 검증
- [x] RELEASE_CHECKLIST.md (이 문서) 신규
- [x] 모바일 전용 README.md 교체 (현재 모노레포 안내)
- [x] `flutter analyze` 클린 유지 (현 상태 No issues)
- [x] `flutter test` 통과 확인 (`test/smoke_test.dart` 추가 — gradeFromScore 경계값 + API baseUrl 주입 가드, 4/4 통과)
- [x] `flutter build apk --release` sanity (49.0MB, 디버그 서명, 136s)
- [x] `flutter build web --release` sanity (36MB, 50.8s, 폰트 tree-shake 99%)
- [x] 운영 빌드 스크립트 `scripts/build_release.ps1` (API URL 강제 주입 — https·`/api/v1`·localhost 차단). 사용: `./scripts/build_release.ps1 -ApiBaseUrl https://<운영도메인>/api/v1 [-Target appbundle]`

### 2.2 코드 정리
- [ ] `lib/` 미사용 import / dead 코드 audit
- [ ] 에러/로딩/빈 상태 일관성 audit (모든 화면)
- [ ] `print` / `debugPrint` 잔재 점검 (출시 빌드에서 노이즈 제거)
- [ ] `assert` / `kDebugMode` 분기 점검

### 2.3 실기기 검증 (Android)
- [ ] 갤럭시(SM A908N) Wi-Fi 연결 → 홈/지도/설정/위젯 전 화면 확인
- [ ] 새 위젯 디자인 (등급별 배경·구분선·세로 스택) 렌더 확인
- [ ] 위치 권한 prompt → 허용/거부 시나리오 점검
- [ ] 백키 / 앱 백그라운드 → 복귀 동작
- [ ] 다양한 화면 크기 (소형 / 표준 / 폴드 펼침)

### 2.4 스토어 제출 자료 (Android Play)
- [ ] 앱 아이콘 512×512 (Adaptive Icon 권장)
- [ ] 피처 그래픽 1024×500
- [ ] 스크린샷 폰 × 최소 2장, 7인치/10인치 태블릿 (선택)
- [ ] 짧은 설명 (80자)
- [ ] 자세한 설명 (4000자 이내)
- [ ] 카테고리 / 콘텐츠 등급 설문
- [ ] **Data Safety form** 작성 (수집 항목: 위치/없음, 공유: 없음)
- [ ] 개인정보처리방침 URL (코덱스 customer_web 확정 후 — 2.6 참조)
- [ ] 연락처 이메일

### 2.5 출시 차단 사항 (Play 업로드 거부 요인) ⏸ 출시 직전 일괄 처리
**아래 둘 다 미해결 — release 빌드는 가능하지만 Play 제출은 불가.**
**의도된 보류 상태** — 사용자 결정으로 출시 직전 한 세션에 함께 처리한다.

- [ ] **applicationId 변경** — 현재 `com.example.ppallae_ppallae`. Play 정책상 `com.example.*` 거부됨.
  - `android/app/build.gradle.kts:24` (applicationId), 같은 파일 `namespace` (line 9), `android/app/src/main/kotlin/com/example/ppallae_ppallae/*.kt` 파일들의 package 선언, `AndroidManifest.xml`의 component 참조까지 함께 옮겨야 함
  - Play Console 업로드 후에는 영구 변경 불가 → 한 번에 결정
  - **후보 (이전 논의):** `com.ppallae.app` (브랜드 도메인과 일치), `com.junhyung.ppallae` (개인 네임스페이스)
- [ ] **Release 서명 키** — 현재 debug 키로 서명 중 (build.gradle.kts:47)
  - 사용자 실행: `keytool -genkey -v -keystore $env:USERPROFILE\ppallae-release.jks -keyalg RSA -keysize 2048 -validity 36500 -alias ppallae`
  - 비밀번호 안전한 곳에 백업 (잃어버리면 앱 업데이트 영구 불가)
  - `android/key.properties` 생성 (gitignore 확인)
  - `android/app/build.gradle.kts` release 서명 설정 변경 (debug → release)
  - `flutter build appbundle --release` (AAB가 Play 제출 기본)
  - Play App Signing 활성화 (구글 보관 키로 추가 보호)

### 2.6 약관·URL 연결 ⏸ customer_web 호스팅 결정 후 일괄 교체
- [ ] **customer_web 호스팅 결정 (보류)** — 후보 Vercel / GitHub Pages / Netlify
  - 호스팅 결정되면 `*.vercel.app` 같은 서브도메인 또는 비즈 도메인 확정 후 아래 URL 일괄 교체
  - 현재 모바일 `_LegalUrls` 는 `https://ppallae.app/...` 형태 placeholder
- [ ] 설정 화면에서 다음 URL 링크 (customer_web URL 확정 후)
  - 개인정보처리방침 (`/privacy`)
  - 서비스 이용약관 (`/terms`)
  - 위치기반서비스 약관 (`/location-terms`)
  - 오픈소스 라이선스 (모바일 `showLicensePage()` 로컬 사용 중)
  - 공공데이터 출처 (모바일 `DataSourceScreen` 로컬 화면 있음, 외부 URL 보조 또는 통합 결정)
  - 고객센터 / 문의 — **결정됨**: Google Form (`forms.gle/F3Z2prSBHTorcB6W9`) 단일 채널. customer_web `/inquiry` 도 같은 Form 으로 server-side redirect 처리됨 (2026-06-10).

---

## 3. 코덱스/외부 작업 대기 ⏸

| 항목 | 트리거 | 내 작업 |
|---|---|---|
| Kakao 비즈 키 교체 | 비즈 키 발급 + 카카오 콘솔 도메인 등록 | `web/index.html` 2곳 + `lib/features/laundry/map/kakao_map_view_mobile.dart` 2곳 (키 + WebView origin) |
| `usesCleartextTraffic` 제거 | 백엔드 HTTPS 운영 시작 | `android/app/src/main/AndroidManifest.xml:10` 라인 제거 |
| 약관/공지/문의 URL 링크 | `customer_web` 정식 URL 확정 | 설정 화면에서 `url_launcher`로 외부 링크 |
| 앱 버전 / 강제 업데이트 | 백엔드 `/app-config/public` 응답 스키마 확정 | `PpallaeApiClient`에 endpoint 추가, 시작 시 체크, 강제 업데이트 다이얼로그 |
| 운영 API URL | 운영 도메인 결정 | `--dart-define=PPALLAE_API_BASE_URL=https://...` 로 release 빌드 |

---

## 4. 확정된 출시 의사결정 (2026-06-01)

- [x] **푸시 알림 MVP 포함** ✅
- [x] **크래시 리포팅: Firebase Crashlytics** ✅
- [x] **분석 도구: Firebase Analytics** ✅
- [x] **iOS는 출시 후** (Android 안정화 → Mac 확보 → iOS) ✅
- [ ] 앱 이름·아이콘 디자인 → 사용자가 AI 생성 (대기)
- [ ] 버전 정책 (`version: 1.0.0+1` → 출시 시 결정)
- [ ] 타깃 국가 (한국만으로 시작 가정 — 확정 필요)

### 4.1 Firebase 통합 작업 (위 결정으로 인한 새 작업)

> **상태(2026-06-03):** 사용자 결정으로 **코드 통합 보류**. 아래 단계는 모두 미반영 — pubspec/플러그인/main.dart init 어디에도 firebase 흔적 없음. 작업 재개 시 이 섹션을 그대로 따라가면 됨.

- [ ] **사용자**: Firebase 콘솔에서 프로젝트 생성 (`ppallae-ppallae` 이름 권장)
- [ ] **사용자**: Android 앱 등록 (패키지명 `com.example.ppallae_ppallae` — 출시 전 변경 시 갱신)
- [ ] **사용자**: `google-services.json` 다운로드 → `android/app/`에 배치
- [ ] **사용자**: `.gitignore`에 `google-services.json` 추가 확인
- [ ] **클루드**: `pubspec.yaml`에 `firebase_core`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics` 추가
- [ ] **클루드**: `android/build.gradle.kts`에 Google Services + Crashlytics 플러그인 추가
- [ ] **클루드**: `lib/main.dart`에서 `Firebase.initializeApp()` + Crashlytics zone 설정
- [ ] **클루드**: 푸시 알림 권한 요청 (Android 13+ `POST_NOTIFICATIONS`)
- [ ] **클루드**: FCM 토큰 획득 + 백엔드로 전송
- [ ] **클루드**: 푸시 수신 핸들러 (foreground/background/terminated)
- [ ] **클루드**: Analytics 이벤트 정의 (`app_open`, `score_viewed`, `region_changed`, `widget_installed`, `search_used` 등)
- [ ] 🤝 **코덱스**: `POST /users/fcm-token` endpoint 구현
- [ ] 🤝 **코덱스**: 알림 발송 트리거 정책 (날씨 급변 / 추천 시간 임박 등)
- [ ] **사용자**: Google Play Data Safety form 답변 갱신 (위치·디바이스 식별자·앱 상호작용·메시지 카테고리 신고)

---

## 5. iOS 별도 트랙 (Mac 확보 후)

- [ ] `ios/Runner.xcodeproj` 빌드
- [ ] `Info.plist` 위치 권한 사용 사유 한글 문구
- [ ] iOS 위치 권한 단계 (When In Use vs Always)
- [ ] Apple Developer 계정 ($99/년)
- [ ] App Store Connect 제출 자료 (스크린샷 6.7"/6.5"/5.5", App Privacy)
- [ ] iOS 위젯 (별도 작업 — Android와 구조 다름)

---

## 6. 출시 후 (1.0.x 패치 / 1.1 기능)

- [ ] 푸시 알림 (출시 시 미포함이라면)
- [ ] 사용자 피드백 반영 사이클
- [ ] 분석 도구로 사용 패턴 파악
- [ ] 다국어 지원 (영어부터)
- [ ] 다크 모드
- [ ] 위젯 사이즈 변형 (2×1, 4×2 등)

---

## 7. 비상 / 회전 대비

- [ ] keystore 백업 위치 (분실 시 앱 업데이트 불가)
- [ ] Kakao 비즈 키 회전 절차
- [ ] API base URL 회전 (도메인 이전 시)
- [ ] 백엔드 응답 스키마 변경 시 마이그레이션 (현재는 단일 API 클라이언트라 한 곳만 수정)

---

## 부록 A. 자주 쓰는 명령

```powershell
# 정적 분석 / 테스트
flutter analyze
flutter test

# 웹 (로컬 백엔드)
flutter run -d chrome --web-port 8080 `
  --dart-define=PPALLAE_API_BASE_URL=http://localhost:4000/api/v1

# 안드로이드 실기기 (로컬 백엔드, 같은 Wi-Fi)
flutter run -d <deviceId> `
  --dart-define=PPALLAE_API_BASE_URL=http://<PC-Wi-Fi-IP>:4000/api/v1

# Release sanity
flutter build apk --release --dart-define=PPALLAE_API_BASE_URL=http://localhost:4000/api/v1
flutter build web --release --dart-define=PPALLAE_API_BASE_URL=http://localhost:4000/api/v1

# 출시용 AAB (release 서명 설정 후)
flutter build appbundle --release `
  --dart-define=PPALLAE_API_BASE_URL=https://<prod-domain>/api/v1
```

## 부록 B. 코드 변경 지점 빠른 참조

> 라인 번호는 변경에 따라 어긋날 수 있음 — 표는 진입점 안내용이고 정확한 위치는 `TODO(release)` 주석 검색으로 찾는 게 정확.

| 변경 사유 | 파일 |
|---|---|
| API base URL 기본값 / debug 출력 | `lib/api/ppallae_api_client.dart` |
| Kakao JS 키 (웹, 2곳) | `web/index.html` |
| Kakao JS 키 + WebView origin (모바일) | `lib/features/laundry/map/kakao_map_view_mobile.dart` |
| Cleartext (개발용) | `android/app/src/main/AndroidManifest.xml` |
| applicationId / namespace / signing | `android/app/build.gradle.kts` |
| 위젯 레이아웃 (1x1/2x1 × 5등급) | `android/app/src/main/res/layout/ppallae_widget_*.xml` |
| 위젯 등급 매핑 (아이콘/레이아웃/라벨) | `android/app/src/main/kotlin/.../PpallaeWidgetCommon.kt` |
| 위젯 데이터 저장 키 + Dart 측 등급 매핑 | `lib/features/laundry/widget_service.dart` |
| Dart 측 fallback 등급 (백엔드 grade 빈 경우만) | `lib/features/laundry/laundry_home_screen.dart` (`gradeFromScore`) |
| 에러 코드 카탈로그 | `lib/core/error_codes.dart` |
| 정책/약관/문의 URL 4종 | `lib/features/laundry/legal_screen.dart` (`_LegalUrls`) |

> `TODO(release)` / `TODO(release-blocker)` 두 태그를 IDE 전체 검색하면 출시 전 손봐야 할 코드 지점을 한눈에 본다.
