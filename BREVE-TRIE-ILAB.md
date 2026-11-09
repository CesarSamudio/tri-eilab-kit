# BRIEF — TriE iLab V8.0 / sensor TS2104 — sesión en la laptop del colegio

> **Documento de traspaso.** Fecha: 2026-11-09. Lo escribió el agente de la sesión del
> PC de casa (DSH, mismo modelo). En la laptop hay otro agente con el mismo modelo:
> **este archivo es su brief**. No hace falta que investigues nada de cero: lo
> importante ya está verificado abajo, con la evidencia.
>
> Estructura de esta carpeta:
> - `BREVE-TRIE-ILAB.md` ← **este archivo (empezá por acá)**
> - `AGENTS.md`, `SOUL.md`, `MEMORY.md` ← el contexto y las reglas del usuario
> - `AJUSTE-DSH.txt` ← cómo dejar DSH con el mismo modelo en esta laptop
> - `tools/` ← utilerías (diagnóstico, captura de pantalla, Obsidian)
> - `TriE-kit/` ← la app + el driver + las guías de la prueba

---

## 0. Cómo trabajar con César (mismas reglas que en su PC)

- **Todo va por chat.** Nada de crear `.md` para que lea después. Los archivos solo
  si el archivo *es* el entregable (como este brief).
- **Preguntá antes de producir.** Si el brief es abierto, devolvé 2-3 direcciones
  como pregunta. Si dudás de algo del hardware, preguntá.
- **No propongas planes como cierre.** Respondé observaciones, no "estos son los 7
  cambios que yo haría". Si Cesar quiere ejecutar algo, lo pide él.
- **Si tocás un tema nuevo o distinto**, preguntale con `ask_user_question` si eso
  va a la bóveda de Obsidian o no. Si dice que sí y el tema ya es recurrente,
  **actualizá la nota existente** (`Proyectos/TriE iLab V8.0.md` en
  `F:\Bóveda\Workspace`), no crees otra.
- **Nunca prometas "te aviso"** de algo que va a correr solo. No hay programador:
  DSH duerme cuando termina el turno.
- Cesar es menor de edad: **nada de cuentas de cobro con 18+** (eso aplica a otro
  proyecto, no a este).

---

## 1. La misión

Cesar tiene **el sensor de temperatura TS2104** del sistema TriE iLab / SWR iLab
V8.0 (software de instrumentación del colegio). **No tiene el colector** (la caja
que convierte la señal y habla con la PC), así que no puede medir todavía.

**Va a ir al colegio a probar el equipo**, con esta laptop, y tiene **15 minutos**.
Ahí está el objetivo: que en 15 min sepa si la cadena funciona y, si no, que
tenga evidencia para resolverlo después (no debugueando en el salón).

---

## 2. El hardware (verificado con fuentes oficiales del fabricante)

Fabricante del sistema: **Jiangsu SWR Science & Technology** (Nanjing, China) →
<http://en.sinoswr.com> · contacto `brenda.wan@sinoswr.com`.

### Sensor TS2104 (el que tiene Cesar)
- Sonda de temperatura con **termistor NTC** en la punta de la varilla de acero.
- Exactitud ±0.6 °C · resolución 0.1 °C · rango −50…+150 °C.
- Cuerpo ABS blanco con **puerto RJ45** en la base + sonda por **cable
  transparente tipo auricular 3.5 mm** con empuñadura azul.
- Se enchufa con **cable de red Cat5e** al **colector** (NO a la laptop).
- Manual oficial: *"The sensor does not require calibration"* ·
  <http://en.sinoswr.com/?p=3023>

### Colectores (Data Logger / 采集器) — hay 3 modelos
| Modelo | Puertos de sensor | A la PC | Notas |
|---|---|---|---|
| **TS1001 Easy** | **4 × RJ45** (frontales, 1-4) | USB **Mini-B** | Se alimenta por el cable USB |
| **TS1010 Super** | **4 × RJ45** (en los bordes) | USB **Mini-B** | 3 pilas AA o USB |
| **TS1002 Smart** | 4 × A/D con **cable 1394** | USB **Mini-B** | Tiene pantalla LCD y sensor de temperatura interno (−10…85 °C) |

Manual del TS1010: <http://en.sinoswr.com/?p=3680> ·
Manual del TS1001: `TriE-kit/Manuales-SWR/`

> **Ojo con un dato que se corrigió:** el conector del sensor de Cesar es **RJ45**
> (Cat5e), **no** 1394. El montaje que aparece en el manual del TS2104 usa el
> Smart, pero ese manual es de otra variante. Con un RJ45, el colector compatible
> es el **Easy TS1001** o el **Super TS1010**.

### La cadena
```
TS2104 --Cat5e--> COLECTOR (RJ45) --USB Mini-B--> LAPTOP
```
**El cable de red también ALIMENTA el sensor.** Manual TS1010 §5: *"It is used to
connect super data logger and sensors **to power sensors** and transfer data from
sensor to datalogger"*. Manual TS1001: *"Data cable is 100cm long. It is used to
connect datalogger to sensors **so that sensors are powered**"*.
→ **Sin colector, el sensor no tiene corriente y no mide nada.**

---

## 3. Cómo funciona el software (descifrado del `DIS.exe`, no suposición)

- La app (`DIS.exe`) es **Delphi de 32 bits de 2012** y su manifiesto dice
  `requireAdministrator` → **siempre pide admin al abrir**. No es un error.
- Configura la tarjeta de red de la PC con:
  `netsh interface ip set address name="<nic>" static 192.168.2.X 255.255.255.0 192.168.2.1`
  y descubre el colector por broadcast a `192.168.2.255`.
- **Solo reconoce dos nombres de tarjeta**, que busca en
  `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkCards`:
  `Linux USB Ethernet/RNDIS Gadget` y `TriE iLab Advance USB Ethernet`.
  → Es **Ethernet virtual sobre USB (RNDIS)**. Windows ya lo trae: en el modo
  RJ45 **no hace falta instalar ningún driver**.
- Modos de interfaz de la app: `Smart(USB)`, `Advance(USB)`, `USBSensor`,
  `SmartPro(USB)`. En `setup.ini`: `Interface=`, `RemoteIP=`, `SetUSBNetIP=`.
- `RemoteIP` = IP del **colector**; el gateway `192.168.2.1` = el colector.
- La app guarda su config en `setup.ini` y escribe en
  `HKLM\SOFTWARE\WinChipHead\IC\CH375` → por eso necesita admin.
- Errores internos en **chino simplificado GBK** (ver §8).

---

## 4. Lo que YA está resuelto (no lo rehagas)

| Qué | Estado | Evidencia |
|---|---|---|
| Error "no se encontró CH375DLL.DLL" | **Arreglado** | La DLL va junto a los `.exe` en `TriE-kit/TriEiLab/` |
| Driver CH375 del CD (2011) | **No instala** | `pnputil` → *"El hash para el archivo no está presente en el archivo de catálogo"*, 0 paquetes. Sus `.sys` no llevan firma embebida (verificado: `NotSigned`) |
| Driver CH375 oficial WCH v3.6 | **Instalado y verificado** | `pnputil /add-driver` → *"se agregó correctamente"*, `oem64.inf`, firmante *Microsoft Windows Hardware Compatibility Publisher*. **En `TriE-kit/Driver-Oficial-WCH-v3.6/`** |
| `SETUP.EXE /S` del fabricante | **No hace nada** | exitcode 0, sin servicio, sin `.sys` |
| ¿Hay que desinstalar algo? | **No** | La v8.0-fix nunca instaló el driver (0 paquetes), así que no hay nada en el DriverStore que limpiar |
| Sistema en la laptop de casa | Win10 Pro 19045, VBS=0, Secure Boot=0, HVCI **no probado con HVCI activo** | |

**Sobre HVCI (Integridad de memoria):** el driver v3.6 es de 2026 y firmado por
Microsoft, así que *debería* entrar con HVCI activo, pero **no está probado**
(la PC de prueba la tenía apagada). Si en la laptop el driver no entra:
Seguridad de Windows → Seguridad del dispositivo → Integridad de memoria →
Desactivar → reiniciar → reinstalar. **Avisa: eso come tiempo de la ventana.**

---

## 5. Plan de los 15 minutos

| min | Paso | Qué mirar |
|---|---|---|
| 0-2 | Sensor →Cat5e→ **colector**; colector →USB→ laptop | LED verde fijo en el colector. Si no prende: otro puerto USB, otro cable, pilas AA, adaptador USB‑C→A |
| 2-5 | `TriE-kit/INSTALAR EN LAPTOP.cmd` → admin → **opción 2** | Debe decir `[OK] Driver CH375 instalado y verificado` |
| 5-7 | Abrir "TriE iLab" del Escritorio (UAC → Sí) | Pantalla "Digital Information System", 4 pestañas |
| **7-9** | **Setup → Interface** | `Advance(USB)` si el colector tiene RJ45 · `Smart(USB)` si tiene pantalla. **El paso que más se olvida y la causa #1 de "Sin sensor"** |
| 9-12 | Ver el sensor | Si dice "Sin sensor": probá otro RJ45 (1→2→3→4), reiniciá la app, revisá el modo |
| 12-14 | Grabar: experimento nuevo, intervalo 100 ms → Start → Stop | La curva tiene que dibujarse. **Sacale foto** |
| 14-15 | Exportar al Escritorio | Foto de la curva + archivo exportado |

> **Plan C:** si el TS2104 no aparece, pero el colector es TS1002 o TS1010, esos
> tienen **sensor de temperatura interno** (−10…85 °C, ±0.4 °C) → se puede medir
> igual y la práctica está salvada. Buscá el canal de temperatura interno.

---

## 6. Árbol de fallos: qué hacer si…

### A) La app dice "Sin sensor" en las 4 pestañas
1. ¿El colector tiene **RJ45**? → modo `Advance(USB)`. ¿Tiene pantalla? → `Smart(USB)`. **(Setup → Interface)**
2. Probá otro puerto RJ45 del colector (1→2→3→4). Reiniciá la app.
3. En el Administrador de dispositivos: ¿aparece la caja? ¿como "TriE USB
   Connection", como "Unknown Device", o no aparece?
4. ¿El LED del colector está verde? Si no → es alimentación, no es software.

### B) El driver no instala (error de hash)
- Significa que se está usando el INF viejo. Usá **siempre**
  `TriE-kit/Driver-Oficial-WCH-v3.6/CH375WDM.INF`.
- Comprobación: `pnputil /enum-drivers | findstr /i ch375wdm` → debe aparecer
  `ch375wdm.inf` con firmante *Microsoft Windows Hardware Compatibility Publisher*.

### C) El aparato aparece como "Unknown Device"
- Administrador de dispositivos → clic derecho en él → **Desinstalar dispositivo**
  (tildando *"eliminar el software de controlador"*) → desenchufar → enchufar.

### D) La app no abre / error al abrir
- **"no se encontró CH375DLL.DLL"** → la DLL no está junto a `DIS.exe`:
  copiarla de `TriE-kit/TriEiLab/Driver/CH375DLL.DLL` (o de la subcarpeta
  `Driver-Oficial-WCH-v3.6/CH375DLL.dll`, pero **la de 2005 de la app es la
  correcta**: la app está enlazada contra la API vieja).
- **"Windows protegió tu PC"** → Más información → Ejecutar de todas formas.
- **No pide admin / no abre** → es un exe de 32 bits: la app requiere admin.

### E) "Sin conexión" / no encuentra el colector
- El software pone la NIC en `192.168.2.x` con gateway `192.168.2.1`. Si la
  laptop tiene **varias** tarjetas (WiFi, Ethernet, VPN), puede elegir la
  equivocada. Verificá en `Adaptadores de red` cuál tomó.
- Forzar a mano: `netsh interface ip set address name="<nombre exacto>" static 192.168.2.11 255.255.255.0 192.168.2.1`

---

## 7. Comandos y rutas (en esta laptop)

> **Dos disposiciones posibles:** en el **paquete de la laptop** la app está en
> `TriE-kit/TriEiLab/` y el driver en `TriE-kit/Driver-Oficial-WCH-v3.6/`. En el
> **repo de GitHub** (`CesarSamudio/tri-eilab-kit`) la app está en `TriEiLab/` y
> el driver en `TriEiLab/Driver-Oficial-WCH-v3.6/`. **Buscá el archivo, no la
> ruta exacta** — abajo van los comandos con variables para que no importe.

**Rutas del paquete:**
- App: `TriE-kit/TriEiLab/DIS.exe`
- Driver oficial: `TriE-kit/Driver-Oficial-WCH-v3.6/CH375WDM.INF`
- Instalador: `TriE-kit/INSTALAR EN LAPTOP.cmd`
- Log de la instalación: `%TEMP%\trieilab-instalar.log`

**Diagnóstico todo-en-uno (1 clic, sin admin):**
```
TriE-kit/DIAGNOSTICO.cmd
```
Deja todo en el Escritorio, en `TriE-diagnostico\`:
`DIAGNOSTICO.txt` (SO, Secure Boot, HVCI, driverstore, dispositivos USB, adaptadores
de red, IPs, `setup.ini`, log del instalador) y `PANTALLA.png` (captura de pantalla).

**Captura de la ventana de la app** (para leer un error con visión):
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-window.ps1 -Out "captura.png" -ProcessName DIS
```
(`capture-window.ps1` usa `-Maximize` si la ventanita queda chica.)

**Ver el driverstore:**
```
pnputil /enum-drivers
```

**Dispositivos USB conectados:**
```powershell
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB\*' } |
  Select-Object Status, FriendlyName, InstanceId | Format-Table -AutoSize
```

**Config de la app:**
```powershell
Get-Content "TriE-kit\TriEiLab\setup.ini" -Encoding UTF8 |
  Select-String 'Interface|RemoteIP|SetUSBNetIP'
```

---

## 8. Leer los errores en chino (GBK)

Los textos de error de esta app vienen en **chino simplificado codificado en GBK**
(codepage 936). PowerShell 5.1 los lee mal (mojibake). Para leerlos:

```powershell
[System.IO.File]::ReadAllText($ruta, [System.Text.Encoding]::GetEncoding(936))
```

Si el error está en un **diálogo** (no en un archivo), la vía es la captura de
ventana + visión (el modelo de esta sesión tiene `input: [text, image]`).

Ejemplos ya decodificados:
- `警告 / 程序已经在运行` = "Advertencia: el programa ya se está ejecutando" → cerrá
  y abrí de nuevo.
- `El hash para el archivo no está presente en el archivo de catálogo` → usá el
  driver oficial v3.6.

---

## 9. Lo que hay que entregar al final (a César, por chat)

1. **¿Funcionó?** Sí/No + qué se midió (foto de la curva si hubo).
2. Si no: **el `DIAGNOSTICO.txt` + `PANTALLA.png`** y el error **decodificado**.
3. Qué falta pedir en el colegio: **el colector** (Easy TS1001 o Super TS1010) +
   su **cable USB**; si es posible, también un **sensor serie ZC** (USB directo,
   no necesita caja) o preguntar por un **ZC0009** (sensor de temperatura USB).
4. Si todo anduvo: actualizar la nota de Obsidian
   `Proyectos/TriE iLab V8.0.md` (regenerar `F:\Bóveda\Workspace\Proyectos/…`).

**No hacer en la laptop:** no tocar la seguridad del sistema (HVCI, Secure Boot)
sin avisarle a César, porque un reinicio se come la ventana de 15 minutos.
