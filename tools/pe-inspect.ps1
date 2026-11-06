param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Path)

function Get-PEStr {
    param([byte[]]$B, [int]$Off)
    $sb = New-Object System.Text.StringBuilder
    while ($Off -lt $B.Length) {
        $c = $B[$Off]
        if ($c -eq 0) { break }
        [void]$sb.Append([char]$c); $Off++
    }
    $sb.ToString()
}

function Get-PEInfo {
    param([string]$File)
    $B = [System.IO.File]::ReadAllBytes($File)
    if ($B[0] -ne 0x4D -or $B[1] -ne 0x5A) { throw "No es PE: $File" }
    $peOff = [BitConverter]::ToInt32($B, 0x3C)
    $machine = [BitConverter]::ToUInt16($B, $peOff + 4)
    $numSec = [BitConverter]::ToUInt16($B, $peOff + 6)
    $optSize = [BitConverter]::ToUInt16($B, $peOff + 20)
    $magic = [BitConverter]::ToUInt16($B, $peOff + 24)
    $is64 = ($magic -eq 0x20b)
    $ddOff = $peOff + 24 + $(if ($is64) { 112 } else { 96 })
    $importRVA = [BitConverter]::ToUInt32($B, $ddOff + 8)
    $exportRVA = [BitConverter]::ToUInt32($B, $ddOff)

    $machineName = switch ($machine) {
        0x014c { 'x86 (32-bit)' }
        0x8664 { 'x64 (64-bit)' }
        default { "0x{0:X}" -f $machine }
    }
    $bitness = if ($is64) { 'PE32+ / 64-bit' } else { 'PE32 / 32-bit' }

    $secStart = $peOff + 24 + $optSize
    $secs = @()
    for ($i = 0; $i -lt $numSec; $i++) {
        $o = $secStart + ($i * 40)
        $secs += [pscustomobject]@{
            VA    = [BitConverter]::ToUInt32($B, $o + 12)
            VSize = [BitConverter]::ToUInt32($B, $o + 8)
            Raw   = [BitConverter]::ToUInt32($B, $o + 20)
            RSize = [BitConverter]::ToUInt32($B, $o + 16)
        }
    }
    $script:Map = {
        param([uint32]$rva)
        foreach ($s in $secs) {
            if ($rva -ge $s.VA -and $rva -lt ($s.VA + $s.RSize)) {
                return [int]($s.Raw + ($rva - $s.VA))
            }
        }
        return -1
    }

    $imports = @()
    if ($importRVA -ne 0) {
        $off = & $script:Map $importRVA
        if ($off -ge 0) {
            for ($d = 0; $d -lt 256; $d++) {
                $base = $off + ($d * 20)
                $oft  = [BitConverter]::ToUInt32($B, $base)
                $nameRVA = [BitConverter]::ToUInt32($B, $base + 12)
                $ft   = [BitConverter]::ToUInt32($B, $base + 16)
                if ($oft -eq 0 -and $nameRVA -eq 0) { break }
                $no = & $script:Map $nameRVA
                if ($no -lt 0) { continue }
                $dll = Get-PEStr $B $no
                $funcs = @()
                $tr = if ($oft -ne 0) { $oft } else { $ft }
                $to = & $script:Map $tr
                if ($to -ge 0) {
                    for ($t = 0; $t -lt 4096; $t++) {
                        if ($is64) { $v = [BitConverter]::ToUInt64($B, $to + ($t * 8)) }
                        else {
                            $raw32 = [BitConverter]::ToUInt32($B, $to + ($t * 4))
                            $v = [uint64]($raw32 + 0)
                        }
                        if ($v -eq 0) { break }
                        $ordFlag = if ($is64) { ([uint64]1 -shl 63) } else { ([uint64]1 -shl 31) }
                        if (($v -band $ordFlag) -ne 0) {
                            $funcs += "#$($v -band 0xFFFF)"
                        } else {
                            $ho = & $script:Map ([uint32]$v)
                            if ($ho -lt 0) { $funcs += "<rva invalida>"; continue }
                            $funcs += (Get-PEStr $B ($ho + 2))
                        }
                    }
                }
                $imports += [pscustomobject]@{ DLL = $dll; Functions = $funcs }
            }
        }
    }

    $exports = @()
    if ($exportRVA -ne 0) {
        $eo = & $script:Map $exportRVA
        if ($eo -ge 0) {
            $nNames = [BitConverter]::ToUInt32($B, $eo + 24)
            $namesRVA = [BitConverter]::ToUInt32($B, $eo + 32)
            $no = & $script:Map $namesRVA
            if ($no -ge 0) {
                for ($i = 0; $i -lt [math]::Min($nNames, 512); $i++) {
                    $n = & $script:Map ([BitConverter]::ToUInt32($B, $no + ($i * 4)))
                    if ($n -lt 0) { continue }
                    $exports += (Get-PEStr $B $n)
                }
            }
        }
    }

    [pscustomobject]@{
        File = $File; Machine = $machineName; Bitness = $bitness
        Imports = $imports; Exports = $exports
    }
}

foreach ($p in $Path) {
    if (-not (Test-Path -LiteralPath $p)) { Write-Host "NO EXISTE: $p" -ForegroundColor Red; continue }
    try {
        $r = Get-PEInfo -File $p
    } catch {
        Write-Host "ERROR leyendo $p : $_" -ForegroundColor Red; continue
    }
    Write-Host ("=" * 100)
    Write-Host ("ARCHIVO : " + $r.File)
    Write-Host ("ARQ     : " + $r.Machine + "  (" + $r.Bitness + ")")
    Write-Host "IMPORTA :"
    foreach ($i in $r.Imports) {
        Write-Host ("  -> " + $i.DLL + "   (" + $i.Functions.Count + " funcs)")
        foreach ($f in $i.Functions) { Write-Host ("       " + $f) }
    }
    if ($r.Exports.Count -gt 0) {
        Write-Host "EXPORTA :"
        foreach ($e in $r.Exports) { Write-Host ("       " + $e) }
    }
}
