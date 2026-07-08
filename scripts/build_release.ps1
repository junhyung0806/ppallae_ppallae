<#
.SYNOPSIS
  빨래빨래 운영 release 빌드 (API base URL 강제 주입).

.DESCRIPTION
  앱의 기본 API URL은 http://localhost:4000/api/v1 (로컬 개발용)이다.
  운영/베타 빌드에서 이 기본값으로 나가면 앱이 죽으므로, 이 스크립트는
  PPALLAE_API_BASE_URL 을 반드시 받아 --dart-define 으로 주입한다.

.PARAMETER ApiBaseUrl
  운영 API base URL. 예: https://ppallae-api.up.railway.app/api/v1
  https 이고 /api/v1 로 끝나야 한다.

.PARAMETER Target
  apk (기본) 또는 appbundle (Play 업로드용 .aab).

.PARAMETER KakaoJsKey
  카카오 JavaScript 키(비즈니스 채널). 지정 시 --dart-define=PPALLAE_KAKAO_JS_KEY 로
  주입돼 지도/주변 빨래방이 운영 키로 동작한다. 미지정 시 앱 내 개발용 테스트 키 폴백.
  (web/index.html 은 정적 파일이라 별도 치환 필요 — 모바일 빌드에만 적용됨.)

.EXAMPLE
  ./scripts/build_release.ps1 -ApiBaseUrl https://ppallae-api.up.railway.app/api/v1
  ./scripts/build_release.ps1 -ApiBaseUrl https://api.ppallae.app/api/v1 -Target appbundle -KakaoJsKey <키>
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$ApiBaseUrl,

  [ValidateSet('apk', 'appbundle')]
  [string]$Target = 'apk',

  [string]$KakaoJsKey = ''
)

$ErrorActionPreference = 'Stop'

if ($ApiBaseUrl -notmatch '^https://') {
  throw "ApiBaseUrl 은 https:// 로 시작해야 합니다 (운영은 평문 http 금지). 받은 값: $ApiBaseUrl"
}
if ($ApiBaseUrl -notmatch '/api/v1/?$') {
  throw "ApiBaseUrl 은 /api/v1 로 끝나야 합니다. 받은 값: $ApiBaseUrl"
}
if ($ApiBaseUrl -match 'localhost|127\.0\.0\.1|10\.0\.2\.2') {
  throw "운영 빌드에 로컬 주소가 들어왔습니다: $ApiBaseUrl"
}

Write-Host "==> 운영 빌드 ($Target)" -ForegroundColor Cyan
Write-Host "    API: $ApiBaseUrl" -ForegroundColor Cyan

$defines = @("--dart-define=PPALLAE_API_BASE_URL=$ApiBaseUrl")
if ($KakaoJsKey -ne '') {
  Write-Host "    Kakao JS 키: 주입됨 (운영 키)" -ForegroundColor Cyan
  $defines += "--dart-define=PPALLAE_KAKAO_JS_KEY=$KakaoJsKey"
} else {
  Write-Host "    Kakao JS 키: 미지정 → 앱 내 개발용 테스트 키 사용 (출시 전 -KakaoJsKey 권장)" -ForegroundColor Yellow
}

flutter build $Target --release @defines

if ($LASTEXITCODE -ne 0) { throw "flutter build 실패 (exit $LASTEXITCODE)" }

if ($Target -eq 'apk') {
  Write-Host "==> 산출물: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
} else {
  Write-Host "==> 산출물: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
}
