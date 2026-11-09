@echo off
setlocal
title TriE iLab - Instalar en esta computadora
set "APP=%~dp0TriEiLab"
set "DRV=%~dp0TriEiLab\Driver-Oficial-WCH-v3.6"
set "LOG=%TEMP%\trieilab-instalar.log"
set "MODO=%~1"

echo =========================================================== > "%LOG%"
echo [%date% %time%] Inicio  modo=%MODO% >> "%LOG%"

net session >nul 2>&1
if not "%errorlevel%"=="0" (
  if /i "%MODO%"=="/test" (
    echo   [SKIP] Sin admin: no se puede probar.
    echo   Ejecuta este archivo con clic derecho ^> Ejecutar como administrador.
    pause
    exit /b 1
  )
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '%MODO%' -Verb RunAs" >nul 2>&1
  exit /b
)
echo   [OK] Administrador >> "%LOG%"

echo   Quitando el bloqueo de Windows a los archivos... >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%APP%' -Recurse -Force -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue" >> "%LOG%" 2>&1

if not exist "%APP%\DIS.exe" (
  echo   [ERROR] No se encontro DIS.exe en "%APP%" >> "%LOG%"
  if /i not "%MODO%"=="/test" pause
  exit /b 1
)
echo   [OK] DIS.exe encontrado >> "%LOG%"

rem ---- El arreglo clave: la DLL tiene que estar junto a los .exe ----
if exist "%APP%\CH375DLL.DLL" (
  echo   [OK] CH375DLL.DLL ya esta junto a DIS.exe >> "%LOG%"
) else (
  if exist "%APP%\Driver\CH375DLL.DLL" (
    copy /Y "%APP%\Driver\CH375DLL.DLL" "%APP%\CH375DLL.DLL" >> "%LOG%" 2>&1
    echo   [OK] DLL copiada >> "%LOG%"
  ) else (
    echo   [ERROR] No se encontro CH375DLL.DLL >> "%LOG%"
    if /i not "%MODO%"=="/test" pause
    exit /b 1
  )
)

taskkill /F /IM DIS.exe >>nul 2>&1
taskkill /F /IM CCD.exe >>nul 2>&1
taskkill /F /IM Sound.exe >>nul 2>&1
taskkill /F /IM ReadData.exe >>nul 2>&1

echo   --- Estado de HVCI y Secure Boot (informativo) --- >> "%LOG%"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled >> "%LOG%" 2>&1
reg query "HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot\State" /v UEFISecureBootEnabled >> "%LOG%" 2>&1

if /i "%MODO%"=="/test" (
  echo   [TEST] Todo OK. No se instalo el driver ni se creo el acceso directo.
  exit /b 0
)

if /i "%MODO%"=="/app" goto app
if /i "%MODO%"=="/full" goto driver

echo.
echo   =========================================================
echo    Que quieres hacer?
echo.
echo    1) Solo la aplicacion (ya queda lista)
echo    2) Aplicacion + driver CH375 del sensor
echo       (necesario si el colector se conecta por USB-serie;
echo        si el colector tiene puertos RJ45 para el sensor, el
echo        driver lo instala Windows solo y podes usar la opcion 1)
echo    0) Salir
echo.
set /p OPT="   Opcion: "
if "%OPT%"=="0" exit /b 0
if "%OPT%"=="2" goto driver
goto app

:driver
echo.
echo   Instalando driver CH375 oficial WCH v3.6... >> "%LOG%"
if exist "%DRV%\CH375WDM.INF" (
  pnputil /add-driver "%DRV%\CH375WDM.INF" /install >> "%LOG%" 2>&1
) else (
  echo   [WARN] No esta Driver-Oficial-WCH-v3.6, se intenta el del CD >> "%LOG%"
  pnputil /add-driver "%APP%\Driver\CH375WDM.INF" /install >> "%LOG%" 2>&1
)

echo   --- Verificacion del driver store --- >> "%LOG%"
pnputil /enum-drivers >> "%LOG%" 2>&1

echo.
echo   =========================================================
echo    RESULTADO
echo   =========================================================
pnputil /enum-drivers 2>nul | findstr /i "ch375wdm" >nul
if errorlevel 1 (
  echo    [AVISO] El driver CH375 NO quedo instalado.
  echo    - Si el colector tiene puertos RJ45 para el sensor: probablemente
  echo      no lo necesitas (Windows lo instala solo al conectar).
  echo    - Si te dice "hash... no esta presente en el catalogo": estas
  echo      usando el driver viejo del CD. Usa la carpeta
  echo      Driver-Oficial-WCH-v3.6.
  echo    Log: %LOG%
) else (
  echo    [OK] Driver CH375 instalado y verificado.
)
echo   =========================================================
echo.
echo   Dispositivos WCH conectados ahora:
pnputil /enum-devices /connected /class USB 2>nul | findstr /i "CH37 CH375 CH376 wch.cn TriE"
if errorlevel 1 echo   (Todavia no hay ningun sensor CH375 conectado. Conectalo y reinicia la app.)

:app
echo   Creando acceso directo en el Escritorio... >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\TriE iLab.lnk'); $s.TargetPath='%APP%\DIS.exe'; $s.WorkingDirectory='%APP%'; $s.Save()" >> "%LOG%" 2>&1
echo   Iniciando TriE iLab...
start "" "%APP%\DIS.exe"
echo.
echo   Listo. La app pide permisos de administrador al abrir (es normal).
echo   Log: %LOG%
echo.
echo   Si tenes el sensor y la caja: sigue "PRUEBA RAPIDA 15 MIN.txt".
pause
exit /b 0
