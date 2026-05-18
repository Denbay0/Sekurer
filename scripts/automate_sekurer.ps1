param(
    [string]$BaseUrl = $env:BASE_URL,
    [string]$ApiHostPort = $env:API_HOST_PORT,
    [string]$AndroidSdkRoot = $(if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "C:\Users\denba\AppData\Local\Android\Sdk" }),
    [string]$FlutterBin = $env:FLUTTER_BIN,
    [string]$AvdName = "Pixel_7_API_34",
    [switch]$SkipDocker,
    [switch]$SkipFlutter
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$BackendLog = Join-Path $ProjectRoot "backend\logs\api.log"
$AutomationLog = Join-Path $ProjectRoot "backend\logs\automation.log"
$MobileDir = Join-Path $ProjectRoot "mobile"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $AutomationLog) | Out-Null

function Write-AutomationLog {
    param([string]$Message)
    $line = "$(Get-Date -Format o) $Message"
    Write-Host $line
    Add-Content -LiteralPath $AutomationLog -Value $line
}

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-AutomationLog "step_start name=$Name"
    try {
        $result = & $Action
        Write-AutomationLog "step_ok name=$Name result=$result"
        return [pscustomobject]@{ Name = $Name; Ok = $true; Result = $result; Error = $null }
    } catch {
        Write-AutomationLog "step_error name=$Name error=$($_.Exception.Message)"
        return [pscustomobject]@{ Name = $Name; Ok = $false; Result = $null; Error = $_.Exception.Message }
    }
}

function ConvertTo-OneLineJson {
    param([object]$Value)
    return ($Value | ConvertTo-Json -Depth 8 -Compress)
}

function Invoke-JsonRequest {
    param(
        [string]$Uri,
        [string]$Method = "GET",
        [object]$Body = $null,
        [string]$Token = ""
    )
    $headers = @("Accept: application/json")
    if ($Token) {
        $headers += "Authorization: Bearer $Token"
    }
    $args = @("-s", "-f", "-X", $Method, $Uri)
    foreach ($header in $headers) {
        $args += @("-H", $header)
    }
    if ($null -ne $Body) {
        $tmp = Join-Path $env:TEMP ("sekurer-body-" + [guid]::NewGuid().ToString("N") + ".json")
        ConvertTo-OneLineJson $Body | Set-Content -LiteralPath $tmp -Encoding ascii
        $args += @("-H", "Content-Type: application/json", "--data-binary", "@$tmp")
    }
    $response = & curl.exe @args
    if ($LASTEXITCODE -ne 0) {
        throw "curl failed for $Method $Uri"
    }
    if (-not $response) {
        return $null
    }
    return ($response | ConvertFrom-Json)
}

function Resolve-ComposeBaseUrl {
    if ($BaseUrl) {
        return $BaseUrl.TrimEnd("/")
    }

    $port = $null
    try {
        $portLine = docker compose port api 8000 2>$null
        if ($LASTEXITCODE -eq 0 -and $portLine) {
            $port = (($portLine | Select-Object -First 1) -split ":")[-1]
        }
    } catch {
        $port = $null
    }

    $candidates = @()
    if ($port) {
        $candidates += "http://localhost:$port"
    }
    if ($ApiHostPort) {
        $candidates += "http://localhost:$ApiHostPort"
    }
    $candidates += @("http://localhost:8000", "http://localhost:8001")

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        try {
            $null = Invoke-JsonRequest -Uri "$candidate/health"
            return $candidate
        } catch {
        }
    }
    throw "Could not resolve a healthy API base URL"
}

function Resolve-FlutterExecutable {
    if ($FlutterBin -and (Test-Path -LiteralPath $FlutterBin)) {
        return $FlutterBin
    }
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }
    $candidates = @(
        "C:\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat",
        "C:\tools\flutter\bin\flutter.bat",
        "C:\Users\denba\flutter\bin\flutter.bat",
        "C:\Users\denba\Downloads\flutter\bin\flutter.bat"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    throw "Flutter SDK was not found in PATH or known install locations"
}

function New-TestAudioFile {
    $audioPath = Join-Path $env:TEMP ("sekurer-call-" + [guid]::NewGuid().ToString("N") + ".mp3")
    [IO.File]::WriteAllBytes($audioPath, [byte[]](
        0x49,0x44,0x33,0x03,0x00,0x00,0x00,0x00,0x00,0x21,
        0x54,0x49,0x54,0x32,0x00,0x00,0x00,0x0F,0x00,0x00,
        0x03,0x44,0x75,0x6D,0x6D,0x79,0x20,0x61,0x75,0x64,0x69,0x6F,0x00
    ))
    return $audioPath
}

Set-Location -LiteralPath $ProjectRoot
Write-AutomationLog "sekurer_automation_start project=$ProjectRoot"

if (-not $SkipDocker) {
    $null = Invoke-Step "docker_compose_ps" { docker compose ps | Out-String }
    $null = Invoke-Step "alembic_upgrade_head" { docker compose exec -T api alembic upgrade head | Out-String }
}

$ResolvedBaseUrl = $null
$health = Invoke-Step "api_health" {
    $script:ResolvedBaseUrl = Resolve-ComposeBaseUrl
    ConvertTo-OneLineJson (Invoke-JsonRequest -Uri "$script:ResolvedBaseUrl/health")
}

$workerStatus = Invoke-Step "worker_status" {
    if (-not $script:ResolvedBaseUrl) { $script:ResolvedBaseUrl = Resolve-ComposeBaseUrl }
    ConvertTo-OneLineJson (Invoke-JsonRequest -Uri "$script:ResolvedBaseUrl/worker/status")
}

$email = "auto_$(Get-Date -Format yyyyMMddHHmmss)@example.com"
$password = "demo12345"
$token = $null
$callId = $null
$finalStatus = $null
$taskCount = 0

$register = Invoke-Step "register" {
    if (-not $script:ResolvedBaseUrl) { $script:ResolvedBaseUrl = Resolve-ComposeBaseUrl }
    $response = Invoke-JsonRequest -Uri "$script:ResolvedBaseUrl/api/v1/auth/register" -Method "POST" -Body @{ email = $email; password = $password; name = "Automation Test" }
    if (-not $response.access_token) { throw "Registration did not return access_token" }
    "registered=$email"
}

$login = Invoke-Step "login" {
    if (-not $register.Ok) { throw "Skipped because register failed" }
    $response = Invoke-JsonRequest -Uri "$script:ResolvedBaseUrl/api/v1/auth/login" -Method "POST" -Body @{ email = $email; password = $password }
    if (-not $response.access_token) { throw "Login did not return access_token" }
    $script:token = $response.access_token
    "token=ok"
}

$upload = Invoke-Step "upload_audio" {
    if (-not $script:token) { throw "Skipped because login failed" }
    $audioPath = New-TestAudioFile
    $response = & curl.exe -s -f -X POST "$script:ResolvedBaseUrl/api/v1/calls/upload" `
        -H "Authorization: Bearer $script:token" `
        -F "file=@$audioPath;type=audio/mpeg" `
        -F "title=Automation call" `
        -F "contact_name=Automation Contact" `
        -F "phone_number=+15555550123"
    if ($LASTEXITCODE -ne 0) { throw "Upload request failed" }
    $json = $response | ConvertFrom-Json
    if (-not $json.id) { throw "Upload did not return call id" }
    $script:callId = $json.id
    "call_id=$script:callId"
}

$processing = Invoke-Step "worker_processing" {
    if (-not $script:callId) { throw "Skipped because upload failed" }
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Seconds 2
        $detail = Invoke-JsonRequest -Uri "$script:ResolvedBaseUrl/api/v1/calls/$script:callId" -Token $script:token
        $script:finalStatus = $detail.status
        if ($script:finalStatus -eq "ready" -or $script:finalStatus -eq "failed") {
            break
        }
    }
    if ($script:finalStatus -ne "ready") { throw "Call status ended as $script:finalStatus" }
    "status=$script:finalStatus"
}

$tasks = Invoke-Step "tasks_check" {
    if (-not $script:token) { throw "Skipped because login failed" }
    $items = Invoke-JsonRequest -Uri "$script:ResolvedBaseUrl/api/v1/tasks" -Token $script:token
    $script:taskCount = @($items).Count
    if ($script:taskCount -lt 1) { throw "Expected at least one task" }
    "tasks=$script:taskCount"
}

$flutterResult = $null
if (-not $SkipFlutter) {
    $flutterResult = Invoke-Step "flutter_android" {
        $flutter = Resolve-FlutterExecutable
        $env:ANDROID_SDK_ROOT = $AndroidSdkRoot
        $preferredNdk = Join-Path $AndroidSdkRoot "ndk\28.2.13676358"
        if (-not (Test-Path -LiteralPath $preferredNdk)) {
            $preferredNdk = Join-Path $AndroidSdkRoot "ndk\30.0.14904198"
        }
        $env:ANDROID_NDK_HOME = $preferredNdk
        $env:PATH = "$(Split-Path -Parent $flutter);$AndroidSdkRoot\platform-tools;$AndroidSdkRoot\emulator;$env:PATH"
        $adb = Join-Path $AndroidSdkRoot "platform-tools\adb.exe"
        $emulator = Join-Path $AndroidSdkRoot "emulator\emulator.exe"
        if (-not (Test-Path -LiteralPath $adb)) { throw "adb not found at $adb" }
        if (-not (Test-Path -LiteralPath $emulator)) { throw "emulator not found at $emulator" }

        Set-Location -LiteralPath $MobileDir
        if (-not (Test-Path -LiteralPath (Join-Path $MobileDir "android\app"))) {
            & $flutter create --platforms=android .
            if ($LASTEXITCODE -ne 0) { throw "flutter create failed" }
        }
        $mobileApiUrl = $script:ResolvedBaseUrl.Replace("localhost", "10.0.2.2").Replace("127.0.0.1", "10.0.2.2")
        & $flutter clean
        if ($LASTEXITCODE -ne 0) { throw "flutter clean failed" }
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }
        & $flutter build apk --release --dart-define="API_BASE_URL=$mobileApiUrl"
        if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed" }

        $devices = & $adb devices
        if (($devices -join "`n") -notmatch "emulator-5554\s+device") {
            Start-Process -FilePath $emulator -ArgumentList @("-avd", $AvdName, "-no-snapshot-load") -WindowStyle Hidden
            for ($i = 0; $i -lt 90; $i++) {
                Start-Sleep -Seconds 2
                $devices = & $adb devices
                if (($devices -join "`n") -match "emulator-5554\s+device") { break }
            }
        }
        for ($i = 0; $i -lt 120; $i++) {
            Start-Sleep -Seconds 2
            $bootCompleted = (& $adb shell getprop sys.boot_completed 2>$null | Out-String).Trim()
            $packageService = (& $adb shell service check package 2>$null | Out-String)
            if ($bootCompleted -eq "1" -and $packageService -match "found") { break }
        }
        $bootCompleted = (& $adb shell getprop sys.boot_completed 2>$null | Out-String).Trim()
        $packageService = (& $adb shell service check package 2>$null | Out-String)
        if ($bootCompleted -ne "1" -or $packageService -notmatch "found") {
            throw "Android emulator is not ready for APK install"
        }
        & $flutter install -d emulator-5554 --release
        if ($LASTEXITCODE -ne 0) { throw "flutter install failed" }
        & $adb shell monkey -p com.example.sekurer_mobile 1 | Out-Null
        Start-Sleep -Seconds 2

        $mobileEmail = "mobile_ui_$(Get-Date -Format yyyyMMddHHmmss)@mail.com"
        $mobileEmailInput = $mobileEmail.Replace("@", "\@")
        $mobilePassword = "demo12345"
        & $adb shell input tap 540 840
        Start-Sleep -Seconds 1
        & $adb shell input tap 200 400
        & $adb shell input text MobileUITest
        & $adb shell input tap 200 545
        & $adb shell input text $mobileEmailInput
        & $adb shell input tap 200 690
        & $adb shell input text $mobilePassword
        & $adb shell input tap 540 925
        Start-Sleep -Seconds 6
        & $adb shell uiautomator dump /sdcard/sekurer-after-register.xml | Out-Null
        $afterRegister = (& $adb shell cat /sdcard/sekurer-after-register.xml) -join "`n"
        if ($afterRegister -match "Неизвестная ошибка|Сервер не отвечает|Invalid") {
            throw "mobile UI register failed"
        }
        if ($afterRegister -notmatch "Sekurer") {
            throw "mobile UI register did not reach home screen"
        }

        & $adb shell input tap 1000 220
        Start-Sleep -Seconds 2
        & $adb shell input tap 200 400
        & $adb shell input text $mobileEmailInput
        & $adb shell input tap 200 545
        & $adb shell input text $mobilePassword
        & $adb shell input tap 540 715
        Start-Sleep -Seconds 6
        & $adb shell uiautomator dump /sdcard/sekurer-after-login.xml | Out-Null
        $afterLogin = (& $adb shell cat /sdcard/sekurer-after-login.xml) -join "`n"
        if ($afterLogin -match "Неизвестная ошибка|Сервер не отвечает|Invalid") {
            throw "mobile UI login failed"
        }
        if ($afterLogin -notmatch "Sekurer") {
            throw "mobile UI login did not reach home screen"
        }

        "flutter=apk_built_installed_launched_mobile_ui_ok api=$mobileApiUrl email=$mobileEmail"
    }
}

$backendSmokeOk = $health.Ok -and $workerStatus.Ok -and $register.Ok -and $login.Ok -and $upload.Ok -and $processing.Ok -and $tasks.Ok
$flutterOk = $SkipFlutter -or ($null -ne $flutterResult -and $flutterResult.Ok)
$summary = [ordered]@{
    final_smoke = ($backendSmokeOk -and $flutterOk)
    backend_smoke = $backendSmokeOk
    base_url = $ResolvedBaseUrl
    email = $email
    call_id = $callId
    call_status = $finalStatus
    task_count = $taskCount
    flutter = if ($null -eq $flutterResult) { "skipped" } elseif ($flutterResult.Ok) { "ok" } else { "failed: $($flutterResult.Error)" }
}
$summaryLine = "final_smoke " + (ConvertTo-OneLineJson $summary)
Write-AutomationLog $summaryLine
try {
    $null = Invoke-JsonRequest -Uri "$ResolvedBaseUrl/automation/log" -Method "POST" -Body @{ event = "final_smoke"; payload = $summary }
} catch {
    Write-AutomationLog "api_log_error error=$($_.Exception.Message)"
}

if (-not $summary.final_smoke) {
    exit 1
}
