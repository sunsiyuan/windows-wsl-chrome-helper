# windows-wsl-chrome-helper

One-click launcher for starting Chrome on Windows with a DevTools port, verifying access from WSL, and printing a ready-to-paste message for chatbot or agent tools.

## Files

- `Start-Debug-Chrome.ps1`: Starts or reuses Chrome with remote debugging on port `9222`, verifies WSL access through port `9223`, and prints a handoff message for tools running in WSL.
- `start-debug-chrome.cmd`: Double-click entry point for Windows desktop use.
- `install-portproxy-admin.cmd`: One-time admin helper to create `0.0.0.0:9223 -> 127.0.0.1:9222` with `netsh interface portproxy`.

## Usage

1. Run `install-portproxy-admin.cmd` once as Administrator.
2. Double-click `start-debug-chrome.cmd`.
3. In WSL, connect to:

```sh
HOST_IP="$(sed -n 's/^nameserver //p' /etc/resolv.conf | head -n 1)"
curl "http://$HOST_IP:9223/json/version"
```

4. Copy the printed "Message For Lobster Bot" into your chatbot or automation tool so it reuses this browser instead of launching its own.

## Notes

- Chrome uses a separate profile directory at `C:\temp\chrome-devtools`.
- Windows local access stays on `http://127.0.0.1:9222`.
- WSL access uses the Windows host IP on port `9223`.
