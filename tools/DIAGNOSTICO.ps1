param(
    [string]$Salida = "$env:USERPROFILE\Desktop\TriE-diagnostico"
)
$ErrorActionPreference = 'SilentlyContinue'
New-Item -ItemType Directory -Force -Path $Salida | Out-Null
$txt = Join-Path $Salida 'DIAGNOSTICO.txt'
function W($t){ $t | Tee-Object -FilePath $txt -Append | Out-Null }

W "================================================================"
W " DIAGNOSTICO TriE iLab - generado $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "================================================================"
W ""
W "### 1) SISTEMA OPERATIVO"
$os = Get-CimInstance Win32_OperatingSystem
W ("  SO            : {0} build {1} ({2})" -f $os.Caption, $os.BuildNumber, $os.OSArchitecture)
W ("  Fabricante    : {0} {1}" -f (Get-CimInstance Win32_ComputerSystem).Manufacturer, (Get-CimInstance Win32_ComputerSystem).Model)
W ("  Admin         : {0}" -f (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
W ("  Secure Boot   : {0}" -f (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction SilentlyContinue).UEFISecureBootEnabled)
W ("  VBS (HVCI)    : {0}" -f (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -ErrorAction SilentlyContinue).EnableVirtualizationBasedSecurity)
W ("  Integridad mem: {0}" -f (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -ErrorAction SilentlyContinue).Enabled)
W ""

W "### 2) DRIVERSTORE - entradas CH375"
$dd = pnputil /enum-drivers 2>$null | Out-String
$blocks = ($dd -split "Nombre publicado:") | Where-Object { $_ -match 'ch375wdm' }
if($blocks){
  foreach($b in $blocks){
    W ("  Nombre publicado: " + (($b -split "`r?`n")[0]).Trim())
    ($b -split "`r?`n") | Select-Object -Skip 1 | Where-Object { $_ -match 'Nombre original|Proveedor|Clase|GUID|Versi|firmante' } | ForEach-Object { W ("  " + $_.Trim()) }
    W "  ---"
  }
} else {
  W "  (NO HAY NINGUNA ENTRADA CH375 EN EL DRIVERSTORE)"
  W '  Si el driver deberia estar instalado: instalalo con'
  W '  pnputil /add-driver "<carpeta>\Driver-Oficial-WCH-v3.6\CH375WDM.INF" /install'
}
W ""

W "### 3) DISPOSITIVOS WCH / TRIE (USB)"
$pd = pnputil /enum-devices /connected 2>$null | Out-String
($pd -split "`r?`n") | Where-Object { $_ -match 'CH37|CH375|CH376|wch\.cn|TriE|1A86|4348' } | ForEach-Object { W ("  " + $_.Trim()) }
W ""
W "### 3b) TODOS LOS USB CONECTADOS (clase)"
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB\*' } |
  ForEach-Object { W ("  [{0,-9}] {1,-42} {2}" -f $_.Status, $_.FriendlyName, $_.InstanceId) }
W ""

W "### 4) ADAPTADORES DE RED (el modo Advance usa RNDIS)"
Get-PnpDevice -Class Net | Where-Object { $_.Status -ne 'Unknown' -or $_.FriendlyName -match 'Ethernet|USB' } |
  ForEach-Object { W ("  [{0,-9}] {1,-46} {2}" -f $_.Status, $_.FriendlyName, $_.InstanceId) }
W ""
W "### 4b) CONFIGURACION IP DE LOS ADAPTADORES"
Get-NetIPConfiguration | ForEach-Object {
  W ("  {0} ({1})" -f $_.InterfaceAlias, $_.InterfaceDescription)
  W ("     IPv4: {0}   GW: {1}" -f (($_.IPv4Address.IPAddress) -join ','), (($_.IPv4DefaultGateway.NextHop) -join ','))
}
W ""
W "### 4c) DESCIPCION DE LAS TARJETAS (la app busca estas dos)"
$nk = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkCards'
Get-ChildItem $nk -ErrorAction SilentlyContinue | ForEach-Object {
  $p = Get-ItemProperty $_.PSPath
  W ("  {0,-40} {1}" -f $p.Description, $_.PSChildName)
}
W ""

W "### 5) SERVICIOS Y ARCHIVOS DEL DRIVER"
Get-Service -Name '*CH375*' -ErrorAction SilentlyContinue | ForEach-Object { W ("  Servicio {0}: {1}" -f $_.Name, $_.Status) }
Get-ChildItem 'C:\Windows\System32\drivers\CH375*','C:\Windows\System32\CH375*','C:\Windows\SysWOW64\CH375*' -ErrorAction SilentlyContinue |
  ForEach-Object { W ("  {0}  ({1} bytes)" -f $_.FullName, $_.Length) }
W ""

W "### 6) CONFIGURACION DE LA APP (setup.ini)"
$appDirs = @("$env:USERPROFILE\Desktop\TriEiLab", "$env:USERPROFILE\Desktop\TriE iLab", "$env:PUBLIC\Desktop\TriEiLab", "C:\Program Files (x86)\TriEiLab")
$found = $false
foreach($d in $appDirs){
  $ini = Join-Path $d 'setup.ini'
  if(Test-Path $ini){
    $found = $true
    W ("  --- {0} ---" -f $ini)
    (Get-Content $ini -Encoding UTF8) | Where-Object { $_ -match 'Interface|RemoteIP|SetUSBNetIP|Language|AppTitle' } | ForEach-Object { W ("     " + $_) }
  }
}
if(-not $found){ W "  (no se encontro setup.ini en las rutas habituales)" }
W ""
W "### 6b) DONDE ESTA LA APP"
Get-ChildItem "$env:USERPROFILE\Desktop" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'TriE' } |
  ForEach-Object { W ("  {0}" -f $_.FullName) }
Get-ChildItem "$env:USERPROFILE\Desktop" -Filter '*TriE*.lnk' -ErrorAction SilentlyContinue |
  ForEach-Object {
    $sh = New-Object -ComObject WScript.Shell
    $s = $sh.CreateShortcut($_.FullName)
    W ("  Acceso directo {0} -> {1}" -f $_.Name, $s.TargetPath)
  }
W ""

W "### 7) LOG DE LA INSTALACION"
$log = "$env:TEMP\trieilab-instalar.log"
if(Test-Path $log){
  W "  --- $log ---"
  (Get-Content $log) | ForEach-Object { W ("     " + $_) }
} else { W "  (no existe $log)" }
W ""

W "### 8) CAPTURA DE PANTALLA (leela si la app muestra un error)"
try{
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  $b = [System.Windows.Forms.SystemInformation]::VirtualScreen
  $bmp = New-Object System.Drawing.Bitmap($b.Width, $b.Height)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($b.X, $b.Y, 0, 0, $bmp.Size)
  $png = Join-Path $Salida 'PANTALLA.png'
  $bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  W ("  Captura guardada en: {0}  ({1}x{2})" -f $png, $b.Width, $b.Height)
}catch{ W ("  No se pudo capturar: {0}" -f $_.Exception.Message) }
W ""

W "================================================================"
W (" FIN. Mandame la carpeta '{0}' (el .txt y el .png)." -f $Salida)
W "================================================================"
Write-Host ""
Write-Host " Diagnostico generado en: $Salida" -ForegroundColor Green
Write-Host " Mandame el archivo DIAGNOSTICO.txt y la imagen PANTALLA.png." -ForegroundColor Green
