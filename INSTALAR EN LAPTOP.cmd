@echo off
setlocal
title TriE iLab - Instalar en esta computadora
set "APP=%~dp0TriEiLab"
set "LOG=%TEMP%\trieilab-instalar.log"
set "MODO=%~1"

echo =========================================================== > "%LOG%"
echo [%date% %time%] Inicio  modo=%MODO% >> "%LOG%"

net session >nul 2>&1
if not "%errorlevel%"=="0" (
  if /i "%MODO%"=="/test" (
    echo   [SKIP] Sin admin: no se puede probar. Ejecuta el .cmd con clic derecho ^> Ejecutar como administrador.
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

echo   Copiando CH375DLL.DLL junto a los ejecutables... >> "%LOG%"
if exist "%APP%\CH375DLL.DLL" (
  echo   [OK] La DLL ya estaba en su sitio >> "%LOG%"
) else (
  if exist "%APP%\Driver\CH375DLL.DLL" (
    copy /Y "%APP%\Driver\CH375DLL.DLL" "%APP%\CH375DLL.DLL" >> "%LOG%" 2>&1
    echo   [OK] DLL copiada >> "%LOG%"
  ) else (
    echo   [ERROR] No se encontro Driver\CH375DLL.DLL >> "%LOG%"
    if /i not "%MODO%"=="/test" pause
    exit /b 1
  )
)

taskkill /F /IM DIS.exe >>nul 2>&1
taskkill /F /IM CCD.exe >>nul 2>&1
taskkill /F /IM Sound.exe >>nul 2>&1
taskkill /F /IM ReadData.exe >>nul 2>&1

reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled >> "%LOG%" 2>&1
reg query "HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot\State" /v UEFISecureBootEnabled >> "%LOG%" 2>&1

if /i "%MODO%"=="/test" (
  echo   [TEST] Todo OK. No se creo acceso directo ni se instalo el driver.
  exit /b 0
)

if /i "%MODO%"=="/full" goto driver
if /i "%MODO%"=="/app" goto app

echo.
echo   =========================================================
echo    Que quieres hacer?
echo.
echo    1) Solo la aplicacion (ya queda lista)
echo    2) Aplicacion + driver CH375 del sensor
echo       (necesario si vas a conectar la caja del instrumento)
echo    0) Salir
echo.
set /p OPT="   Opcion: "
if "%OPT%"=="2" goto driver
goto app

:driver
echo.
echo   Instalando driver CH375... >> "%LOG%"
pnputil /add-driver "%APP%\Driver\CH375WDM.INF" /install >> "%LOG%" 2>&1
echo   Driver CH375 instalado. Log: %LOG%
echo.
echo   Si Windows lo bloquea: Seguridad de Windows ^> Seguridad del
echo   dispositivo ^> Integridad de memoria ^> Desactivar ^> Reiniciar.
echo.
pnputil /enum-devices /connected /class USB 2>nul | findstr /i "CH37 CH375 CH376 wch.cn TriE"
if errorlevel 1 echo   (Todavia no hay ningun sensor CH375 conectado.)

:app
echo   Creando acceso directo en el Escritorio... >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\TriE iLab.lnk'); $s.TargetPath='%APP%\DIS.exe'; $s.WorkingDirectory='%APP%'; $s.Save()" >> "%LOG%" 2>&1
echo   Iniciando TriE iLab...
start "" "%APP%\DIS.exe"
echo.
echo   Listo. La app pide permisos de administrador al abrir (es normal).
echo   Log: %LOG%
pause
exit /b 0
