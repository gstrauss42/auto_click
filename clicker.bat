<# : clicker.bat
@echo off
set "CLICKER_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ([IO.File]::ReadAllText($env:CLICKER_SELF))"
exit /b
#>

# =====================================================================
#  Burst clicker - double-click this .bat to start.
#    F6 = fire one burst of clicks at the mouse cursor
#    F7 = quit (closing this window also quits)
#  Installs nothing and changes no system settings. Delete to remove.
# =====================================================================

# ----------------------------- SETTINGS ------------------------------
$Clicks     = 450   # clicks per burst (hard cap 5000)
$DurationMs = 100    # burst length in milliseconds
$BurstKey   = 'F6'   # any System.Windows.Forms.Keys name, e.g. F8, Pause
$QuitKey    = 'F7'
$CooldownMs = 300    # burst-key presses this soon after a burst are ignored

# Never fire over these window classes: desktop, taskbars, File Explorer,
# console windows. At burst speed every other click is a double-click,
# so these would open things over and over.
$Protected = @(
    'Progman', 'WorkerW',
    'Shell_TrayWnd', 'Shell_SecondaryTrayWnd',
    'CabinetWClass',
    'ConsoleWindowClass', 'CASCADIA_HOSTING_WINDOW_CLASS'
)
# ---------------------------------------------------------------------

$ErrorActionPreference = 'Stop'
try {
    $Host.UI.RawUI.WindowTitle = "Burst clicker - $QuitKey to quit"
    Add-Type -AssemblyName System.Windows.Forms
    $burstVk = [int][System.Windows.Forms.Keys]$BurstKey
    $quitVk  = [int][System.Windows.Forms.Keys]$QuitKey

    Add-Type -IgnoreWarnings -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class BurstClicker
{
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    [StructLayout(LayoutKind.Sequential)]
    public struct MSG
    {
        public IntPtr hwnd; public uint message; public IntPtr wParam; public IntPtr lParam;
        public uint time; public POINT pt;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT
    {
        public int dx; public int dy; public uint mouseData; public uint dwFlags;
        public uint time; public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT { public uint type; public MOUSEINPUT mi; }

    [DllImport("user32.dll")] static extern uint SendInput(uint count, INPUT[] inputs, int size);
    [DllImport("user32.dll")] static extern bool RegisterHotKey(IntPtr hWnd, int id, uint mods, uint vk);
    [DllImport("user32.dll")] static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetMessage(out MSG msg, IntPtr hWnd, uint min, uint max);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr DispatchMessage(ref MSG msg);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out POINT p);
    [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
    [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr hWnd, uint flags);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hWnd, StringBuilder name, int max);
    [DllImport("winmm.dll")] static extern uint timeBeginPeriod(uint ms);
    [DllImport("winmm.dll")] static extern uint timeEndPeriod(uint ms);

    const uint INPUT_MOUSE = 0, LEFTDOWN = 0x0002, LEFTUP = 0x0004;
    const uint WM_HOTKEY = 0x0312, MOD_NOREPEAT = 0x4000, GA_ROOT = 2;
    const int ID_BURST = 1, ID_QUIT = 2;

    public static string Run(int clicks, int durationMs, int burstVk, int quitVk, int cooldownMs, string[] protectedClasses)
    {
        clicks = Math.Max(1, Math.Min(clicks, 5000));
        durationMs = Math.Max(1, Math.Min(durationMs, 10000));

        if (!RegisterHotKey(IntPtr.Zero, ID_BURST, MOD_NOREPEAT, (uint)burstVk))
            return "Could not grab the burst key - another program (or another copy of this) is using it.";
        if (!RegisterHotKey(IntPtr.Zero, ID_QUIT, MOD_NOREPEAT, (uint)quitVk))
        {
            UnregisterHotKey(IntPtr.Zero, ID_BURST);
            return "Could not grab the quit key - another program is using it.";
        }

        timeBeginPeriod(1);
        try
        {
            Stopwatch clock = Stopwatch.StartNew();
            long readyAtMs = 0;
            MSG msg;
            while (GetMessage(out msg, IntPtr.Zero, 0, 0) > 0)
            {
                if (msg.message != WM_HOTKEY || msg.hwnd != IntPtr.Zero) { DispatchMessage(ref msg); continue; }
                int id = msg.wParam.ToInt32();
                if (id == ID_QUIT) break;
                if (id == ID_BURST && clock.ElapsedMilliseconds >= readyAtMs)
                {
                    Console.WriteLine("  " + Burst(clicks, durationMs, protectedClasses));
                    readyAtMs = clock.ElapsedMilliseconds + cooldownMs;
                }
            }
        }
        finally
        {
            timeEndPeriod(1);
            UnregisterHotKey(IntPtr.Zero, ID_BURST);
            UnregisterHotKey(IntPtr.Zero, ID_QUIT);
        }
        return null;
    }

    static IntPtr RootUnderCursor()
    {
        POINT p;
        if (!GetCursorPos(out p)) return IntPtr.Zero;
        IntPtr w = WindowFromPoint(p);
        return w == IntPtr.Zero ? IntPtr.Zero : GetAncestor(w, GA_ROOT);
    }

    static string ClassOf(IntPtr hWnd)
    {
        StringBuilder sb = new StringBuilder(256);
        GetClassName(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }

    static string Burst(int clicks, int durationMs, string[] protectedClasses)
    {
        IntPtr target = RootUnderCursor();
        if (target == IntPtr.Zero) return "Skipped: no window under the cursor.";
        string cls = ClassOf(target);
        foreach (string name in protectedClasses)
            if (string.Equals(name, cls, StringComparison.OrdinalIgnoreCase))
                return "Skipped: cursor is over a protected window (" + cls + ").";

        IntPtr startForeground = GetForegroundWindow();
        INPUT[] click = new INPUT[2];
        click[0].type = INPUT_MOUSE; click[0].mi.dwFlags = LEFTDOWN;
        click[1].type = INPUT_MOUSE; click[1].mi.dwFlags = LEFTUP;
        int size = Marshal.SizeOf(typeof(INPUT));

        double ticksPerClick = (double)Stopwatch.Frequency * durationMs / 1000.0 / clicks;
        long checkEvery = Stopwatch.Frequency / 1000;   // re-check the target every 1 ms
        long sleepIfOver = Stopwatch.Frequency / 500;   // only sleep when >2 ms to wait
        long nextCheck = 0;
        int sent = 0;
        Stopwatch sw = Stopwatch.StartNew();

        for (int i = 0; i < clicks; i++)
        {
            long due = (long)(i * ticksPerClick);
            while (true)
            {
                long wait = due - sw.ElapsedTicks;
                if (wait <= 0) break;
                if (wait > sleepIfOver) Thread.Sleep(1); else Thread.SpinWait(20);
            }

            if (sw.ElapsedTicks >= nextCheck)
            {
                if (RootUnderCursor() != target)
                    return "Stopped after " + sent + " clicks: cursor left the window.";
                IntPtr fg = GetForegroundWindow();
                if (fg != IntPtr.Zero && fg != target && fg != startForeground)
                    return "Stopped after " + sent + " clicks: another window came to the front.";
                nextCheck = sw.ElapsedTicks + checkEvery;
            }

            // Down + up in one call: Windows inserts them as a unit, so the button can never stick.
            if (SendInput(2, click, size) != 2)
                return "Stopped after " + sent + " clicks: Windows blocked the input (target running as admin?).";
            sent++;
        }
        return "Burst: " + sent + " clicks in " + sw.Elapsed.TotalMilliseconds.ToString("0.0") + " ms.";
    }
}
'@

    Write-Host ''
    Write-Host "  Ready: $Clicks clicks over $DurationMs ms per burst."
    Write-Host "  $BurstKey = fire at the mouse cursor    $QuitKey = quit (or close this window)"
    Write-Host '  Skips desktop/taskbar/Explorer/console windows; a burst stops if the cursor leaves its window.'
    Write-Host ''

    $err = [BurstClicker]::Run($Clicks, $DurationMs, $burstVk, $quitVk, $CooldownMs, [string[]]$Protected)
    if ($err) { throw $err }
}
catch {
    Write-Host ''
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host '  Press Enter to close' | Out-Null
}

