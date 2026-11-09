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

---

## Driver CH375 oficial de WCH v3.6 (añadido en `v8.1`)

La carpeta `TriEiLab/Driver-Oficial-WCH-v3.6/` contiene el **paquete de
driver oficial de WCH** para el chip **CH375/CH376** (el adaptador USB-serie
que usa la caja del instrumento):

- Archivos: `CH375WDM.INF`, `CH375WDM.CAT`, `CH375WDM.sys`, `CH375W64.sys`,
  `CH375M64.sys`, `CH375DLL.dll`, `CH375DLL64.dll`.
- Procedencia: <https://www.wch-ic.com/download/file?id=28> (descarga
  pública del fabricante, ~298 KB, versión 3.6, `DriverVer 3.6.2026.04`).
- Firma: **Microsoft Windows Hardware Compatibility Publisher** (WHQL),
  con validez verificada.

**Por qué se incluye:** el driver que venía en el CD (`Driver\CH375WDM.INF`,
versión 2.6 de 2011) **no se puede instalar** en Windows moderno. Sus `.sys`
no coinciden con el hash del catálogo firmado y Windows responde *"El hash
para el archivo no está presente en el archivo de catálogo especificado"*;
además no llevan firma embebida, así que sin catálogo válido no cargan. El
paquete de 2026 sí instala y además funciona en Windows 11 con Integridad de
memoria (HVCI) activada, cosa que el de 2011 no.

Este driver **es de WCH, no mío**, y se redistribute tal como WCH lo
publica. No se modificó ningún byte de él. El CD original y su driver
(`Driver/`) se conservan sin tocar, por si alguien quiere el histórico.

> Nota: `CH375DLL.DLL` (la DLL de usuario que usa la app, de 2005) **no** debe
> sustituirse por la `CH375DLL.dll` de la v3.6: la app está enlazada contra la
> API vieja. La DLL original del CD se sigue usando junto a los `.exe`.

