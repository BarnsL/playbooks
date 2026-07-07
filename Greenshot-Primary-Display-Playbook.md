# Greenshot Primary Display Playbook

Capture only the primary monitor with Print Screen — dynamically detects resolution so it survives display resizes (Parsec, RDP, resolution changes). Keeps region/window snipping available via Greenshot.

## Quick Reference

| Key | Action | Handled by |
|---|---|---|
| **PrtScn** | Capture primary monitor only → clipboard | PowerShell background script |
| **Ctrl + PrtScn** | Windows Snipping Tool (region) | PowerShell background script |
| **Alt + PrtScn** | Active window capture | Greenshot |

## Architecture

Two pieces work together:

1. **PowerShell background script** — registers PrtScn as a global hotkey, captures primary monitor dynamically every press (no hardcoded resolution)
2. **Greenshot** — handles Alt+PrtScn (window capture) and optional manual region capture from tray icon

Greenshot's own PrtScn binding is **disabled** — the PowerShell script owns PrtScn to ensure primary-only capture regardless of monitor configuration.

## Setup

### 1. Disable Snipping Tool Print Screen hijack

```cmd
reg add "HKCU\Control Panel\Keyboard" /v PrintScreenKeyForSnippingEnabled /t REG_DWORD /d 0 /f
```

### 2. Install Greenshot

Download from https://getgreenshot.org/downloads/

```cmd
Greenshot-INSTALLER-1.3.315-RELEASE.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

### 3. Configure Greenshot (free PrtScn for PowerShell)

Edit `%APPDATA%\Greenshot\Greenshot.ini`:

```ini
RegionHotkey=Ctrl + PrintScreen
WindowHotkey=Alt + PrintScreen
FullscreenHotkey=None
LastregionHotkey=None
```

### 4. Install the PowerShell capture script

Save `CapturePrimary.ps1` to a permanent location (e.g., `C:\Users\%USERNAME%\playbooks\`).

The script:
- Registers PrtScn as a global hotkey using Win32 `RegisterHotKey`
- On every press, queries `[System.Windows.Forms.Screen]::PrimaryScreen.Bounds` dynamically
- Captures that exact region to clipboard
- Also binds Ctrl+PrtScn to Windows Snipping Tool

### 5. Auto-start both

#### Greenshot
Create shortcut in `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\`:
- Target: `%LOCALAPPDATA%\Programs\Greenshot\Greenshot.exe`

#### PowerShell capture script
Create shortcut in the same Startup folder:
- Target: `powershell.exe`
- Arguments: `-WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\%USERNAME%\playbooks\CapturePrimary.ps1"`

### 6. Start immediately

```cmd
start "" "%LOCALAPPDATA%\Programs\Greenshot\Greenshot.exe"
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\%USERNAME%\playbooks\CapturePrimary.ps1"
```

## Why This Approach

Greenshot's built-in `ScreenCaptureMode=Fixed` + `ScreenToCapture=N` has two failure modes:

1. **Wrong screen ordering** — with negative-coordinate secondary displays (left of primary), Greenshot's internal monitor enumeration doesn't match .NET's `Screen.AllScreens` ordering, leading to `IndexOutOfRangeException` or capturing the wrong monitor
2. **Hardcoded resolution** — using `LastCapturedRegion` with a fixed pixel region breaks when the primary monitor changes resolution (Parsec, RDP, display scaling changes)

The PowerShell script avoids both: it calls `.NET`'s `PrimaryScreen.Bounds` every single press, so it always captures exactly what Windows considers the primary display at that moment.

## Troubleshooting

**PrtScn does nothing:**
- Verify the PowerShell script is running: `tasklist | findstr powershell`
- Check Greenshot isn't also bound to PrtScn: verify `FullscreenHotkey=None` and `LastregionHotkey=None` in `Greenshot.ini`
- Restart the script: kill powershell processes, re-run step 6

**Greenshot not responding:**
- Kill and restart after config changes (reads `.ini` at startup only)

**Both Greenshot and script fighting over Ctrl+PrtScn:**
- Set Greenshot's `RegionHotkey` to something unused or `None`

## Uninstall

```cmd
taskkill /F /IM Greenshot.exe
taskkill /F /IM powershell.exe
# Uninstall Greenshot via Windows, or:
"%LOCALAPPDATA%\Programs\Greenshot\unins000.exe" /VERYSILENT
# Re-enable Snipping Tool PrtScn:
reg add "HKCU\Control Panel\Keyboard" /v PrintScreenKeyForSnippingEnabled /t REG_DWORD /d 1 /f
# Remove startup shortcuts from:
# %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\
```
