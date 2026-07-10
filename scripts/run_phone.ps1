# 폰(USB) 개발 실행 — adb reverse 터널 + flutter run 을 한 번에.
#
# 사용법 (저장소 루트에서):
#   .\scripts\run_phone.ps1                # 연결된 기기 1대면 자동 선택
#   .\scripts\run_phone.ps1 -DeviceId RFCN1012PHE
#
# 왜 필요한가: 폰의 localhost = 폰 자신이라, PC 백엔드(4000)에 붙으려면
# USB 터널(adb reverse)이 필요하다. 터널은 케이블을 뽑으면 사라져서
# 매번 까먹기 쉬움 → 이 스크립트가 항상 먼저 뚫고 실행한다.

param(
    [string]$DeviceId = "",
    [string]$ApiBase = "http://localhost:4000/api/v1"
)

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    Write-Host "[X] adb 를 찾을 수 없습니다: $adb" -ForegroundColor Red
    exit 1
}

# 1) 기기 연결 확인
$devices = (& $adb devices) -split "`n" | Where-Object { $_ -match "\tdevice$" }
if ($devices.Count -eq 0) {
    Write-Host "[X] 연결된 기기가 없습니다. USB 케이블과 'USB 디버깅 허용' 팝업을 확인하세요." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] 기기: $($devices -join ', ')" -ForegroundColor Green

# 2) USB 터널 (폰 localhost:4000 → PC 4000)
& $adb reverse tcp:4000 tcp:4000 | Out-Null
Write-Host "[OK] adb reverse tcp:4000 → PC:4000" -ForegroundColor Green

# 3) 백엔드 살아있는지 확인 (죽어있으면 경고만 하고 계속)
try {
    $null = Invoke-WebRequest -Uri "http://localhost:4000/api/v1/health" -UseBasicParsing -TimeoutSec 4
    Write-Host "[OK] 백엔드(4000) UP" -ForegroundColor Green
} catch {
    Write-Host "[!] 백엔드(4000)가 꺼져 있습니다 — 앱은 뜨지만 점수가 안 나옵니다." -ForegroundColor Yellow
    Write-Host "    별도 터미널에서: cd C:\Users\asdfc\ppallae_ppallae_api_server; npm run start:dev" -ForegroundColor Yellow
}

# 4) flutter run
$args = @("run", "--dart-define=PPALLAE_API_BASE_URL=$ApiBase")
if ($DeviceId) { $args += @("-d", $DeviceId) }
flutter @args
