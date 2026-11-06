# TriE iLab V8.0 — fix de `CH375DLL.DLL` (Windows 10 / 11)

> [!IMPORTANT]
> **Trabajo escolar, con fines educativos y no comerciales.**
> TriE iLab V8.0 es software propietario de **WCH / TriE (W.ch)**, el
> fabricante de los instrumentos, y se incluye aquí porque venía en el CD del
> equipo de medición con el que se hizo la práctica.
> **No se modificó un solo byte** de los archivos del fabricante: lo único que
> se hizo fue copiar `CH375DLL.DLL` a la carpeta de los ejecutables.
> Lo que sí es trabajo propio es el diagnóstico, el instalador portable y las
> herramientas de análisis. → Ver [`NOTICE.md`](./NOTICE.md)

Este repo trae el **software de los instrumentos de medición** (TriE iLab V8.0)
ya reparado, más el instalador portable para ponerlo funcionando en cualquier
Windows 10/11 x64.

## El problema

Al abrir `DIS.exe` salía:

> La ejecución de código no puede continuar porque no se encontró CH375DLL.DLL.

No era el sistema operativo, ni el CD, ni los discos. **`DIS.exe` (Delphi 7,
32 bits, 2012) enlaza estáticamente con `CH375DLL.DLL`**, y esa DLL venía en la
subcarpeta `TriEiLab\Driver\`.

Windows **nunca busca DLLs en subcarpetas**. El orden de búsqueda es:

1. La carpeta desde donde se cargó el `.exe`
2. `System32`
3. Carpeta de 16 bits
4. Carpeta de Windows
5. El directorio actual
6. Las carpetas del `PATH`

Como `CH375DLL.DLL` solo estaba en `Driver\`, el proceso moría antes de
arrancar.

## La solución

Copiar `CH375DLL.DLL` **junto a los ejecutables**. Afecta a los cuatro:

| Archivo | Depende de `CH375DLL.DLL` |
|---|---|
| `DIS.exe` | sí (9 funciones) |
| `CCD.exe` | sí (8 funciones) |
| `Sound.exe` | sí (8 funciones) |
| `ReadData.exe` | sí (8 funciones) |

```
TriEiLab\
    DIS.exe
    CH375DLL.DLL   <-- acá (copiado desde Driver\)
    CCD.exe
    Sound.exe
    ReadData.exe
    Driver\        <-- original, se puede borrar
    Lang\          <-- traducciones (CHS / EN / ESP)
```

## Cómo instalarlo en una laptop

1. Descargar el ZIP (`TriE iLab-Kit para laptops.zip`) y descomprimirlo **completo**.
2. Clic derecho en `INSTALAR EN LAPTOP.cmd` → **Ejecutar como administrador**.
3. Opción `2` = aplicación + driver CH375 del sensor.

El instalador se auto-eleva, le quita el bloqueo de archivos a SmartScreen,
verifica la DLL, crea el acceso directo en el Escritorio, instala el driver y
abre la app.

## El sensor: driver CH375 (WCH)

Sin el sensor físico la app abre igual, pero las 4 pestañas de la pantalla
principal muestran **"Sin sensor"**.

- Driver: `Driver\CH375WDM.INF` (CH372/CH375/CH376, WDM, v2.6 — 2011).
- El catálogo está firmado por **Microsoft (WHQL)** → instala en Windows 10/11.
- IDs de hardware: `USB\VID_4348&PID_5537`, `VID_1A86&PID_5537`,
  `VID_1A86&PID_5576`, `VID_4348&PID_55E0`. El dispositivo aparece como
  **"TriE USB Connection"**.
- El driver instala la DLL en `SysWOW64` (por eso el `.exe` de 32 bits la
  encuentra sola si el driver está instalado).

### Si Windows 11 bloquea el driver

El driver es de 2011 y no es compatible con **HVCI / Integridad de memoria**:

> Seguridad de Windows → Seguridad del dispositivo → Integridad de memoria →
> Desactivar → reiniciar → repetir la instalación.

## Notas

- `DIS.exe` tiene `requireAdministrator` en su manifiesto → **siempre pide
  permisos de administrador** al abrir. Es normal, no es un error.
- Los textos internos de `CH375DLL.DLL` están en chino simplificado (GBK), por
  eso algunos mensajes salen con caracteres raros (ej. "警告 / 程序已经在运行" =
  "Advertencia: el programa ya se está ejecutando"). Es solo cosmético.
- La app guarda su configuración en `setup.ini` (dentro de la carpeta) y escribe
  en `HKLM\SOFTWARE\WinChipHead\IC\CH375` → por eso necesita admin.
