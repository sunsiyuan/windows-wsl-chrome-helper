# windows-wsl-chrome-helper

One-click launcher for repairing the Windows-to-WSL Chrome CDP bridge, starting Chrome with a DevTools port, verifying access from WSL, and printing a ready-to-paste message for chatbot or agent tools.

## Files

- `Start-Debug-Chrome.ps1`: Self-elevates, repairs the bridge, starts or reuses Chrome with remote debugging on port `9222`, verifies WSL access through port `9223`, and prints a handoff message for tools running in WSL.
- `start-debug-chrome.cmd`: Double-click entry point for Windows desktop use. Existing desktop shortcuts can keep pointing here.
- `install-portproxy-admin.cmd`: Legacy stub; the repair step is now built into `Start-Debug-Chrome.ps1`.

## Usage

1. Double-click `start-debug-chrome.cmd` or use the existing desktop shortcut.
2. Accept the UAC prompt so the launcher can repair the bridge automatically.
3. In WSL, connect to:

```sh
HOST_IP="$(ip route | awk '/default/ {print $3}')"
curl "http://$HOST_IP:9223/json/version"
```

4. Copy the printed "Message For Lobster Bot" into your chatbot or automation tool so it reuses this browser instead of launching its own.

## Notes

- Chrome uses a separate profile directory at `C:\temp\chrome-devtools`.
- Windows local access stays on `http://127.0.0.1:9222`.
- WSL access uses the Windows host IP on port `9223`.
- The launcher delegates repair/start work to `C:\Users\Sun\work\openclaw-wsl2-windows10-bridge\scripts\windows\`.
