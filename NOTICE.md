# AVISO / DISCLAIMER

## Sobre el software incluido en este repositorio

TriE iLab V8.0 —los archivos `DIS.exe`, `CCD.exe`, `Sound.exe`, `ReadData.exe`,
`CH375DLL.DLL`, `Sensor30.dll`, `Sensor35.dll`, `PComm.dll`, `PUsb.dll`,
`borlndmm.dll`, `DES.ico`, `Func.dt`, `SensorUnit.ini`, `setup.ini` y el
contenido de las carpetas `Driver\` y `Lang\`— es **software propietario de
WCH / TriE (W.ch)**, el fabricante de los instrumentos de medición. Se
distribuye en un CD que se entrega junto al equipo de medición.

**Este repositorio es un trabajo escolar** (proyecto de instrumentación y
medición) elaborado con fines **educativos y no comerciales**. No es un
producto, no se ofrece ningún servicio derivado de él y no hay intención de
lucro.

### Qué aporta este repositorio (trabajo propio)

- El **diagnóstico** del fallo `CH375DLL.DLL` (la DLL quedaba en la
  subcarpeta `Driver\` y Windows no busca DLLs ahí).
- El **método de instalación portable** y los scripts para Windows 10/11.
- Las **herramientas de análisis** del ejecutable (`tools/`), escritas para
  este diagnóstico.

El software del fabricante se incluye **únicamente** porque forma parte del
material recibido en el CD del equipo de medición con el que se realizó la
práctica, y porque sin él la práctica no se puede reproducir.

### Si representas a WCH / TriE

Si eres el titular de los derechos y consideras que este repositorio debe
retirarse, **bórralo o ponlo en privado de inmediato**: lo hago sin
preguntar. Un aviso así no reemplaza una autorización, así que la decisión
final es del titular.

---

## Nota sobre la modificación

La **única modificación** que se le hizo al programa fue **copiar
`CH375DLL.DLL` a la carpeta donde están los ejecutables** (de `Driver\` a la
raíz). No se parcheó, ni se recompiló, ni se alteró un solo byte de ningún
archivo del fabricante: el `DIS.exe` que corre es el original del CD, sin
modificar.
