# Ppallae Architecture

## 전체 개요

`ppallae_ppallae`는 Flutter 프론트엔드와 FastAPI 백엔드가 협력하는 멀티모달 날씨 기반 빨래 추천 애플리케이션입니다.

- Flutter 앱: 사용자 위치와 날씨, 빨래 추천 UI
- FastAPI 백엔드: KMA API 요청, 응답 캐시, 안전한 인증키 관리
- PostgreSQL + PostGIS: 위치 기반 데이터 확장 준비

## 주요 컴포넌트

### Flutter 앱 (`lib/`)

- `lib/main.dart`: 앱 진입점
- `lib/app.dart`: 전역 앱 구성
- `lib/features/home/`: 위치 검색과 시작 화면
- `lib/features/map/`: 지도 기반 위치 탐색
- `lib/features/recommendation/`: 빨래 추천 로직과 상태
- `lib/features/settings/`: 사용자 설정
- `lib/features/weekly/`: 주간 예보 및 패턴 확인

### 백엔드 (`backend/app/`)

- `backend/app/main.py`: FastAPI 애플리케이션 시작
- `backend/app/config.py`: 환경 변수 기반 설정 관리
- `backend/app/kma.py`: 기상청 API 호출, 좌표 변환 및 예외 처리
- `backend/app/models.py`: SQLAlchemy 모델 정의
- `backend/sql/init_postgis.sql`: PostGIS 초기화 스크립트

### 인프라

- `backend/Dockerfile`: 백엔드 컨테이너 이미지
- `backend/docker-compose.yml`: PostGIS DB와 FastAPI 백엔드 함께 실행
- `backend/.env.example`: 로컬/개발 환경 변수 템플릿

## 데이터/요청 흐름

1. 사용자가 Flutter 앱에서 위치를 선택하거나 현재 위치를 허용합니다.
2. 앱은 `WEATHER_BACKEND_BASE_URL`에 정의된 백엔드 URL로 `GET /weather` 요청을 보냅니다.
3. 백엔드는 요청된 `lat`, `lng` 값을 받아 캐시에서 날씨 데이터를 확인합니다.
4. 캐시에 항목이 없거나 만료된 경우 KMA API를 호출해 날씨 데이터를 가져옵니다.
5. 백엔드는 날씨 데이터를 앱 친화형 JSON 형식으로 변환하여 응답합니다.
6. Flutter 앱은 받은 데이터를 기반으로 빨래 적합도, 습도, 강수 확률 등을 계산하여 추천 UI를 업데이트합니다.

## 보안 및 확장 설계

- KMA 인증키는 클라이언트가 아닌 서버에서만 사용됩니다.
- `backend/.env.example`로 환경 변수를 관리하여 비밀값이 코드에 포함되지 않게 합니다.
- 백엔드는 캐시 TTL(`WEATHER_CACHE_TTL_SECONDS`)과 요청 제한(`WEATHER_RATE_LIMIT_PER_MINUTE`)을 지원합니다.
- PostGIS 기반 모델은 위치/빨래방 정보를 저장하고 추천 엔진 확장으로 이어질 수 있습니다.

## 포트폴리오용 핵심 포인트

- 클라이언트/서버 분리 + 백엔드 API 설계
- 외부 공공 데이터(KMA) 통합 및 안전한 키 관리
- Flutter 멀티 플랫폼 UI 구현 경험
- Docker Compose를 이용한 로컬 개발 환경 구축
- 위치 기반 애플리케이션을 위한 공간 데이터 설계

## 향후 개선 방향

- 빨래방 추천과 사용자 위치 기반 추천 로직
- 사용자 행동 기록 기반 개인화
- Push 알림 또는 스케줄 알림
- 인증 기반 사용자 계정 및 클라우드 배포
