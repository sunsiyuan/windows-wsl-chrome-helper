param(
  [string]$BridgeRepo = "C:\Users\Sun\work\openclaw-wsl2-windows10-bridge",
  [string]$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe",
  [string]$ProfileDir = "C:\temp\chrome-devtools",
  [int]$WindowsPort = 9222,
  [int]$WslPort = 9223
)
$ErrorActionPreference = "Stop"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath),'-BridgeRepo',('"{0}"' -f $BridgeRepo),'-ChromePath',('"{0}"' -f $ChromePath),'-ProfileDir',('"{0}"' -f $ProfileDir),'-WindowsPort',$WindowsPort,'-WslPort',$WslPort)
  exit 0
}
& (Join-Path $BridgeRepo 'scripts\windows\setup-admin.ps1') -ChromeLocalPort $WindowsPort -ChromeBridgePort $WslPort | Out-Host
& (Join-Path $BridgeRepo 'scripts\windows\start-chrome-cdp.ps1') -ChromeLocalPort $WindowsPort -ChromeBridgePort $WslPort -ChromePath $ChromePath -ProfileDir $ProfileDir | Out-Host
$windowsUrl = "http://127.0.0.1:$WindowsPort/json/version"
$version = Invoke-RestMethod -Uri $windowsUrl -TimeoutSec 5
$wslHost = (wsl.exe -e sh -lc "ip route | awk '/default/ {print \$3}'").Trim()
$wslUrl = "http://${wslHost}:$WslPort/json/version"
$wslJson = wsl.exe -e sh -lc "curl -sS --max-time 8 $wslUrl"
Write-Host "Windows endpoint: $windowsUrl" -ForegroundColor Green
Write-Host "WSL endpoint: $wslUrl" -ForegroundColor Green
Write-Host $wslJson
$botWsUrl = $version.webSocketDebuggerUrl -replace '127\.0\.0\.1', $wslHost -replace ":$WindowsPort", ":$WslPort"
$message = @"
Goal: I am a Windows + WSL user and I need tools running in WSL to reuse the Chrome DevTools instance already started on Windows.

Please use this browser configuration instead of launching a new browser:

- Windows local endpoint: $windowsUrl
- WSL endpoint: $wslUrl
- DevTools Browser WebSocket: $botWsUrl
- Dedicated profile directory: $ProfileDir
"@
Write-Host ""
Write-Host '== Message For Lobster Bot ==' -ForegroundColor Cyan
Write-Host $message
try { Set-Clipboard -Value $message } catch {}
Read-Host 'Done. Press Enter to close'
