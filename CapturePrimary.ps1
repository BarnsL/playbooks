# CapturePrimary.ps1 — Background script that binds PrtScn to primary-monitor-only capture
# Dynamically detects resolution — survives resizes, Parsec, RDP, etc.
# Run once at logon: powershell -WindowStyle Hidden -File CapturePrimary.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class GlobalHotkey : NativeWindow, IDisposable {
    private const int WM_HOTKEY = 0x0312;
    private const int MOD_NOREPEAT = 0x4000;
    private int _id;
    private Action _callback;

    [DllImport("user32.dll")]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    public GlobalHotkey(int id, uint modifiers, uint vk, Action callback) {
        _id = id;
        _callback = callback;
        this.CreateHandle(new CreateParams());
        RegisterHotKey(this.Handle, id, modifiers | MOD_NOREPEAT, vk);
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == _id) {
            _callback();
        }
        base.WndProc(ref m);
    }

    public void Dispose() {
        UnregisterHotKey(this.Handle, _id);
        this.DestroyHandle();
    }
}
"@ -ReferencedAssemblies System.Windows.Forms

# Capture primary monitor to clipboard
function Capture-PrimaryScreen {
    try {
        $primary = [System.Windows.Forms.Screen]::PrimaryScreen
        $bounds = $primary.Bounds
        
        $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
        $graphics.Dispose()
        
        [System.Windows.Forms.Clipboard]::SetImage($bitmap)
        $bitmap.Dispose()
    } catch {
        # Silently ignore clipboard errors (e.g. clipboard locked)
    }
}

# Register PrtScn (VK_SNAPSHOT = 0x2C, no modifier)
$hotkey = New-Object GlobalHotkey 1, 0, 0x2C, ${function:Capture-PrimaryScreen}

# Register Ctrl+PrtScn → Windows Snipping Tool
$snippingHotkey = New-Object GlobalHotkey 2, 2, 0x2C, { 
    Start-Process "explorer.exe" "ms-screenclip:" 
}

# Keep running until logoff
Write-Host "Primary-screen capture active. PrtScn = primary only. Ctrl+PrtScn = snipping."
[System.Windows.Forms.Application]::Run()
