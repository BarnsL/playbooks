# Windows Print Screen — Primary Monitor Only (Greenshot)

Capturing only the primary monitor with Print Screen, while keeping full region/window snipping available. Works with multi-monitor setups including negative-coordinate displays (secondary to the left of primary).

## Quick Reference

| Key | Action |
|---|---|
| **PrtScn** | Capture primary monitor only → clipboard + Desktop PNG |
| **Ctrl + PrtScn** | Region snipping (drag to select) |
| **Alt + PrtScn** | Active window capture |

## Why Greenshot vs Native Windows

- Windows `PrtScn` always captures ALL monitors into one wide bitmap — no native way to limit to primary only
- Windows `Win+Shift+S` opens Snipping Tool (requires manual region selection every time)
- Greenshot is open-source, lightweight, and gives per-key binding with fixed-region capture

## Full Setup Process

### 1. Disable Snipping Tool Print Screen Hijack

Windows 10/11 hijacks `PrtScn` to open Snipping Tool by default. Disable it:

```
reg add "HKCU\Control Panel\Keyboard" /v PrintScreenKeyForSnippingEnabled /t REG_DWORD /d 0 /f
```

### 2. Install Greenshot

Download from: https://getgreenshot.org/downloads/

Silent install:
```bash
Greenshot-INSTALLER-1.3.315-RELEASE.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

### 3. Configure Greenshot

Greenshot settings live at `%APPDATA%\Greenshot\Greenshot.ini`.

#### Core hotkey mapping

```ini
; PrtScn = capture last region (set to primary monitor bounds)
RegionHotkey=Ctrl + PrintScreen
WindowHotkey=Alt + PrintScreen
FullscreenHotkey=None
LastregionHotkey=PrintScreen
```

#### Fixed region = primary monitor bounds

Set the "last captured region" to match your primary monitor resolution:

```ini
LastCapturedRegion=0,0,1920,1080
```

Replace `1920,1080` with your primary monitor's actual resolution. Find it via:
```powershell
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
```

#### Capture settings

```ini
CaptureMousepointer=True
CaptureDelay=100
OutputFilePath=C:\Users\%USERNAME%\Desktop
OutputFileFormat=png
OutputFileCopyPathToClipboard=True
```

### 4. Auto-start with Windows

Create a shortcut in the Startup folder:
```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Greenshot.lnk
```
Target: `%LOCALAPPDATA%\Programs\Greenshot\Greenshot.exe`

### 5. Restart Greenshot

```bash
taskkill /F /IM Greenshot.exe
start "" "%LOCALAPPDATA%\Programs\Greenshot\Greenshot.exe"
```

## Why Fixed Region Instead of Screen Detection

Greenshot's `ScreenCaptureMode=Fixed` + `ScreenToCapture=N` uses internal screen enumeration that can break with:
- Monitors at negative coordinates (secondary to the left of primary)
- Different display adapters (dual GPU setups)
- Some Windows 11 builds

The "capture last region" approach (`LastregionHotkey`) with a preset `LastCapturedRegion` matching the primary monitor bounds bypasses screen detection entirely — it captures that exact pixel region every time.

## Troubleshooting

**PrtScn captures wrong screen or all monitors:**
Check that `FullscreenHotkey=None` (not `PrintScreen`) — otherwise the fullscreen capture overrides the region capture.

**IndexOutOfRangeException in Greenshot:**
Means Greenshot's internal screen list doesn't match what you set in `ScreenToCapture`. Switch to the fixed-region approach above.

**Greenshot not responding to PrtScn:**
- Kill and restart Greenshot after config changes (it reads `.ini` at startup only)
- Check no other tool is registered for the same hotkey
- Verify the registry key from step 1 is still `0`

**Want different output location:**
Change `OutputFilePath` in the `.ini`. Supports environment variables.

## Uninstall

```bash
taskkill /F /IM Greenshot.exe
# Standard Windows uninstall, or:
"%LOCALAPPDATA%\Programs\Greenshot\unins000.exe" /VERYSILENT
# Re-enable Snipping Tool PrtScn:
reg add "HKCU\Control Panel\Keyboard" /v PrintScreenKeyForSnippingEnabled /t REG_DWORD /d 1 /f
```
