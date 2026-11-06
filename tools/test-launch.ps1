param(
    [string]$Exe = 'C:\Users\Usuario\Documents\TriEiLab\DIS.exe',
    [int]$WaitSec = 10,
    [string]$Shot = 'C:\Users\Usuario\Documents\deepseek-harness\default-workspace\tools\dis-launch.png'
)

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$src = @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class Win {
    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }

    public static List<string> List(uint targetPid) {
        var res = new List<string>();
        EnumWindows((h, l) => {
            uint pid; GetWindowThreadProcessId(h, out pid);
            if (pid == targetPid) {
                var sb = new StringBuilder(512); GetWindowText(h, sb, 512);
                var cn = new StringBuilder(256); GetClassName(h, cn, 256);
                RECT r; GetWindowRect(h, out r);
                res.Add(string.Format("hwnd={0} vis={1} class='{2}' title='{3}' rect={4},{5},{6}x{7}",
                    h, IsWindowVisible(h), cn, sb, r.Left, r.Top, (r.Right-r.Left), (r.Bottom-r.Top)));
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
}
'@
Add-Type -TypeDefinition $src -ReferencedAssemblies System.Drawing, System.Windows.Forms

Write-Host ">>> Lanzando: $Exe"
$p = Start-Process -FilePath $Exe -WorkingDirectory (Split-Path $Exe) -PassThru
Start-Sleep -Seconds $WaitSec

$p.Refresh()
if ($p.HasExited) {
    Write-Host ">>> El proceso TERMINO solo. ExitCode = $($p.ExitCode)"
} else {
    Write-Host ">>> Proceso VIVO. PID = $($p.Id)  MainWindowTitle = '$($p.MainWindowTitle)'"
    Write-Host ">>> Ventanas:"
    [Win]::List([uint32]$p.Id) | ForEach-Object { Write-Host "    $_" }
}

# Captura de pantalla completa
$vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
$bmp = New-Object System.Drawing.Bitmap($vs.Width, $vs.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($vs.Left, $vs.Top, 0, 0, $bmp.Size)
$bmp.Save($Shot, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host ">>> Captura: $Shot ($($vs.Width)x$($vs.Height))"

if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
