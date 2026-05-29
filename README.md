# 빨래빨래 (ppallae_ppallae)

날씨와 현재 위치를 바탕으로 **언제 빨래를 널면 가장 잘 마를지**를 알려주는 앱입니다.

빨래 건조는 날씨 영향을 크게 받습니다. 습도가 높거나 비 올 가능성이 크면 같은 빨래도 훨씬 늦게 마르고, 두꺼운 빨래는 시간을 더 신중하게 골라야 합니다. 빨래빨래는 기상청 예보를 증발 물리 기반으로 분석해 빨래지수·추천 시간·예상 건조시간을 알려줍니다.

## 구성

모노레포 구조입니다.

| 경로 | 설명 | 스택 |
|------|------|------|
| `lib/` | 모바일/웹 앱 | Flutter, Dart |
| `apps/backend/` | API 서버 | NestJS, Prisma, Redis, BullMQ |
| `apps/admin/` | 관리자 백오피스 | Next.js |

## 주요 기능

- 앱 시작 시 현재 위치(GPS)를 가져와 그 지역의 빨래지수를 바로 표시
- 기온·습도·바람·하늘상태·강수·미세먼지를 반영한 빨래지수(0~100) + 등급
- **증발 물리(수증기압 부족분 VPD) 기반 예상 건조시간**
- 빨래 종류(얇음/중간/두꺼움) × 건조 장소(실외/베란다/실내/제습기/건조기)별 차등
- 시간별 예보 카드(초단기예보 + 동네예보, 3일치) + 추천 시작 시간
- 지도(카카오맵)에서 위치를 탭해 다른 지역 조회, 즐겨찾기
- 내 주변 빨래방(카카오 로컬) 카드
- 관리자 페이지: 대시보드, 공지/빨래종류/설정 관리, 감사 로그

## 외부 데이터

- **기상청 단기예보** (API 허브): 초단기실황·초단기예보·동네예보
- **에어코리아** (공공데이터포털): 미세먼지
- **카카오**: 지도(JS SDK) + 로컬 API(주변 빨래방)

API 키는 모두 **백엔드에서만** 사용하며, 앱은 자체 백엔드 API만 호출합니다(카카오맵 JS키만 클라이언트 노출 — 도메인 등록으로 보호).

## 실행 방법

사전 준비: Docker, Node 22+, Flutter SDK.

```powershell
# 1. DB + Redis (Docker)
docker compose up db redis -d

# 2. 백엔드 (포트 4000)
cd apps/backend
npm install
cp .env.example .env   # 키 채우기 (없으면 mock 데이터로 동작)
npx prisma migrate dev
npx prisma db seed
npm run start:dev

# 3. 앱 (포트 8080)
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=PPALLAE_API_BASE_URL=http://localhost:4000/api/v1

# 4. (선택) 관리자 (포트 3500)
cd apps/admin
npm install
npm run dev   # http://localhost:3500
```

기본 포트: PostgreSQL `5433`, Redis `16379`, API `4000`, 앱 `8080`, 관리자 `3500`.

## 환경 변수

`apps/backend/.env` (템플릿: `.env.example`). 키가 비어 있으면 해당 데이터는 mock으로 동작합니다.

```text
DATABASE_URL=postgresql://ppallae:ppallae_dev@localhost:5433/ppallae?schema=public
REDIS_URL=redis://localhost:16379
KMA_API_KEY=            # 기상청 API 허브
AIRKOREA_API_KEY=       # 공공데이터포털 에어코리아
KAKAO_REST_API_KEY=     # 카카오 로컬 (주변 빨래방)
JWT_SECRET=             # 운영에선 32자+ 강한 값 필수
```

카카오맵 JS키는 `web/index.html`에 있으며, 카카오 콘솔의 Web 플랫폼 도메인에 `http://localhost:8080`을 등록해야 지도가 표시됩니다.

## 테스트

```powershell
cd apps/backend && npm test      # 알고리즘/수집 단위 테스트
flutter analyze                  # 정적 분석
```

## 더 보기

- `ARCHITECTURE.md`: 전체 구조와 데이터 흐름
