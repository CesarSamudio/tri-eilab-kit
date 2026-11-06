param(
    [Parameter(Mandatory=$true)][int]$X,
    [Parameter(Mandatory=$true)][int]$Y,
    [int]$WaitSec = 4,
    [string]$Expect = '',
    [string]$Shot = ''
)
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
$src = @'
using System;
using System.Runtime.InteropServices;
public class M {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
    public static void Click(int x, int y) {
        SetCursorPos(x, y);
        System.Threading.Thread.Sleep(300);
        mouse_event(0x0002, 0, 0, 0, IntPtr.Zero);
        System.Threading.Thread.Sleep(90);
        mouse_event(0x0004, 0, 0, 0, IntPtr.Zero);
    }
}
'@
Add-Type -TypeDefinition $src -ReferencedAssemblies System.Drawing, System.Windows.Forms
[M]::Click($X, $Y)
Start-Sleep -Seconds $WaitSec
if ($Shot -ne '') {
    $vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $bmp = New-Object System.Drawing.Bitmap($vs.Width, $vs.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($vs.Left, $vs.Top, 0, 0, $bmp.Size)
    $bmp.Save($Shot, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "captura -> $Shot"
}
Write-Output "--- Procesos DIS tras el clic ---"
Get-Process -Name DIS -ErrorAction SilentlyContinue | ForEach-Object { "PID $($_.Id) alive title='$($_.MainWindowTitle)'" }
if (-not (Get-Process -Name DIS -ErrorAction SilentlyContinue)) { Write-Output "(ninguno: la app se cerro)" }
Write-Output "--- Ventanas UAC/consent ---"
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match 'consent|CredentialUIBroker' } | ForEach-Object { "UAC: $($_.ProcessName) PID $($_.Id)" }
