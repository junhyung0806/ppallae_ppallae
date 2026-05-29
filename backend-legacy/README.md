# Ppallae Backend

`ppallae_ppallae` 앱의 백엔드는 KMA 기상청 API를 클라이언트 대신 호출하고, 앱에 필요한 날씨 정보를 구조화하여 전달하는 역할을 합니다. 이로 인해 API 키는 서버 측 환경 변수로 안전하게 관리되며, Flutter 클라이언트는 단순한 `GET /weather` 호출만 수행합니다.

## 주요 역할

- KMA API 프록시 및 데이터 변환
- 날씨 응답 캐시(TTL 기반)로 요청 최적화
- 환경 변수 기반 구성
- PostGIS 확장 데이터베이스 구조 준비
- 로컬 개발을 위한 Docker Compose 제공

## 기술 스택

- Python 3.11
- FastAPI
- SQLAlchemy
- asyncpg
- GeoAlchemy2
- cachetools
- Uvicorn
- PostgreSQL + PostGIS

## 환경 구성

`backend/.env.example`를 복사하여 `.env`를 만들고 값을 설정하세요.

필수 값:
- `DATABASE_URL`
- `WEATHER_SERVICE_API_KEY`
- `KMA_AUTH_KEY`

기본 개발 설정:
- `APP_HOST=0.0.0.0`
- `APP_PORT=8081`
- `WEATHER_CACHE_TTL_SECONDS=600`
- `WEATHER_RATE_LIMIT_PER_MINUTE=90`

## 실행 방법

### 로컬 Python 환경

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -e .
uvicorn app.main:app --reload --host 0.0.0.0 --port 8081
```

### Docker Compose

```powershell
cd backend
docker compose up --build
```

이 구성은 `db`(PostGIS)와 `api` 서비스를 함께 실행합니다.

## API 엔드포인트

### `GET /health`

- 상태 확인용 엔드포인트
- 서버 실행 여부를 점검하는 데 사용

### `GET /weather`

쿼리 파라미터:
- `lat` (위도)
- `lng` (경도)
- `sourceType` (데이터 출처 태그)
- `label` (사용자 지정 위치 이름)

응답 예시:

```json
{
  "current": {
    "temperatureCelsius": 23.4,
    "humidity": 61,
    "windSpeedMps": 2.1,
    "skyCondition": "partlyCloudy",
    "rainProbability": 10
  },
  "hourly": [
    {
      "at": "2026-04-21T23:00:00+09:00",
      "weather": {
        "temperatureCelsius": 22.9,
        "humidity": 63,
        "windSpeedMps": 1.9,
        "skyCondition": "cloudy",
        "rainProbability": 20
      }
    }
  ],
  "meta": {
    "source": "kma-proxy",
    "stage": "backend_success",
    "userMessage": "외부 날씨 백엔드 데이터로 추천을 표시 중입니다.",
    "provider": "KMA API Hub",
    "traceId": "trace-1234"
  }
}
```

## 데이터 저장 구조

백엔드는 향후 확장을 고려해 설계되었습니다.

- `users`: 사용자 기본 정보
- `saved_locations`: 사용자가 저장한 위치와 좌표
- `laundromats`: 빨래방 메타데이터
- `laundry_runs`: 빨래 실행 기록
- `weather_cache_entries`: 위치 기반 날씨 캐시

## 프로젝트 구조

- `backend/app/main.py`: FastAPI 애플리케이션 진입점
- `backend/app/config.py`: 환경 변수 및 설정
- `backend/app/kma.py`: KMA API 호출 및 변환
- `backend/app/models.py`: SQLAlchemy 데이터 모델
- `backend/sql/init_postgis.sql`: PostGIS 초기화 스크립트

## Flutter 연동

Flutter 앱은 `WEATHER_BACKEND_BASE_URL` 환경 변수로 백엔드 주소를 받습니다.

```powershell
flutter run -d chrome --dart-define=WEATHER_BACKEND_BASE_URL=http://localhost:8081/weather
```

앱 전용 클라이언트 키를 추가하려면:

```powershell
flutter run -d chrome --dart-define=WEATHER_BACKEND_BASE_URL=http://localhost:8081/weather --dart-define=WEATHER_BACKEND_API_KEY=your-client-key
```

## 참고 자료

- `../README.md`: 전체 프로젝트 개요 및 포트폴리오 설명
- `../ARCHITECTURE.md`: 시스템 설계 및 데이터 흐름

