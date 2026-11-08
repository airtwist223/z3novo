<#
z3report.ps1: report for testers of the Z3NOVO firmware (Lenovo ThinkCentre M715s, board AM4P2MS), OS side, Windows.

    powershell -ExecutionPolicy Bypass -File z3report.ps1

Works without administrator rights. Started without them in an interactive window, it offers to restart itself with
them (one UAC prompt); they add the UEFI variables (Z3Chip, Z3Novo*), the minidump list and the monitors'
connection types. -NoElevate skips the offer.

Writes ONE UTF-8 text file z3report-os-<date>-<time>.txt to the Desktop and prints its path. Read-only.
Computer and user names, serial numbers, UUIDs, MAC tails, IP addresses, Wi-Fi names, user folder paths and
unique numbers in SMBIOS strings are masked in the file. Read the file before sending it.

Never done here: reading the Windows product key (ACPI MSDM table, DigitalProductId) or the product ID; reading ACPI
thermal zones (MSAcpi_ThermalZoneTemperature, "Thermal Zone Information" counters: on the AM4P2MS board they run
firmware code that accesses the Super I/O chip); loading drivers; writing anything but the report; the network.

Windows PowerShell 5.1 (Windows 10 and 11). The code is plain ASCII on purpose: all Russian text sits in the
$TextData block, which is re-decoded at run time if the file lost its UTF-8 BOM on the way.
#>
param(
    [switch]$NoElevate,   # do not offer to restart with administrator rights
    [switch]$Relaunched   # set by the script itself when it restarts elevated: no offer, wait for Enter at the end
)

Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Version = '1.0'
$ScriptPath = $PSCommandPath   # captured here, at script level, for the elevated restart
if (-not $ScriptPath) { $ScriptPath = $MyInvocation.MyCommand.Path }
$GuidChip = '7a3c5d11-42e9-4f60-9d1b-5e7713a8c402'   # Z3Chip, the firmware driver's log
$GuidApp = '7c9d3f2a-41b6-4e1d-9a57-2f8e116cd4a0'    # Z3Novo*, the setup app's variables
$Inv = [Globalization.CultureInfo]::InvariantCulture

# ---------------------------------------------------------------- texts: key|Russian|English
# Every line starts with ASCII, so a script read in the ANSI code page still parses; Init-Texts repairs the Russian.
$TextData = @'
_check|проверка|check
title|Отчёт ОС для Z3NOVO|Z3NOVO OS report
ps_old|Нужен PowerShell 3 или новее (в Windows 10 и 11 он есть).|Needs PowerShell 3 or newer (Windows 10 and 11 have it).
collecting|Собираю отчёт ОС, это займёт до пары минут...|Collecting the OS report, up to a couple of minutes...
hint_admin|Без прав администратора не будет переменных UEFI и списка мини-дампов. Полнее: откройте PowerShell от имени администратора и запустите снова.|Without administrator rights the UEFI variables and the minidump list are missing. For more, open PowerShell as administrator and run it again.
done|Готово|Done
check|Перед отправкой откройте файл и проверьте его: имена, адреса и серийные номера замазаны, но убедитесь сами.|Before sending, open the file and check it: names, addresses and serial numbers are masked, but please make sure.
send|Отправьте этот файл тому, кто ведёт тест прошивки.|Send this file to the person running the firmware test.
write_failed|Не удалось записать отчёт|Failed to write the report
failed|не удалось|failed
skipped|пропущено|skipped
none|нет|none
need_admin|нужны права администратора|needs administrator rights
not_uefi|Windows загружена не в режиме UEFI|Windows was not started in UEFI mode
no_ip|IP-адреса и имена сетей Wi-Fi не собираются|IP addresses and Wi-Fi network names are not collected
no_z3vars|переменных Z3Chip и Z3Novo* не видно|no Z3Chip or Z3Novo* variables visible to the OS
close|Нажмите Enter, чтобы закрыть окно|Press Enter to close this window
crash_list|Запуски, штатные и внезапные выключения, синие экраны, сначала старые (последние 80)|Starts, clean and unexpected shutdowns, blue screens, oldest first (last 80)
elevate_q|Для полного отчёта нужны права администратора: переменные прошивки, мини-дампы, тип подключения мониторов. Перезапустить скрипт с ними? Enter или Д — да, Н — нет.|A full report needs administrator rights: firmware variables, minidumps, monitor connection types. Restart the script with them? Enter or Y for yes, N for no.
yes_words|д да|y yes
elevate_started|Открыто окно с правами администратора, отчёт соберётся в нём. Это окно можно закрыть.|A window with administrator rights is open; the report is collected there. You can close this one.
elevate_no|Продолжаю без прав администратора.|Going on without administrator rights.
elevate_failed|Не удалось перезапустить с правами администратора, продолжаю без них|Could not restart with administrator rights, going on without them
hz_unknown|частота неизвестна (стандартный драйвер)|refresh rate unknown (standard driver)
gpu_nodriver|драйвер производителя не установлен, работает «Базовый видеоадаптер (Майкрософт)»|the vendor's driver is not installed, the Microsoft Basic Display Adapter is in use
no_data|нет данных|no data
collected|Собрано: версия Windows, время загрузки и аптайм; SMBIOS (BIOS, плата, процессор, модули памяти); микрокод; видео и его память (выделенная и общая); мониторы; устройства PCI и устройства с ошибками; сетевые адаптеры (без адресов); диски (модель и объём); сбои, зависания, синие экраны и аппаратные ошибки (WHEA) за 30 дней; события прошивки, ACPI и TPM; ошибки дисков, NTFS и видеодрайвера; список мини-дампов (имена и размеры); переменные UEFI Z3Chip и Z3Novo* (hex, только с правами администратора).|Collected: Windows version, boot time and uptime; SMBIOS (BIOS, board, CPU, memory modules); microcode; graphics and its memory (dedicated and shared); monitors; PCI devices and devices with problems; network adapters (no addresses); disks (model and size); crashes, hangs, blue screens and hardware errors (WHEA) over 30 days; firmware, ACPI and TPM events; disk, NTFS and display driver errors; the minidump list (names and sizes); UEFI variables Z3Chip and Z3Novo* (hex, administrator only).
excluded|Исключено: имя компьютера, имена пользователей, серийные номера (и похожие на них уникальные номера в строках SMBIOS), UUID, MAC-адреса (оставлены первые 3 байта), IP-адреса, имена сетей Wi-Fi, пути в папках пользователей (заменены на ~), ключ и код продукта Windows (не читаются вовсе). Скрипт ничего не меняет в системе, не ставит драйверы и не читает термозоны ACPI.|Excluded: computer name, user names, serial numbers (and serial-like unique numbers in SMBIOS strings), UUIDs, MAC addresses (first 3 bytes kept), IP addresses, Wi-Fi names, user folder paths (shown as ~), the Windows product key and product ID (never read). The script changes nothing, installs no drivers and does not read ACPI thermal zones.
masks|Замены / Masks: <host> <user> <serial> <uuid> <id> <ip> <email> <wifi> <url> <key>, ~ = папка пользователя / user folder, aa:bb:cc:xx:xx:xx = MAC.|
end_check|Проверьте файл перед отправкой: замазанные места выглядят как <host>, <user>, <ip>, ~ и так далее. Если увидите то, чем не хотите делиться, удалите эту строку.|Check this file before sending it: masked values look like <host>, <user>, <ip>, ~ and so on. If you see anything you do not want to share, delete that line.
sensors|Температуры и обороты на Windows не читаются: встроенного безопасного способа нет, а чтение термозон ACPI на плате AM4P2MS заставляет прошивку обращаться к микросхеме Super I/O.|Temperatures and fan speeds are not read on Windows: there is no safe built-in way, and reading ACPI thermal zones on the AM4P2MS board makes the firmware access the Super I/O chip.
sec_summary|Кратко|Summary
sec_os|ОС|OS
sec_fw|Прошивка и плата (SMBIOS)|Firmware and board (SMBIOS)
sec_cpu|Процессор|CPU
sec_mem|Память|Memory
sec_gpu|Видео и его память|Graphics and its memory
sec_mon|Мониторы|Monitors
sec_problems|Устройства с ошибками|Devices with problems
sec_crashes|Сбои, зависания и перезагрузки за 30 дней|Crashes, hangs and restarts over 30 days
sec_whea|Аппаратные ошибки (WHEA) и проверка памяти за 30 дней|Hardware errors (WHEA) and memory tests over 30 days
sec_fwev|События прошивки, ACPI, TPM и питания за 30 дней|Firmware, ACPI, TPM and power events over 30 days
sec_storage|Ошибки дисков и NTFS за 30 дней|Disk and NTFS errors over 30 days
sec_gpuerr|Сбросы и сбои видеодрайвера за 30 дней|Display driver resets and failures over 30 days
sec_dumps|Аварийные дампы|Crash dumps
sec_pci|Устройства PCI|PCI devices
sec_net|Сетевые адаптеры, без адресов|Network adapters, no addresses
sec_disks|Диски|Disks
sec_sensors|Датчики|Sensors
sec_efi|Переменные UEFI Z3Chip и Z3Novo*, только чтение|UEFI variables Z3Chip and Z3Novo*, read only
sec_end|Конец|End
'@

$Texts = @{}
function Init-Texts {
    $data = $TextData
    $chk = @($data -split "`n" | Where-Object { $_ -like '_check|*' })
    $ok = $false
    if ($chk.Count -gt 0) { $ok = (($chk[0].TrimEnd("`r") -split '\|')[1]).Length -eq 8 }
    if (-not $ok) {
        # The file had no BOM and was read in the ANSI code page: turn the text back into bytes and read them as UTF-8.
        try { $data = [Text.Encoding]::UTF8.GetString([Text.Encoding]::Default.GetBytes($data)) } catch { }
    }
    foreach ($line in ($data -split "`n")) {
        $p = $line.TrimEnd("`r").Split([char[]]@('|'), 3)
        if ($p.Count -eq 3) { $Texts[$p[0]] = @($p[1], $p[2]) }
    }
}
function TR([string]$k) { $t = $Texts[$k]; if ($t) { return $t[0] }; return $k }
function TE([string]$k) { $t = $Texts[$k]; if ($t) { return $t[1] }; return $k }
function Tx([string]$k) { $t = $Texts[$k]; if ($t) { return ('{0} / {1}' -f $t[1], $t[0]) }; return $k }
Init-Texts

if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host (TR 'ps_old')
    Write-Host (TE 'ps_old')
    exit 1
}

$IsAdmin = $false
try { $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } catch { }

# ---------------------------------------------------------------- output and small helpers

$Lines = New-Object 'System.Collections.Generic.List[string]'
$Facts = @{}
$Mark = [string][char]1   # marks a line of free text (event messages): IPv4 masking applies there too
function W([string]$s) { [void]$Lines.Add($s) }
function WT([string]$s) { [void]$Lines.Add($Mark + $s) }
function KV([string]$k, $v) {
    if ($null -eq $v) { return }
    $t = ("$v").Trim()
    if ($t -ne '') { W ('  {0,-30} {1}' -f ($k + ':'), $t) }
}
function Note([string]$s) { W ('  ' + $s) }
function F([string]$fmt) { return [string]::Format($Inv, $fmt, [object[]]$args) }
function ErrText($e) {
    $m = ''
    if ($e -is [System.Management.Automation.ErrorRecord]) { $m = [string]$e.Exception.Message } else { $m = [string]$e }
    $m = (($m -split "`r?`n")[0]).Trim()
    if ($m.Length -gt 220) { $m = $m.Substring(0, 220) }
    return $m
}
function ToDate($v) {
    if ($null -eq $v) { return $null }
    if ($v -is [datetime]) { return $v }
    try { return [Management.ManagementDateTimeConverter]::ToDateTime([string]$v) } catch { return $null }
}
function FmtDate($v) {
    $d = ToDate $v
    if ($d) { return $d.ToString('yyyy-MM-dd HH:mm:ss', $Inv) }
    return ''
}
function GiB($b) { if ($null -eq $b -or "$b" -eq '') { return '' }; return (F '{0:0.00} GiB' ([double]$b / 1GB)) }
function MiB($b) { if ($null -eq $b -or "$b" -eq '') { return '' }; return (F '{0:0} MiB' ([double]$b / 1MB)) }

$HaveCim = [bool](Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
$script:CimDead = $false
function Invoke-Q($Class, $Props, $Filter, $Ns) {
    if ($HaveCim) {
        $p = @{ ClassName = $Class; Namespace = $Ns; OperationTimeoutSec = 60; ErrorAction = 'Stop' }
        if ($Props) { $p['Property'] = $Props }
        if ($Filter) { $p['Filter'] = $Filter }
        return Get-CimInstance @p
    }
    $p = @{ Class = $Class; Namespace = $Ns; ErrorAction = 'Stop' }
    if ($Props) { $p['Property'] = $Props }
    if ($Filter) { $p['Filter'] = $Filter }
    return Get-WmiObject @p
}
# One WMI query with only the named properties (so serial numbers and the like are never even fetched). If WMI once
# runs into the time limit, later queries are skipped at once instead of waiting a minute each.
function Q([string]$Class, [string[]]$Props, [string]$Filter, [string]$Ns) {
    if (-not $Ns) { $Ns = 'root\cimv2' }
    if ($script:CimDead) { throw 'WMI did not answer an earlier query in time; skipped' }
    $t0 = [DateTime]::UtcNow
    try {
        return (Invoke-Q $Class $Props $Filter $Ns)
    } catch {
        if (([DateTime]::UtcNow - $t0).TotalSeconds -ge 50) { $script:CimDead = $true; throw }
        if (-not $Props) { throw }
    }
    # A quick failure with named properties: an older Windows may lack one of them. Ask without the list; only the
    # properties the caller names are ever printed.
    return (Invoke-Q $Class $null $Filter $Ns)
}

# Registry: single named values only (never whole keys).
$HKLM = [Microsoft.Win32.Registry]::LocalMachine
try {
    if ([Environment]::Is64BitOperatingSystem) {
        $HKLM = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
    }
} catch { }
function RegVal([string]$Sub, [string]$Name) {
    $k = $null
    try {
        $k = $HKLM.OpenSubKey($Sub)
        if ($k) { $v = $k.GetValue($Name); return , $v }
    } catch { } finally { if ($k) { $k.Close() } }
    return $null
}
function RegSubKeys([string]$Sub) {
    $k = $null
    try {
        $k = $HKLM.OpenSubKey($Sub)
        if ($k) { return , $k.GetSubKeyNames() }
    } catch { } finally { if ($k) { $k.Close() } }
    return , @()
}
# A registry value that may be a string or UTF-16 bytes.
function RegText($v) {
    if ($null -eq $v) { return '' }
    if ($v -is [byte[]]) { return ([Text.Encoding]::Unicode.GetString($v)).Trim([char]0, ' ') }
    if ($v -is [array]) { return ($v -join ' ') }
    return ([string]$v).Trim()
}

# Run a program with a time limit; returns its standard output.
function Invoke-Exe([string]$File, [string]$Arguments, [int]$TimeoutSec) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $File
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    try { $psi.StandardOutputEncoding = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage) } catch { }
    $p = [System.Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEndAsync()
    [void]$p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        try { $p.Kill() } catch { }
        throw ('timeout after {0} s: {1}' -f $TimeoutSec, $File)
    }
    return $out.Result
}

# The PNP instance id without its last part (for USB devices that part is often the serial number).
function HwId([string]$pnp) {
    if (-not $pnp) { return '' }
    $i = $pnp.LastIndexOf([char]'\')
    if ($i -gt 0) { return $pnp.Substring(0, $i) }
    return $pnp
}
function MaskMac([string]$m) {
    if (-not $m) { return '' }
    $p = $m -split '[:-]'
    if ($p.Count -lt 6) { return '?' }
    return ('{0}:{1}:{2}:xx:xx:xx' -f $p[0], $p[1], $p[2])
}
$CmText = @{
    1 = 'not configured'; 3 = 'driver corrupted or low memory'; 10 = 'cannot start'; 12 = 'not enough free resources (resource conflict)';
    14 = 'needs a restart'; 18 = 'reinstall drivers'; 19 = 'registry problem'; 21 = 'being removed'; 22 = 'disabled';
    24 = 'not present, not working or no drivers'; 28 = 'drivers not installed'; 29 = 'disabled by the firmware (no resources given)';
    31 = 'driver could not be loaded'; 32 = 'driver service disabled'; 33 = 'cannot determine resources'; 34 = 'needs manual configuration';
    35 = 'firmware lacks information (MPS table)'; 36 = 'IRQ translation failed'; 37 = 'driver returned failure'; 38 = 'previous driver instance still loaded';
    39 = 'driver missing or corrupted'; 40 = 'registry service key missing'; 41 = 'driver loaded but device not found'; 42 = 'duplicate device';
    43 = 'device reported a problem and was stopped'; 44 = 'shut down by an application or service'; 45 = 'not connected';
    47 = 'prepared for safe removal'; 48 = 'driver blocked'; 49 = 'registry too large'; 50 = 'cannot apply properties';
    51 = 'waiting on another device'; 52 = 'driver not signed'; 53 = 'reserved by the kernel debugger'; 54 = 'failed, being reset'
}

# ---------------------------------------------------------------- masking

$KeepGuids = @($GuidChip, $GuidApp, '8be4df61-93ca-11d2-aa0d-00e098032b8c', '4d36e968-e325-11ce-bfc1-08002be10318')
$ReUrl = New-Object Text.RegularExpressions.Regex '(?i)\b[a-z][a-z0-9+.-]*://[^\s''"<>]+'
$ReEmail = New-Object Text.RegularExpressions.Regex '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'
$ReWinHome = New-Object Text.RegularExpressions.Regex '(?i)(?:\b[a-z]:)?\\+(?:Users|Documents and Settings)\\+[^\\\s"'':;,]+'
$ReUnixHome = New-Object Text.RegularExpressions.Regex '(?i)/(?:home|Users)/[^/\s"'':;,]+'
$ReSerial = New-Object Text.RegularExpressions.Regex '(?i)(?<k>\b(?:serial\s*(?:number|no\.?)?|s/n)\s*[:=]\s*)[^\s,;]+'
$ReKey = New-Object Text.RegularExpressions.Regex '\b[A-Z0-9]{5}(?:-[A-Z0-9]{5}){4}\b'
$ReUuid = New-Object Text.RegularExpressions.Regex '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'
$ReMac = New-Object Text.RegularExpressions.Regex '(?i)(?<![0-9a-f:-])[0-9a-f]{2}(?<s>[:-])[0-9a-f]{2}(?:\k<s>[0-9a-f]{2}){4,}(?![0-9a-f])'
$ReIp4 = New-Object Text.RegularExpressions.Regex '(?<![\d.])(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?!\d|\.\d)'
$ReIp6 = New-Object Text.RegularExpressions.Regex '(?i)(?<![0-9a-z_:])[0-9a-f:]*:[0-9a-f:]*(?![0-9a-z_:])'
$ReHex32 = New-Object Text.RegularExpressions.Regex '(?<![0-9A-Za-z])[0-9A-Fa-f]{32}(?![0-9A-Za-z])'
$ReHexDump = New-Object Text.RegularExpressions.Regex '^    [0-9a-f]{4}: '

$UuidEval = [Text.RegularExpressions.MatchEvaluator] {
    param($m)
    if ($KeepGuids -contains $m.Value.ToLowerInvariant()) { return $m.Value }
    return '<uuid>'
}
$MacEval = [Text.RegularExpressions.MatchEvaluator] {
    param($m)
    $sep = $m.Groups['s'].Value
    $p = $m.Value.Split([char[]]@($sep[0]))
    $o = New-Object 'System.Collections.Generic.List[string]'
    for ($i = 0; $i -lt $p.Count; $i++) { if ($i -lt 3) { $o.Add($p[$i]) } else { $o.Add('xx') } }
    return ($o -join $sep)
}
$Ip6Eval = [Text.RegularExpressions.MatchEvaluator] {
    param($m)
    $v = $m.Value
    $g = $v.Split([char[]]@(':'))
    $n = 0; $h = 0
    foreach ($x in $g) {
        if ($x.Length -gt 4) { return $v }
        if ($x.Length -gt 0) { $n++; $h += $x.Length }
    }
    if (($v.Contains('::') -and $n -ge 2 -and $h -ge 4) -or ($g.Count -eq 8 -and $n -eq 8)) { return '<ip>' }
    return $v
}

$MaskTokens = New-Object 'System.Collections.Generic.List[object]'
function Add-Token([string]$Rep, [string]$Name, [bool]$IgnoreCase) {
    if (-not $Name) { return }
    $Name = $Name.Trim()
    if ($Name.Length -lt 2) { return }
    foreach ($t in $MaskTokens) { if ($t.Name -ceq $Name) { return } }
    $opt = [Text.RegularExpressions.RegexOptions]::None
    if ($IgnoreCase) { $opt = [Text.RegularExpressions.RegexOptions]::IgnoreCase }
    $re = New-Object Text.RegularExpressions.Regex ('(?<![A-Za-z0-9_])' + [regex]::Escape($Name) + '(?![A-Za-z0-9_])'), $opt
    $MaskTokens.Add([pscustomobject]@{ Name = $Name; Re = $re; Rep = $Rep })
}

function Build-Tokens {
    $sys = @('Public', 'Default', 'Default User', 'All Users', 'defaultuser0', 'defaultuser100000', 'WDAGUtilityAccount',
        'Administrator', 'Guest', 'DefaultAccount', 'WORKGROUP', 'localhost')
    $hosts = @($env:COMPUTERNAME)
    try { $hosts += [System.Net.Dns]::GetHostName() } catch { }
    foreach ($h in $hosts) { if ($h -and $sys -notcontains $h) { Add-Token '<host>' $h $true } }
    if ($env:USERDOMAIN -and $env:USERDOMAIN -ne $env:COMPUTERNAME -and $sys -notcontains $env:USERDOMAIN) { Add-Token '<domain>' $env:USERDOMAIN $true }
    $users = @($env:USERNAME)
    try {
        $root = Join-Path $env:SystemDrive 'Users'
        foreach ($d in @(Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction Stop)) { $users += $d.Name }
    } catch { }
    try {
        if (Get-Command Get-LocalUser -ErrorAction SilentlyContinue) {
            foreach ($u in @(Get-LocalUser -ErrorAction Stop)) { $users += $u.Name; if ($u.FullName) { $users += $u.FullName } }
        }
    } catch { }
    foreach ($u in $users) { if ($u -and $sys -notcontains $u) { Add-Token '<user>' $u $false } }
    # Saved Wi-Fi profiles: their names are network names. Used only to mask them; never written to the report.
    try {
        $txt = Invoke-Exe 'netsh.exe' 'wlan show profiles' 10
        foreach ($l in ($txt -split "`r?`n")) {
            if ($l -match '^\s{2,}\S.*?\s:\s(.+)$') { Add-Token '<wifi>' $Matches[1].Trim() $false }
        }
    } catch { }
    $sorted = @($MaskTokens | Sort-Object { $_.Name.Length } -Descending)
    $MaskTokens.Clear()
    foreach ($t in $sorted) { $MaskTokens.Add($t) }
}

function Mask([string]$s) {
    $ip4 = $false
    # Compare the character itself: a culture-aware StartsWith treats U+0001 as ignorable and matches every line.
    if ($s.Length -gt 0 -and [int]$s[0] -eq 1) { $ip4 = $true; $s = $s.Substring(1) }
    if ($ReHexDump.IsMatch($s)) { return $s }     # hex dumps of UEFI variables stay as they are
    $s = $ReUrl.Replace($s, '<url>')
    $s = $ReEmail.Replace($s, '<email>')
    # Names before paths, so a user folder with a space in its name ("C:\Users\Ivan Petrov") goes as a whole.
    foreach ($t in $MaskTokens) { $s = $t.Re.Replace($s, $t.Rep) }
    $s = $ReWinHome.Replace($s, '~')
    $s = $ReUnixHome.Replace($s, '~')
    $s = $ReSerial.Replace($s, '${k}<serial>')
    $s = $ReKey.Replace($s, '<key>')
    $s = $ReUuid.Replace($s, $UuidEval)
    $s = $ReMac.Replace($s, $MacEval)
    if ($ip4) { $s = $ReIp4.Replace($s, '<ip>') }  # structured lines skip this: driver versions like 1.0.0.88 look like IPs
    $s = $ReIp6.Replace($s, $Ip6Eval)
    $s = $ReHex32.Replace($s, '<id>')
    return $s
}

# SMBIOS strings (BIOS, board, system, chassis): vendors sometimes put a unique number into a "Version" or similar
# field (a Lenovo board: "SDK0J40697 WIN 1234567890123"). In these fields every run of 8+ digits, and every
# letters-and-digits run of 10+ characters that is not a Lenovo machine type and model (10MCS02600), part number
# (SDK0J40697) or notebook board model (LNVNB161216), becomes <serial>: "SDK0J40697 WIN 1234567890123" ->
# "SDK0J40697 WIN <serial>". The same rule is in z3report.sh (smbsafe). Memory part numbers are model numbers and
# are not passed through it.
$ReSmbRun = New-Object Text.RegularExpressions.Regex '[A-Za-z0-9]+'
$SmbEval = [Text.RegularExpressions.MatchEvaluator] {
    param($m)
    $r = $m.Value
    if ($r.Length -ge 8 -and $r -cmatch '^[0-9]+$') { return '<serial>' }
    if ($r.Length -ge 10 -and $r -cmatch '[A-Za-z]' -and $r -cmatch '[0-9]') {
        if ($r -cmatch '^[0-9]{2}[0-9A-Z]{8}$') { return $r }          # Lenovo machine type and model
        if ($r -cmatch '^[0-9A-Z]{4}[A-Z][0-9]{5}$') { return $r }     # Lenovo part number (FRU)
        if ($r -cmatch '^LNVNB[0-9]{6}$') { return $r }                 # Lenovo notebook board model
        return '<serial>'
    }
    return $r
}
function SmbSafe($v) {
    if ($null -eq $v) { return '' }
    return $ReSmbRun.Replace(([string]$v).Trim(), $SmbEval)
}

# The maker of a PCI device from VEN_xxxx in its id, so a card without its driver still says whose it is.
$VendorNames = @{
    '10DE' = 'NVIDIA'; '1002' = 'AMD'; '1022' = 'AMD'; '8086' = 'Intel'; '1A03' = 'ASPEED'; '102B' = 'Matrox'; '15AD' = 'VMware';
    '1234' = 'QEMU/Bochs'; '1AF4' = 'Red Hat (virtio)'; '1B36' = 'Red Hat (QEMU)'; '1414' = 'Microsoft (Hyper-V)'; '80EE' = 'VirtualBox';
    '5333' = 'S3'; '126F' = 'Silicon Motion'; '1013' = 'Cirrus Logic'; '1106' = 'VIA'; '1039' = 'SiS'; '10EC' = 'Realtek';
    '14E4' = 'Broadcom'; '1B21' = 'ASMedia'; '144D' = 'Samsung'; '1D17' = 'Zhaoxin'; '1ED5' = 'Moore Threads'
}
function VendorOf([string]$pnp) {
    if (-not $pnp -or $pnp -notmatch 'VEN_([0-9A-Fa-f]{4})') { return '' }
    $id = $Matches[1].ToUpperInvariant()
    $n = $VendorNames[$id]
    if (-not $n) { $n = 'unknown vendor' }
    return ($n + ' (VEN_' + $id + ')')
}

# WmiMonitorConnectionParams.VideoOutputTechnology (D3DKMDT_VIDEO_OUTPUT_TECHNOLOGY).
function VotName($v) {
    if ($null -eq $v) { return '' }
    switch ([int64]$v) {
        0 { return 'VGA (HD15)' }
        1 { return 'S-Video' }
        2 { return 'composite' }
        3 { return 'component' }
        4 { return 'DVI' }
        5 { return 'HDMI' }
        6 { return 'LVDS, internal' }
        8 { return 'D-Jpn' }
        9 { return 'SDI' }
        10 { return 'DisplayPort' }
        11 { return 'DisplayPort embedded, internal' }
        12 { return 'UDI' }
        13 { return 'UDI embedded, internal' }
        14 { return 'SDTV dongle' }
        15 { return 'Miracast' }
        16 { return 'indirect, wired' }
        17 { return 'indirect, virtual' }
        2147483648 { return 'internal' }
        4294967295 { return 'not reported by the driver (the standard Microsoft driver does not say) / драйвер не сообщает (стандартный драйвер Microsoft этого не знает)' }
        -1 { return 'not reported by the driver (the standard Microsoft driver does not say) / драйвер не сообщает (стандартный драйвер Microsoft этого не знает)' }
    }
    return ('code ' + $v)
}

# Interactive means a person can answer: not a service, not -NonInteractive, input not redirected.
function Test-Interactive {
    if (-not [Environment]::UserInteractive) { return $false }
    foreach ($a in [Environment]::GetCommandLineArgs()) { if ($a -match '^[-/]noni') { return $false } }
    try { if ([Console]::IsInputRedirected) { return $false } } catch { }
    return $true
}
# Started without administrator rights by a person: offer to restart elevated (one UAC prompt). Yes: start an
# elevated PowerShell with the same script and -ExecutionPolicy Bypass, then quit this one. No, or UAC refused or
# failed: go on as now.
function Request-Elevation {
    if ($IsAdmin -or $NoElevate -or $Relaunched -or -not $ScriptPath) { return }
    if (-not (Test-Interactive)) { return }
    Write-Host ''
    Write-Host (TR 'elevate_q')
    Write-Host (TE 'elevate_q')
    $ans = $null
    try { $ans = Read-Host '[Y/n]' } catch { return }
    $a = ([string]$ans).Trim().ToLowerInvariant()
    $yes = @('') + @((TR 'yes_words') -split ' ') + @((TE 'yes_words') -split ' ')
    if ($yes -notcontains $a) { Write-Host (Tx 'elevate_no'); return }
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $ScriptPath + '"'), '-Relaunched')
    try {
        $exe = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        Start-Process -FilePath $exe -ArgumentList $argList -Verb RunAs -ErrorAction Stop
        Write-Host (Tx 'elevate_started')
        exit 0
    } catch {
        Write-Host ((Tx 'elevate_failed') + ': ' + (ErrText $_))
    }
}

# ---------------------------------------------------------------- native code (compiled only when used)

$DxgiCode = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class Z3Dxgi {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct Desc1 {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string Description;
        public uint VendorId;
        public uint DeviceId;
        public uint SubSysId;
        public uint Revision;
        public UIntPtr DedicatedVideoMemory;
        public UIntPtr DedicatedSystemMemory;
        public UIntPtr SharedSystemMemory;
        public uint LuidLow;
        public int LuidHigh;
        public uint Flags;
    }
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate int EnumAdapters1Fn(IntPtr self, uint index, out IntPtr adapter);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate int GetDesc1Fn(IntPtr self, out Desc1 desc);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate uint ReleaseFn(IntPtr self);
    [DllImport("dxgi.dll")]
    static extern int CreateDXGIFactory1(ref Guid riid, out IntPtr factory);

    static Delegate Slot(IntPtr obj, int index, Type t) {
        IntPtr vtbl = Marshal.ReadIntPtr(obj);
        return Marshal.GetDelegateForFunctionPointer(Marshal.ReadIntPtr(vtbl, index * IntPtr.Size), t);
    }

    // One string per adapter: name|vendor|device|dedicated video|dedicated system|shared system (bytes)|flags
    public static string[] List() {
        List<string> res = new List<string>();
        Guid iid = new Guid("770aae78-f26f-4dba-a829-253c83d1b387"); // IDXGIFactory1
        IntPtr f;
        int hr = CreateDXGIFactory1(ref iid, out f);
        if (hr < 0) throw new Exception("CreateDXGIFactory1 0x" + hr.ToString("X8"));
        try {
            EnumAdapters1Fn enumAdapters = (EnumAdapters1Fn)Slot(f, 12, typeof(EnumAdapters1Fn)); // IDXGIFactory1::EnumAdapters1
            for (uint i = 0; i < 16; i++) {
                IntPtr a;
                if (enumAdapters(f, i, out a) < 0) break; // DXGI_ERROR_NOT_FOUND ends the list
                try {
                    Desc1 d;
                    GetDesc1Fn getDesc = (GetDesc1Fn)Slot(a, 10, typeof(GetDesc1Fn)); // IDXGIAdapter1::GetDesc1
                    if (getDesc(a, out d) >= 0)
                        res.Add(d.Description + "|" + d.VendorId.ToString("X4") + "|" + d.DeviceId.ToString("X4") + "|" +
                                d.DedicatedVideoMemory.ToUInt64() + "|" + d.DedicatedSystemMemory.ToUInt64() + "|" +
                                d.SharedSystemMemory.ToUInt64() + "|" + d.Flags);
                } finally {
                    ((ReleaseFn)Slot(a, 2, typeof(ReleaseFn)))(a);
                }
            }
        } finally {
            ((ReleaseFn)Slot(f, 2, typeof(ReleaseFn)))(f);
        }
        return res.ToArray();
    }
}
'@

$FwCode = @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

// Read-only access to UEFI variables: list the names, read one variable. Nothing here writes.
public static class Z3Fw {
    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    struct TokPriv1 { public uint Count; public long Luid; public uint Attr; }

    [DllImport("advapi32.dll", SetLastError = true)]
    static extern bool OpenProcessToken(IntPtr process, uint access, out IntPtr token);
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool LookupPrivilegeValueW(string system, string name, out long luid);
    [DllImport("advapi32.dll", SetLastError = true)]
    static extern bool AdjustTokenPrivileges(IntPtr token, bool disableAll, ref TokPriv1 state, uint length, IntPtr previous, IntPtr returned);
    [DllImport("kernel32.dll")]
    static extern IntPtr GetCurrentProcess();
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CloseHandle(IntPtr handle);
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern uint GetFirmwareEnvironmentVariableExW(string name, string guid, byte[] buffer, uint size, out uint attributes);
    [DllImport("ntdll.dll")]
    static extern int NtEnumerateSystemEnvironmentValuesEx(uint infoClass, IntPtr buffer, ref uint length);

    // Turns on SeSystemEnvironmentPrivilege for this process only. Returns "" or the reason it failed.
    public static string EnablePrivilege() {
        IntPtr tok;
        if (!OpenProcessToken(GetCurrentProcess(), 0x28 /* TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY */, out tok))
            return "OpenProcessToken: " + new Win32Exception(Marshal.GetLastWin32Error()).Message;
        try {
            TokPriv1 tp = new TokPriv1();
            tp.Count = 1;
            tp.Attr = 2; // SE_PRIVILEGE_ENABLED
            if (!LookupPrivilegeValueW(null, "SeSystemEnvironmentPrivilege", out tp.Luid))
                return "LookupPrivilegeValue: " + new Win32Exception(Marshal.GetLastWin32Error()).Message;
            if (!AdjustTokenPrivileges(tok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero))
                return "AdjustTokenPrivileges: " + new Win32Exception(Marshal.GetLastWin32Error()).Message;
            if (Marshal.GetLastWin32Error() == 1300) return "the privilege is not held (not an administrator)";
            return "";
        } finally {
            CloseHandle(tok);
        }
    }

    // All variable names as "name|guid" (guid in lower case without braces).
    public static string[] Names() {
        uint size = 0x10000;
        for (int round = 0; round < 8; round++) {
            IntPtr buf = Marshal.AllocHGlobal((int)size);
            try {
                uint got = size;
                int st = NtEnumerateSystemEnvironmentValuesEx(1 /* names */, buf, ref got);
                if (st == unchecked((int)0xC0000023) || st == unchecked((int)0x80000005)) { // buffer too small
                    size = Math.Max(got, size * 2);
                    continue;
                }
                if (st < 0) throw new Exception("NtEnumerateSystemEnvironmentValuesEx 0x" + st.ToString("X8"));
                List<string> names = new List<string>();
                long off = 0;
                while (off + 20 <= got) {
                    int next = Marshal.ReadInt32(buf, (int)off);
                    byte[] g = new byte[16];
                    Marshal.Copy(new IntPtr(buf.ToInt64() + off + 4), g, 0, 16);
                    string name = Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + off + 20));
                    names.Add(name + "|" + new Guid(g).ToString());
                    if (next <= 0) break;
                    off += next;
                }
                return names.ToArray();
            } finally {
                Marshal.FreeHGlobal(buf);
            }
        }
        throw new Exception("the variable list is too large");
    }

    // The data of one variable, or null with the reason in err.
    public static byte[] Read(string name, string guid, out uint attr, out string err) {
        byte[] buf = new byte[0x20000];
        err = "";
        uint n = GetFirmwareEnvironmentVariableExW(name, "{" + guid + "}", buf, (uint)buf.Length, out attr);
        if (n == 0) {
            int e = Marshal.GetLastWin32Error();
            err = e == 203 ? "not found" : e + " " + new Win32Exception(e).Message;
            return null;
        }
        byte[] data = new byte[n];
        Array.Copy(buf, data, (int)n);
        return data;
    }
}
'@

$FwTypeCode = @'
using System.Runtime.InteropServices;

public static class Z3FwType {
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool GetFirmwareType(out uint type);

    // 1 BIOS, 2 UEFI, 0 unknown. Needs no rights (Windows 8 and later).
    public static int Get() {
        uint t;
        return GetFirmwareType(out t) ? (int)t : 0;
    }
}
'@

function Use-Type([string]$Name, [string]$Code) {
    if (-not ($Name -as [type])) { Add-Type -TypeDefinition $Code -Language CSharp -ErrorAction Stop }
}

# How Windows was started: 2 UEFI, 1 legacy BIOS, 0 unknown. The variable firmware_type needs no rights; the registry
# value and the API are the fall-backs.
function Get-FwType {
    $e = [string]$env:firmware_type
    if ($e -eq 'UEFI') { return 2 }
    if ($e -eq 'Legacy') { return 1 }
    $r = RegVal 'SYSTEM\CurrentControlSet\Control' 'PEFirmwareType'
    if ($r -eq 1 -or $r -eq 2) { return [int]$r }
    try {
        Use-Type 'Z3FwType' $FwTypeCode
        $t = [Z3FwType]::Get()
        if ($t -eq 1 -or $t -eq 2) { return $t }
    } catch { }
    return 0
}

# 16 bytes per line: "    0000: xx xx ...  |ascii|", the same layout as the Linux script.
function HexDump([byte[]]$b, [int]$Max) {
    $n = [Math]::Min($b.Length, $Max)
    for ($o = 0; $o -lt $n; $o += 16) {
        $hex = New-Object Text.StringBuilder
        $asc = New-Object Text.StringBuilder
        $end = [Math]::Min($o + 16, $n)
        for ($i = $o; $i -lt $end; $i++) {
            $c = [int]$b[$i]
            [void]$hex.Append(' ').Append($c.ToString('x2'))
            if ($c -ge 32 -and $c -lt 127) { [void]$asc.Append([char]$c) } else { [void]$asc.Append('.') }
        }
        W ('    {0}:{1}  |{2}|' -f $o.ToString('x4'), $hex.ToString().PadRight(48), $asc.ToString())
    }
}

# ---------------------------------------------------------------- event log

$Since30 = 'TimeCreated[timediff(@SystemTime) <= 2592000000]'
function Get-Ev([string]$Log, [string]$Cond, [int]$Max, [string]$Extra) {
    $xp = '*[System[(' + $Cond + ') and ' + $Since30 + ']]'
    if ($Extra) { $xp = $xp + ' and ' + $Extra }
    try {
        $ev = @(Get-WinEvent -LogName $Log -FilterXPath $xp -MaxEvents $Max -ErrorAction Stop)
    } catch {
        if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { return , @() }
        throw
    }
    [array]::Reverse($ev)   # oldest first
    return , $ev
}
function Prov([string[]]$Names) { return (($Names | ForEach-Object { "Provider[@Name='" + $_ + "']" }) -join ' or ') }
function EvHead($e) { return (F '{0:yyyy-MM-dd HH:mm:ss}  {1} {2}' $e.TimeCreated $e.ProviderName $e.Id) }
function EvText($e, [int]$MaxLines) {
    $m = $null
    try { $m = $e.Message } catch { }
    if (-not $m) {
        $vals = @()
        try { $vals = @($e.Properties | ForEach-Object { [string]$_.Value }) } catch { }
        $m = '(no message text) ' + ($vals -join ', ')
    }
    return , @(($m -split "`r?`n") | Where-Object { $_.Trim() -ne '' } | Select-Object -First $MaxLines)
}
function Ev-Data($e) {
    $d = @{}
    try {
        $x = [xml]$e.ToXml()
        foreach ($n in @($x.Event.EventData.Data)) { if ($n.Name) { $d[$n.Name] = $n.'#text' } }
    } catch { }
    return $d
}
# Print events: a head line, then up to MaxLines lines of the message.
function Out-Ev($list, [int]$MaxLines) {
    if (@($list).Count -eq 0) { Note ('  ' + (Tx 'none')); return }
    foreach ($e in $list) {
        W ('    ' + (EvHead $e))
        foreach ($l in (EvText $e $MaxLines)) { WT ('        ' + $l.Trim()) }
    }
}

# ---------------------------------------------------------------- steps

$RunAs = 'normal user (some parts need administrator)'
if ($IsAdmin) { $RunAs = 'administrator' }
$FwType = Get-FwType   # 1 BIOS, 2 UEFI, 0 unknown

$StepNo = 0
$StepTotal = 18
function Step([string]$Tag, [string]$Key, [scriptblock]$Body) {
    $script:StepNo++
    Write-Host ('  [{0,2}/{1}] {2}' -f $script:StepNo, $StepTotal, (Tx $Key))
    W ''
    W ('=== [{0}] {1}' -f $Tag, (Tx $Key))
    try { & $Body } catch { W ('  ' + (Tx 'failed') + ': ' + (ErrText $_)) }
}

$script:PnpAll = $null
function Get-Pnp {
    if ($null -eq $script:PnpAll) {
        $script:PnpAll = @(Q 'Win32_PnPEntity' @('Name', 'PNPDeviceID', 'PNPClass', 'Status', 'ConfigManagerErrorCode', 'Service'))
    }
    return , $script:PnpAll
}
$script:DrvMap = $null
function Get-DrvMap {
    if ($null -eq $script:DrvMap) {
        $script:DrvMap = @{}
        try {
            foreach ($d in @(Q 'Win32_PnPSignedDriver' @('DeviceID', 'DriverVersion', 'DriverDate', 'DriverProviderName'))) {
                if ($d.DeviceID) { $script:DrvMap[$d.DeviceID.ToUpperInvariant()] = $d }
            }
        } catch { }
    }
    return $script:DrvMap
}
function DrvOf([string]$pnp) {
    if (-not $pnp) { return $null }
    return (Get-DrvMap)[$pnp.ToUpperInvariant()]
}

function Step-Os {
    $os = Q 'Win32_OperatingSystem' @('Caption', 'Version', 'BuildNumber', 'OSArchitecture', 'LastBootUpTime')
    $cv = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    KV 'Windows' $os.Caption
    KV 'Version' (F '{0}, build {1}.{2}, {3}' $os.Version (RegVal $cv 'CurrentBuild') (RegVal $cv 'UBR') (RegVal $cv 'DisplayVersion'))
    KV 'Edition' (RegVal $cv 'EditionID')
    KV 'Architecture' $os.OSArchitecture
    $boot = ToDate $os.LastBootUpTime
    if ($boot) {
        KV 'Boot time' (FmtDate $boot)
        $up = (Get-Date) - $boot
        KV 'Uptime' (F '{0}d {1:00}h {2:00}m' $up.Days $up.Hours $up.Minutes)
    }
    $fs = RegVal 'SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled'
    $fsText = '?'
    if ($fs -eq 1) { $fsText = 'on (after "Shut down" Windows resumes from hibernation, so the boot time above changes only on restart)' }
    elseif ($fs -eq 0) { $fsText = 'off' }
    KV 'Fast Startup' $fsText
    try {
        $cs = Q 'Win32_ComputerSystem' @('HypervisorPresent')
        KV 'Hypervisor present' $cs.HypervisorPresent
    } catch { }
    try {
        $dg = Q 'Win32_DeviceGuard' @('VirtualizationBasedSecurityStatus') '' 'root\Microsoft\Windows\DeviceGuard'
        $vbs = @('off', 'enabled, not running', 'running')[[int]$dg.VirtualizationBasedSecurityStatus]
        KV 'Virtualization-based security' $vbs
    } catch { }
    KV 'PowerShell' $PSVersionTable.PSVersion.ToString()
    KV 'Run as' $RunAs
    $Facts['os'] = F '{0} {1} build {2}.{3}' $os.Caption (RegVal $cv 'DisplayVersion') (RegVal $cv 'CurrentBuild') (RegVal $cv 'UBR')
    $Facts['faststartup'] = $fsText
}

function Step-Firmware {
    $b = Q 'Win32_BIOS' @('Manufacturer', 'SMBIOSBIOSVersion', 'BIOSVersion', 'ReleaseDate', 'SMBIOSMajorVersion', 'SMBIOSMinorVersion',
        'SystemBiosMajorVersion', 'SystemBiosMinorVersion', 'EmbeddedControllerMajorVersion', 'EmbeddedControllerMinorVersion')
    # Every SMBIOS string goes through SmbSafe (unique numbers -> <serial>).
    KV 'BIOS vendor' (SmbSafe $b.Manufacturer)
    KV 'BIOS version' (SmbSafe $b.SMBIOSBIOSVersion)
    KV 'BIOS version strings' ((@($b.BIOSVersion) | ForEach-Object { SmbSafe $_ }) -join ' | ')
    KV 'BIOS date' (FmtDate $b.ReleaseDate)
    KV 'BIOS release' (F '{0}.{1}' $b.SystemBiosMajorVersion $b.SystemBiosMinorVersion)
    KV 'EC release' (F '{0}.{1}' $b.EmbeddedControllerMajorVersion $b.EmbeddedControllerMinorVersion)
    KV 'SMBIOS version' (F '{0}.{1}' $b.SMBIOSMajorVersion $b.SMBIOSMinorVersion)
    $Facts['bios'] = F '{0} {1} ({2})' (SmbSafe $b.Manufacturer) (SmbSafe $b.SMBIOSBIOSVersion) (FmtDate $b.ReleaseDate)
    try {
        $bb = Q 'Win32_BaseBoard' @('Manufacturer', 'Product', 'Version')
        $board = F '{0} {1} {2}' (SmbSafe $bb.Manufacturer) (SmbSafe $bb.Product) (SmbSafe $bb.Version)
        KV 'Board' $board
        $Facts['board'] = $board
    } catch { Note ('Board: ' + (Tx 'failed') + ': ' + (ErrText $_)) }
    try {
        $cs = Q 'Win32_ComputerSystem' @('Manufacturer', 'Model', 'SystemFamily', 'SystemSKUNumber')
        KV 'System' (F '{0} {1}' (SmbSafe $cs.Manufacturer) (SmbSafe $cs.Model))
        KV 'Family / SKU' (F '{0} / {1}' (SmbSafe $cs.SystemFamily) (SmbSafe $cs.SystemSKUNumber))
    } catch { }
    try {
        $kinds = @{ 3 = 'desktop'; 4 = 'low profile desktop'; 5 = 'pizza box'; 6 = 'mini tower'; 7 = 'tower'; 8 = 'portable'; 9 = 'laptop';
            10 = 'notebook'; 13 = 'all in one'; 15 = 'space-saving'; 16 = 'lunch box'; 35 = 'mini PC'; 36 = 'stick PC'
        }
        foreach ($en in @(Q 'Win32_SystemEnclosure' @('Manufacturer', 'Version', 'ChassisTypes'))) {
            $types = @($en.ChassisTypes | ForEach-Object { $k = $kinds[[int]$_]; if ($k) { $k } else { 'type ' + $_ } }) -join ', '
            KV 'Chassis' (F '{0} {1}, {2}' (SmbSafe $en.Manufacturer) (SmbSafe $en.Version) $types)
        }
    } catch { }
    $ft = '?'
    if ($FwType -eq 2) { $ft = 'UEFI' } elseif ($FwType -eq 1) { $ft = 'legacy BIOS (CSM)' }
    KV 'Boot mode' $ft
    $sb = RegVal 'SYSTEM\CurrentControlSet\Control\SecureBoot\State' 'UEFISecureBootEnabled'
    $sbText = '?'
    if ($sb -eq 1) { $sbText = 'on' } elseif ($sb -eq 0) { $sbText = 'off' }
    KV 'Secure Boot' $sbText
}

function Microcode($b) {
    if ($b -isnot [byte[]] -or $b.Length -lt 8) { return '' }
    $lo = [BitConverter]::ToUInt32($b, 0)
    $hi = [BitConverter]::ToUInt32($b, 4)
    $v = $lo
    if ($hi -ne 0) { $v = $hi }
    return ('0x{0} (raw {1})' -f $v.ToString('X8'), (($b | ForEach-Object { $_.ToString('X2') }) -join ' '))
}
function Step-Cpu {
    foreach ($c in @(Q 'Win32_Processor' @('Name', 'Caption', 'SocketDesignation', 'NumberOfCores', 'NumberOfLogicalProcessors',
                'MaxClockSpeed', 'CurrentClockSpeed', 'L2CacheSize', 'L3CacheSize', 'VirtualizationFirmwareEnabled'))) {
        KV 'Model' $c.Name
        KV 'Family / model / stepping' $c.Caption
        KV 'Socket' $c.SocketDesignation
        KV 'Cores / logical CPUs' (F '{0} / {1}' $c.NumberOfCores $c.NumberOfLogicalProcessors)
        KV 'Max / current MHz' (F '{0} / {1}' $c.MaxClockSpeed $c.CurrentClockSpeed)
        KV 'L2 / L3 cache KB' (F '{0} / {1}' $c.L2CacheSize $c.L3CacheSize)
        KV 'Virtualization in firmware' $c.VirtualizationFirmwareEnabled
        if (-not $Facts['cpu']) { $Facts['cpu'] = ([string]$c.Name).Trim() }
    }
    $k = 'HARDWARE\DESCRIPTION\System\CentralProcessor\0'
    KV 'Identifier' (RegVal $k 'Identifier')
    $mc = Microcode (RegVal $k 'Update Revision')
    $mcFw = Microcode (RegVal $k 'Previous Update Revision')
    KV 'Microcode now' $mc
    KV 'Microcode from firmware' $mcFw
    $Facts['microcode'] = F '{0}, from firmware {1}' $mc $mcFw
}

function Step-Memory {
    $cs = Q 'Win32_ComputerSystem' @('TotalPhysicalMemory')
    KV 'Seen by Windows' (GiB $cs.TotalPhysicalMemory)
    try {
        foreach ($a in @(Q 'Win32_PhysicalMemoryArray' @('MaxCapacity', 'MaxCapacityEx', 'MemoryDevices', 'MemoryErrorCorrection'))) {
            $max = $a.MaxCapacityEx
            if (-not $max) { $max = $a.MaxCapacity }
            KV 'Slots / max capacity' (F '{0} / {1}' $a.MemoryDevices (GiB ([double]$max * 1KB)))
        }
    } catch { }
    $types = @{ 20 = 'DDR'; 21 = 'DDR2'; 24 = 'DDR3'; 26 = 'DDR4'; 34 = 'DDR5'; 35 = 'LPDDR5' }
    $sum = 0.0
    $mods = @(Q 'Win32_PhysicalMemory' @('BankLabel', 'DeviceLocator', 'Capacity', 'Speed', 'ConfiguredClockSpeed', 'Manufacturer',
            'PartNumber', 'SMBIOSMemoryType', 'FormFactor', 'ConfiguredVoltage'))
    Note 'Modules (no serial numbers):'
    foreach ($m in $mods) {
        $sum += [double]$m.Capacity
        $t = $types[[int]$m.SMBIOSMemoryType]
        if (-not $t) { $t = 'type ' + $m.SMBIOSMemoryType }
        $volt = ''
        if ($m.ConfiguredVoltage) { $volt = F ', {0:0.00} V' ([double]$m.ConfiguredVoltage / 1000) }
        W (F '    {0,-32} {1} {2}, {3} MT/s (configured {4}), {5} {6}{7}' ([string]$m.DeviceLocator + ' / ' + [string]$m.BankLabel) (GiB $m.Capacity) $t `
                $m.Speed $m.ConfiguredClockSpeed ([string]$m.Manufacturer).Trim() ([string]$m.PartNumber).Trim() $volt)
    }
    KV 'Installed' (F '{0} in {1} module(s)' (GiB $sum) $mods.Count)
    if ($sum -gt 0 -and $cs.TotalPhysicalMemory) { KV 'Not visible to Windows' (F '{0} (firmware, integrated graphics)' (GiB ($sum - [double]$cs.TotalPhysicalMemory))) }
    $Facts['memory'] = F '{0} in {1} module(s), Windows sees {2}' (GiB $sum) $mods.Count (GiB $cs.TotalPhysicalMemory)
}

function Step-Graphics {
    $sum = @()
    $pnp = @()
    try { $pnp = Get-Pnp } catch { }   # only for the BasicDisplay check; the adapter list does not depend on it
    try {
        foreach ($v in @(Q 'Win32_VideoController' @('Name', 'DriverVersion', 'DriverDate', 'AdapterRAM', 'VideoProcessor', 'PNPDeviceID', 'Status',
                    'ConfigManagerErrorCode', 'CurrentHorizontalResolution', 'CurrentVerticalResolution', 'CurrentRefreshRate', 'InfFilename', 'InfSection'))) {
            # The Microsoft Basic Display Adapter (display.inf, section MSBDA, service BasicDisplay): no vendor driver.
            $svc = @($pnp | Where-Object { $_.PNPDeviceID -eq $v.PNPDeviceID } | ForEach-Object { $_.Service })
            $basic = ($v.InfFilename -eq 'display.inf') -or ($v.InfSection -eq 'MSBDA') -or ($svc -contains 'BasicDisplay')
            $vendor = VendorOf $v.PNPDeviceID
            Note ('Adapter: ' + $v.Name)
            KV '  vendor' $vendor
            KV '  hardware id' (HwId $v.PNPDeviceID)
            KV '  driver' (F '{0} ({1}), {2}' $v.DriverVersion (FmtDate $v.DriverDate) $v.InfFilename)
            if ($basic) { KV '  driver note' (Tx 'gpu_nodriver') }
            KV '  status' (F '{0}, problem code {1}' $v.Status $v.ConfigManagerErrorCode)
            KV '  AdapterRAM (WMI, caps at 4 GB)' (MiB $v.AdapterRAM)
            if ($v.CurrentHorizontalResolution) {
                $hz = Tx 'hz_unknown'   # the basic driver reports 0 or 1 Hz
                if ([int]$v.CurrentRefreshRate -gt 1) { $hz = F '{0} Hz' $v.CurrentRefreshRate }
                KV '  current mode' (F '{0}x{1}, {2}' $v.CurrentHorizontalResolution $v.CurrentVerticalResolution $hz)
            }
            $note = ''
            if ($basic) { $note = ', no vendor driver' }
            $sum += (F '{0} [{1}, driver {2}{3}]' $v.Name $vendor $v.DriverVersion $note)
        }
    } catch { Note ('Win32_VideoController: ' + (Tx 'failed') + ': ' + (ErrText $_)) }
    $Facts['gpu'] = $sum -join '; '
    Note 'Driver registry (display class; may include adapters no longer present):'
    $cls = 'SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
    foreach ($sk in (RegSubKeys $cls)) {
        if ($sk -notmatch '^\d{4}$') { continue }
        $p = $cls + '\' + $sk
        $desc = RegText (RegVal $p 'DriverDesc')
        if (-not $desc) { continue }
        $mem = RegVal $p 'HardwareInformation.qwMemorySize'
        if ($null -eq $mem) {
            $mem = RegVal $p 'HardwareInformation.MemorySize'
            if ($mem -is [byte[]] -and $mem.Length -ge 4) { $mem = [BitConverter]::ToUInt32($mem, 0) }
        }
        W (F '    {0}: {1} | driver {2} ({3}, {4}) | dedicated memory {5} | VBIOS {6} | chip {7}' $sk $desc (RegText (RegVal $p 'DriverVersion')) `
                (RegText (RegVal $p 'DriverDate')) (RegText (RegVal $p 'ProviderName')) (MiB $mem) (RegText (RegVal $p 'HardwareInformation.BiosString')) `
                (RegText (RegVal $p 'HardwareInformation.ChipType')))
    }
    Note 'DXGI (what Windows gives programs; for an integrated GPU "dedicated video" is the UMA frame buffer set by the firmware):'
    try {
        Use-Type 'Z3Dxgi' $DxgiCode
        foreach ($a in [Z3Dxgi]::List()) {
            $p = $a.Split([char[]]@('|'))
            $soft = ''
            if (([int64]$p[6] -band 2) -ne 0) { $soft = ' (software adapter)' }
            W (F '    {0} [{1}:{2}]{3}: dedicated video {4}, dedicated system {5}, shared system {6}' $p[0] $p[1] $p[2] $soft `
                    (MiB ([double]$p[3])) (MiB ([double]$p[4])) (MiB ([double]$p[5])))
            if (-not $soft -and -not $Facts['gpumem']) { $Facts['gpumem'] = F 'dedicated {0}, shared {1}' (MiB ([double]$p[3])) (MiB ([double]$p[5])) }
        }
    } catch { Note ('    DXGI: ' + (Tx 'failed') + ': ' + (ErrText $_)) }
}

function Step-Monitors {
    $list = @(Q 'WmiMonitorID' @('InstanceName', 'Active', 'ManufacturerName', 'ProductCodeID', 'UserFriendlyName') '' 'root\wmi')
    if ($list.Count -eq 0) { Note (Tx 'none'); return }
    # How each monitor is connected (DisplayPort, HDMI, DVI, VGA, internal); joined to WmiMonitorID by InstanceName,
    # which is never printed.
    $conn = @{}
    $connNote = ''
    try {
        foreach ($c in @(Q 'WmiMonitorConnectionParams' @('InstanceName', 'VideoOutputTechnology') '' 'root\wmi')) {
            $conn[[string]$c.InstanceName] = $c.VideoOutputTechnology
        }
        if ($conn.Count -eq 0) { $connNote = Tx 'no_data' }
    } catch {
        if ($IsAdmin) { $connNote = (Tx 'no_data') + ': ' + (ErrText $_) } else { $connNote = Tx 'need_admin' }
    }
    $dec = { param($a) if ($null -eq $a) { return '' }; return (-join ([char[]]@($a | Where-Object { $_ -ne 0 }))).Trim() }
    foreach ($m in $list) {
        $how = $connNote
        $key = [string]$m.InstanceName
        if ($conn.ContainsKey($key)) { $how = VotName $conn[$key] } elseif (-not $how) { $how = Tx 'no_data' }
        W (F '  {0} {1} {2} | active {3} | connection: {4}' (& $dec $m.ManufacturerName) (& $dec $m.ProductCodeID) (& $dec $m.UserFriendlyName) $m.Active $how)
    }
}

function Step-Problems {
    $pnp = Get-Pnp   # assign first: piping the function would hand the whole array over as one item
    $bad = @($pnp | Where-Object { ($_.ConfigManagerErrorCode -and $_.ConfigManagerErrorCode -ne 0) -or ($_.Status -and $_.Status -ne 'OK') })
    $Facts['pnp_bad'] = $bad.Count
    if ($bad.Count -eq 0) { Note (Tx 'none'); return }
    foreach ($d in ($bad | Sort-Object PNPClass, Name)) {
        $code = [int]$d.ConfigManagerErrorCode
        W (F '  {0} | {1} | {2} | class {3} | code {4}: {5} | status {6}' $d.Name (VendorOf $d.PNPDeviceID) (HwId $d.PNPDeviceID) $d.PNPClass $code $CmText[$code] $d.Status)
    }
}

function Step-Crashes {
    $c41 = 0; $c41bc = 0; $c41pb = 0; $c6008 = 0; $c1001 = 0
    Note ((Tx 'crash_list') + ':')
    $cond = '(' + (Prov @('EventLog')) + ' and (EventID=6005 or EventID=6006 or EventID=6008)) or (' +
    (Prov @('Microsoft-Windows-Kernel-Power')) + ' and EventID=41) or (' +
    (Prov @('Microsoft-Windows-WER-SystemErrorReporting')) + ' and EventID=1001) or (' +
    (Prov @('User32')) + ' and EventID=1074)'
    $ev = Get-Ev 'System' $cond 80
    if ($ev.Count -eq 0) { Note ('  ' + (Tx 'none')) }
    foreach ($e in $ev) {
        $h = '    ' + (EvHead $e) + '  '
        switch ($e.Id) {
            6005 { W ($h + 'START (event log service started)') }
            6006 { W ($h + 'clean shutdown') }
            6008 {
                $c6008++
                $t = @(EvText $e 1)
                WT ($h + 'UNEXPECTED SHUTDOWN: ' + ($t -join ' '))
            }
            41 {
                $c41++
                $d = Ev-Data $e
                $bc = [int64]0
                [void][int64]::TryParse([string]$d['BugcheckCode'], [ref]$bc)
                $pb = [string]$d['PowerButtonTimestamp']
                $parts = @()
                if ($bc -ne 0) { $c41bc++; $parts += ('bugcheck 0x' + $bc.ToString('X')) } else { $parts += 'no bugcheck: hang, power loss or reset' }
                if ($pb -and $pb -ne '0') { $c41pb++; $parts += 'power button was pressed' }
                if ($d['SleepInProgress'] -and [string]$d['SleepInProgress'] -ne '0') { $parts += ('sleep transition ' + $d['SleepInProgress']) }
                if ($d.ContainsKey('BootAppStatus')) { $parts += ('BootAppStatus ' + $d['BootAppStatus']) }
                if ($d.ContainsKey('Checkpoint')) { $parts += ('Checkpoint ' + $d['Checkpoint']) }
                W ($h + 'KERNEL-POWER 41, rebooted without a clean shutdown: ' + ($parts -join '; '))
            }
            1001 {
                $c1001++
                $t = @(EvText $e 2)
                WT ($h + 'BUGCHECK (blue screen): ' + ($t -join ' '))
            }
            1074 {
                $d = @()
                try { $d = @($e.Properties | ForEach-Object { [string]$_.Value }) } catch { }
                $proc = ''
                if ($d.Count -gt 0 -and $d[0]) {
                    $x = $d[0] -replace '\s*\(.*$', ''         # "C:\...\winlogon.exe (PCNAME)" -> file name only
                    $proc = $x.Substring($x.LastIndexOf([char]'\') + 1)
                }
                $kind = ''
                if ($d.Count -gt 4) { $kind = $d[4] }
                $why = ''
                if ($d.Count -gt 2) { $why = $d[2] }
                W ($h + 'planned ' + $kind + ' by ' + $proc + ': ' + $why)
            }
            default { W ($h) }
        }
    }
    $Facts['kp41'] = F '{0} (with a bugcheck code {1}, power button pressed {2})' $c41 $c41bc $c41pb
    $Facts['ev6008'] = $c6008
    $Facts['bugcheck'] = $c1001
}

function Step-Whea {
    $ev = Get-Ev 'System' ((Prov @('Microsoft-Windows-WHEA-Logger')) + ' and (EventID=1 or EventID=17 or EventID=18 or EventID=19 or EventID=20 or EventID=46 or EventID=47)') 40
    $fatal = @($ev | Where-Object { $_.Id -eq 1 -or $_.Id -eq 18 -or $_.Id -eq 20 -or $_.Id -eq 46 }).Count
    $Facts['whea'] = F '{0} (fatal {1}, corrected {2})' $ev.Count $fatal ($ev.Count - $fatal)
    Note 'WHEA-Logger 1/17/18/19/20/46/47 (last 40):'
    Out-Ev $ev 14
    Note 'Windows Memory Diagnostic results:'
    Out-Ev (Get-Ev 'System' (Prov @('Microsoft-Windows-MemoryDiagnostics-Results')) 10) 3
}

function Step-FwEvents {
    $cond = '((' + (Prov @('ACPI', 'Microsoft-Windows-HAL', 'TPM', 'Microsoft-Windows-TPM-WMI', 'Microsoft-Windows-Kernel-Boot', 'Microsoft-Windows-Kernel-Processor-Power')) +
    ') and (Level=1 or Level=2 or Level=3)) or (' + (Prov @('Microsoft-Windows-Kernel-Power')) + ' and (Level=2 or Level=3))'
    $ev = Get-Ev 'System' $cond 60
    $Facts['fwev'] = $ev.Count
    Note 'ACPI, HAL, TPM, Kernel-Boot, Kernel-Processor-Power (37: CPU speed limited by firmware), Kernel-Power warnings (last 60):'
    Out-Ev $ev 4
}

function Step-Storage {
    $cond = '(' + (Prov @('disk', 'Ntfs', 'Microsoft-Windows-Ntfs', 'volmgr', 'storahci', 'stornvme', 'Microsoft-Windows-StorPort', 'iaStorAC', 'iaStorA', 'amdsata', 'rcraid')) +
    ') and (Level=1 or Level=2 or Level=3)'
    $ev = Get-Ev 'System' $cond 50
    $Facts['storage'] = $ev.Count
    Out-Ev $ev 3
}

function Step-GpuErrors {
    $ev = Get-Ev 'System' ('(' + (Prov @('Display', 'amdkmdag', 'amdkmdap', 'nvlddmkm', 'igfx')) + ') and (Level=1 or Level=2 or Level=3)') 40
    $Facts['tdr'] = $ev.Count
    Note 'Display driver events (4101: driver stopped responding and recovered), last 40:'
    Out-Ev $ev 3
    Note 'Windows Error Reporting: LiveKernelEvent and BlueScreen reports, last 20:'
    $wer = Get-Ev 'Application' ((Prov @('Windows Error Reporting')) + ' and EventID=1001') 20 "*[EventData[Data='LiveKernelEvent' or Data='BlueScreen']]"
    Out-Ev $wer 8
}

function Step-Dumps {
    $cc = 'SYSTEM\CurrentControlSet\Control\CrashControl'
    $kinds = @{ 0 = 'none'; 1 = 'complete'; 2 = 'kernel'; 3 = 'small (minidump)'; 7 = 'automatic' }
    $cde = RegVal $cc 'CrashDumpEnabled'
    $kt = '?'
    if ($null -ne $cde) {
        $kt = $kinds[[int]$cde]
        if (-not $kt) { $kt = [string]$cde }
    }
    KV 'Dump type' $kt
    KV 'Restart after a blue screen' (RegVal $cc 'AutoReboot')
    $n = 0
    foreach ($dir in @((Join-Path $env:SystemRoot 'Minidump'), (Join-Path $env:SystemRoot 'LiveKernelReports'))) {
        try {
            $files = @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction Stop | Where-Object { $_.Extension -eq '.dmp' } |
                    Sort-Object LastWriteTime -Descending | Select-Object -First 30)
            Note ($dir + ':')
            if ($files.Count -eq 0) { Note ('  ' + (Tx 'none')) }
            foreach ($f in $files) {
                $n++
                W (F '    {0}  {1,12} bytes  {2}' (FmtDate $f.LastWriteTime) $f.Length $f.FullName.Substring($dir.Length).TrimStart('\'))
            }
        } catch [System.Management.Automation.ItemNotFoundException] {
            Note ($dir + ': ' + (Tx 'none'))
        } catch {
            if ($IsAdmin) { Note ($dir + ': ' + (Tx 'failed') + ': ' + (ErrText $_)) } else { Note ($dir + ': ' + (Tx 'skipped') + ', ' + (Tx 'need_admin')) }
        }
    }
    try {
        $md = Get-Item -LiteralPath (Join-Path $env:SystemRoot 'MEMORY.DMP') -Force -ErrorAction Stop
        KV 'MEMORY.DMP' (F '{0} bytes, {1}' $md.Length (FmtDate $md.LastWriteTime))
    } catch { KV 'MEMORY.DMP' 'not found or not readable' }
    if ($IsAdmin) { $Facts['dumps'] = $n } else { $Facts['dumps'] = 'not checked, needs administrator' }
}

function Step-Pci {
    $pnp = Get-Pnp
    $list = @($pnp | Where-Object { $_.PNPDeviceID -like 'PCI\*' } | Sort-Object PNPDeviceID)
    foreach ($d in $list) {
        $dv = DrvOf $d.PNPDeviceID
        $ver = ''
        if ($dv) { $ver = F '{0} {1}' $dv.DriverVersion $dv.DriverProviderName }
        W (F '  {0} | {1} | {2} | {3} | service {4} | driver {5}' (HwId $d.PNPDeviceID) (VendorOf $d.PNPDeviceID) $d.Name $d.Status $d.Service $ver)
    }
    $Facts['pci'] = $list.Count
}

function Step-Network {
    $st = @{ 0 = 'disconnected'; 1 = 'connecting'; 2 = 'connected'; 3 = 'disconnecting'; 4 = 'hardware not present'; 5 = 'hardware disabled';
        6 = 'hardware malfunction'; 7 = 'media disconnected'; 8 = 'authenticating'; 9 = 'authenticated'; 10 = 'authentication failed'
    }
    foreach ($a in @(Q 'Win32_NetworkAdapter' @('Name', 'PNPDeviceID', 'MACAddress', 'NetConnectionStatus', 'Speed', 'ServiceName') 'PhysicalAdapter=TRUE')) {
        $dv = DrvOf $a.PNPDeviceID
        $speed = '?'
        if ($a.Speed -and [double]$a.Speed -lt 1e12) { $speed = F '{0} Mbit/s' ([double]$a.Speed / 1e6) }
        $s = $st[[int]$a.NetConnectionStatus]
        W (F '  {0} | {1} | MAC {2} | {3} | {4} | service {5} | driver {6}' $a.Name (HwId $a.PNPDeviceID) (MaskMac $a.MACAddress) $s $speed $a.ServiceName $dv.DriverVersion)
    }
    Note (Tx 'no_ip')
}

function Step-Disks {
    foreach ($d in @(Q 'Win32_DiskDrive' @('Index', 'Model', 'Size', 'InterfaceType', 'MediaType', 'FirmwareRevision', 'Status'))) {
        W (F '  disk {0}: {1} | {2} | {3} | {4} | firmware {5} | status {6}' $d.Index $d.Model (GiB $d.Size) $d.InterfaceType $d.MediaType $d.FirmwareRevision $d.Status)
    }
    try {
        $media = @{ 0 = 'unspecified'; 3 = 'HDD'; 4 = 'SSD'; 5 = 'SCM' }
        $bus = @{ 1 = 'SCSI'; 3 = 'ATA'; 7 = 'USB'; 8 = 'RAID'; 10 = 'SAS'; 11 = 'SATA'; 12 = 'SD'; 17 = 'NVMe' }
        $health = @{ 0 = 'healthy'; 1 = 'warning'; 2 = 'unhealthy'; 5 = 'unknown' }
        foreach ($p in @(Q 'MSFT_PhysicalDisk' @('FriendlyName', 'MediaType', 'BusType', 'HealthStatus', 'Size') '' 'root\Microsoft\Windows\Storage')) {
            W (F '  {0} | {1} | {2} | {3} | health {4}' $p.FriendlyName $media[[int]$p.MediaType] $bus[[int]$p.BusType] (GiB $p.Size) $health[[int]$p.HealthStatus])
        }
    } catch { }
}

function Step-Efi {
    Note "Format: 'var NAME-GUID attr=ATTRIBUTES size=BYTES', then 16 bytes per line (offset: hex bytes |ASCII|). Only variables the firmware made visible to the OS (runtime access) appear."
    if (-not $IsAdmin) {
        Note ((Tx 'skipped') + ': ' + (Tx 'need_admin'))
        $Facts['efivars'] = 'skipped, needs administrator'
        return
    }
    if ($FwType -ne 2) {
        Note ((Tx 'skipped') + ': ' + (Tx 'not_uefi'))
        $Facts['efivars'] = 'skipped, not UEFI'
        return
    }
    Use-Type 'Z3Fw' $FwCode
    $perr = [Z3Fw]::EnablePrivilege()
    if ($perr) { throw $perr }
    $want = @()
    try {
        foreach ($nm in [Z3Fw]::Names()) {
            $p = $nm.Split([char[]]@('|'), 2)
            if ($p.Count -eq 2 -and ($p[1] -eq $GuidChip -or $p[1] -eq $GuidApp)) { $want += [pscustomobject]@{ Name = $p[0]; Guid = $p[1] } }
        }
    } catch {
        Note ('Variable list: ' + (Tx 'failed') + ': ' + (ErrText $_) + '; trying the known names')
        $want += [pscustomobject]@{ Name = 'Z3Chip'; Guid = $GuidChip }
        foreach ($n in @('Z3NovoPrefs', 'Z3NovoDiag', 'Z3NovoBackup', 'Z3NovoFan', 'Z3NovoCurve', 'Z3NovoDash', 'Z3NovoConsole', 'Z3NovoOcRb',
                'Z3NovoRollback', 'Z3NovoDefaultsBoot', 'Z3NovoSkipOnce', 'Z3EntryTestWindow')) {
            $want += [pscustomobject]@{ Name = $n; Guid = $GuidApp }
        }
    }
    $done = 0
    $missing = @()
    foreach ($v in ($want | Sort-Object Guid, Name)) {
        $attr = [uint32]0
        $err = ''
        $data = [Z3Fw]::Read($v.Name, $v.Guid, [ref]$attr, [ref]$err)
        if ($null -eq $data) {
            if ($err -eq 'not found') { $missing += $v.Name; continue }
            W ('  var ' + $v.Name + '-' + $v.Guid)
            W ('    ' + (Tx 'failed') + ': ' + $err)
            continue
        }
        $done++
        W (F '  var {0}-{1} attr=0x{2} size={3}' $v.Name $v.Guid $attr.ToString('x8') $data.Length)
        HexDump $data 65536
        if ($data.Length -gt 65536) { Note '  (first 65536 bytes shown)' }
    }
    if ($missing.Count -gt 0) { Note ('not present: ' + ($missing -join ', ')) }
    if ($done -eq 0 -and $missing.Count -eq 0) { Note (Tx 'no_z3vars') }
    $Facts['efivars'] = $done
    $Facts['z3chip'] = 'absent'
    foreach ($v in $want) { if ($v.Name -eq 'Z3Chip' -and $missing -notcontains 'Z3Chip') { $Facts['z3chip'] = 'present' } }
}

# ---------------------------------------------------------------- run

Request-Elevation   # may restart the script elevated and quit this copy

Write-Host ('Z3NOVO: ' + (TR 'collecting'))
Write-Host ('        ' + (TE 'collecting'))
if (-not $IsAdmin) {
    Write-Host ('  ' + (TR 'hint_admin'))
    Write-Host ('  ' + (TE 'hint_admin'))
}

Step 'os' 'sec_os' { Step-Os }
Step 'firmware' 'sec_fw' { Step-Firmware }
Step 'cpu' 'sec_cpu' { Step-Cpu }
Step 'memory' 'sec_mem' { Step-Memory }
Step 'graphics' 'sec_gpu' { Step-Graphics }
Step 'monitors' 'sec_mon' { Step-Monitors }
Step 'problems' 'sec_problems' { Step-Problems }
Step 'crashes' 'sec_crashes' { Step-Crashes }
Step 'whea' 'sec_whea' { Step-Whea }
Step 'fwevents' 'sec_fwev' { Step-FwEvents }
Step 'storage' 'sec_storage' { Step-Storage }
Step 'gpuerrors' 'sec_gpuerr' { Step-GpuErrors }
Step 'dumps' 'sec_dumps' { Step-Dumps }
Step 'sensors' 'sec_sensors' { Note (TR 'sensors'); Note (TE 'sensors') }
Step 'pci' 'sec_pci' { Step-Pci }
Step 'network' 'sec_net' { Step-Network }
Step 'disks' 'sec_disks' { Step-Disks }
Step 'efivars' 'sec_efi' { Step-Efi }

try { Build-Tokens } catch { }

function FactOr([string]$k, [string]$def) { $v = $Facts[$k]; if ($null -eq $v -or "$v" -eq '') { return $def }; return [string]$v }
$summary = New-Object 'System.Collections.Generic.List[string]'
$saved = $Lines
$Lines = $summary
W ''
W ('=== [summary] ' + (Tx 'sec_summary'))
KV 'BIOS' (FactOr 'bios' '?')
KV 'Board' (FactOr 'board' '?')
KV 'CPU' ((FactOr 'cpu' '?') + ', microcode ' + (FactOr 'microcode' '?'))
KV 'Memory' (FactOr 'memory' '?')
KV 'Graphics' ((FactOr 'gpu' '?') + '; ' + (FactOr 'gpumem' 'memory unknown'))
KV 'Windows' (FactOr 'os' '?')
KV 'Fast Startup' (FactOr 'faststartup' '?')
KV 'Kernel-Power 41, 30 days' (FactOr 'kp41' 'unknown')
KV 'Unexpected shutdowns 6008' (FactOr 'ev6008' 'unknown')
KV 'Blue screens (1001), 30 days' (FactOr 'bugcheck' 'unknown')
KV 'WHEA hardware errors, 30d' (FactOr 'whea' 'unknown')
KV 'Firmware/ACPI/TPM events' (FactOr 'fwev' 'unknown')
KV 'Disk and NTFS events' (FactOr 'storage' 'unknown')
KV 'Display driver events' (FactOr 'tdr' 'unknown')
KV 'Devices with problems' (FactOr 'pnp_bad' 'unknown')
KV 'Crash dump files' (FactOr 'dumps' 'unknown')
KV 'Z3Chip variable' (FactOr 'z3chip' 'unknown (needs administrator)')
KV 'Z3 UEFI variables dumped' (FactOr 'efivars' '?')
$Lines = $saved

$stamp = (Get-Date).ToString('yyyy-MM-dd-HHmmss', $Inv)
$created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz', $Inv)
$head = @(
    ((TE 'title') + ' / ' + (TR 'title')),
    ('script z3report.ps1 ' + $Version + ' (Windows) | created ' + $created + ' | run as ' + $RunAs),
    (TR 'collected'), (TR 'excluded'), (TE 'collected'), (TE 'excluded'), (TR 'masks')
)
$foot = @('', ('=== [end] ' + (Tx 'sec_end')), ('  ' + (TR 'end_check')), ('  ' + (TE 'end_check')))
# The header and footer are fixed text; everything collected goes through the masking.
$all = New-Object 'System.Collections.Generic.List[string]'
foreach ($l in $head) { $all.Add([string]$l) }
foreach ($l in $summary) { $all.Add((Mask $l)) }
foreach ($l in $Lines) { $all.Add((Mask $l)) }
foreach ($l in $foot) { $all.Add([string]$l) }
$text = ($all -join "`r`n") + "`r`n"

$outPath = $null
$dirs = @()
try { $dirs += [Environment]::GetFolderPath('Desktop') } catch { }
$dirs += @($env:USERPROFILE, (Get-Location).ProviderPath, $env:TEMP)
foreach ($d in $dirs) {
    if (-not $d -or -not (Test-Path -LiteralPath $d -PathType Container)) { continue }
    $cand = Join-Path $d ('z3report-os-' + $stamp + '.txt')
    try {
        [IO.File]::WriteAllText($cand, $text, (New-Object Text.UTF8Encoding $true))   # UTF-8 with BOM, so Notepad shows Russian
        $outPath = $cand
        break
    } catch { }
}
Write-Host ''
if (-not $outPath) {
    Write-Host ((TR 'write_failed') + ' / ' + (TE 'write_failed'))
    if ($Relaunched) { try { [void](Read-Host ((TR 'close') + ' / ' + (TE 'close'))) } catch { } }
    exit 1
}
Write-Host ((TR 'done') + ' / ' + (TE 'done') + ':')
Write-Host ('  ' + $outPath)
Write-Host (TR 'check')
Write-Host (TE 'check')
Write-Host ((TR 'send') + ' / ' + (TE 'send'))
# Started by "Run with PowerShell" from Explorer, or restarted elevated by this script: the window would close at once,
# so wait for Enter.
if ($Relaunched -or [Environment]::CommandLine -match 'Set-ExecutionPolicy -Scope Process') {
    try { [void](Read-Host ((TR 'close') + ' / ' + (TE 'close'))) } catch { }
}
