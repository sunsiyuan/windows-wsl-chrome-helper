$ErrorActionPreference = 'Stop'

$chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$profileDir = 'C:\temp\chrome-devtools'
$windowsPort = 9222
$wslPort = 9223

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "== $Text ==" -ForegroundColor Cyan
}

if (-not (Test-Path $chromePath)) {
    Write-Host "Chrome not found: $chromePath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

Write-Section "Start Chrome"

$versionUrl = "http://127.0.0.1:$windowsPort/json/version"
$existing = $null
try {
    $existing = Invoke-RestMethod -Uri $versionUrl -TimeoutSec 2
} catch {
}

if (-not $existing) {
    Start-Process -FilePath $chromePath -ArgumentList @(
        "--remote-debugging-port=$windowsPort",
        "--user-data-dir=$profileDir"
    ) | Out-Null

    $started = $false
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 800
        try {
            $existing = Invoke-RestMethod -Uri $versionUrl -TimeoutSec 2
            $started = $true
            break
        } catch {
        }
    }

    if (-not $started) {
        Write-Host "Chrome started failed or debug port $windowsPort is unavailable." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host "Windows endpoint: $versionUrl" -ForegroundColor Green
Write-Host "Browser: $($existing.Browser)"
Write-Host "WebSocket: $($existing.webSocketDebuggerUrl)"

Write-Section "Resolve WSL Host"

$wslHost = $null
try {
    $wslHost = (wsl.exe -e sh -lc "sed -n 's/^nameserver //p' /etc/resolv.conf | head -n 1").Trim()
} catch {
}

if (-not $wslHost) {
    Write-Host "WSL host IP not found. Skipping WSL test." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

Write-Host "WSL sees Windows host as: $wslHost"

Write-Section "Test WSL Access"

$wslUrl = "http://${wslHost}:$wslPort/json/version"
$wslOutput = $null
try {
    $wslOutput = wsl.exe -e sh -lc "curl -s --max-time 5 $wslUrl"
} catch {
}

if ($LASTEXITCODE -eq 0 -and $wslOutput) {
    Write-Host "WSL endpoint: $wslUrl" -ForegroundColor Green
    Write-Host $wslOutput
} else {
    Write-Host "WSL test failed for $wslUrl" -ForegroundColor Yellow
    Write-Host "This launcher expects a Windows portproxy: 0.0.0.0:$wslPort -> 127.0.0.1:$windowsPort"
    Write-Host "If needed, run the admin setup script once."
}

Write-Host ""
Read-Host "Done. Press Enter to close"
