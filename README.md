# ppallae_ppallae

날씨와 현재 위치를 바탕으로 빨래하기 좋은 타이밍을 알려주는 Flutter 앱입니다.

빨래는 생각보다 날씨 영향을 많이 받습니다. 습도가 높거나 비가 올 가능성이 크면 같은 빨래라도 훨씬 늦게 마르고, 두꺼운 이불이나 후드티는 더 신중하게 시간을 골라야 합니다. `ppallae_ppallae`는 이런 상황을 앱 안에서 바로 판단할 수 있도록 만든 프로젝트입니다.

## 주요 기능

- 현재 위치를 가져와 주소와 날씨 정보를 함께 표시합니다.
- 습도, 강수 확률, 기온, 바람, 하늘 상태를 반영해 빨래 추천 점수를 계산합니다.
- 빨래 두께를 가벼움, 보통, 두꺼움, 초두꺼움으로 나누어 추천 결과를 다르게 보여줍니다.
- 선택한 위치 주변의 빨래방을 지도와 카드 형태로 확인할 수 있습니다.
- 주간 화면에서 날짜별 빨래 적합도를 비교할 수 있습니다.
- FastAPI 백엔드를 통해 기상청 API 키를 클라이언트에 노출하지 않도록 분리했습니다.

## 사용 기술

- Flutter, Dart
- FastAPI, Python
- KMA API Hub
- Kakao Maps JavaScript SDK
- OpenStreetMap Nominatim
- PostgreSQL, PostGIS
- Docker, Docker Compose

## 프로젝트 구조

```text
lib/
  app.dart
  features/
    home/              # 홈 화면, 위치 검색, 현재 위치 표시
    map/               # 지도와 주변 빨래방 UI
    recommendation/    # 빨래 추천 점수, 날씨 모델, 상태 관리
    weekly/            # 주간 빨래 캘린더
    settings/          # 사용자 설정과 저장 위치

backend/
  app/
    main.py            # FastAPI 진입점
    config.py          # 환경 변수 설정
    kma.py             # 기상청 API 호출과 응답 변환
  docker-compose.yml
  .env.example
```

## 실행 방법

### 1. 백엔드 실행

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -e .
uvicorn app.main:app --reload --host 0.0.0.0 --port 8081
```

Docker를 사용할 경우에는 아래 명령으로 실행할 수 있습니다.

```powershell
cd backend
docker compose up --build
```

### 2. Flutter 앱 실행

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define=WEATHER_BACKEND_BASE_URL=http://localhost:8081/weather
```

앱 전용 API 키를 사용하는 경우에는 다음 값을 함께 넘깁니다.

```powershell
flutter run -d chrome --web-port=8080 --dart-define=WEATHER_BACKEND_BASE_URL=http://localhost:8081/weather --dart-define=WEATHER_BACKEND_API_KEY=your-client-key
```

## Kakao 지도 설정

웹 지도는 `web/index.html`에 등록된 Kakao JavaScript SDK 키를 사용합니다. 로컬에서 지도를 확인하려면 Kakao Developers 콘솔의 Web 플랫폼 사이트 도메인에 아래 주소를 등록해야 합니다.

```text
http://localhost:8080
```

브라우저에서 `127.0.0.1` 주소로 실행한다면 이것도 함께 등록해두는 편이 좋습니다.

```text
http://127.0.0.1:8080
```

`flutter run -d chrome`만 사용하면 실행할 때마다 포트가 바뀔 수 있어서, 지도 테스트 시에는 `--web-port=8080`을 고정해서 실행했습니다.

주소 변환은 Kakao Local REST API 키가 있으면 Kakao를 먼저 사용하고, 키가 없거나 실패하면 OpenStreetMap으로 대체합니다.

```powershell
flutter run -d chrome --web-port=8080 --dart-define=KAKAO_REST_API_KEY=your-rest-api-key
```

## 환경 변수

백엔드 환경 변수는 `backend/.env.example`을 복사해 `.env` 파일로 관리합니다.

```text
WEATHER_SERVICE_API_KEY=
DATABASE_URL=
KMA_AUTH_KEY=
```

- `WEATHER_SERVICE_API_KEY`: 앱과 백엔드 사이에서 사용할 선택적 API 키
- `DATABASE_URL`: PostgreSQL 연결 문자열
- `KMA_AUTH_KEY`: 기상청 API 호출에 사용하는 인증키

## 구현하면서 신경 쓴 부분

날씨 API 키는 Flutter 앱에 직접 넣지 않고 백엔드에서만 사용하도록 분리했습니다. 클라이언트는 백엔드의 `/weather` 엔드포인트만 호출하고, 백엔드는 좌표를 기준으로 기상청 데이터를 가져온 뒤 앱에서 쓰기 쉬운 형태로 변환합니다.

추천 점수는 단순히 비 여부만 보지 않고 습도, 강수 확률, 바람, 기온, 하늘 상태를 함께 반영했습니다. 여기에 빨래 두께를 더해 같은 날씨라도 가벼운 빨래와 이불 빨래의 추천 결과가 다르게 나오도록 만들었습니다.

웹에서는 Kakao 지도 SDK를 사용하고, 모바일 네이티브 환경에서는 Google Map 위젯을 사용할 수 있도록 플랫폼별 지도를 분리했습니다. 지도 로딩 실패가 생겼을 때 원인을 확인할 수 있도록 웹 지도 진단 로그도 함께 표시합니다.

## 앞으로 개선하고 싶은 부분

- 실제 빨래방 데이터를 연결해 거리 기반 추천 고도화
- 사용자별 세탁 기록을 바탕으로 선호 시간대 반영
- 비 예보나 습도 급상승 시 알림 제공
- 로그인 기반 저장 위치 동기화
- 배포 환경에서 백엔드와 데이터베이스 운영 구조 정리

## 관련 문서

- `backend/README.md`: 백엔드 실행 방법과 API 설명
- `ARCHITECTURE.md`: 전체 구조와 데이터 흐름 정리
