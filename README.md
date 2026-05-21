# ppallae_ppallae

## 프로젝트 개요

`ppallae_ppallae`는 위치 기반 날씨 데이터를 활용해 빨래하기 좋은 타이밍을 추천하는 Flutter 애플리케이션입니다. 모바일과 웹 플랫폼을 모두 염두에 두고 설계했으며, 백엔드에서는 KMA API를 안전하게 프록시하고 캐시를 적용하여 응답 속도와 보안을 개선합니다.

## 핵심 기능

- 위치 기반 실시간 날씨 조회
- 빨래 난이도, 습도, 강수 확률을 고려한 빨래 추천
- 구글 지도와 주소 검색을 통한 위치 선택
- Flutter Web/Android/iOS 크로스 플랫폼 지원
- FastAPI 백엔드로 KMA 인증키 분리 및 환경 변수 관리
- PostgreSQL + PostGIS 확장 예정 구조

## 기술 스택

- Flutter / Dart
- FastAPI / Python
- SQLAlchemy / asyncpg
- PostGIS
- Docker / Docker Compose
- KMA API Hub

## 아키텍처

이 프로젝트는 클라이언트 앱과 백엔드 API로 구성됩니다.

- `lib/`: Flutter 앱 소스
- `backend/app/`: FastAPI 백엔드 로직
- `backend/docker-compose.yml`: PostGIS 포함 로컬 개발 환경
- `backend/.env.example`: 환경 변수 구성 예시
- `ARCHITECTURE.md`: 시스템 구성과 데이터 흐름 설명

## 실행 방법

### 1) 백엔드 실행

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -e .
uvicorn app.main:app --reload --host 0.0.0.0 --port 8081
```

또는 Docker로 실행:

```powershell
cd backend
docker compose up --build
```

### 2) Flutter 앱 실행

```powershell
flutter pub get
flutter run -d chrome --dart-define=WEATHER_BACKEND_BASE_URL=http://localhost:8081/weather
```

옵션으로 앱 전용 API 키를 사용할 경우:

```powershell
flutter run -d chrome --dart-define=WEATHER_BACKEND_BASE_URL=http://localhost:8081/weather --dart-define=WEATHER_BACKEND_API_KEY=your-client-key
```

## 환경 변수

백엔드에서는 인증키를 하드코딩하지 않고 환경 변수로 관리합니다. `backend/.env.example`를 복사해 `.env`를 생성하고 필요한 값을 설정하세요.

- `WEATHER_SERVICE_API_KEY`: KMA API 호출용 서버 인증키
- `DATABASE_URL`: PostgreSQL 연결 문자열
- `KMA_AUTH_KEY`: KMA 공공 데이터 인증키

## 포트폴리오 강조 포인트

- 클라이언트/서버 분리 아키텍처 구축
- 외부 API 키를 서버 측에서 안전하게 보호
- 캐시 기반 날씨 데이터 최적화
- Flutter 멀티 플랫폼 UI와 FastAPI 백엔드 통합
- 확장 가능한 PostGIS 기반 데이터 저장 구조 설계

## 향후 확장 계획

- 빨래방 추천 기능 추가
- 사용자 선호도 기반 개인화 추천
- 세탁 기록 및 사용 패턴 분석
- 알림/스케줄링 기능
- 인증 기반 사용자 계정 관리

## 추가 문서

- `backend/README.md`: 백엔드 전용 실행과 API 설명
- `ARCHITECTURE.md`: 전체 시스템 흐름과 설계 요소
