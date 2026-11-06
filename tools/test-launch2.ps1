param(
    [string]$Exe = 'C:\Users\Usuario\Documents\TriEiLab\DIS.exe',
    [string]$Clicks = '',
    [int]$WaitSec = 6,
    [string]$Prefix = 'C:\Users\Usuario\Documents\deepseek-harness\default-workspace\tools\dis-step'
)

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$src = @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class Win2 {
    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
    [DllImport("user32.dll")] public static extern IntPtr SetForegroundWindow(IntPtr h);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }

    public static List<string> List(uint targetPid) {
        var res = new List<string>();
        EnumWindows((h, l) => {
            uint pid; GetWindowThreadProcessId(h, out pid);
            if (pid == targetPid) {
                var sb = new StringBuilder(512); GetWindowText(h, sb, 512);
                var cn = new StringBuilder(256); GetClassName(h, cn, 256);
                RECT r; GetWindowRect(h, out r);
                if (IsWindowVisible(h) || sb.Length > 0)
                    res.Add(string.Format("TOP class='{0}' title='{1}' vis={2} rect={3},{4} {5}x{6}",
                        cn, sb, IsWindowVisible(h), r.Left, r.Top, (r.Right-r.Left), (r.Bottom-r.Top)));
                EnumChildWindows(h, (ch, l2) => {
                    var sb2 = new StringBuilder(512); GetWindowText(ch, sb2, 512);
                    var cn2 = new StringBuilder(256); GetClassName(ch, cn2, 256);
                    if (sb2.Length > 0)
                        res.Add("    child class='" + cn2 + "' text='" + sb2 + "'");
                    return true;
                }, IntPtr.Zero);
            }
            return true;
        }, IntPtr.Zero);
        return res;
    }
    public static void Click(int x, int y) {
        SetCursorPos(x, y);
        System.Threading.Thread.Sleep(250);
        mouse_event(0x0002, 0, 0, 0, IntPtr.Zero);
        System.Threading.Thread.Sleep(80);
        mouse_event(0x0004, 0, 0, 0, IntPtr.Zero);
    }
}
'@
Add-Type -TypeDefinition $src -ReferencedAssemblies System.Drawing, System.Windows.Forms

function Shot([string]$file) {
    $vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $bmp = New-Object System.Drawing.Bitmap($vs.Width, $vs.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($vs.Left, $vs.Top, 0, 0, $bmp.Size)
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

Write-Host ">>> Lanzando: $Exe"
$p = Start-Process -FilePath $Exe -WorkingDirectory (Split-Path $Exe) -PassThru
Start-Sleep -Seconds $WaitSec
$p.Refresh()
Write-Host ">>> PID $($p.Id) alive=$(-not $p.HasExited)"
[Win2]::List([uint32]$p.Id) | ForEach-Object { Write-Host "    $_" }

$i = 0
foreach ($c in ($Clicks -split ';' | Where-Object { $_ -ne '' })) {
    $i++
    $xy = $c -split ','
    $x = [int]$xy[0]; $y = [int]$xy[1]
    Write-Host ">>> CLICK #$i en ($x,$y)"
    [Win2]::Click($x, $y)
    Start-Sleep -Seconds $WaitSec
    $p.Refresh()
    if ($p.HasExited) { Write-Host "    el proceso TERMINO (exit $($p.ExitCode))"; break }
    [Win2]::List([uint32]$p.Id) | ForEach-Object { Write-Host "    $_" }
    $f = "$Prefix-$i.png"
    Shot $f
    Write-Host "    captura -> $f"
}

Shot "$Prefix-final.png"
Write-Host ">>> Captura final -> $Prefix-final.png"

if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
