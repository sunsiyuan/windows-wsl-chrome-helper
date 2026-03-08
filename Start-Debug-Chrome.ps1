$ErrorActionPreference = 'Stop'

$chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$profileDir = 'C:\temp\chrome-devtools'
$windowsPort = 9222
$wslPort = 9223
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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
        Write-Host "Chrome start failed or debug port $windowsPort is unavailable." -ForegroundColor Red
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
$wslOk = $false
try {
    $wslOutput = wsl.exe -e sh -lc "curl -s --max-time 5 $wslUrl"
} catch {
}

if ($LASTEXITCODE -eq 0 -and $wslOutput) {
    $wslOk = $true
    Write-Host "WSL endpoint: $wslUrl" -ForegroundColor Green
    Write-Host $wslOutput
} else {
    Write-Host "WSL test failed for $wslUrl" -ForegroundColor Yellow
    Write-Host "This launcher expects a Windows portproxy: 0.0.0.0:$wslPort -> 127.0.0.1:$windowsPort"
    Write-Host "If needed, run the admin setup script once."
}

Write-Section "Message For Lobster Bot"

$botWsUrl = $existing.webSocketDebuggerUrl -replace '127.0.0.1', $wslHost -replace ':9222', ":$wslPort"
$botMessage = @"
Goal: I am a Windows + WSL user and I need tools running in WSL to reuse the Chrome DevTools instance already started on Windows.

Please use this browser configuration instead of launching a new browser:

- Windows local endpoint: $versionUrl
- WSL endpoint: $wslUrl
- DevTools Browser WebSocket: $botWsUrl
- Dedicated profile directory: $profileDir

Recommended integration steps:

1. Request $wslUrl first and confirm it returns JSON.
2. Read webSocketDebuggerUrl from that JSON response.
3. Reuse this browser for all tab creation, inspection, and automation.
4. If the tool only accepts host and port, use host=$wslHost port=$wslPort.
5. If the tool runs on Windows instead of WSL, use host=127.0.0.1 port=$windowsPort.
"@

Write-Host $botMessage

try {
    Set-Clipboard -Value $botMessage
    Write-Host "The bot message has been copied to the clipboard." -ForegroundColor Green
} catch {
    Write-Host "Clipboard copy failed. You can still copy the message from this window." -ForegroundColor Yellow
}

if (-not $wslOk) {
    Write-Host ""
    Write-Host "WSL test is not passing. Fix the portproxy before using this with WSL tools." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Repo: $repoDir"
Write-Host ""
Read-Host "Done. Press Enter to close"
