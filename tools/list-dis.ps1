Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
$src = @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class Win3 {
    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
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
                res.Add(string.Format("TOP class='{0}' title='{1}' vis={2} rect={3},{4} {5}x{6}",
                    cn, sb, IsWindowVisible(h), r.Left, r.Top, (r.Right-r.Left), (r.Bottom-r.Top)));
                EnumChildWindows(h, (ch, l2) => {
                    var sb2 = new StringBuilder(512); GetWindowText(ch, sb2, 512);
                    var cn2 = new StringBuilder(256); GetClassName(ch, cn2, 256);
                    if (sb2.Length > 0) res.Add("    child class='" + cn2 + "' text='" + sb2 + "'");
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

$procs = Get-Process -Name DIS -ErrorAction SilentlyContinue
if (-not $procs) { Write-Host "No hay procesos DIS"; exit }
foreach ($p in $procs) {
    $p.Refresh()
    Write-Host ("=" * 90)
    Write-Host ("PID {0}  Start={1}  Title='{2}'  Path={3}" -f $p.Id, $p.StartTime, $p.MainWindowTitle, $p.Path)
    Write-Host ("  HandleCount={0}  WS={1}MB  Threads={2}" -f $p.HandleCount, [math]::Round($p.WorkingSet64/1MB,1), $p.Threads.Count)
    [Win3]::List([uint32]$p.Id) | ForEach-Object { Write-Host "   $_" }
}

# Otros procesos sospechosos (CCD, Sound, ReadData)
foreach ($n in @('CCD','Sound','ReadData','DRVSETUP64','SETUP')) {
    $q = Get-Process -Name $n -ErrorAction SilentlyContinue
    if ($q) { foreach ($x in $q) { Write-Host ("OTRO: {0} PID={1} title='{2}'" -f $x.ProcessName, $x.Id, $x.MainWindowTitle) } }
}
