# 빨래빨래 아키텍처

## 전체 개요

날씨 기반 빨래 타이밍 추천 서비스. 모노레포로 앱·백엔드·관리자를 함께 둡니다.

- **Flutter 앱** (`lib/`): 위치 기반 빨래지수·예보·지도·빨래방 UI. 자체 백엔드 API만 호출
- **NestJS 백엔드** (`apps/backend/`): 공공 API 수집·캐싱·빨래지수 계산·관리자 인증. 모든 비밀키 보관
- **Next.js 관리자** (`apps/admin/`): 공지/빨래종류/설정 관리, 대시보드, 감사 로그
- **PostgreSQL + PostGIS / Redis**: 영속 데이터 + 캐시/큐

## 백엔드 모듈 (`apps/backend/src/`)

| 모듈 | 역할 |
|------|------|
| `modules/weather` | 기상청 격자 변환 + 초단기실황/초단기예보/동네예보 (KMA provider + mock) |
| `modules/air-quality` | 에어코리아 미세먼지 (AirKorea provider + mock) |
| `modules/laundry-score` | 빨래지수 알고리즘 + VPD 증발 기반 건조시간 (순수 함수 + 테스트) |
| `modules/data-ingestion` | BullMQ 워커 — 지역별 날씨/미세먼지 수집·캐싱 (cron fan-out) |
| `modules/weather-query` | 캐시→온디맨드 수집→DB 폴백 + stale 판정 |
| `modules/regions` | 지역 검색, 좌표→행정구역 변환 (lat/lng 미저장) |
| `modules/laundry-types` | 빨래 종류 3종 |
| `modules/laundromats` | 주변 빨래방 (카카오 로컬 + mock) |
| `modules/widget` `notices` `app-config` | 위젯 요약, 공지, 공개 설정 |
| `modules/admin` | JWT 인증, 관리 API, 감사 로그 |
| `prisma` `redis` `cache` `health` | 인프라 |

전역: helmet, ThrottlerGuard(레이트리밋), ValidationPipe, URI 버저닝(`/api/v1`), 환경변수 검증.

## Flutter 앱 (`lib/`)

- `main.dart` → `features/laundry/laundry_shell.dart` (홈/설정 탭)
- `features/laundry/laundry_home_controller.dart`: 상태(지역·점수·예보·빨래방·즐겨찾기·GPS), ChangeNotifier
- `features/laundry/laundry_home_screen.dart`: 점수/날씨/추천시간/지도/시간별/빨래방
- `features/laundry/map/`: 카카오맵 웹 위젯 (조건부 import, 비웹 스텁)
- `api/`: 백엔드 HTTP 클라이언트 + 모델
- `widget_service.dart`: 안드로이드 홈 위젯(home_widget) 갱신

## 데이터 흐름

1. 앱이 GPS 좌표를 얻어 `GET /regions/current?lat&lng`로 행정구역 변환 (좌표는 변환에만, 미저장)
2. `GET /laundry-score/current?regionCode&...` 호출
3. 백엔드 `WeatherQueryService`: Redis 캐시 → 없으면 온디맨드 수집(KMA+AirKorea) → 실패 시 DB 폴백, 90분 초과면 `stale`
4. `laundry-score`가 증발지수(VPD×바람×일사) 기반으로 점수·등급·건조시간·추천시간 계산
5. 앱은 점수/날씨/시간별/추천시간 표시. 별도로 `/laundromats/nearby`로 주변 빨래방 로드
6. BullMQ 스케줄러가 주기적으로 지역별 데이터를 미리 수집·캐싱

## 보안

- 공공/카카오 비밀키는 서버 `.env`에만 (앱엔 카카오맵 JS키만, 도메인 제한)
- 앱은 공공 API 직접 호출 안 함 — 자체 백엔드 경유
- GPS 좌표 미저장 (nx/ny·행정코드만)
- JWT(bcrypt) 관리자 인증, 로그인 레이트리밋, 운영 시 강한 JWT 시크릿 강제
- helmet 보안 헤더, 입력 검증 DTO, Prisma 파라미터화 쿼리

## 빌드/실행

`docker compose up db redis -d` → 백엔드 `npm run start:dev` → 앱 `flutter run`. 자세한 건 `README.md`.
