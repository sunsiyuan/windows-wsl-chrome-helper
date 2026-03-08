# windows-wsl-chrome-helper

One-click launcher for starting Chrome on Windows with a DevTools port and verifying access from WSL.

## Files

- `Start-Debug-Chrome.ps1`: Starts or reuses Chrome with remote debugging on port `9222`, then verifies WSL access through port `9223`.
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

## Notes

- Chrome uses a separate profile directory at `C:\temp\chrome-devtools`.
- Windows local access stays on `http://127.0.0.1:9222`.
- WSL access uses the Windows host IP on port `9223`.
