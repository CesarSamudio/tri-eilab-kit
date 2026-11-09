@echo off
setlocal
title TriE iLab - Diagnostico (sin admin, no cambia nada)
echo.
echo   Generando el diagnostico...
echo   (Tarda unos segundos. No modifica nada del sistema.)
echo.
set "PS1=%~dp0tools\DIAGNOSTICO.ps1"
if not exist "%PS1%" set "PS1=%~dp0..\tools\DIAGNOSTICO.ps1"
if not exist "%PS1%" (
  echo   [ERROR] No se encontro DIAGNOSTICO.ps1
  echo   Buscado en: %~dp0tools\DIAGNOSTICO.ps1
  echo              %~dp0..\tools\DIAGNOSTICO.ps1
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Salida "%USERPROFILE%\Desktop\TriE-diagnostico"
echo.
echo   Se genero la carpeta "TriE-diagnostico" en el Escritorio:
echo     - DIAGNOSTICO.txt  (estado del sistema, driverstore, dispositivos, IP, setup.ini, log)
echo     - PANTALLA.png     (captura de pantalla, para leer el error de la app)
echo.
pause
