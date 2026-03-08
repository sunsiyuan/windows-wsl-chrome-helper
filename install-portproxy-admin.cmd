@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Please run this file as Administrator.
  pause
  exit /b 1
)

netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=9223 >nul 2>&1
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=9223 connectaddress=127.0.0.1 connectport=9222
netsh interface portproxy show v4tov4
pause
