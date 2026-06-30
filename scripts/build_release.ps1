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

.EXAMPLE
  ./scripts/build_release.ps1 -ApiBaseUrl https://ppallae-api.up.railway.app/api/v1
  ./scripts/build_release.ps1 -ApiBaseUrl https://api.ppallae.app/api/v1 -Target appbundle
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$ApiBaseUrl,

  [ValidateSet('apk', 'appbundle')]
  [string]$Target = 'apk'
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

flutter build $Target --release --dart-define=PPALLAE_API_BASE_URL=$ApiBaseUrl

if ($LASTEXITCODE -ne 0) { throw "flutter build 실패 (exit $LASTEXITCODE)" }

if ($Target -eq 'apk') {
  Write-Host "==> 산출물: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
} else {
  Write-Host "==> 산출물: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
}
