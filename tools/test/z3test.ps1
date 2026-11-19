<#
z3test.ps1: an unattended test for testers of the Z3NOVO firmware (Lenovo ThinkCentre M715s, board AM4P2MS), in their own
Windows 10 or 11.

    powershell -ExecutionPolicy Bypass -File z3test.ps1            short run, about 35 minutes
    powershell -ExecutionPolicy Bypass -File z3test.ps1 -Long      long run, about 1.5 hours
    powershell -ExecutionPolicy Bypass -File z3test.ps1 -Stop      stop a run and undo its changes

What it does, in this order: a snapshot of the system (the whole z3report.ps1 report plus memory set and running, PCIe
links, NVMe drives, Secure Boot and TPM, the Windows activation status); sleep and wake N times, woken by a scheduled task
with WakeToRun; load on all cores and the memory with pattern checks (a C# helper compiled by Windows itself); idle (long
run); N restarts in a row, continued after each start by a startup task running as SYSTEM, without automatic logon; then
the events of the test window (Kernel-Power, Power-Troubleshooter, WHEA, blue screens and minidumps, display driver
resets, disk, NVMe and USB errors) and a plain-words SUMMARY. Everything goes into ONE zip on the Desktop.

Needs administrator rights. Temporary changes, each written to a journal and undone at the end, on a stop, on Ctrl+C,
or at the next start after a run that broke off: the scheduled tasks \Z3NOVO\Z3TEST-resume and \Z3NOVO\Z3TEST-wake, the
"Allow wake timers" setting of the active power plan (AC), the folder C:\ProgramData\Z3TEST. A one-time task
\Z3NOVO\Z3TEST-show shows the result at the next logon when the run finished while nobody was logged on; it expires by
itself after 3 days and the next run removes it too.

Never done here: firmware variables are only read, never written; no BIOS settings; no direct hardware access from
Windows (I/O ports, SMBus, the Super I/O chip, the EC, ACPI thermal zones); no network; no programs or drivers installed;
the Windows product key is never read (the activation status only).

Windows PowerShell 5.1. The code is plain ASCII on purpose: all Russian text sits in the $TextData and $TestTextData
blocks, re-decoded at run time if the file lost its UTF-8 BOM on the way. Made by a build script from the z3test sources
and z3report.ps1: the part between the two "z3report.ps1" marker lines is z3report.ps1 itself, copied unchanged (fix
the report there, not here).
#>
param(
    [switch]$Long,              # long run: more sleeps and restarts, a longer load, 18 minutes of idling
    [int]$SleepCycles = -1,     # sleeps (default 3, long 8)
    [int]$SleepSeconds = -1,    # how long each sleep lasts before the timer wakes the computer (default 60, long 90)
    [int]$Reboots = -1,         # restarts (default 3, long 8)
    [int]$LoadMinutes = -1,     # load on all cores and the memory (default 10, long 20)
    [int]$IdleMinutes = -1,     # idling (default 3, long 18)
    [string[]]$Skip = @(),      # steps to leave out: sleep, load, idle, reboot (comma separated)
    [switch]$Yes,               # start without the question
    [switch]$Stop,              # stop a running test (or undo the changes of one that broke off) and make its archive
    [switch]$NoElevate,         # do not offer to restart with administrator rights
    [switch]$Resume,            # internal: started by the startup task
    [switch]$Relaunched         # internal: restarted elevated by the script itself
)

# ==== z3report.ps1 1.0 (sha256 3a957cfd160512e7...), its lines 26 to 1214, copied unchanged by build.sh: do not edit here ====

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

# ==== end of the z3report.ps1 part ====

# ================================================================ z3test: texts, key|Russian|English ({0}, {1}: values)

$TestTextData = @'
_check|проверка|check
mode_short|короткий|short
mode_long|долгий|long
ph_snapshot|Снимок системы: сведения, как у z3report, и ещё память, линки PCIe, NVMe, Secure Boot, TPM, активация.|System snapshot: the z3report details plus memory, PCIe links, NVMe, Secure Boot, TPM and activation.
sleep_go|Сон {0} из {1}: компьютер уснёт на {2} с и проснётся сам. Не трогайте мышь и клавиатуру.|Sleep {0} of {1}: the computer sleeps for {2} s and wakes by itself. Do not touch the mouse or the keyboard.
sleep_back|Проснулся после сна {0}: спал и просыпался {1} с.|Back from sleep {0}: asleep and back in {1} s.
load_go|Нагрузка {0} мин, потоков: {1}; проверка {2} ГБ памяти по шаблонам и вычислений процессора.|Load for {0} min: {1} threads, pattern checks over {2} GB of memory and CPU calculation checks.
idle_go|Простой {0} мин: компьютер ничего не делает (часть зависаний Ryzen бывает именно так).|Idling for {0} min: the computer does nothing (some Ryzen hangs happen just like this).
reboot_first|Перезагрузки подряд: {0}. Сейчас Windows перезагрузится, проверка продолжится сама; входить в Windows не нужно.|Restarts: {0} in a row. Windows restarts now and the test goes on by itself; you do not need to log on.
reboot_next|Перезагрузка {0} из {1}.|Restart {0} of {1}.
reboot_comment|Z3NOVO z3test: перезагрузка {0} из {1}. Остановить: файл Z3TEST-STOP на рабочем столе.|Z3NOVO z3test: restart {0} of {1}. To stop: a file Z3TEST-STOP on the Desktop.
reboot_now|Перезагрузка...|Restarting...
final_go|Итог: собираю события и журналы, откатываю временные изменения, делаю архив.|Finishing: collecting the events and logs, undoing the temporary changes, making the archive.
elev_q|Для проверки нужны права администратора (задачи планировщика, сон, перезагрузки). Перезапустить скрипт с ними? Enter или Д — да, Н — нет.|The test needs administrator rights (scheduled tasks, sleep, restarts). Restart the script with them? Enter or Y for yes, N for no.
elev_started|Открыто окно с правами администратора, проверка пойдёт в нём. Это окно можно закрыть.|A window with administrator rights is open; the test runs there. You can close this one.
need_win10|Нужна Windows 10 или 11.|Needs Windows 10 or 11.
need_admin_run|Без прав администратора проверка не запускается. Откройте PowerShell от имени администратора и запустите скрипт снова.|The test does not run without administrator rights. Open PowerShell as administrator and run the script again.
already_running|Проверка уже идёт (в другом окне или после перезагрузки). Остановить её: z3test.ps1 -Stop или файл Z3TEST-STOP на рабочем столе.|A test is already running (in another window or after a restart). To stop it: z3test.ps1 -Stop, or a file Z3TEST-STOP on the Desktop.
stale_found|Прошлая проверка не закончилась ({0}). Откатываю её изменения и делаю её архив.|The previous test did not finish ({0}). Undoing its changes and making its archive.
need_yes|Окно не интерактивное: чтобы начать без вопроса, добавьте -Yes.|This is not an interactive window: add -Yes to start without the question.
cancelled|Отменено, ничего не изменено.|Cancelled, nothing changed.
intro_title|Z3NOVO: проверка в системе (z3test), режим «{0}», около {2} мин.|Z3NOVO in-system test (z3test), {1} run, about {2} min.
intro_plan|Что будет: снимок системы; сон с пробуждением по таймеру: {0} × {1} с; нагрузка на процессор и память {2} мин; простой {3} мин; перезагрузки: {4}; итог и архив.|What happens: a system snapshot; sleep {0} times for {1} s, woken by a timer; load on the CPU and memory for {2} min; idling for {3} min; restarts: {4}; the result and the archive.
intro_nos3|Внимание: Windows не предлагает обычный сон (S3), шаг сна будет пропущен (подробности будут в snapshot.txt).|Note: Windows offers no ordinary sleep (S3) here, so the sleep step will be skipped (details in snapshot.txt).
intro_before|Перед началом:|Before you start:
intro_1|  1. Сохраните работу и закройте программы: компьютер будет сам засыпать и перезагружаться.|  1. Save your work and close programs: the computer will go to sleep and restart by itself.
intro_2|  2. Права администратора есть. Прошивку, настройки BIOS и железо скрипт не трогает; временные изменения (задачи планировщика, «Разрешить таймеры пробуждения») он запишет и вернёт.|  2. Administrator rights: yes. The script does not touch the firmware, the BIOS settings or the hardware; its temporary changes (scheduled tasks, "Allow wake timers") are written down and undone.
intro_3_on|  3. Быстрый запуск Windows включён. На время тестов прошивки его лучше выключить: Панель управления → Электропитание → Действия кнопок питания → снять «Включить быстрый запуск». Самой проверке он не мешает.|  3. Windows Fast Startup is on. Better turn it off while testing the firmware: Control Panel → Power Options → Choose what the power buttons do → untick "Turn on fast startup". It does not get in the way of this test.
intro_3_off|  3. Быстрый запуск Windows выключен — хорошо.|  3. Windows Fast Startup is off: good.
intro_4_block|  4. BitLocker спрашивает при включении «{0}»: перезагрузки без человека не пройдут, этот шаг будет пропущен.|  4. BitLocker asks for "{0}" at power-on: restarts cannot go on without a person, so that step is skipped.
intro_4_on|  4. BitLocker включён без PIN: перезагрузки пройдут сами. Ключ восстановления BitLocker держите под рукой на всякий случай.|  4. BitLocker is on without a PIN: restarts go on by themselves. Keep the BitLocker recovery key at hand just in case.
intro_4_off|  4. BitLocker с PIN не найден (если он у вас есть — остановите проверку: перезагрузки без человека не пройдут).|  4. No BitLocker PIN found (if you do have one, stop the test: restarts cannot go on without a person).
intro_5|  5. Если компьютер уснул и не проснулся за 5 минут — нажмите кнопку питания. Не реагирует — держите кнопку 5 секунд и включите снова: скрипт сам допишет итог.|  5. If the computer went to sleep and has not woken within 5 minutes, press the power button. No response: hold the button for 5 seconds and power on again; the script finishes the result by itself.
intro_6|  6. Лучше заранее установить обновления Windows: обновление при перезагрузке удлиняет её, и это попадёт в замечания.|  6. Better install Windows updates first: an update during a restart makes it longer, and that shows up as a note.
intro_stop|Остановить: Ctrl+C в этом окне; или файл Z3TEST-STOP на рабочем столе; или «powershell -ExecutionPolicy Bypass -File z3test.ps1 -Stop».|To stop: Ctrl+C in this window; or a file Z3TEST-STOP on the Desktop; or "powershell -ExecutionPolicy Bypass -File z3test.ps1 -Stop".
intro_result|Итог: один архив Z3TEST-win-<дата>-<время>.zip на рабочем столе.|The result: one archive Z3TEST-win-<date>-<time>.zip on the Desktop.
intro_go|Enter — начать; Н и Enter — отказаться.|Enter to start; N and Enter to cancel.
stop_flag|На рабочем столе создан файл Z3TEST-STOP.txt: проверка остановится и сделает архив.|The file Z3TEST-STOP.txt is on the Desktop now: the test stops and makes its archive.
stop_nothing|Идущей или оборванной проверки нет; оставшиеся задачи планировщика убраны.|No test is running or broken off; leftover scheduled tasks are removed.
stop_sent|Проверке передана просьба остановиться. Жду, пока она откатит изменения и сделает архив (до 5 минут)...|The test was asked to stop. Waiting while it undoes its changes and makes the archive (up to 5 minutes)...
stop_done|Проверка остановлена, архив на рабочем столе.|The test has stopped; the archive is on the Desktop.
stop_slow|Проверка ещё не остановилась. Если идёт перезагрузка — она остановится после неё.|The test has not stopped yet. If a restart is under way, it stops after it.
show_where|Архив для отправки (бот @z3novo_bot или GitHub Issues):|The archive to send (the @z3novo_bot bot or GitHub Issues):
snap_title|Z3NOVO z3test: снимок системы|Z3NOVO z3test: system snapshot
no_nvme|накопителей NVMe нет|no NVMe drive
ev_title|Z3NOVO z3test: события за время проверки, с|Z3NOVO z3test: events of the test window, from
ev_sys|Журнал System: питание, запуск и выключение, WHEA, синие экраны, все ошибки и предупреждения|System log: power, start and shutdown, WHEA, blue screens, and every error and warning
ev_wer|Отчёты об ошибках ядра (LiveKernelEvent, BlueScreen)|Windows Error Reporting: LiveKernelEvent and BlueScreen
dumps_title|Z3NOVO z3test: аварийные дампы за время проверки (только имена и размеры)|Z3NOVO z3test: crash dumps written during the test (names and sizes only)
sec_x_mem|Память: задано и работает|Memory: set and running
sec_x_pcie|Линки PCIe: скорость и ширина|PCIe links: speed and width
sec_x_nvme|Накопители: модель, прошивка, состояние|Drives: model, firmware, health
sec_x_sec|Secure Boot и TPM|Secure Boot and TPM
sec_x_act|Активация Windows, только статус|Windows activation, status only
sec_x_power|Сон и настройки питания|Sleep and power settings
sec_x_bl|BitLocker, только виды защиты|BitLocker, kinds of protectors only
w_sleep|сна {0}|sleep {0}
w_sleeps|всех снов|all sleeps
w_reboot|перезагрузки {0}|restart {0}
w_end|конца проверки|the end of the test
w_ph_snapshot|снимок системы|the system snapshot
w_ph_sleep|сон|sleep
w_ph_load|нагрузка|load
w_ph_idle|простой|idling
w_ph_reboot|перезагрузки|restarts
w_ph_final|итог|finishing
w_ph_start|начало|the start
v_dev_missing|После {0} пропали устройства: {1}|Devices gone after {0}: {1}
v_dev_broken|После {0} у устройств появились ошибки: {1}|Devices with a new problem after {0}: {1}
v_link_narrow|После {0} линк PCIe стал уже: {1}|A PCIe link got narrower after {0}: {1}
v_mem_nomods|Модули памяти не видны в SMBIOS: ни объёма, ни частоты планок.|No memory modules in SMBIOS: neither the size nor the speed of the modules.
v_mem_info|Память: стоит {0} (планок: {1}), Windows видит {2}, частота {3} МТ/с, видеопамять {4}.|Memory: {0} installed ({1} module(s)), Windows sees {2}, speed {3} MT/s, graphics memory {4}.
x_gfx_unknown|неизвестно: видеодрайвер её не сообщает|unknown: the video driver does not give it
x_rest_unknown|не посчитать без размера видеопамяти|not counted without the graphics memory
gfx_unknown|неизвестна (нет видеодрайвера)|unknown (no video driver)
v_mem_mixed|Планки работают на разной частоте: {0} МТ/с.|The modules run at different speeds: {0} MT/s.
v_mem_missing|Windows видит заметно меньше памяти, чем стоит: стоит {0}, видно {1}, видеопамять {2}. Возможно, одна планка не используется.|Windows sees much less memory than is installed: {0} installed, {1} seen, graphics memory {2}. Maybe one module is not used.
v_link|Линк: {0} — сейчас {1} x{2}, само устройство умеет {3} x{4}.|Link: {0} runs at {1} x{2}, the device itself can do {3} x{4}.
v_nvme|Накопитель NVMe: {0}, прошивка {1}.|NVMe drive: {0}, firmware {1}.
v_sb|Secure Boot: {0} (SetupMode {1}).|Secure Boot: {0} (SetupMode {1}).
v_tpm|TPM: {0}.|TPM: {0}.
v_act_none|Статус активации Windows не найден.|No Windows activation status found.
v_act_ok|Windows активирована (канал лицензии {0}).|Windows is activated (licence channel {0}).
v_act_not|Windows не активирована: {0} (канал {1}). Если до прошивки была активирована — напишите об этом.|Windows is not activated: {0} (channel {1}). If it was activated before the firmware update, please say so.
v_sleep_skipped|Сон пропущен по выбору.|Sleep skipped by choice.
v_sleep_aoac|Сон не проверялся: здесь «современный режим ожидания» (S0), обычного сна S3 в Windows нет.|Sleep not tested: this system uses modern standby (S0), Windows has no ordinary S3 sleep here.
v_sleep_nos3|Сон не проверялся: Windows не предлагает сон S3 (причина — в snapshot.txt, раздел powercfg /a).|Sleep not tested: Windows offers no S3 sleep (the reason is in snapshot.txt, powercfg /a).
v_sleep_rtc|Windows считает, что часы будят компьютер только из {0}, не из сна S3.|Windows says the clock can wake the computer only from {0}, not from S3 sleep.
v_sleep_setup|Сон не проверялся: не удалось подготовить таймер пробуждения ({0}).|Sleep not tested: the wake timer could not be set up ({0}).
v_sleep_fail|Сон {0}: компьютер не уснул ({1}).|Sleep {0}: the computer did not go to sleep ({1}).
v_sleep_notasleep|Сон {0}: компьютер не уснул (вернулся через {1} с, записи о сне нет).|Sleep {0}: the computer did not go to sleep (back after {1} s, no sleep record).
v_sleep_state|Сон {0}: вместо сна S3 было {1}.|Sleep {0}: {1} instead of S3 sleep.
v_sleep_slow|Сон {0}: проснулся по таймеру, но всё заняло {1} с — долго.|Sleep {0}: woke by the timer, but it all took {1} s, which is long.
v_sleep_early|Сон {0}: проснулся раньше таймера, через {1} с; разбудило: {2}.|Sleep {0}: woke before the timer, after {1} s; woken by: {2}.
v_sleep_late|Сон {0}: таймер не разбудил компьютер; проснулся только через {1}, разбудило: {2} (нажали кнопку?).|Sleep {0}: the timer did not wake the computer; it woke only after {1}, woken by: {2} (a button press?).
v_sleep_ok|Сон: {0} из {1} раз уснул и проснулся по таймеру, устройства на месте.|Sleep: {0} of {1} times went to sleep and woke by the timer, devices all there.
v_sleep_unplanned|Windows сама уснула во время проверки, не по команде скрипта (раз: {0}; первый — в {1}, шаг «{2}», спала {3}, разбудило: {4}). Время этого шага и его итог неточны. Обычно так бывает, когда компьютер проснулся по таймеру и никто не трогал мышь и клавиатуру; если повторится — напишите.|Windows went to sleep by itself during the test, not by the script ({0} time(s); the first at {1}, step "{2}", asleep {3}, woken by: {4}). That step's time and result are not exact. It usually happens after a timer wake with nobody at the mouse or keyboard; if it happens again, please say so.
v_sleep_fw|Прошивка при пробуждении из сна: в среднем {0} мс (BiosInitDuration).|The firmware part of waking from sleep: {0} ms on average (BiosInitDuration).
dur_s|{0} с|{0} s
dur_min|{0} мин|{0} min
v_load_fail|Нагрузка не запустилась: Windows не собрала помощник нагрузки ({0}).|The load did not start: Windows could not build the load helper ({0}).
v_load_skipped|Нагрузка пропущена по выбору.|Load skipped by choice.
v_load_mem|Ошибки памяти под нагрузкой: {0} (подробно — load.txt). Это серьёзно: память или её настройки нестабильны.|Memory errors under load: {0} (details in load.txt). This is serious: the memory or its settings are unstable.
v_load_cpu|Ошибки вычислений процессора под нагрузкой: {0} (load.txt). Похоже на нестабильность: разгон, Curve Optimizer или напряжение.|CPU calculation errors under load: {0} (load.txt). Looks like instability: overclocking, Curve Optimizer or voltage.
v_load_ok|Нагрузка {0} мин, потоков: {1}; {2} ГБ памяти, проверено {3} ГБ по шаблонам, ошибок памяти и вычислений нет.|Load for {0} min on {1} threads: {2} GB of memory, {3} GB checked by patterns, no memory or calculation errors.
v_idle_skipped|Простой пропущен по выбору.|Idling skipped by choice.
v_idle_ok|Простой {0} мин прошёл без зависаний.|{0} min of idling went without a hang.
v_reboot_skipped|Перезагрузки пропущены по выбору.|Restarts skipped by choice.
v_reboot_bitlocker|Перезагрузки пропущены: BitLocker спрашивает при включении «{0}».|Restarts skipped: BitLocker asks for "{0}" at power-on.
v_reboot_ok|Перезагрузки: {0} из {1} прошли чисто; от команды до старта Windows в среднем {2}.|Restarts: {0} of {1} went cleanly; from the command to Windows starting {2} on average.
v_reboot_cancelled|Перезагрузка {0} не случилась (её отменили?); остальные пропущены.|Restart {0} did not happen (cancelled?); the rest were skipped.
v_reboot_kp41|Перезагрузка {0} прошла не чисто: Windows записала внезапное выключение (Kernel-Power 41) — компьютер, похоже, завис и его включили заново.|Restart {0} was not clean: Windows logged an unexpected shutdown (Kernel-Power 41); the computer seems to have hung and was powered on again.
v_reboot_starts|Перезагрузка {0}: Windows стартовала несколько раз ({1}) вместо одного.|Restart {0}: Windows started {1} times instead of once.
v_reboot_long|Перезагрузка {0} заняла {1} — долго (зависание, которое кто-то сбросил, или обновление Windows).|Restart {0} took {1}, which is long (a hang somebody reset, or a Windows update).
v_unexp_sleep|КОМПЬЮТЕР НЕ ПРОСНУЛСЯ из сна {0} (уснул в {1}): его включили заново, Windows стартовала в {2} и записала внезапное выключение (Kernel-Power 41{3}).|THE COMPUTER DID NOT WAKE from sleep {0} (asleep at {1}): it was powered on again, Windows started at {2} and logged an unexpected shutdown (Kernel-Power 41{3}).
v_unexp_bsod|Синий экран во время шага «{0}»: код {1}; последняя отметка «жив» в {2}, Windows снова стартовала в {3}.|A blue screen during "{0}": code {1}; last sign of life at {2}, Windows started again at {3}.
v_unexp_hang|Компьютер завис или выключился во время шага «{0}»: последняя отметка «жив» в {1}, Windows снова стартовала в {2} (через {3}); внезапное выключение (Kernel-Power 41).|The computer hung or lost power during "{0}": last sign of life at {1}, Windows started again at {2} ({3} later); unexpected shutdown (Kernel-Power 41).
v_unexp_clean|Проверку прервал штатный перезапуск или выключение во время шага «{0}» (последняя отметка в {1}, старт в {2}).|A normal restart or shutdown cut the test short during "{0}" (last sign of life at {1}, started at {2}).
v_ev_whea_f|Неисправимые аппаратные ошибки (WHEA): {0} (events.txt).|Fatal hardware errors (WHEA): {0} (events.txt).
v_ev_whea_c|Исправленные аппаратные ошибки (WHEA): {0} (events.txt).|Corrected hardware errors (WHEA): {0} (events.txt).
v_ev_bsod|Синие экраны за время проверки: {0} ({1}).|Blue screens during the test: {0} ({1}).
v_ev_kp41|Внезапные выключения за время проверки (Kernel-Power 41): {0}.|Unexpected shutdowns during the test (Kernel-Power 41): {0}.
v_ev_tdr|Видеодрайвер сбрасывался или сообщал об ошибках: {0} (events.txt).|The display driver reset or reported errors: {0} (events.txt).
v_ev_disk_e|Ошибки дисков или NVMe: {0} ({1}).|Disk or NVMe errors: {0} ({1}).
v_ev_disk_w|Предупреждения дисков или NVMe: {0} ({1}).|Disk or NVMe warnings: {0} ({1}).
v_ev_usb|Ошибки или предупреждения USB: {0} (events.txt).|USB errors or warnings: {0} (events.txt).
v_ev_acpi|Ошибки ACPI (прошивка): {0} (events.txt).|ACPI (firmware) errors: {0} (events.txt).
v_ev_kpp37|Прошивка ограничивала частоту процессора (Kernel-Processor-Power 37): {0} записей.|The firmware limited the CPU speed (Kernel-Processor-Power 37): {0} records.
v_ev_clean|Журналы Windows за время проверки чистые: нет аппаратных ошибок, синих экранов, внезапных выключений, сбросов видео, ошибок дисков и USB.|The Windows logs of the test are clean: no hardware errors, blue screens, unexpected shutdowns, display resets, disk or USB errors.
v_ev_failed|Журналы событий не прочитаны: {0}.|The event logs could not be read: {0}.
v_dump_mini|Аварийные дампы (синий экран): {0}.|Crash dumps (blue screen): {0}.
v_dump_live|Отчёты ядра о сбоях (LiveKernelReports, часто от видеодрайвера): {0}.|Kernel fault reports (LiveKernelReports, often the display driver): {0}.
v_stall|Система замирала (раз: {0}), самая долгая пауза {1} с (шаг «{2}», в {3}).|The system froze for a while: {0} times, the longest pause {1} s ("{2}", at {3}).
v_stopped|Проверка остановлена на шаге «{0}», остальные шаги не выполнены.|The test was stopped at "{0}"; the remaining steps did not run.
v_broke_off|Проверка оборвалась на шаге «{0}» (окно закрыли или компьютер выключили), итог собран при следующем запуске.|The test broke off at "{0}" (the window was closed or the computer switched off); the result was made at the next start.
v_fan_win|Вентилятор после сна (ошибка T2.0 на 5600G): в Windows не проверяется — для этого нужен доступ к железу, который на этой плате может подвесить микросхему датчиков. Проверка — z3test.sh --deep в Linux; или на слух: меняются ли обороты под нагрузкой после сна.|The fan after sleep (a T2.0 bug on a 5600G): not checked in Windows, since that needs hardware access which can hang this board's sensor chip. Use z3test.sh --deep in Linux, or listen: does the fan speed change under load after a sleep.
v_script_error|Скрипт остановился из-за своей ошибки: {0}. Пришлите архив — это поможет её исправить.|The script stopped on an error of its own: {0}. Please send the archive; it helps to fix it.
sum_title|Z3NOVO: проверка в системе (z3test) — ИТОГ|Z3NOVO in-system test (z3test): RESULT
sum_run|Скрипт z3test.ps1 {0}, режим «{1}» (по плану около {5} мин); начало {2}, конец {3}, шло {4}.|Script z3test.ps1 {0}, {1} run (about {5} min as planned); started {2}, ended {3}, took {4}.
sum_board|Компьютер:|Computer:
sum_bios|BIOS:|BIOS:
sum_cpu|Процессор:|CPU:
sum_mem|Память:|Memory:
sum_gpu|Видео:|Graphics:
sum_os|Windows:|Windows:
res_ok|ИТОГ: ВСЁ В ПОРЯДКЕ|RESULT: ALL GOOD
res_warn|ИТОГ: ЕСТЬ ЗАМЕЧАНИЯ|RESULT: SOME NOTES
res_err|ИТОГ: ЕСТЬ ОШИБКИ|RESULT: ERRORS FOUND
sum_err|ОШИБКИ:|ERRORS:
sum_warn|ЗАМЕЧАНИЯ:|NOTES:
sum_ok|В ПОРЯДКЕ:|OK:
sum_skip|ПРОПУЩЕНО ИЛИ НЕ ПРОВЕРЯЕТСЯ:|SKIPPED OR NOT CHECKED:
sum_info|СВЕДЕНИЯ:|DETAILS:
sum_send1|Что отправить: этот архив целиком (Z3TEST-...zip) — в Telegram-бот @z3novo_bot («Проблема» или «Всё работает») или на GitHub: Issues → New issue.|What to send: this whole archive (Z3TEST-...zip), to the Telegram bot @z3novo_bot ("Problem" or "Everything works") or on GitHub: Issues → New issue.
sum_send2|Напишите версию Z3NOVO (в заголовке меню BIOS) и что было необычного. Есть ошибки — приложите и отчёт из BIOS: Del → F11.|Say which Z3NOVO version (in the BIOS menu title) and anything unusual. With errors, attach the BIOS report as well: Del, then F11.
sum_send3|Перед отправкой можно просмотреть файлы: имена, адреса и серийные номера замазаны (<host>, <user>, <serial>...).|You may look through the files before sending: names, addresses and serial numbers are masked (<host>, <user>, <serial>...).
sum_files|Файлы в архиве|Files in the archive
fl_summary|SUMMARY.txt: этот итог|SUMMARY.txt: this result
fl_report|report-os.txt: отчёт z3report (система, сбои за 30 дней)|report-os.txt: the z3report report (system, crashes over 30 days)
fl_snapshot|snapshot.txt: память, линки PCIe, диски, Secure Boot, TPM, активация, питание|snapshot.txt: memory, PCIe links, drives, Secure Boot, TPM, activation, power
fl_progress|progress.txt: все шаги по времени|progress.txt: every step by time
fl_sleep|sleep.txt: каждый сон и записи Windows о нём|sleep.txt: each sleep with the Windows records about it
fl_load|load.txt: нагрузка, проверки памяти и вычислений|load.txt: the load and the memory and CPU checks
fl_reboots|reboots.txt: каждая перезагрузка|reboots.txt: each restart
fl_events|events.txt: события Windows за время проверки|events.txt: Windows events during the test
fl_dumps|dumps.txt: аварийные дампы за время проверки (только имена)|dumps.txt: crash dumps written during the test (names only)
fl_devices|devices-start.txt, devices-end.txt: устройства в начале и в конце|devices-start.txt, devices-end.txt: devices at the start and the end
fl_changes|changes-undone.txt: временные изменения и их откат|changes-undone.txt: the temporary changes and how they were undone
fl_state|state.txt: служебная запись шагов проверки|state.txt: the test's own record of its steps
'@

# ================================================================ z3test: native helpers (compiled only when used)

$PwrCode = @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

// Sleep, the power capabilities and "keep the system awake". Nothing here touches hardware: these are Windows calls.
public static class Z3Pwr {
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
    [DllImport("powrprof.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.I1)]
    static extern bool SetSuspendState([MarshalAs(UnmanagedType.I1)] bool hibernate, [MarshalAs(UnmanagedType.I1)] bool forceCritical,
                                       [MarshalAs(UnmanagedType.I1)] bool disableWakeEvent);
    [DllImport("powrprof.dll")]
    static extern uint CallNtPowerInformation(int level, IntPtr input, uint inputLength, [Out] byte[] output, uint outputLength);
    [DllImport("kernel32.dll")]
    static extern uint SetThreadExecutionState(uint flags);
    [DllImport("kernel32.dll")]
    static extern bool IsSystemResumeAutomatic();

    // Turns on one privilege for this process only. Returns "" or the reason it failed.
    static string Privilege(string name) {
        IntPtr tok;
        if (!OpenProcessToken(GetCurrentProcess(), 0x28 /* TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY */, out tok))
            return "OpenProcessToken: " + new Win32Exception(Marshal.GetLastWin32Error()).Message;
        try {
            TokPriv1 tp = new TokPriv1();
            tp.Count = 1;
            tp.Attr = 2; // SE_PRIVILEGE_ENABLED
            if (!LookupPrivilegeValueW(null, name, out tp.Luid))
                return "LookupPrivilegeValue: " + new Win32Exception(Marshal.GetLastWin32Error()).Message;
            if (!AdjustTokenPrivileges(tok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero))
                return "AdjustTokenPrivileges: " + new Win32Exception(Marshal.GetLastWin32Error()).Message;
            if (Marshal.GetLastWin32Error() == 1300) return name + " is not held";
            return "";
        } finally {
            CloseHandle(tok);
        }
    }

    // Sleep (S3), never hibernation. Returns "" once the computer is back, or why it did not go to sleep.
    public static string Sleep() {
        string p = Privilege("SeShutdownPrivilege");
        if (p.Length > 0) return p;
        if (SetSuspendState(false, false, false)) return "";
        return "SetSuspendState: " + new Win32Exception(Marshal.GetLastWin32Error()).Message;
    }

    // SYSTEM_POWER_CAPABILITIES as raw bytes (76), or null. Offsets: 5 S3, 6 S4, 19 WakeAlarmPresent, 20 AoAc
    // (modern standby), 64 RtcWake (deepest state the clock can wake from: 4 = S3).
    public static byte[] Caps() {
        byte[] b = new byte[76];
        uint st = CallNtPowerInformation(4 /* SystemPowerCapabilities */, IntPtr.Zero, 0, b, (uint)b.Length);
        return st == 0 ? b : null;
    }

    // ES_CONTINUOUS | ES_SYSTEM_REQUIRED while the test runs (no idle sleep, the screen may go dark), ES_CONTINUOUS to end it.
    public static void KeepAwake(bool on) {
        SetThreadExecutionState(on ? 0x80000001u : 0x80000000u);
    }

    // After a wake by a timer nobody is at the computer: Windows starts its unattended idle timer (2 min by default) and
    // goes back to sleep when it runs out "unless an application has called SetThreadExecutionState" since the wake. A
    // request made before the sleep does not count (seen 18.11: Kernel-Power 42 "System Idle" 2.5 min after a timer wake,
    // in the middle of the load, with the request of this script still listed by powercfg /requests). So the request is
    // made anew right after every wake, and Tick() repeats the plain "system required" from the heartbeat.
    public static void StayAwake() {
        SetThreadExecutionState(0x80000000u);
        SetThreadExecutionState(0x80000001u);
        SetThreadExecutionState(0x00000001u);
    }
    public static void Tick() {
        SetThreadExecutionState(0x00000001u);
    }
    // True after a wake with nobody at the computer (the unattended idle timer runs).
    public static bool Unattended() {
        return IsSystemResumeAutomatic();
    }
}
'@

$LoadCode = @'
using System;
using System.Collections.Generic;
using System.Threading;

// Load on every logical CPU: each thread owns a slice of memory, writes a pattern over all of it and reads it back,
// pattern after pattern, and between patterns repeats a fixed floating point and integer calculation whose result must
// come out exactly the same every time. A wrong word in memory is a memory error; a different result is a CPU error.
public static class Z3Load {
    static volatile bool s_stop;
    static Thread[] s_threads;
    static long s_memErrors, s_cpuErrors, s_passes, s_bytes, s_bursts, s_allocated;
    static readonly object s_lock = new object();
    static readonly List<string> s_notes = new List<string>();
    static int s_noted;

    public static long MemErrors { get { return Interlocked.Read(ref s_memErrors); } }
    public static long CpuErrors { get { return Interlocked.Read(ref s_cpuErrors); } }
    public static long Passes { get { return Interlocked.Read(ref s_passes); } }
    public static long BytesChecked { get { return Interlocked.Read(ref s_bytes); } }
    public static long Bursts { get { return Interlocked.Read(ref s_bursts); } }
    public static long Allocated { get { return Interlocked.Read(ref s_allocated); } }

    static readonly string[] Names = { "zeros", "ones", "checker", "walking-one", "address", "random", "random-inverse" };

    static void Note(string s) {
        lock (s_lock) {
            if (s_noted < 60) { s_notes.Add(s); s_noted++; }
        }
    }
    public static string[] TakeNotes() {
        lock (s_lock) {
            string[] a = s_notes.ToArray();
            s_notes.Clear();
            return a;
        }
    }

    public static void Start(int threads, long bytesPerThread) {
        s_stop = false;
        s_memErrors = 0; s_cpuErrors = 0; s_passes = 0; s_bytes = 0; s_bursts = 0; s_allocated = 0; s_noted = 0;
        lock (s_lock) { s_notes.Clear(); }
        s_threads = new Thread[threads];
        for (int i = 0; i < threads; i++) {
            int id = i;
            Thread t = new Thread(delegate () { Worker(id, bytesPerThread); });
            t.IsBackground = true;
            t.Priority = ThreadPriority.BelowNormal;
            s_threads[i] = t;
        }
        foreach (Thread t in s_threads) t.Start();
    }

    public static void Stop() {
        s_stop = true;
        if (s_threads != null)
            foreach (Thread t in s_threads) t.Join(60000);
        s_threads = null;
        GC.Collect();
    }

    static ulong Mix(ulong x) {
        unchecked {
            x ^= x >> 33; x *= 0xff51afd7ed558ccdUL;
            x ^= x >> 33; x *= 0xc4ceb9fe1a85ec53UL;
            x ^= x >> 33;
            return x;
        }
    }

    static ulong Word(int p, long i, ulong seed, int pass) {
        unchecked {
            switch (p) {
                case 0: return 0UL;
                case 1: return ~0UL;
                case 2: return ((i + pass) & 1) == 0 ? 0x5555555555555555UL : 0xAAAAAAAAAAAAAAAAUL;
                case 3: return 1UL << (int)((i + pass) & 63);
                case 4: return (ulong)i * 0x9E3779B97F4A7C15UL ^ seed;
                case 5: return Mix((ulong)i ^ seed ^ ((ulong)pass << 40));
                default: return ~Mix((ulong)i ^ seed ^ ((ulong)pass << 40));
            }
        }
    }

    // A fixed calculation, about a quarter of a second: square roots, divisions and a 64-bit hash.
    static double Compute(int id) {
        unchecked {
            double a = 1.0 + id * 1e-3, b = 0.5, s = 0;
            ulong h = 1469598103934665603UL;
            for (int k = 1; k <= 6000000; k++) {
                a = a * 1.0000001 + 1e-9;
                b = Math.Sqrt(a * b + k);
                s += b / (a + k);
                h = (h ^ (ulong)k) * 1099511628211UL;
            }
            return s + (double)(h & 0xFFFFF);
        }
    }

    static void Worker(int id, long bytes) {
        List<ulong[]> chunks = new List<ulong[]>();
        long want = bytes / 8;
        const int Chunk = 16 * 1024 * 1024; // ulongs: 128 MB per array
        try {
            while (want > 0 && !s_stop) {
                int n = (int)Math.Min(want, (long)Chunk);
                chunks.Add(new ulong[n]);
                Interlocked.Add(ref s_allocated, (long)n * 8);
                want -= n;
            }
        } catch (OutOfMemoryException) {
            Note("thread " + id + ": out of memory, kept " + (chunks.Count * 128) + " MB or less");
        }
        ulong seed = unchecked(0x9E3779B97F4A7C15UL * (ulong)(id + 1));
        double golden = Compute(id);
        int pass = 0;
        while (!s_stop) {
            for (int p = 0; p < Names.Length && !s_stop; p++) {
                long baseIndex = 0;
                foreach (ulong[] c in chunks) {
                    for (int k = 0; k < c.Length; k++) c[k] = Word(p, baseIndex + k, seed, pass);
                    baseIndex += c.Length;
                    if (s_stop) break;
                }
                baseIndex = 0;
                foreach (ulong[] c in chunks) {
                    if (s_stop) break;
                    for (int k = 0; k < c.Length; k++) {
                        ulong w = Word(p, baseIndex + k, seed, pass);
                        if (c[k] != w) {
                            Interlocked.Increment(ref s_memErrors);
                            Note("MEMORY ERROR thread " + id + " pattern " + Names[p] + " pass " + pass + " word 0x" +
                                 (baseIndex + k).ToString("x") + ": want " + w.ToString("x16") + " got " + c[k].ToString("x16") +
                                 " xor " + (w ^ c[k]).ToString("x16"));
                            c[k] = w;
                        }
                    }
                    Interlocked.Add(ref s_bytes, (long)c.Length * 8);
                    baseIndex += c.Length;
                }
                Interlocked.Increment(ref s_passes);
                if (s_stop) break;
                double r = Compute(id);
                Interlocked.Increment(ref s_bursts);
                if (r != golden) {
                    Interlocked.Increment(ref s_cpuErrors);
                    Note("CPU ERROR thread " + id + ": the fixed calculation gave " + r.ToString("R") + ", first time " + golden.ToString("R"));
                }
            }
            pass++;
        }
        chunks.Clear();
    }
}
'@

# ================================================================ z3test: base

$TestVersion = '1.1'
$TaskPath = '\Z3NOVO\'
$Root = Join-Path $env:ProgramData 'Z3TEST'
$LockFile = Join-Path $Root 'lock'
$CurrentFile = Join-Path $Root 'current.txt'
$CleanupFile = Join-Path $Root 'cleanup.txt'   # what outlives a run: the logon task that shows the result
$Utf8NoBom = New-Object Text.UTF8Encoding $false
$Utf8Bom = New-Object Text.UTF8Encoding $true
$Fixed = [string][char]2   # marks a line of fixed text: it is not masked (only collected values are)
$Bound = @{}
foreach ($k in $PSBoundParameters.Keys) { $Bound[$k] = $PSBoundParameters[$k] }

$script:RunDir = $null
$script:State = @{}
$script:Lock = $null
$script:Handoff = $false       # a restart is on its way: nothing may be undone on the way out
$script:StopNow = $false
$script:Interactive = $false
$script:Phase = 'start'
$script:BeatWall = 0
$script:BeatTicks = 0
$script:BeatGapMax = 0
$script:TokensBuilt = $false
$script:Sw = [Diagnostics.Stopwatch]::StartNew()

# Texts of this script: the same "key|Russian|English" lines and the same repair as $TextData of z3report.ps1.
function Add-Texts([string]$data) {
    $chk = @($data -split "`n" | Where-Object { $_ -like '_check|*' })
    $ok = $false
    if ($chk.Count -gt 0) { $ok = (($chk[0].TrimEnd("`r") -split '\|')[1]).Length -eq 8 }
    if (-not $ok) {
        try { $data = [Text.Encoding]::UTF8.GetString([Text.Encoding]::Default.GetBytes($data)) } catch { }
    }
    foreach ($line in ($data -split "`n")) {
        $p = $line.TrimEnd("`r").Split([char[]]@('|'), 3)
        if ($p.Count -eq 3) { $Texts[$p[0]] = @($p[1], $p[2]) }
    }
}
Add-Texts $TestTextData

function FR([string]$k) { return [string]::Format($Inv, (TR $k), [object[]]$args) }
function FE([string]$k) { return [string]::Format($Inv, (TE $k), [object[]]$args) }

function Now-Epoch { return [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }
function Ep-Local([long]$e) {
    if ($e -le 0) { return '?' }
    return [DateTimeOffset]::FromUnixTimeSeconds($e).ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss', $Inv)
}
function Ep-Time([long]$e) {
    if ($e -le 0) { return '?' }
    return [DateTimeOffset]::FromUnixTimeSeconds($e).ToLocalTime().ToString('HH:mm:ss', $Inv)
}
function Ep-Date([long]$e) { return [DateTimeOffset]::FromUnixTimeSeconds($e).LocalDateTime }
function Date-Ep($d) {
    if ($null -eq $d) { return [long]0 }
    return ([DateTimeOffset]([datetime]$d)).ToUnixTimeSeconds()
}
function Dur([long]$s) {
    if ($s -lt 0) { $s = 0 }
    if ($s -ge 3600) { return (F '{0}h {1:00}m' ([Math]::Floor($s / 3600)) ([Math]::Floor(($s % 3600) / 60))) }
    if ($s -ge 60) { return (F '{0}m {1:00}s' ([Math]::Floor($s / 60)) ($s % 60)) }
    return (F '{0}s' $s)
}

# A duration as a text token for Verdict ("@@dur_s:45", "@@dur_min:7.5"): the unit in the language of the line.
function DurTok([long]$s) {
    if ($s -lt 0) { $s = 0 }
    if ($s -lt 120) { return ('@@dur_s:' + $s) }
    return ('@@dur_min:' + (F '{0:0.#}' ($s / 60.0)))
}

function DurLang([long]$s, [int]$Lang) {
    $tok = (DurTok $s).Substring(2).Split([char[]]@(':'), 2)
    $fmt = TR $tok[0]
    if ($Lang -eq 1) { $fmt = TE $tok[0] }
    return [string]::Format($Inv, $fmt, [object[]]@($tok[1]))
}

function RunFile([string]$n) { return (Join-Path $script:RunDir $n) }
function Add-Line([string]$Path, [string]$Line) {
    try { [IO.File]::AppendAllText($Path, $Line + "`r`n", $Utf8NoBom) } catch { }
}
function Log([string]$File, [string]$Text) {
    if (-not $script:RunDir) { return }
    Add-Line (RunFile $File) ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss', $Inv) + '  ' + $Text)
}
# Progress: on the screen (Russian, then English) and in progress.txt (English).
function Say([string]$k) {
    $ru = [string]::Format($Inv, (TR $k), [object[]]$args)
    $en = [string]::Format($Inv, (TE $k), [object[]]$args)
    if ($script:Interactive) {
        Write-Host ((Get-Date).ToString('HH:mm:ss', $Inv) + '  ' + $ru)
        Write-Host ('          ' + $en) -ForegroundColor DarkGray
    }
    Log 'progress.txt' ('[' + $script:Phase + '] ' + $en)
}
function SayPlain([string]$k) {
    if (-not $script:Interactive) { return }
    Write-Host ([string]::Format($Inv, (TR $k), [object[]]$args))
    Write-Host ([string]::Format($Inv, (TE $k), [object[]]$args)) -ForegroundColor DarkGray
}
# One line of the result: OK, WARN (a note), ERR (an error), SKIP (left out), INFO. The values put into the texts are
# collected data, so they are masked here; the texts themselves are fixed.
# An argument "@@key" or "@@key:value" is one of these texts itself, in the language of the line.
function Verdict([string]$Level, [string]$k) {
    $vr = @()
    $ve = @()
    foreach ($a in $args) {
        $s = [string]$a
        if ($s.StartsWith('@@', [StringComparison]::Ordinal)) {
            $p = $s.Substring(2).Split([char[]]@(':'), 2)
            $x = @()
            if ($p.Count -gt 1) { $x = @($p[1]) }
            $vr += [string]::Format($Inv, (TR $p[0]), [object[]]$x)
            $ve += [string]::Format($Inv, (TE $p[0]), [object[]]$x)
        } else {
            $m = Mask $s
            $vr += $m
            $ve += $m
        }
    }
    $ru = [string]::Format($Inv, (TR $k), [object[]]$vr).Replace('|', '/')
    $en = [string]::Format($Inv, (TE $k), [object[]]$ve).Replace('|', '/')
    if ($script:RunDir) { Add-Line (RunFile 'verdicts.txt') ($Level + '|' + $ru + '|' + $en) }
    Log 'progress.txt' ('[' + $script:Phase + '] ' + $Level + ': ' + $en)
    if ($script:Interactive -and $Level -ne 'OK' -and $Level -ne 'INFO') {
        $c = 'Yellow'
        if ($Level -eq 'ERR') { $c = 'Red' }
        Write-Host ('          ' + $Level + ': ' + $ru) -ForegroundColor $c
    }
}

# ---------------------------------------------------------------- state of a run (C:\ProgramData\Z3TEST\run-*)

function Save-State {
    $f = RunFile 'state.txt'
    $tmp = $f + '.new'
    $lines = @($script:State.Keys | Sort-Object | ForEach-Object { $_ + '=' + ([string]$script:State[$_]).Replace("`r", ' ').Replace("`n", ' ') })
    [IO.File]::WriteAllLines($tmp, [string[]]$lines, $Utf8NoBom)
    if (-not (Test-Path -LiteralPath $f)) { [IO.File]::Move($tmp, $f); return }
    try { [IO.File]::Replace($tmp, $f, $null) } catch { [IO.File]::Copy($tmp, $f, $true); Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}
function Load-State([string]$dir) {
    $s = @{}
    $f = Join-Path $dir 'state.txt'
    if (-not (Test-Path -LiteralPath $f)) { $f = $f + '.new' }
    if (Test-Path -LiteralPath $f) {
        foreach ($l in [IO.File]::ReadAllLines($f)) {
            $i = $l.IndexOf('=')
            if ($i -gt 0) { $s[$l.Substring(0, $i)] = $l.Substring($i + 1) }
        }
    }
    return $s
}
function StateNum([string]$k) {
    $v = [long]0
    [void][long]::TryParse([string]$script:State[$k], [ref]$v)
    return $v
}
function SetS([string]$k, $v) { $script:State[$k] = [string]$v; Save-State }

# Heartbeat: heartbeat.txt holds the last moment this script was alive (and on which step), so after a hang and a reset the
# next start can tell when it stopped. -Gaps: a pause of over a minute between two beats (the system stopped answering for
# a while and went on) is written down.
function Beat([string]$Detail, [switch]$Gaps) {
    $now = Now-Epoch
    $ticks = $script:Sw.Elapsed.TotalSeconds
    if ($Gaps -and $script:BeatTicks -gt 0) {
        $gap = $ticks - $script:BeatTicks
        if ($gap -gt 60) {
            Log 'progress.txt' (F '[{0}] STALL: no beat for {1:0} s (until {2})' $script:Phase $gap (Ep-Time $now))
            $n = (StateNum 'stalls') + 1
            $script:State['stalls'] = $n
            if ($gap -gt (StateNum 'stall_max')) { $script:State['stall_max'] = [long]$gap; $script:State['stall_at'] = $now; $script:State['stall_phase'] = $script:Phase }
            Save-State
        }
    }
    $script:BeatTicks = $ticks
    if ($now - $script:BeatWall -ge 10 -and $script:RunDir) {
        $script:BeatWall = $now
        try { [IO.File]::WriteAllText((RunFile 'heartbeat.txt'), (F '{0}|{1}|{2}' $now $script:Phase $Detail), $Utf8NoBom) } catch { }
        try { [Z3Pwr]::Tick() } catch { }   # keeps resetting the idle timers, the unattended one too (see Z3Pwr.StayAwake)
    }
}
function Reset-Beat { $script:BeatTicks = 0; $script:BeatWall = 0 }

function Test-StopRequested {
    if ($script:StopNow) { return $true }
    if ($script:Interactive) {
        try {
            while ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq [ConsoleKey]::C -and ($k.Modifiers -band [ConsoleModifiers]::Control)) { $script:StopNow = $true }
            }
        } catch { }
    }
    if ($script:RunDir -and (Test-Path -LiteralPath (RunFile 'STOP'))) { $script:StopNow = $true }
    $d = [string]$script:State['desktop']
    if ($d) {
        foreach ($n in @('Z3TEST-STOP', 'Z3TEST-STOP.txt')) {
            if (Test-Path -LiteralPath (Join-Path $d $n)) { $script:StopNow = $true }
        }
    }
    if ($script:StopNow) { Log 'progress.txt' ('[' + $script:Phase + '] stop requested') }
    return $script:StopNow
}
# Waits, beating and watching for a stop. $false: a stop was asked for.
function Wait-Step([int]$Seconds, [string]$Detail, [switch]$Gaps) {
    $end = $script:Sw.Elapsed.TotalSeconds + $Seconds
    while ($script:Sw.Elapsed.TotalSeconds -lt $end) {
        if (Test-StopRequested) { return $false }
        Start-Sleep -Milliseconds 1000
        Beat $Detail -Gaps:$Gaps
    }
    return $true
}

# ---------------------------------------------------------------- the change journal: everything the test changes

function Record-Change([string]$Line) { Add-Line (RunFile 'changes.txt') $Line }

function Remove-Z3Task([string]$Name) {
    $t = $null
    try { $t = Get-ScheduledTask -TaskPath $TaskPath -TaskName $Name -ErrorAction Stop } catch { }
    if ($t) { Unregister-ScheduledTask -TaskPath $TaskPath -TaskName $Name -Confirm:$false -ErrorAction Stop }
}
function Remove-Z3TaskFolder {
    try {
        $svc = New-Object -ComObject 'Schedule.Service'
        $svc.Connect()
        $top = $svc.GetFolder('\')
        $f = $null
        try { $f = $top.GetFolder('Z3NOVO') } catch { return }
        if ($f.GetTasks(1).Count -eq 0 -and $f.GetFolders(0).Count -eq 0) { $top.DeleteFolder('Z3NOVO', 0) }
    } catch { }
}

# Undo what the journal of a run lists, newest first. Every undo can be repeated safely. -Only: only lines starting with
# one of these kinds ("power", "task|Z3TEST-wake"); -Except: all but these. What is not undone stays for later.
function Undo-Changes([string]$Dir, [string[]]$Only, [string[]]$Except) {
    $f = Join-Path $Dir 'changes.txt'
    if (-not (Test-Path -LiteralPath $f)) { return }
    $all = @([IO.File]::ReadAllLines($f) | Where-Object { $_ -ne '' })
    $keep = New-Object 'System.Collections.Generic.List[string]'
    $undo = New-Object 'System.Collections.Generic.List[string]'
    foreach ($l in $all) {
        $sel = $true
        if ($Only) {
            $sel = $false
            foreach ($o in $Only) { if ($l -eq $o -or $l.StartsWith($o + '|')) { $sel = $true } }
        }
        if ($Except) { foreach ($o in $Except) { if ($l -eq $o -or $l.StartsWith($o + '|')) { $sel = $false } } }
        if ($sel) { $undo.Add($l) } else { $keep.Add($l) }
    }
    $done = Join-Path $Dir 'changes-undone.txt'
    for ($i = $undo.Count - 1; $i -ge 0; $i--) {
        $l = $undo[$i]
        $p = $l.Split([char[]]@('|'))
        $res = 'undone'
        try {
            switch ($p[0]) {
                'task' { Remove-Z3Task $p[1] }
                'power' {
                    # power|SCHEME|SUBGROUP|SETTING|ac|OLD (OLD as 0x........)
                    $old = [Convert]::ToInt32($p[5], 16)
                    [void](Invoke-Exe 'powercfg.exe' ('/setacvalueindex ' + $p[1] + ' ' + $p[2] + ' ' + $p[3] + ' ' + $old) 30)
                    if ((Get-ActiveScheme) -eq $p[1]) { [void](Invoke-Exe 'powercfg.exe' ('/setactive ' + $p[1]) 30) }
                }
                'taskfolder' { Remove-Z3TaskFolder }
                default { $res = 'unknown, left as it is' }
            }
        } catch { $res = 'FAILED: ' + (ErrText $_) }
        Add-Line $done ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss', $Inv) + '  ' + $l + '  -> ' + $res)
    }
    if ($keep.Count -gt 0) { [IO.File]::WriteAllLines($f, [string[]]$keep.ToArray(), $Utf8NoBom) } else { Remove-Item -LiteralPath $f -Force }
}

# Tasks left from earlier runs that outlive them (the logon task that shows a result).
function Clear-Leftovers {
    if (Test-Path -LiteralPath $CleanupFile) {
        foreach ($l in [IO.File]::ReadAllLines($CleanupFile)) {
            $p = $l.Split([char[]]@('|'))
            if ($p[0] -eq 'task' -and $p.Count -gt 1) { try { Remove-Z3Task $p[1] } catch { } }
        }
        Remove-Item -LiteralPath $CleanupFile -Force -ErrorAction SilentlyContinue
    }
    Remove-Z3TaskFolder
}

# ---------------------------------------------------------------- the folder and the lock

# C:\ProgramData\Z3TEST belongs to administrators and SYSTEM only: the startup task runs a copy of this script from there
# as SYSTEM, so nobody else may be able to put anything in it.
function Prepare-Root {
    if (-not (Test-Path -LiteralPath $Root)) { [void](New-Item -ItemType Directory -Path $Root -Force) }
    $ic = Join-Path $env:SystemRoot 'System32\icacls.exe'
    [void](Invoke-Exe $ic ('"' + $Root + '" /setowner *S-1-5-32-544 /T /C /Q') 120)
    # The folder itself only (no /T): on files, /inheritance:r with these (OI)(CI) grants leaves an EMPTY access list, so
    # the lock, current.txt and the old run became unreadable even for administrators and every later start, -Stop or
    # -Resume failed (seen on the board 18.11). What is inside inherits from the folder: /reset drops anything else.
    [void](Invoke-Exe $ic ('"' + $Root + '" /inheritance:r /grant:r *S-1-5-32-544:(OI)(CI)F *S-1-5-18:(OI)(CI)F /C /Q') 120)
    [void](Invoke-Exe $ic ('"' + (Join-Path $Root '*') + '" /reset /T /C /Q') 120)
    $acl = Get-Acl -LiteralPath $Root
    $owner = $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value
    $me = ''
    try { $me = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value } catch { }
    if ($owner -ne 'S-1-5-32-544' -and $owner -ne 'S-1-5-18' -and $owner -ne $me) { throw ('the folder ' + $Root + ' belongs to ' + $owner + ', not to the administrators') }
    foreach ($r in $acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier])) {
        $sid = $r.IdentityReference.Value
        if ($sid -ne 'S-1-5-32-544' -and $sid -ne 'S-1-5-18' -and $r.AccessControlType -eq 'Allow') {
            throw ('the folder ' + $Root + ' is also open to ' + $sid)
        }
    }
}
function Get-Lock {
    try {
        if (-not (Test-Path -LiteralPath $Root)) { return $true }
        $script:Lock = [IO.File]::Open($LockFile, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        return $true
    } catch { return $false }
}
function Release-Lock {
    if ($script:Lock) { try { $script:Lock.Dispose() } catch { } }
    $script:Lock = $null
}
function Current-Run {
    if (-not (Test-Path -LiteralPath $CurrentFile)) { return $null }
    $d = ([IO.File]::ReadAllText($CurrentFile)).Trim()
    if ($d -and (Test-Path -LiteralPath (Join-Path $d 'state.txt'))) { return $d }
    if ($d -and (Test-Path -LiteralPath (Join-Path $d 'state.txt.new'))) { return $d }
    return $null
}

# ---------------------------------------------------------------- power settings (read through powercfg, changed only as recorded)

function Get-ActiveScheme {
    $t = Invoke-Exe 'powercfg.exe' '/getactivescheme' 30
    if ($t -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { return $Matches[1].ToLowerInvariant() }
    return ''
}
# The AC and DC values of one setting: the last two 0x........ numbers powercfg prints (the rest of its text is in the
# language of Windows). Returns @{ ac = '0x...'; dc = '0x...' } or $null.
function Get-PowerValue([string]$Scheme, [string]$Sub, [string]$Setting) {
    $t = Invoke-Exe 'powercfg.exe' ('/q ' + $Scheme + ' ' + $Sub + ' ' + $Setting) 30
    $m = @([regex]::Matches($t, '0x[0-9a-fA-F]{8}') | ForEach-Object { $_.Value.ToLowerInvariant() })
    if ($m.Count -lt 2) { return $null }
    return @{ ac = $m[$m.Count - 2]; dc = $m[$m.Count - 1] }
}

function Get-PowerCaps {
    $r = @{ ok = $false; S3 = $false; S4 = $false; AoAc = $false; WakeAlarm = $false; RtcWake = 0 }
    try {
        Use-Type 'Z3Pwr' $PwrCode
        $b = [Z3Pwr]::Caps()
        if ($b) {
            $r.ok = $true
            $r.S3 = $b[5] -ne 0
            $r.S4 = $b[6] -ne 0
            $r.WakeAlarm = $b[19] -ne 0
            $r.AoAc = $b[20] -ne 0
            $r.RtcWake = [BitConverter]::ToInt32($b, 64)
        }
    } catch { $r['err'] = ErrText $_ }
    return $r
}
function StateName($v) {
    switch ([int]$v) { 1 { return 'S0' } 2 { return 'S1' } 3 { return 'S2' } 4 { return 'S3' } 5 { return 'S4 (hibernate)' } 6 { return 'S5 (off)' } }
    return ('code ' + $v)
}

# BitLocker on the Windows drive: on, and with a protector that asks for something at power-on (PIN, startup key,
# password)? Only the kinds of protectors are read, never their ids or keys.
function Get-BitLockerBlock {
    $r = @{ known = $false; on = $false; block = ''; text = '' }
    try {
        $vol = Get-CimInstance -Namespace 'root\cimv2\Security\MicrosoftVolumeEncryption' -ClassName 'Win32_EncryptableVolume' -Filter ("DriveLetter='" + $env:SystemDrive + "'") -ErrorAction Stop
        if (-not $vol) { $r.text = 'no BitLocker volume for ' + $env:SystemDrive; $r.known = $true; return $r }
        $r.on = ([int]$vol.ProtectionStatus -eq 1)
        # Kinds that ask for something at power-on; 1 TPM and 3 recovery password do not.
        $asks = @{ 2 = 'startup key'; 4 = 'TPM and PIN'; 5 = 'TPM and startup key'; 6 = 'TPM, PIN and startup key'; 8 = 'password' }
        $quiet = @{ 1 = 'TPM'; 3 = 'recovery password' }
        $found = @()
        foreach ($k in @(1, 2, 3, 4, 5, 6, 8)) {
            $g = Invoke-CimMethod -InputObject $vol -MethodName 'GetKeyProtectors' -Arguments @{ KeyProtectorType = [uint32]$k } -ErrorAction Stop
            $n = @($g.VolumeKeyProtectorID | Where-Object { $_ }).Count
            if ($n -gt 0) {
                if ($asks.ContainsKey($k)) {
                    $found += $asks[$k]
                    if ($r.on) { $r.block = $asks[$k] }
                } else { $found += $quiet[$k] }
            }
        }
        $r.known = $true
        $st = 'off'
        if ($r.on) { $st = 'on' }
        $r.text = F '{0}, protectors: {1}' $st (($found -join ', '))
    } catch { $r.text = 'not readable: ' + (ErrText $_) }
    return $r
}

# ---------------------------------------------------------------- devices: what is present, for "lost after sleep or restart"

$DevPrefixes = @('PCI\', 'USB\', 'USB4\', 'SCSI\', 'NVME\', 'HDAUDIO\', 'DISPLAY\', 'STORAGE\', 'BTH\')
function Get-DevList {
    $h = @{}
    foreach ($d in @(Q 'Win32_PnPEntity' @('Name', 'PNPDeviceID', 'PNPClass', 'ConfigManagerErrorCode'))) {
        $id = [string]$d.PNPDeviceID
        if (-not $id) { continue }
        $u = $id.ToUpperInvariant()
        $ok = $false
        foreach ($p in $DevPrefixes) { if ($u.StartsWith($p)) { $ok = $true; break } }
        if (-not $ok) { continue }
        $h[$u] = [pscustomobject]@{ Id = $id; Name = [string]$d.Name; Class = [string]$d.PNPClass; Code = [int]$d.ConfigManagerErrorCode }
    }
    return $h
}
# devices-<tag>.raw keeps the full ids (some USB ids end in a serial number): it stays in the run folder and is never
# packed. devices-<tag>.txt, without the last part of each id, goes into the archive.
function Save-DevList($h, [string]$Tag) {
    $raw = New-Object 'System.Collections.Generic.List[string]'
    $txt = New-Object 'System.Collections.Generic.List[string]'
    foreach ($k in ($h.Keys | Sort-Object)) {
        $d = $h[$k]
        $raw.Add(($d.Id + '|' + $d.Code + '|' + $d.Class + '|' + $d.Name))
        $txt.Add((F '  {0,-12} code {1,-3} {2} | {3}' $d.Class $d.Code (HwId $d.Id) $d.Name))
    }
    [IO.File]::WriteAllLines((RunFile ('devices-' + $Tag + '.raw')), [string[]]$raw.ToArray(), $Utf8NoBom)
    [IO.File]::WriteAllLines((RunFile ('devices-' + $Tag + '.txt')), [string[]]$txt.ToArray(), $Utf8NoBom)
}
function Load-DevList([string]$Tag) {
    $h = @{}
    $f = RunFile ('devices-' + $Tag + '.raw')
    if (-not (Test-Path -LiteralPath $f)) { return $null }
    foreach ($l in [IO.File]::ReadAllLines($f)) {
        $p = $l.Split([char[]]@('|'), 4)
        if ($p.Count -lt 4) { continue }
        $h[$p[0].ToUpperInvariant()] = [pscustomobject]@{ Id = $p[0]; Code = [int]$p[1]; Class = $p[2]; Name = $p[3] }
    }
    return $h
}
# Compared with the start: @{ missing = names; broken = names (a problem code now, none at the start); added = count }.
function Compare-Dev($base, $now) {
    $r = @{ missing = @(); broken = @(); added = 0 }
    if (-not $base -or -not $now) { return $r }
    foreach ($k in $base.Keys) {
        $b = $base[$k]
        if (-not $now.ContainsKey($k)) { $r.missing += ($b.Name + ' [' + (HwId $b.Id) + ']'); continue }
        $n = $now[$k]
        if ($b.Code -eq 0 -and $n.Code -ne 0) { $r.broken += (F '{0} [{1}] code {2}: {3}' $n.Name (HwId $n.Id) $n.Code $CmText[$n.Code]) }
    }
    foreach ($k in $now.Keys) { if (-not $base.ContainsKey($k)) { $r.added++ } }
    return $r
}

# PCIe links of every PCI device that has one: @{ ID = @{ cs; cw; ms; mw } } (speed codes 1..5 = 2.5..32 GT/s).
$LinkGuid = '{3ab22e31-8264-4b4e-9af5-a8d2d8e33e62}'
function Get-Links {
    $res = @{}
    if (-not (Get-Command Get-PnpDeviceProperty -ErrorAction SilentlyContinue)) { throw 'Get-PnpDeviceProperty is not available' }
    $ids = @(Q 'Win32_PnPEntity' @('PNPDeviceID') | ForEach-Object { [string]$_.PNPDeviceID } | Where-Object { $_ -like 'PCI\*' })
    if ($ids.Count -eq 0) { return $res }
    $names = @('DEVPKEY_PciDevice_CurrentLinkSpeed', 'DEVPKEY_PciDevice_CurrentLinkWidth', 'DEVPKEY_PciDevice_MaxLinkSpeed', 'DEVPKEY_PciDevice_MaxLinkWidth')
    $props = $null
    try { $props = @(Get-PnpDeviceProperty -InstanceId $ids -KeyName $names -ErrorAction Stop) } catch { $props = $null }
    if ($null -eq $props) { $props = @(Get-PnpDeviceProperty -InstanceId $ids -ErrorAction SilentlyContinue) }
    foreach ($p in $props) {
        $k = [string]$p.KeyName
        $w = ''
        if ($k -like '*CurrentLinkSpeed' -or $k -eq ($LinkGuid + ' 9')) { $w = 'cs' }
        elseif ($k -like '*CurrentLinkWidth' -or $k -eq ($LinkGuid + ' 10')) { $w = 'cw' }
        elseif ($k -like '*MaxLinkSpeed' -or $k -eq ($LinkGuid + ' 11')) { $w = 'ms' }
        elseif ($k -like '*MaxLinkWidth' -or $k -eq ($LinkGuid + ' 12')) { $w = 'mw' }
        if (-not $w -or $null -eq $p.Data) { continue }
        $id = ([string]$p.InstanceId).ToUpperInvariant()
        if (-not $res.ContainsKey($id)) { $res[$id] = @{ cs = 0; cw = 0; ms = 0; mw = 0; id = [string]$p.InstanceId } }
        $res[$id][$w] = [int]$p.Data
    }
    return $res
}
function SpeedText($c) {
    switch ([int]$c) { 1 { return '2.5 GT/s' } 2 { return '5 GT/s' } 3 { return '8 GT/s' } 4 { return '16 GT/s' } 5 { return '32 GT/s' } }
    return '?'
}
function Save-Links($l, [string]$Tag) {
    $raw = New-Object 'System.Collections.Generic.List[string]'
    foreach ($k in ($l.Keys | Sort-Object)) { $x = $l[$k]; $raw.Add((F '{0}|{1}|{2}|{3}|{4}' $x.id $x.cs $x.cw $x.ms $x.mw)) }
    [IO.File]::WriteAllLines((RunFile ('links-' + $Tag + '.raw')), [string[]]$raw.ToArray(), $Utf8NoBom)
}
function Load-Links([string]$Tag) {
    $h = @{}
    $f = RunFile ('links-' + $Tag + '.raw')
    if (-not (Test-Path -LiteralPath $f)) { return $null }
    foreach ($l in [IO.File]::ReadAllLines($f)) {
        $p = $l.Split([char[]]@('|'))
        if ($p.Count -ge 5) { $h[$p[0].ToUpperInvariant()] = @{ id = $p[0]; cs = [int]$p[1]; cw = [int]$p[2]; ms = [int]$p[3]; mw = [int]$p[4] } }
    }
    return $h
}
# Links that got narrower than at the start (the speed changes by itself with power saving; the width should not).
function Compare-Links($base, $now, $names) {
    $out = @()
    if (-not $base -or -not $now) { return $out }
    foreach ($k in $base.Keys) {
        if (-not $now.ContainsKey($k)) { continue }
        $b = $base[$k]; $n = $now[$k]
        if ($b.cw -gt 0 -and $n.cw -gt 0 -and $n.cw -lt $b.cw) {
            $nm = ''
            if ($names -and $names.ContainsKey($k)) { $nm = $names[$k].Name }
            $out += (F '{0} [{1}] x{2} -> x{3}' $nm (HwId $b.id) $b.cw $n.cw)
        }
    }
    return $out
}
# After a sleep or a restart: the devices and the links against the start, as verdicts. $What: "sleep 2" and so on.
function Check-Devices([string]$What, [string]$Level) {
    $now = $null
    try { $now = Get-DevList } catch { Log 'progress.txt' ('device list failed: ' + (ErrText $_)); return }
    $base = Load-DevList 'start'
    $c = Compare-Dev $base $now
    if ($c.missing.Count -gt 0) { Verdict 'ERR' 'v_dev_missing' $What ($c.missing -join '; ') }
    if ($c.broken.Count -gt 0) { Verdict $Level 'v_dev_broken' $What ($c.broken -join '; ') }
    $links = $null
    try { $links = Get-Links } catch { }
    if ($links) {
        $nl = Compare-Links (Load-Links 'start') $links $now
        if ($nl.Count -gt 0) { Verdict 'WARN' 'v_link_narrow' $What ($nl -join '; ') }
    }
    Log 'progress.txt' (F '[{0}] devices after {1}: missing {2}, new problems {3}, new devices {4}' $script:Phase $What $c.missing.Count $c.broken.Count $c.added)
}

# ---------------------------------------------------------------- events

# Events of one log since an epoch time, oldest first. Providers are filtered here, not in the query (a provider name
# the system does not know would make the whole query fail).
function Get-EvSince([string]$Log, [long]$From, [int[]]$Ids, [string[]]$Providers, [int]$MaxLevel) {
    $h = @{ LogName = $Log; StartTime = (Ep-Date $From) }
    if ($Ids) { $h['Id'] = $Ids }
    $ev = @()
    try {
        $ev = @(Get-WinEvent -FilterHashtable $h -ErrorAction Stop)
    } catch {
        if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { return , @() }
        throw
    }
    if ($Providers) { $ev = @($ev | Where-Object { $Providers -contains $_.ProviderName }) }
    if ($MaxLevel -gt 0) { $ev = @($ev | Where-Object { $_.Level -ge 1 -and $_.Level -le $MaxLevel }) }
    $ev = @($ev | Sort-Object TimeCreated, RecordId)
    return , $ev
}
function EvLines($e, [int]$MaxLines) {
    $out = @('    ' + (EvHead $e) + '  level ' + $e.Level)
    foreach ($l in (EvText $e $MaxLines)) { $out += ($Mark + '        ' + $l.Trim()) }
    return $out
}
function EvAll($e) {
    $d = Ev-Data $e
    return (($d.Keys | Sort-Object | ForEach-Object { $_ + '=' + $d[$_] }) -join '; ')
}
function Get-BootEpoch {
    $os = Q 'Win32_OperatingSystem' @('LastBootUpTime')
    $d = ToDate $os.LastBootUpTime
    if (-not $d) { return [long]0 }
    return (Date-Ep $d)
}

# ================================================================ z3test: the snapshot

# The whole z3report.ps1 report, the same steps and the same summary, into one file of the run folder. The lines are
# written as collected and masked when the archive is made, like everything else.
function Invoke-Report([string]$Path) {
    $Lines.Clear()
    $Facts.Clear()
    $script:StepNo = 0
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
    $created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz', $Inv)
    $all = New-Object 'System.Collections.Generic.List[string]'
    foreach ($l in @(((TE 'title') + ' / ' + (TR 'title')), ('script z3report.ps1 ' + $Version + ' (Windows), inside z3test.ps1 ' + $TestVersion + ' | created ' + $created + ' | run as ' + $RunAs),
            (TR 'collected'), (TR 'excluded'), (TE 'collected'), (TE 'excluded'), (TR 'masks'))) { $all.Add($Fixed + $l) }
    foreach ($l in $summary) { $all.Add($l) }
    foreach ($l in $Lines) { $all.Add($l) }
    foreach ($l in @('', ('=== [end] ' + (Tx 'sec_end')), ('  ' + (TR 'end_check')), ('  ' + (TE 'end_check')))) { $all.Add($Fixed + $l) }
    [IO.File]::WriteAllLines($Path, [string[]]$all.ToArray(), $Utf8NoBom)
    foreach ($k in @('bios', 'board', 'cpu', 'memory', 'gpu', 'os', 'faststartup', 'z3chip')) { $script:State['f_' + $k] = FactOr $k '?' }
    Save-State
}
function FactOr([string]$k, [string]$def) { $v = $Facts[$k]; if ($null -eq $v -or "$v" -eq '') { return $def }; return [string]$v }

# Extra sections, in the z3report layout, into snapshot.txt.
function Write-Extras([string]$Path) {
    $Lines.Clear()
    $script:StepNo = 0
    $script:StepTotal = 7
    Step 'memory_set' 'sec_x_mem' { Ex-Memory }
    Step 'pcie' 'sec_x_pcie' { Ex-Pcie }
    Step 'nvme' 'sec_x_nvme' { Ex-Nvme }
    Step 'security' 'sec_x_sec' { Ex-Security }
    Step 'activation' 'sec_x_act' { Ex-Activation }
    Step 'power' 'sec_x_power' { Ex-Power }
    Step 'bitlocker' 'sec_x_bl' { Ex-BitLocker }
    $script:StepTotal = 18
    $all = New-Object 'System.Collections.Generic.List[string]'
    $all.Add($Fixed + (Tx 'snap_title') + ', z3test.ps1 ' + $TestVersion)
    foreach ($l in $Lines) { $all.Add($l) }
    [IO.File]::WriteAllLines($Path, [string[]]$all.ToArray(), $Utf8NoBom)
    $Lines.Clear()
}

function Ex-Memory {
    $cs = Q 'Win32_ComputerSystem' @('TotalPhysicalMemory')
    $mods = @(Q 'Win32_PhysicalMemory' @('DeviceLocator', 'BankLabel', 'Capacity', 'Speed', 'ConfiguredClockSpeed', 'Manufacturer', 'PartNumber'))
    Note 'Speed: "rated" is what the module says it can do (SMBIOS Speed); "set" is what the firmware runs it at (Configured Memory Speed).'
    $sum = 0.0
    $set = @{}
    foreach ($m in $mods) {
        $sum += [double]$m.Capacity
        KV ([string]$m.DeviceLocator + ' / ' + [string]$m.BankLabel) (F '{0}, rated {1} MT/s, set {2} MT/s, {3} {4}' (GiB $m.Capacity) $m.Speed $m.ConfiguredClockSpeed `
                ([string]$m.Manufacturer).Trim() ([string]$m.PartNumber).Trim())
        if ($m.ConfiguredClockSpeed) { $set[[string]$m.ConfiguredClockSpeed] = 1 }
    }
    $seen = [double]$cs.TotalPhysicalMemory
    $gfx = 0.0
    try {
        Use-Type 'Z3Dxgi' $DxgiCode
        foreach ($a in [Z3Dxgi]::List()) {
            $p = $a.Split([char[]]@('|'))
            if (([int64]$p[6] -band 2) -eq 0 -and [double]$p[3] -gt $gfx) { $gfx = [double]$p[3] }
        }
    } catch { }
    # Without the vendor's video driver (Microsoft Basic Display Adapter) DXGI gives no graphics memory: unknown, not 0.
    $rest = $sum - $seen - $gfx
    KV 'Installed (SMBIOS)' (F '{0} in {1} module(s)' (GiB $sum) $mods.Count)
    KV 'Seen by Windows' (GiB $seen)
    if ($gfx -gt 0) {
        KV 'Graphics memory (largest DXGI dedicated)' (GiB $gfx)
        KV 'Not accounted for' (F '{0} (the firmware keeps some for itself, usually under 1 GB)' (GiB $rest))
    } else {
        KV 'Graphics memory (largest DXGI dedicated)' (Tx 'x_gfx_unknown')
        KV 'Not accounted for' (Tx 'x_rest_unknown')
    }
    $speeds = @($set.Keys | Sort-Object)
    $script:State['f_mem_set'] = ($speeds -join ', ')
    if ($mods.Count -eq 0) { Verdict 'WARN' 'v_mem_nomods'; return }
    $gfxText = '@@gfx_unknown'
    if ($gfx -gt 0) { $gfxText = GiB $gfx }
    Verdict 'INFO' 'v_mem_info' (GiB $sum) $mods.Count (GiB $seen) ($speeds -join '/') $gfxText
    if ($speeds.Count -gt 1) { Verdict 'WARN' 'v_mem_mixed' ($speeds -join ', ') }
    if ($sum -gt 0 -and $gfx -gt 0 -and $rest -gt 1.5GB) { Verdict 'WARN' 'v_mem_missing' (GiB $sum) (GiB $seen) (GiB $gfx) }
}

function Ex-Pcie {
    $names = Get-DevList
    $links = Get-Links
    Save-Links $links 'start'
    Note 'now: the link as it runs; max: what the device itself can do. The slot can be narrower than the device (with a Ryzen with graphics the graphics slot is x8), and many devices lower the speed at idle to save power.'
    foreach ($k in ($links.Keys | Sort-Object)) {
        $x = $links[$k]
        $nm = ''
        $cls = ''
        if ($names.ContainsKey($k)) { $nm = $names[$k].Name; $cls = $names[$k].Class }
        $flag = ''
        if ($x.cw -gt 0 -and $x.mw -gt 0 -and $x.cw -lt $x.mw) { $flag += ', narrower than the device can' }
        if ($x.cs -gt 0 -and $x.ms -gt 0 -and $x.cs -lt $x.ms) { $flag += ', slower than the device can' }
        W (F '  {0} | {1} | now {2} x{3} | max {4} x{5}{6}' $nm (HwId $x.id) (SpeedText $x.cs) $x.cw (SpeedText $x.ms) $x.mw $flag)
        if (($cls -eq 'Display' -or $cls -eq 'SCSIAdapter' -or $cls -eq 'Net' -or $cls -eq 'HDC') -and $x.cw -gt 0) {
            Verdict 'INFO' 'v_link' $nm (SpeedText $x.cs) $x.cw (SpeedText $x.ms) $x.mw
        }
    }
    if ($links.Count -eq 0) { Note (Tx 'no_data') }
}

function Ex-Nvme {
    $n = 0
    foreach ($p in @(Get-PhysicalDisk -ErrorAction Stop)) {
        $bus = [string]$p.BusType
        if ($bus -eq '17') { $bus = 'NVMe' }
        KV ([string]$p.FriendlyName) (F 'bus {0}, firmware {1}, {2}, health {3}, {4}' $bus $p.FirmwareVersion (GiB $p.Size) $p.HealthStatus $p.MediaType)
        if ($bus -eq 'NVMe') {
            $n++
            Verdict 'INFO' 'v_nvme' ([string]$p.FriendlyName) ([string]$p.FirmwareVersion)
        }
        try {
            $rc = Get-StorageReliabilityCounter -PhysicalDisk $p -ErrorAction Stop
            KV '  reliability' (F 'temperature {0} C (max {1}), wear {2} %, power-on hours {3}, read errors {4} (uncorrected {5}), write errors {6} (uncorrected {7})' `
                    $rc.Temperature $rc.TemperatureMax $rc.Wear $rc.PowerOnHours $rc.ReadErrorsTotal $rc.ReadErrorsUncorrected $rc.WriteErrorsTotal $rc.WriteErrorsUncorrected)
        } catch { KV '  reliability' ((Tx 'no_data') + ': ' + (ErrText $_)) }
    }
    if ($n -eq 0) { Note (Tx 'no_nvme') }
}

function Ex-Security {
    $sb = '?'
    try {
        $c = Confirm-SecureBootUEFI -ErrorAction Stop
        if ($c) { $sb = 'on' } else { $sb = 'off' }
        KV 'Secure Boot (Confirm-SecureBootUEFI)' $sb
    } catch { KV 'Secure Boot (Confirm-SecureBootUEFI)' ('not available: ' + (ErrText $_)) }
    $setup = '?'
    if ($FwType -eq 2 -and $IsAdmin) {
        try {
            Use-Type 'Z3Fw' $FwCode
            $perr = [Z3Fw]::EnablePrivilege()
            if ($perr) { throw $perr }
            $g = '8be4df61-93ca-11d2-aa0d-00e098032b8c'
            $db = 'd719b2cb-3d3a-4596-a3bc-dad00e67656f'
            Note 'UEFI variables, read only (the key lists only by their size):'
            foreach ($v in @(@('SecureBoot', $g), @('SetupMode', $g), @('AuditMode', $g), @('DeployedMode', $g), @('PK', $g), @('KEK', $g), @('db', $db), @('dbx', $db))) {
                $attr = [uint32]0
                $err = ''
                $d = [Z3Fw]::Read($v[0], $v[1], [ref]$attr, [ref]$err)
                if ($null -eq $d) { KV ('  ' + $v[0]) $err }
                elseif ($d.Length -eq 1) {
                    KV ('  ' + $v[0]) (F 'value {0}' $d[0])
                    if ($v[0] -eq 'SetupMode') { $setup = [string]$d[0] }
                }
                else { KV ('  ' + $v[0]) (F 'present, {0} bytes' $d.Length) }
            }
        } catch { Note ('UEFI variables: ' + (Tx 'failed') + ': ' + (ErrText $_)) }
    }
    Verdict 'INFO' 'v_sb' $sb $setup
    $tpm = '?'
    try {
        $t = Get-Tpm -ErrorAction Stop
        KV 'TPM present / ready / enabled / activated / owned' (F '{0} / {1} / {2} / {3} / {4}' $t.TpmPresent $t.TpmReady $t.TpmEnabled $t.TpmActivated $t.TpmOwned)
        KV 'TPM maker, version' (F '{0}, {1}' $t.ManufacturerIdTxt $t.ManufacturerVersion)
        KV 'TPM locked out' $t.LockedOut
        $tpm = F 'present {0}, ready {1}, {2} {3}' $t.TpmPresent $t.TpmReady $t.ManufacturerIdTxt $t.ManufacturerVersion
    } catch { KV 'Get-Tpm' ((Tx 'failed') + ': ' + (ErrText $_)) }
    try {
        foreach ($w in @(Q 'Win32_Tpm' @('SpecVersion', 'ManufacturerVersionInfo', 'PhysicalPresenceVersionInfo', 'IsEnabled_InitialValue', 'IsActivated_InitialValue') '' 'root\cimv2\Security\MicrosoftTpm')) {
            KV 'TPM spec version' $w.SpecVersion
            KV 'TPM physical presence version' $w.PhysicalPresenceVersionInfo
            $tpm = $tpm + ', spec ' + (([string]$w.SpecVersion).Split(',')[0])
        }
    } catch { KV 'Win32_Tpm' ((Tx 'failed') + ': ' + (ErrText $_)) }
    Verdict 'INFO' 'v_tpm' $tpm
}

function Ex-Activation {
    Note 'Only the status, the product name and the licence channel are read; never the product key or its last characters.'
    $st = @{ 0 = 'unlicensed'; 1 = 'licensed (activated)'; 2 = 'out-of-box grace'; 3 = 'out-of-tolerance grace (hardware changed)'; 4 = 'non-genuine grace';
        5 = 'notification (not activated)'; 6 = 'extended grace' }
    $p = @(Get-CimInstance -ClassName 'SoftwareLicensingProduct' -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" `
            -Property @('Name', 'Description', 'LicenseStatus', 'GracePeriodRemaining') -OperationTimeoutSec 180 -ErrorAction Stop)
    if ($p.Count -eq 0) { Note (Tx 'no_data'); Verdict 'WARN' 'v_act_none'; return }
    foreach ($x in $p) {
        $s = $st[[int]$x.LicenseStatus]
        if (-not $s) { $s = 'code ' + $x.LicenseStatus }
        KV 'Product' $x.Name
        KV 'Channel' $x.Description
        KV 'Status' $s
        KV 'Grace minutes left' $x.GracePeriodRemaining
        $ch = ''
        if ([string]$x.Description -match '([A-Z_]+) channel') { $ch = $Matches[1] }
        if ([int]$x.LicenseStatus -eq 1) { Verdict 'INFO' 'v_act_ok' $ch }
        else { Verdict 'WARN' 'v_act_not' $s $ch }
    }
}

function Ex-Power {
    $c = Get-PowerCaps
    if ($c.ok) {
        KV 'S3 sleep / S4 hibernate' (F '{0} / {1}' $c.S3 $c.S4)
        KV 'Modern standby (S0 low power idle)' $c.AoAc
        KV 'Wake alarm / RTC wakes from' (F '{0} / {1}' $c.WakeAlarm (StateName $c.RtcWake))
    } else { KV 'Power capabilities' ((Tx 'failed') + ': ' + $c.err) }
    $sch = Get-ActiveScheme
    KV 'Active power plan' $sch
    if ($sch) {
        foreach ($s in @('STANDBYIDLE', 'HYBRIDSLEEP', 'HIBERNATEIDLE', 'RTCWAKE')) {
            $v = Get-PowerValue $sch 'SUB_SLEEP' $s
            if ($v) { KV ('  ' + $s) (F 'AC {0}, DC {1}' $v.ac $v.dc) }
        }
    }
    KV 'Fast Startup (HiberbootEnabled)' (RegVal 'SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled')
    KV 'Last firmware POST time (FwPOSTTime, ms)' (RegVal 'SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'FwPOSTTime')
    Note 'powercfg /a:'
    try {
        foreach ($l in ((Invoke-Exe 'powercfg.exe' '/a' 30) -split "`r?`n")) { if ($l.Trim()) { W ('    ' + $l.TrimEnd()) } }
    } catch { Note ((Tx 'failed') + ': ' + (ErrText $_)) }
}

function Ex-BitLocker {
    $b = Get-BitLockerBlock
    KV ('BitLocker on ' + $env:SystemDrive) $b.text
}

function Phase-Snapshot {
    Say 'ph_snapshot'
    Invoke-Report (RunFile 'report-os.txt')
    Write-Extras (RunFile 'snapshot.txt')
    try { Save-DevList (Get-DevList) 'start' } catch { Log 'progress.txt' ('device list failed: ' + (ErrText $_)) }
    return 'next'
}

# ================================================================ z3test: sleep

$PsExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

# The wake task: once, at the given time, with "wake the computer to run this task"; it only runs cmd /c exit.
function Register-WakeTask([datetime]$At) {
    $act = New-ScheduledTaskAction -Execute (Join-Path $env:SystemRoot 'System32\cmd.exe') -Argument '/c exit 0'
    $trg = New-ScheduledTaskTrigger -Once -At $At
    $set = New-ScheduledTaskSettingsSet -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
    $pr = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    [void](Register-ScheduledTask -TaskPath $TaskPath -TaskName 'Z3TEST-wake' -Action $act -Trigger $trg -Settings $set -Principal $pr -Force -ErrorAction Stop)
}

# "Allow wake timers" of the active plan on AC must be "Enable" (1): "Important wake timers only" (2) skips a task's timer.
function Enable-WakeTimers {
    $sch = Get-ActiveScheme
    if (-not $sch) { throw 'no active power plan' }
    $v = Get-PowerValue $sch 'SUB_SLEEP' 'RTCWAKE'
    if (-not $v) { throw 'the setting "Allow wake timers" is not readable' }
    Log 'sleep.txt' ('power plan ' + $sch + ', Allow wake timers: AC ' + $v.ac + ', DC ' + $v.dc)
    if ($v.ac -ne '0x00000001') {
        Record-Change ('power|' + $sch + '|SUB_SLEEP|RTCWAKE|ac|' + $v.ac)
        [void](Invoke-Exe 'powercfg.exe' ('/setacvalueindex ' + $sch + ' SUB_SLEEP RTCWAKE 1') 30)
        [void](Invoke-Exe 'powercfg.exe' ('/setactive ' + $sch) 30)
        Log 'sleep.txt' 'Allow wake timers (AC) set to 1 for the test; it goes back at the end'
    }
}

function Phase-Sleep {
    $n = StateNum 'sleep_total'
    $secs = StateNum 'sleep_secs'
    if ($n -le 0) { Verdict 'SKIP' 'v_sleep_skipped'; return 'next' }
    $caps = Get-PowerCaps
    if ($caps.ok -and $caps.AoAc) { Verdict 'SKIP' 'v_sleep_aoac'; return 'next' }
    if ($caps.ok -and -not $caps.S3) { Verdict 'WARN' 'v_sleep_nos3'; return 'next' }
    if ($caps.ok -and $caps.RtcWake -lt 4) { Verdict 'WARN' 'v_sleep_rtc' (StateName $caps.RtcWake) }
    try { Use-Type 'Z3Pwr' $PwrCode } catch { Verdict 'WARN' 'v_sleep_setup' (ErrText $_); return 'next' }
    if ((StateNum 'sleep_done') -eq 0) {
        try {
            Record-Change 'taskfolder'
            Record-Change 'task|Z3TEST-wake'
            Enable-WakeTimers
        } catch {
            Verdict 'WARN' 'v_sleep_setup' (ErrText $_)
            return 'next'
        }
    }
    if ((StateNum 'sleep_ph_from') -eq 0) { SetS 'sleep_ph_from' (Now-Epoch) }
    for ($i = (StateNum 'sleep_done') + 1; $i -le $n; $i++) {
        if (Test-StopRequested) { return 'stop' }
        $before = $null
        try { $before = Get-DevList } catch { }
        $at = (Get-Date).AddSeconds($secs + 8)
        try { Register-WakeTask $at } catch { Verdict 'WARN' 'v_sleep_setup' (ErrText $_); return 'next' }
        $script:State['sleep_i'] = $i
        $script:State['sleep_entered'] = Now-Epoch
        Save-State
        Say 'sleep_go' $i $n $secs
        if (-not (Wait-Step 6 ('sleep ' + $i))) { Remove-Z3Task 'Z3TEST-wake'; return 'stop' }
        Log 'sleep.txt' (F '=== sleep {0} of {1}: wake task at {2}' $i $n $at.ToString('HH:mm:ss', $Inv))
        $t0 = Now-Epoch
        $w0 = $script:Sw.Elapsed.TotalSeconds
        $err = [Z3Pwr]::Sleep()
        try { [Z3Pwr]::StayAwake() } catch { Log 'sleep.txt' ('StayAwake: ' + (ErrText $_)) }
        $w1 = $script:Sw.Elapsed.TotalSeconds
        $t1 = Now-Epoch
        Reset-Beat
        $ua = '?'
        try { $ua = [string][Z3Pwr]::Unattended() } catch { }
        Log 'sleep.txt' (F 'woke with nobody at the computer (IsSystemResumeAutomatic): {0}; the script asked again to keep the system awake; stopwatch {1:0} s, clock {2} s' $ua ($w1 - $w0) ($t1 - $t0))
        $dt = $t1 - $t0
        Say 'sleep_back' $i $dt
        Log 'sleep.txt' (F 'asleep and back: {0} s (from {1} to {2}){3}' $dt (Ep-Time $t0) (Ep-Time $t1) $(if ($err) { '; ' + $err } else { '' }))
        if (-not (Wait-Step 25 ('after sleep ' + $i))) { $script:StopNow = $true }
        Remove-Z3Task 'Z3TEST-wake'
        try {
            $rq = @((Invoke-Exe 'powercfg.exe' '/requests' 30) -split "`r?`n" | Where-Object { $_.Trim() })
            Log 'sleep.txt' ('powercfg /requests 25 s after the wake: ' + ($rq -join ' | '))
        } catch { }
        # What Windows wrote about this sleep.
        $ev = @()
        try { $ev = Get-EvSince 'System' ($t0 - 15) $null @('Microsoft-Windows-Kernel-Power', 'Microsoft-Windows-Power-Troubleshooter') 0 } catch { Log 'sleep.txt' ('events: ' + (ErrText $_)) }
        $k42 = @($ev | Where-Object { $_.ProviderName -eq 'Microsoft-Windows-Kernel-Power' -and $_.Id -eq 42 })
        $k107 = @($ev | Where-Object { $_.ProviderName -eq 'Microsoft-Windows-Kernel-Power' -and $_.Id -eq 107 })
        $pt = @($ev | Where-Object { $_.ProviderName -eq 'Microsoft-Windows-Power-Troubleshooter' -and $_.Id -eq 1 })
        foreach ($e in $ev) {
            foreach ($l in (EvLines $e 8)) { Add-Line (RunFile 'sleep.txt') $l }
            Add-Line (RunFile 'sleep.txt') ($Mark + '        data: ' + (EvAll $e))
        }
        $byTimer = $false
        $src = ''
        $bios = ''
        $state = ''
        if ($pt.Count -gt 0) {
            $d = Ev-Data $pt[$pt.Count - 1]
            foreach ($v in $d.Values) { if ([string]$v -match 'Z3TEST') { $byTimer = $true } }
            $src = [string]$d['WakeSourceText']
            if (-not $src) { $src = 'type ' + [string]$d['WakeSourceType'] }
            $bios = [string]$d['BiosInitDuration']
            # TargetState / EffectiveState: 4 sleep (S3), 5 hibernation; only hibernation in place of sleep is reported.
            if ([string]$d['EffectiveState'] -eq '5') { $state = StateName 5 }
            if ($bios) {
                $script:State['sleep_bios_ms'] = ([string]$script:State['sleep_bios_ms'] + ' ' + $bios).Trim()
            }
        }
        $script:State['sleep_secs_list'] = ([string]$script:State['sleep_secs_list'] + ' ' + $dt).Trim()
        $ok = $true
        if ($err) {
            Verdict 'ERR' 'v_sleep_fail' $i $err
            $ok = $false
        } elseif ($k42.Count -eq 0 -and $pt.Count -eq 0 -and $dt -lt 10) {
            Verdict 'ERR' 'v_sleep_notasleep' $i $dt
            $ok = $false
        } else {
            if ($state) { Verdict 'WARN' 'v_sleep_state' $i $state }
            if ($byTimer) {
                if ($dt -gt $secs + 120) { Verdict 'WARN' 'v_sleep_slow' $i $dt; $ok = $false }
            } elseif ($dt -lt $secs - 20) {
                Verdict 'WARN' 'v_sleep_early' $i $dt $src
                $ok = $false
            } elseif ($dt -gt $secs + 90) {
                Verdict 'WARN' 'v_sleep_late' $i (DurTok $dt) $src
                $ok = $false
            } elseif ($pt.Count -eq 0) {
                Log 'sleep.txt' 'no Power-Troubleshooter event: the wake source is unknown'
            }
        }
        if ($before) {
            $now = $null
            try { $now = Get-DevList } catch { }
            if ($now) {
                $c = Compare-Dev $before $now
                if ($c.missing.Count -gt 0) { Verdict 'ERR' 'v_dev_missing' ('@@w_sleep:' + $i) ($c.missing -join '; '); $ok = $false }
                if ($c.broken.Count -gt 0) { Verdict 'WARN' 'v_dev_broken' ('@@w_sleep:' + $i) ($c.broken -join '; '); $ok = $false }
            }
        }
        if ($ok) { $script:State['sleep_ok'] = (StateNum 'sleep_ok') + 1 }
        $script:State['sleep_done'] = $i
        Save-State
        if ($script:StopNow) { break }
        if ($i -lt $n -and -not (Wait-Step 5 'between sleeps')) { break }
    }
    SetS 'sleep_ph_to' (Now-Epoch)
    Undo-Changes $script:RunDir @('power', 'task|Z3TEST-wake')
    try {
        $l = Get-Links
        $nl = Compare-Links (Load-Links 'start') $l (Get-DevList)
        if ($nl.Count -gt 0) { Verdict 'WARN' 'v_link_narrow' '@@w_sleeps' ($nl -join '; ') }
    } catch { }
    $done = StateNum 'sleep_done'
    $okn = StateNum 'sleep_ok'
    if ($done -gt 0 -and $okn -eq $done) { Verdict 'OK' 'v_sleep_ok' $okn $done }
    $b = @(([string]$script:State['sleep_bios_ms']).Split(' ') | Where-Object { $_ -match '^\d+$' -and [long]$_ -gt 0 } | ForEach-Object { [double]$_ })
    if ($b.Count -gt 0) { Verdict 'INFO' 'v_sleep_fw' (F '{0:0}' (($b | Measure-Object -Average).Average)) }
    if ($script:StopNow) { return 'stop' }
    return 'next'
}

# ================================================================ z3test: load and idle

function Phase-Load {
    $min = StateNum 'load_min'
    if ($min -le 0) { Verdict 'SKIP' 'v_load_skipped'; return 'next' }
    try { Use-Type 'Z3Load' $LoadCode } catch { Verdict 'WARN' 'v_load_fail' (ErrText $_); return 'next' }
    $threads = [Environment]::ProcessorCount
    $os = Q 'Win32_OperatingSystem' @('FreePhysicalMemory', 'TotalVisibleMemorySize')
    $free = [double]$os.FreePhysicalMemory * 1KB
    $total = $free * 0.7
    if (-not [Environment]::Is64BitProcess) { $total = [Math]::Min($total, 1.2GB) }
    $per = [long]([Math]::Floor($total / $threads / 1MB)) * 1MB
    if ($per -lt 16MB) { $per = 16MB }
    Say 'load_go' $min $threads ([Math]::Round($per * $threads / 1GB, 1))
    $script:State['load_started'] = Now-Epoch
    Save-State
    Log 'load.txt' (F 'threads {0}, {1} MB each, free memory at the start {2}' $threads ($per / 1MB) (GiB $free))
    [Z3Load]::Start($threads, $per)
    $stopped = $false
    try {
        Reset-Beat
        $t0 = $script:Sw.Elapsed.TotalSeconds
        $nextLog = 60
        while (($script:Sw.Elapsed.TotalSeconds - $t0) -lt $min * 60) {
            if (-not (Wait-Step 5 ('load ' + [Math]::Floor(($script:Sw.Elapsed.TotalSeconds - $t0) / 60) + ' min') -Gaps)) { $stopped = $true; break }
            foreach ($l in [Z3Load]::TakeNotes()) { Log 'load.txt' $l }
            $el = $script:Sw.Elapsed.TotalSeconds - $t0
            if ($el -ge $nextLog) {
                $nextLog += 60
                $msg = F 'minute {0:0}: allocated {1:0.0} GB, checked {2:0.0} GB, pattern passes {3}, calculations {4}, memory errors {5}, CPU errors {6}' `
                    ($el / 60) ([Z3Load]::Allocated / 1GB) ([Z3Load]::BytesChecked / 1GB) ([Z3Load]::Passes) ([Z3Load]::Bursts) ([Z3Load]::MemErrors) ([Z3Load]::CpuErrors)
                Log 'load.txt' $msg
                if ($script:Interactive) { Write-Host ('          ' + $msg) -ForegroundColor DarkGray }
            }
        }
    } finally {
        [Z3Load]::Stop()
    }
    foreach ($l in [Z3Load]::TakeNotes()) { Log 'load.txt' $l }
    $me = [Z3Load]::MemErrors
    $ce = [Z3Load]::CpuErrors
    $gb = [Z3Load]::BytesChecked / 1GB
    $mins = [Math]::Round(((Now-Epoch) - (StateNum 'load_started')) / 60.0, 1)
    Log 'load.txt' (F 'end: {0} min, allocated {1:0.0} GB, checked {2:0.0} GB, passes {3}, calculations {4}, memory errors {5}, CPU errors {6}' `
            $mins ([Z3Load]::Allocated / 1GB) $gb ([Z3Load]::Passes) ([Z3Load]::Bursts) $me $ce)
    if ($me -gt 0) { Verdict 'ERR' 'v_load_mem' $me }
    if ($ce -gt 0) { Verdict 'ERR' 'v_load_cpu' $ce }
    if ($me -eq 0 -and $ce -eq 0) { Verdict 'OK' 'v_load_ok' $mins $threads (F '{0:0.0}' ([Z3Load]::Allocated / 1GB)) (F '{0:0}' $gb) }
    if ($stopped) { return 'stop' }
    return 'next'
}

function Phase-Idle {
    $min = StateNum 'idle_min'
    if ($min -le 0) { Verdict 'SKIP' 'v_idle_skipped'; return 'next' }
    Say 'idle_go' $min
    $script:State['idle_started'] = Now-Epoch
    Save-State
    Reset-Beat
    $t0 = $script:Sw.Elapsed.TotalSeconds
    while (($script:Sw.Elapsed.TotalSeconds - $t0) -lt $min * 60) {
        if (-not (Wait-Step 10 ('idle ' + [Math]::Floor(($script:Sw.Elapsed.TotalSeconds - $t0) / 60) + ' min') -Gaps)) { return 'stop' }
    }
    Verdict 'OK' 'v_idle_ok' $min
    return 'next'
}

# ================================================================ z3test: restarts

# The startup task: at every start of Windows, as SYSTEM, the copy of this script in the run folder with -Resume.
function Register-ResumeTask {
    $copy = Join-Path $script:RunDir 'z3test.ps1'
    $act = New-ScheduledTaskAction -Execute $PsExe -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $copy + '" -Resume')
    $trg = New-ScheduledTaskTrigger -AtStartup
    $trg.Delay = 'PT30S'
    $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 8) -MultipleInstances IgnoreNew
    $pr = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    Record-Change 'taskfolder'
    Record-Change 'task|Z3TEST-resume'
    [void](Register-ScheduledTask -TaskPath $TaskPath -TaskName 'Z3TEST-resume' -Action $act -Trigger $trg -Settings $set -Principal $pr -Force -ErrorAction Stop)
}

function Phase-Reboot {
    $n = StateNum 'reboot_total'
    if ($n -le 0) { Verdict 'SKIP' 'v_reboot_skipped'; return 'next' }
    if ($script:State['reboot_block']) { Verdict 'SKIP' 'v_reboot_bitlocker' $script:State['reboot_block']; return 'next' }
    $done = StateNum 'reboot_done'
    if ($done -ge $n) {
        if ((StateNum 'reboot_bad') -eq 0) {
            $avg = '?'
            $b = @(([string]$script:State['reboot_secs_list']).Split(' ') | Where-Object { $_ -match '^-?\d+$' } | ForEach-Object { [double]$_ })
            if ($b.Count -gt 0) { $avg = DurTok ([long](($b | Measure-Object -Average).Average)) }
            Verdict 'OK' 'v_reboot_ok' $done $n $avg
        }
        return 'next'
    }
    $i = $done + 1
    if ($i -eq 1) { Say 'reboot_first' $n } else { Say 'reboot_next' $i $n }
    if (-not (Wait-Step 20 ('before restart ' + $i))) { return 'stop' }
    $delay = 60
    $comment = FR 'reboot_comment' $i $n
    $script:State['reboot_i'] = $i
    $script:State['reboot_issued'] = Now-Epoch
    $script:State['reboot_delay'] = $delay
    Save-State
    $sd = Join-Path $env:SystemRoot 'System32\shutdown.exe'
    $out = ''
    try { $out = Invoke-Exe $sd ('/r /t ' + $delay + ' /d p:0:0 /c "' + $comment.Replace('"', "'") + '"') 30 } catch { $out = ErrText $_ }
    Log 'reboots.txt' (F 'restart {0} of {1}: shutdown /r /t {2} at {3} {4}' $i $n $delay (Ep-Time (StateNum 'reboot_issued')) $out.Trim())
    $script:Handoff = $true
    if (-not (Wait-Step ($delay - 5) ('restart ' + $i + ' countdown'))) {
        [void](Invoke-Exe $sd '/a' 30)
        $script:Handoff = $false
        $script:State['reboot_issued'] = 0
        Save-State
        Log 'reboots.txt' 'stop asked during the countdown: restart cancelled (shutdown /a)'
        return 'stop'
    }
    Say 'reboot_now'
    # Windows ends this process while it shuts down. Still here after ten minutes: the restart was cancelled.
    if (Wait-Step 600 ('restart ' + $i + ' under way')) {
        $script:Handoff = $false
        $script:State['reboot_issued'] = 0
        Save-State
        Verdict 'WARN' 'v_reboot_cancelled' $i
        return 'next'
    }
    [void](Invoke-Exe $sd '/a' 30)
    $script:Handoff = $false
    $script:State['reboot_issued'] = 0
    Save-State
    return 'stop'
}

# After a restart the test asked for: how it went.
function Check-Reboot {
    $i = StateNum 'reboot_i'
    $n = StateNum 'reboot_total'
    $issued = StateNum 'reboot_issued'
    $delay = StateNum 'reboot_delay'
    $boot = Get-BootEpoch
    $ev = @()
    try { $ev = Get-EvSince 'System' ($issued - 5) @(41, 6005, 6006, 6008, 1074, 12, 13) $null 0 } catch { Log 'reboots.txt' ('events: ' + (ErrText $_)) }
    $kp41 = @($ev | Where-Object { $_.ProviderName -eq 'Microsoft-Windows-Kernel-Power' -and $_.Id -eq 41 })
    $starts = @($ev | Where-Object { $_.ProviderName -eq 'EventLog' -and $_.Id -eq 6005 }).Count
    $clean = @($ev | Where-Object { ($_.ProviderName -eq 'EventLog' -and $_.Id -eq 6006) -or ($_.ProviderName -eq 'Microsoft-Windows-Kernel-General' -and $_.Id -eq 13) }).Count
    $down = $boot - ($issued + $delay)
    $fw = RegVal 'SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'FwPOSTTime'
    $script:State['reboot_secs_list'] = ([string]$script:State['reboot_secs_list'] + ' ' + $down).Trim()
    if ($fw) { $script:State['reboot_fw_ms'] = ([string]$script:State['reboot_fw_ms'] + ' ' + $fw).Trim() }
    Log 'reboots.txt' (F 'restart {0} of {1}: Windows started at {2}, {3} after the restart began; clean shutdown records {4}, starts {5}, Kernel-Power 41: {6}, firmware POST {7} ms, this script back at {8}' `
            $i $n (Ep-Time $boot) (Dur $down) $clean $starts $kp41.Count $fw (Ep-Time (Now-Epoch)))
    foreach ($e in $ev) { foreach ($l in (EvLines $e 3)) { Add-Line (RunFile 'reboots.txt') $l } }
    $bad = $false
    if ($kp41.Count -gt 0) {
        $script:State['kp41_explained'] = (StateNum 'kp41_explained') + $kp41.Count
        Verdict 'ERR' 'v_reboot_kp41' $i
        $bad = $true
    } elseif ($starts -gt 1) {
        Verdict 'WARN' 'v_reboot_starts' $i $starts
        $bad = $true
    }
    if ($down -gt 300) { Verdict 'WARN' 'v_reboot_long' $i (DurTok $down); $bad = $true }
    if ($bad) { $script:State['reboot_bad'] = (StateNum 'reboot_bad') + 1 }
    $script:State['reboot_done'] = $i
    $script:State['reboot_issued'] = 0
    Save-State
    Check-Devices ('@@w_reboot:' + $i) 'WARN'
}

# After a start nobody asked for, in the middle of a step: a hang, a blue screen, a power cut, or a person.
function Check-Unexpected {
    $ph = [string]$script:State['phase']
    $since = StateNum 'phase_started'
    $boot = Get-BootEpoch
    $beat = 0
    $beatWhat = ''
    try {
        $h = ([IO.File]::ReadAllText((RunFile 'heartbeat.txt'))).Split([char[]]@('|'), 3)
        $beat = [long]$h[0]
        $beatWhat = $h[2]
    } catch { }
    if ($ph -eq 'sleep') { $since = [Math]::Max($since, (StateNum 'sleep_entered') - 30) }
    $ev = @()
    try { $ev = Get-EvSince 'System' ($since - 5) @(41, 6005, 6006, 6008, 1001, 12, 13) $null 0 } catch { }
    $kp41 = @($ev | Where-Object { $_.ProviderName -eq 'Microsoft-Windows-Kernel-Power' -and $_.Id -eq 41 })
    $bc = ''
    $sleepIn = ''
    foreach ($e in $kp41) {
        $d = Ev-Data $e
        $c = [int64]0
        [void][int64]::TryParse([string]$d['BugcheckCode'], [ref]$c)
        if ($c -ne 0) { $bc = '0x' + $c.ToString('X') }
        if ($d['SleepInProgress'] -and [string]$d['SleepInProgress'] -ne '0') { $sleepIn = ', SleepInProgress ' + [string]$d['SleepInProgress'] }
    }
    $clean = @($ev | Where-Object { ($_.ProviderName -eq 'EventLog' -and $_.Id -eq 6006) -or ($_.ProviderName -eq 'Microsoft-Windows-Kernel-General' -and $_.Id -eq 13) }).Count
    $gap = '?'
    if ($beat -gt 0 -and $boot -gt 0) { $gap = DurTok ($boot - $beat) }
    Log 'progress.txt' (F '[{0}] started again at {1} without being asked: last beat {2} ({3}), Kernel-Power 41: {4}, bugcheck {5}, clean shutdown records {6}' `
            $ph (Ep-Local $boot) (Ep-Local $beat) $beatWhat $kp41.Count $bc $clean)
    foreach ($e in $ev) { foreach ($l in (EvLines $e 3)) { Add-Line (RunFile 'progress.txt') $l } }
    $script:State['kp41_explained'] = (StateNum 'kp41_explained') + $kp41.Count
    $script:State['unexpected'] = $ph
    $what = '@@w_ph_' + $ph
    if ($kp41.Count -gt 0 -and $ph -eq 'sleep') {
        Verdict 'ERR' 'v_unexp_sleep' (StateNum 'sleep_i') (Ep-Time (StateNum 'sleep_entered')) (Ep-Time $boot) $sleepIn
    } elseif ($kp41.Count -gt 0 -and $bc) {
        Verdict 'ERR' 'v_unexp_bsod' $what $bc (Ep-Time $beat) (Ep-Time $boot)
    } elseif ($kp41.Count -gt 0) {
        Verdict 'ERR' 'v_unexp_hang' $what (Ep-Time $beat) (Ep-Time $boot) $gap
    } else {
        Verdict 'WARN' 'v_unexp_clean' $what (Ep-Time $beat) (Ep-Time $boot)
    }
    Save-State
}

# ================================================================ z3test: the end of a run

$PowerProv = @('Microsoft-Windows-Kernel-Power', 'Microsoft-Windows-Power-Troubleshooter', 'EventLog', 'User32', 'Microsoft-Windows-Kernel-Boot',
    'Microsoft-Windows-Kernel-General', 'Microsoft-Windows-WHEA-Logger', 'Microsoft-Windows-WER-SystemErrorReporting')
$DiskProv = @('disk', 'Ntfs', 'Microsoft-Windows-Ntfs', 'volmgr', 'storahci', 'stornvme', 'Microsoft-Windows-StorPort', 'iaStorAC', 'iaStorA', 'amdsata',
    'rcraid', 'nvme', 'secnvme', 'Microsoft-Windows-Disk')
$UsbProv = @('USBHUB3', 'USBXHCI', 'usbhub', 'USBHUB', 'Microsoft-Windows-USB-USBHUB3', 'Microsoft-Windows-USB-USBXHCI', 'Microsoft-Windows-USB-USBPORT', 'usbccgp')
$GpuProv = @('Display', 'amdkmdag', 'amdkmdap', 'amdwddmg', 'nvlddmkm', 'igfx', 'igfxn')

# Every event of the test window that matters, into events.txt, and the counts as verdicts.
function Collect-Events {
    $from = (StateNum 'started') - 60
    $f = RunFile 'events.txt'
    Add-Line $f ($Fixed + (Tx 'ev_title') + ', ' + (Ep-Local $from))
    $sys = Get-EvSince 'System' $from $null $null 0
    Add-Line $f ''
    Add-Line $f ($Fixed + '=== [system] ' + (Tx 'ev_sys'))
    $cnt = @{ whea_f = 0; whea_c = 0; bsod = 0; kp41 = 0; tdr = 0; disk_e = 0; disk_w = 0; usb = 0; acpi = 0; kpp37 = 0 }
    $bsod = @()
    $diskProv = @{}
    foreach ($e in $sys) {
        $p = $e.ProviderName
        $lv = [int]$e.Level
        if (-not (($PowerProv -contains $p) -or ($lv -ge 1 -and $lv -le 3))) { continue }
        foreach ($l in (EvLines $e 6)) { Add-Line $f $l }
        if ($p -eq 'Microsoft-Windows-WHEA-Logger') {
            if (@(1, 18, 20, 46) -contains $e.Id) { $cnt.whea_f++ } elseif (@(17, 19, 47) -contains $e.Id) { $cnt.whea_c++ }
        } elseif ($p -eq 'Microsoft-Windows-WER-SystemErrorReporting' -and $e.Id -eq 1001) {
            $cnt.bsod++
            $d = Ev-Data $e
            if ($d['param1']) { $bsod += ([string]$d['param1']).Split(' ')[0] }
        } elseif ($p -eq 'Microsoft-Windows-Kernel-Power' -and $e.Id -eq 41) {
            $cnt.kp41++
        } elseif ($GpuProv -contains $p -and $lv -le 3) {
            if ($p -eq 'Display' -or $lv -le 2) { $cnt.tdr++ }
        } elseif ($DiskProv -contains $p) {
            if ($lv -le 2) { $cnt.disk_e++ } else { $cnt.disk_w++ }
            $diskProv[$p + ' ' + $e.Id] = 1
        } elseif ($UsbProv -contains $p) {
            $cnt.usb++
        } elseif ($p -eq 'ACPI' -and $lv -le 2) {
            $cnt.acpi++
        } elseif ($p -eq 'Microsoft-Windows-Kernel-Processor-Power' -and $e.Id -eq 37) {
            $cnt.kpp37++
        }
    }
    Add-Line $f ''
    Add-Line $f ($Fixed + '=== [wer] ' + (Tx 'ev_wer'))
    $live = 0
    try {
        foreach ($e in (Get-EvSince 'Application' $from @(1001) @('Windows Error Reporting') 0)) {
            $t = ($e.Message + ' ' + (EvAll $e))
            if ($t -notmatch 'LiveKernelEvent|BlueScreen') { continue }
            $live++
            foreach ($l in (EvLines $e 10)) { Add-Line $f $l }
            if ($t -match 'LiveKernelEvent' -and $t -match '\b(141|117|1a8)\b') { $cnt.tdr++ }
        }
    } catch { Add-Line $f ('  ' + (Tx 'failed') + ': ' + (ErrText $_)) }
    foreach ($lg in @(@('Microsoft-Windows-Diagnostics-Performance/Operational', 'Diagnostics-Performance: start (100), shutdown (200), standby (300) times'),
            @('Microsoft-Windows-Kernel-PnP/Configuration', 'Kernel-PnP/Configuration: devices that failed to start (errors and warnings)'))) {
        Add-Line $f ''
        Add-Line $f ($Fixed + '=== [log] ' + $lg[1])
        try {
            $ev = @(Get-EvSince $lg[0] $from $null $null 0)
            if ($lg[0] -like '*PnP*') { $ev = @($ev | Where-Object { $_.Level -ge 1 -and $_.Level -le 3 }) }
            foreach ($e in ($ev | Select-Object -Last 120)) {
                foreach ($l in (EvLines $e 4)) { Add-Line $f $l }
                if ($lg[0] -like '*Performance*') { Add-Line $f ($Mark + '        data: ' + (EvAll $e)) }
            }
            if ($ev.Count -eq 0) { Add-Line $f ('    ' + (Tx 'none')) }
        } catch { Add-Line $f ('  ' + (Tx 'failed') + ': ' + (ErrText $_)) }
    }
    # Sleeps the test did not start: Kernel-Power 42 outside the sleep step (18.11 on the board Windows went back to sleep
    # 2.5 min after a timer wake, in the middle of the load, for 49 min, and the result said nothing about it).
    try {
        $o0 = StateNum 'sleep_ph_from'
        $o1 = StateNum 'sleep_ph_to'
        $un = @()
        foreach ($e in $sys) {
            if ($e.ProviderName -ne 'Microsoft-Windows-Kernel-Power' -or $e.Id -ne 42) { continue }
            $t = Date-Ep $e.TimeCreated
            if ($t -lt (StateNum 'started') - 5) { continue }
            if ($o0 -gt 0 -and $t -ge $o0 - 5 -and ($o1 -le 0 -or $t -le $o1 + 5)) { continue }
            $un += $e
        }
        if ($un.Count -gt 0) {
            $t = Date-Ep $un[0].TimeCreated
            $ph = 'snapshot'
            foreach ($p in $PhaseOrder) { $tp = StateNum ('t_' + $p); if ($tp -gt 0 -and $t -ge $tp) { $ph = $p } }
            $dur = '?'
            $src = '?'
            $wk = @($sys | Where-Object { $_.ProviderName -eq 'Microsoft-Windows-Power-Troubleshooter' -and $_.Id -eq 1 -and (Date-Ep $_.TimeCreated) -ge $t } | Select-Object -First 1)
            if ($wk.Count -gt 0) {
                $d = Ev-Data $wk[0]
                $src = [string]$d['WakeSourceText']
                if (-not $src) {
                    # A button has no WakeSourceText: the last line of the message names it ("Wake Source: Power Button").
                    $ml = @(([string]$wk[0].Message) -split "`r?`n" | Where-Object { $_.Trim() })
                    if ($ml.Count -gt 0) { $src = ($ml[$ml.Count - 1] -replace '^[^:]*:\s*', '').Trim() }
                }
                if (-not $src) { $src = 'type ' + [string]$d['WakeSourceType'] }
                try { $dur = DurTok ([long]([DateTimeOffset]::Parse([string]$d['WakeTime'], $Inv) - [DateTimeOffset]::Parse([string]$d['SleepTime'], $Inv)).TotalSeconds) } catch { }
            }
            Verdict 'WARN' 'v_sleep_unplanned' $un.Count (Ep-Local $t) ('@@w_ph_' + $ph) $dur $src
        }
    } catch { Log 'progress.txt' ('unplanned sleeps: ' + (ErrText $_)) }
    Log 'progress.txt' (F 'event counts: WHEA fatal {0}, corrected {1}; blue screens {2}; Kernel-Power 41 {3} (explained {4}); display driver {5}; disk errors {6}, warnings {7}; USB {8}; ACPI {9}; CPU limited by firmware (37) {10}; WER kernel reports {11}' `
            $cnt.whea_f $cnt.whea_c $cnt.bsod $cnt.kp41 (StateNum 'kp41_explained') $cnt.tdr $cnt.disk_e $cnt.disk_w $cnt.usb $cnt.acpi $cnt.kpp37 $live)
    if ($cnt.whea_f -gt 0) { Verdict 'ERR' 'v_ev_whea_f' $cnt.whea_f }
    if ($cnt.whea_c -gt 0) { Verdict 'WARN' 'v_ev_whea_c' $cnt.whea_c }
    if ($cnt.bsod -gt 0) { Verdict 'ERR' 'v_ev_bsod' $cnt.bsod (($bsod | Select-Object -Unique) -join ', ') }
    if ($cnt.kp41 -gt (StateNum 'kp41_explained')) { Verdict 'ERR' 'v_ev_kp41' ($cnt.kp41 - (StateNum 'kp41_explained')) }
    if ($cnt.tdr -gt 0) { Verdict 'WARN' 'v_ev_tdr' $cnt.tdr }
    if ($cnt.disk_e -gt 0) { Verdict 'ERR' 'v_ev_disk_e' $cnt.disk_e (($diskProv.Keys | Sort-Object) -join ', ') }
    elseif ($cnt.disk_w -gt 0) { Verdict 'WARN' 'v_ev_disk_w' $cnt.disk_w (($diskProv.Keys | Sort-Object) -join ', ') }
    if ($cnt.usb -gt 0) { Verdict 'WARN' 'v_ev_usb' $cnt.usb }
    if ($cnt.acpi -gt 0) { Verdict 'WARN' 'v_ev_acpi' $cnt.acpi }
    if ($cnt.kpp37 -gt 0) { Verdict 'INFO' 'v_ev_kpp37' $cnt.kpp37 }
    if ($cnt.whea_f + $cnt.whea_c + $cnt.bsod + $cnt.tdr + $cnt.disk_e + $cnt.disk_w + $cnt.usb + $cnt.acpi -eq 0 -and $cnt.kp41 -le (StateNum 'kp41_explained')) {
        Verdict 'OK' 'v_ev_clean'
    }
}

function Collect-Dumps {
    $from = StateNum 'started'
    $f = RunFile 'dumps.txt'
    Add-Line $f ($Fixed + (Tx 'dumps_title'))
    $mini = @()
    $live = @()
    foreach ($dir in @((Join-Path $env:SystemRoot 'Minidump'), (Join-Path $env:SystemRoot 'LiveKernelReports'))) {
        Add-Line $f ($dir + ':')
        $files = @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -eq '.dmp' -and (Date-Ep $_.LastWriteTime) -ge $from } | Sort-Object LastWriteTime)
        foreach ($x in $files) {
            $rel = $x.FullName.Substring($dir.Length).TrimStart('\')
            Add-Line $f (F '    {0}  {1,12} bytes  {2}' (FmtDate $x.LastWriteTime) $x.Length $rel)
            if ($dir -like '*Minidump') { $mini += $rel } else { $live += $rel }
        }
        if ($files.Count -eq 0) { Add-Line $f ('    ' + (Tx 'none')) }
    }
    try {
        $md = Get-Item -LiteralPath (Join-Path $env:SystemRoot 'MEMORY.DMP') -Force -ErrorAction Stop
        if ((Date-Ep $md.LastWriteTime) -ge $from) { $mini += 'MEMORY.DMP'; Add-Line $f (F 'MEMORY.DMP {0} bytes, {1}' $md.Length (FmtDate $md.LastWriteTime)) }
    } catch { }
    if ($mini.Count -gt 0) { Verdict 'ERR' 'v_dump_mini' ($mini -join ', ') }
    if ($live.Count -gt 0) { Verdict 'WARN' 'v_dump_live' ($live -join ', ') }
}

# ---------------------------------------------------------------- SUMMARY.txt

function Read-Verdicts {
    $v = @()
    $f = RunFile 'verdicts.txt'
    if (Test-Path -LiteralPath $f) {
        foreach ($l in [IO.File]::ReadAllLines($f)) {
            $p = $l.Split([char[]]@('|'), 3)
            if ($p.Count -eq 3) { $v += [pscustomobject]@{ L = $p[0]; Ru = $p[1]; En = $p[2] } }
        }
    }
    return , $v
}

function Write-Summary([string]$Path) {
    $v = Read-Verdicts
    $nErr = @($v | Where-Object { $_.L -eq 'ERR' }).Count
    $nWarn = @($v | Where-Object { $_.L -eq 'WARN' }).Count
    $res = 'res_ok'
    if ($nErr -gt 0) { $res = 'res_err' } elseif ($nWarn -gt 0) { $res = 'res_warn' }
    $t0 = StateNum 'started'
    $t1 = StateNum 'finished'
    $mode = 'mode_' + [string]$script:State['mode']
    $out = New-Object 'System.Collections.Generic.List[string]'
    foreach ($lang in @(0, 1)) {
        $T = { param($k) if ($lang -eq 0) { return (TR $k) } else { return (TE $k) } }
        if ($lang -eq 1) { $out.Add(''); $out.Add('------------------------------------------------------------------------'); $out.Add('') }
        $out.Add((& $T 'sum_title'))
        $out.Add([string]::Format($Inv, (& $T 'sum_run'), [object[]]@($TestVersion, (& $T $mode), (Ep-Local $t0), (Ep-Local $t1), (DurLang ($t1 - $t0) $lang), (StateNum 'est_min'))))
        foreach ($k in @(@('sum_board', 'f_board'), @('sum_bios', 'f_bios'), @('sum_cpu', 'f_cpu'), @('sum_mem', 'f_memory'), @('sum_gpu', 'f_gpu'), @('sum_os', 'f_os'))) {
            $out.Add(((& $T $k[0]) + ' ' + (Mask ([string]$script:State[$k[1]]))))
        }
        $out.Add('')
        $out.Add(('==== ' + (& $T $res) + ' ===='))
        foreach ($sec in @(@('ERR', 'sum_err'), @('WARN', 'sum_warn'), @('OK', 'sum_ok'), @('SKIP', 'sum_skip'), @('INFO', 'sum_info'))) {
            $items = @($v | Where-Object { $_.L -eq $sec[0] })
            if ($items.Count -eq 0) { continue }
            $out.Add('')
            $out.Add((& $T $sec[1]))
            foreach ($x in $items) {
                $txt = $x.En
                if ($lang -eq 0) { $txt = $x.Ru }
                $out.Add(('  - ' + $txt))
            }
        }
        $out.Add('')
        foreach ($k in @('sum_send1', 'sum_send2', 'sum_send3')) { $out.Add((& $T $k)) }
    }
    $out.Add('')
    $out.Add('------------------------------------------------------------------------')
    $out.Add((Tx 'sum_files'))
    foreach ($k in @('fl_summary', 'fl_report', 'fl_snapshot', 'fl_progress', 'fl_sleep', 'fl_load', 'fl_reboots', 'fl_events', 'fl_dumps', 'fl_devices', 'fl_changes', 'fl_state')) {
        $out.Add(('  ' + (TR $k)))
        $out.Add(('    ' + (TE $k)))
    }
    [IO.File]::WriteAllLines($Path, [string[]]@($out | ForEach-Object { $Fixed + $_ }), $Utf8NoBom)
    $script:State['result'] = $res
}

# ---------------------------------------------------------------- the archive

function Mask-File([string]$Src, [string]$Dst) {
    $out = New-Object 'System.Collections.Generic.List[string]'
    foreach ($l in [IO.File]::ReadAllLines($Src)) {
        if ($l.Length -gt 0 -and [int]$l[0] -eq 2) { $out.Add($l.Substring(1)) } else { $out.Add((Mask $l)) }
    }
    [IO.File]::WriteAllText($Dst, (($out -join "`r`n") + "`r`n"), $Utf8Bom)
}

# Masks every file of the run into a folder and zips it onto the Desktop (the Public Desktop or C:\ProgramData\Z3TEST if
# that fails). Returns the path of the zip, or of a folder when even zipping failed.
function Pack-Run {
    $name = 'Z3TEST-win-' + [string]$script:State['stamp']
    $stage = Join-Path $Root $name
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
    [void](New-Item -ItemType Directory -Path $stage -Force)
    foreach ($n in @('SUMMARY.txt', 'report-os.txt', 'snapshot.txt', 'progress.txt', 'sleep.txt', 'load.txt', 'reboots.txt', 'events.txt', 'dumps.txt',
            'devices-start.txt', 'devices-end.txt', 'changes-undone.txt', 'state.txt')) {
        $src = RunFile $n
        if (Test-Path -LiteralPath $src) {
            try { Mask-File $src (Join-Path $stage $n) } catch { Log 'progress.txt' ('mask ' + $n + ': ' + (ErrText $_)) }
        }
    }
    $dirs = @()
    if ($script:State['desktop']) { $dirs += [string]$script:State['desktop'] }
    $dirs += @((Join-Path $env:PUBLIC 'Desktop'), $Root)
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    foreach ($d in $dirs) {
        if (-not $d -or -not (Test-Path -LiteralPath $d -PathType Container)) { continue }
        $zip = Join-Path $d ($name + '.zip')
        try {
            if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
            # Entry by entry with "/" in the names: ZipFile.CreateFromDirectory under Windows PowerShell 5.1 (.NET 4.x in
            # its old-app mode) writes "folder\file", which the logon task's GetEntry('folder/SUMMARY.txt') does not find
            # and unzip on Linux or macOS warns about or turns into one long file name (seen on the board 18.11).
            $za = [IO.Compression.ZipFile]::Open($zip, [IO.Compression.ZipArchiveMode]::Create)
            try {
                foreach ($fi in @(Get-ChildItem -LiteralPath $stage -File)) {
                    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($za, $fi.FullName, ($name + '/' + $fi.Name), [IO.Compression.CompressionLevel]::Optimal)
                }
            } finally { $za.Dispose() }
            Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
            return $zip
        } catch { Log 'progress.txt' ('zip to ' + $d + ': ' + (ErrText $_)) }
    }
    return $stage
}

# When nobody was logged on at the end: at the next logon of the tester a window shows the SUMMARY from the zip, once.
function Register-ShowTask([string]$Zip) {
    $user = [string]$script:State['user']
    if (-not $user) { return }
    $entry = [IO.Path]::GetFileNameWithoutExtension($Zip) + '/SUMMARY.txt'
    $q = { param($s) return ([string]$s).Replace("'", "''") }
    $cmd = @'
$z = '__ZIP__'
$m = Join-Path $env:LOCALAPPDATA 'Z3TEST-shown-__STAMP__'
if ((Test-Path -LiteralPath $m) -or -not (Test-Path -LiteralPath $z)) { exit }
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $a = [IO.Compression.ZipFile]::OpenRead($z)
    $r = New-Object IO.StreamReader($a.GetEntry('__ENTRY__').Open())
    Write-Host $r.ReadToEnd()
    $r.Close()
    $a.Dispose()
} catch { Write-Host $_ }
Write-Host ''
Write-Host '__WHERE__'
Write-Host $z
[void](New-Item -ItemType File -Path $m -Force)
[void](Read-Host '__CLOSE__')
'@
    $cmd = $cmd.Replace('__ZIP__', (& $q $Zip)).Replace('__STAMP__', (& $q $script:State['stamp'])).Replace('__ENTRY__', (& $q $entry))
    $cmd = $cmd.Replace('__WHERE__', (& $q ((TR 'show_where') + ' / ' + (TE 'show_where')))).Replace('__CLOSE__', (& $q ((TR 'close') + ' / ' + (TE 'close'))))
    $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
    $act = New-ScheduledTaskAction -Execute $PsExe -Argument ('-NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + $b64)
    $trg = New-ScheduledTaskTrigger -AtLogOn -User $user
    $trg.EndBoundary = (Get-Date).AddDays(3).ToString('s', $Inv)
    $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DeleteExpiredTaskAfter (New-TimeSpan -Hours 1) -ExecutionTimeLimit (New-TimeSpan -Hours 4)
    $pr = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    Add-Line $CleanupFile 'task|Z3TEST-show'
    [void](Register-ScheduledTask -TaskPath $TaskPath -TaskName 'Z3TEST-show' -Action $act -Trigger $trg -Settings $set -Principal $pr -Force -ErrorAction Stop)
}

$script:InFinish = $false
function Finish-Run {
    if ($script:InFinish) { return }
    $script:InFinish = $true
    $script:Phase = 'final'
    $script:State['phase'] = 'final'
    $script:State['finished'] = Now-Epoch
    Save-State
    Say 'final_go'
    # The startup task goes last, after the archive: this very process may be its running instance.
    try { Undo-Changes $script:RunDir $null @('task|Z3TEST-resume', 'taskfolder') } catch { Log 'progress.txt' ('undo: ' + (ErrText $_)) }
    try { Collect-Events } catch { Log 'progress.txt' ('events: ' + (ErrText $_)); Verdict 'WARN' 'v_ev_failed' (ErrText $_) }
    try { Collect-Dumps } catch { Log 'progress.txt' ('dumps: ' + (ErrText $_)) }
    try {
        $now = Get-DevList
        Save-DevList $now 'end'
        $c = Compare-Dev (Load-DevList 'start') $now
        if ($c.missing.Count -gt 0) { Verdict 'ERR' 'v_dev_missing' '@@w_end' ($c.missing -join '; ') }
        if ($c.broken.Count -gt 0) { Verdict 'WARN' 'v_dev_broken' '@@w_end' ($c.broken -join '; ') }
    } catch { Log 'progress.txt' ('devices: ' + (ErrText $_)) }
    if ((StateNum 'stalls') -gt 0) { Verdict 'WARN' 'v_stall' (StateNum 'stalls') (StateNum 'stall_max') ('@@w_ph_' + [string]$script:State['stall_phase']) (Ep-Time (StateNum 'stall_at')) }
    $st = [string]$script:State['stopped']
    if ($st) {
        $w = '@@w_ph_' + $st
        if ($st -eq 'ctrl-c' -or $st -eq 'stop') { $w = '@@w_ph_start' }
        if (-not $script:State['unexpected']) { Verdict 'WARN' 'v_stopped' $w }
    }
    Verdict 'SKIP' 'v_fan_win'
    $script:State['finished'] = Now-Epoch
    Write-Summary (RunFile 'SUMMARY.txt')
    Save-State
    if (Test-Path -LiteralPath (RunFile 'changes.txt')) {
        Add-Line (RunFile 'changes-undone.txt') ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss', $Inv) + '  task|Z3TEST-resume and the task folder \Z3NOVO: removed right after this archive was made')
    }
    $zip = Pack-Run
    try { Undo-Changes $script:RunDir $null } catch { Log 'progress.txt' ('undo: ' + (ErrText $_)) }
    $script:State['zip'] = $zip
    $script:State['phase'] = 'done'
    Save-State
    foreach ($n in @('Z3TEST-STOP', 'Z3TEST-STOP.txt')) {
        if ($script:State['desktop']) { Remove-Item -LiteralPath (Join-Path ([string]$script:State['desktop']) $n) -Force -ErrorAction SilentlyContinue }
    }
    if ($script:Interactive) {
        Write-Host ''
        try { foreach ($l in [IO.File]::ReadAllLines((RunFile 'SUMMARY.txt'))) { Write-Host $l.TrimStart([char]2) } } catch { }
        Write-Host ''
        Write-Host ((TR 'show_where') + ' / ' + (TE 'show_where')) -ForegroundColor Green
        Write-Host ('  ' + $zip) -ForegroundColor Green
    } elseif ($zip -like '*.zip') {
        try { Register-ShowTask $zip } catch { Log 'progress.txt' ('show task: ' + (ErrText $_)) }
    }
    if ($zip -like '*.zip') {
        Remove-Item -LiteralPath $CurrentFile -Force -ErrorAction SilentlyContinue
        $d = $script:RunDir
        $script:RunDir = $null
        Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ================================================================ z3test: start, stop, resume

$PhaseOrder = @('snapshot', 'sleep', 'load', 'idle', 'reboot', 'final')
function Next-Phase {
    $i = [array]::IndexOf($PhaseOrder, [string]$script:State['phase'])
    if ($i -lt 0 -or $i -ge $PhaseOrder.Count - 1) { $script:State['phase'] = 'final' } else { $script:State['phase'] = $PhaseOrder[$i + 1] }
    $script:State['phase_started'] = Now-Epoch
    $script:State['t_' + [string]$script:State['phase']] = $script:State['phase_started']
    Save-State
}
function Run-Phases {
    while ($true) {
        $ph = [string]$script:State['phase']
        if ($ph -eq 'final' -or $ph -eq 'done' -or $ph -eq '') { break }
        $script:Phase = $ph
        if (Test-StopRequested) {
            if (-not $script:State['stopped']) { $script:State['stopped'] = $ph }
            break
        }
        $r = ''
        switch ($ph) {
            'snapshot' { $r = [string](@(Phase-Snapshot) | Select-Object -Last 1) }
            'sleep' { $r = [string](@(Phase-Sleep) | Select-Object -Last 1) }
            'load' { $r = [string](@(Phase-Load) | Select-Object -Last 1) }
            'idle' { $r = [string](@(Phase-Idle) | Select-Object -Last 1) }
            'reboot' { $r = [string](@(Phase-Reboot) | Select-Object -Last 1) }
            default { $r = 'next' }
        }
        if ($script:Handoff) { return }
        if ($r -eq 'stop') {
            if (-not $script:State['stopped']) { $script:State['stopped'] = $ph }
            Save-State
            break
        }
        Next-Phase
    }
    Finish-Run
}

function Open-Run([string]$Dir) {
    $script:RunDir = $Dir
    $script:State = Load-State $Dir
    $script:Phase = [string]$script:State['phase']
    $u = [string]$script:State['user_name']
    if ($u) { Add-Token '<user>' $u $false }
}

function Get-Plan {
    $lg = [bool]$Long
    $p = @{ mode = 'short'; sleep_total = 3; sleep_secs = 60; load_min = 10; idle_min = 3; reboot_total = 3 }
    if ($lg) { $p = @{ mode = 'long'; sleep_total = 8; sleep_secs = 90; load_min = 20; idle_min = 18; reboot_total = 8 } }
    if ($SleepCycles -ge 0) { $p.sleep_total = [Math]::Min($SleepCycles, 50) }
    if ($SleepSeconds -ge 0) { $p.sleep_secs = [Math]::Max(30, [Math]::Min($SleepSeconds, 3600)) }
    if ($Reboots -ge 0) { $p.reboot_total = [Math]::Min($Reboots, 50) }
    if ($LoadMinutes -ge 0) { $p.load_min = [Math]::Min($LoadMinutes, 600) }
    if ($IdleMinutes -ge 0) { $p.idle_min = [Math]::Min($IdleMinutes, 600) }
    $sk = @($Skip | ForEach-Object { ([string]$_).Split(',') } | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })
    if ($sk -contains 'sleep') { $p.sleep_total = 0 }
    if ($sk -contains 'load') { $p.load_min = 0 }
    if ($sk -contains 'idle') { $p.idle_min = 0 }
    if ($sk -contains 'reboot' -or $sk -contains 'reboots') { $p.reboot_total = 0 }
    # Seconds per step as measured or reckoned: snapshot ~3 min (the activation query is slow); a sleep is its length plus
    # ~41 s (6 before, ~5 going down and back, 25 settling, 5 between); a restart ~4 min (20 s + the 60 s notice + Windows
    # going down and up again + the 30 s delay of the startup task + 45 s settling); the end ~2 min.
    $p.minutes = [int][Math]::Ceiling((180 + $p.sleep_total * ($p.sleep_secs + 41) + $p.load_min * 60 + $p.idle_min * 60 + $p.reboot_total * 245 + 120) / 60.0)
    return $p
}

function Request-TestElevation {
    if ($NoElevate -or $Relaunched -or -not $ScriptPath -or -not (Test-Interactive)) { return $false }
    Write-Host ''
    SayPlain 'elev_q'
    $ans = $null
    try { $ans = Read-Host '[Y/n]' } catch { return $false }
    $a = ([string]$ans).Trim().ToLowerInvariant()
    $yes = @('') + @((TR 'yes_words') -split ' ') + @((TE 'yes_words') -split ' ')
    if ($yes -notcontains $a) { return $false }
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $ScriptPath + '"'), '-Relaunched')
    foreach ($k in $Bound.Keys) {
        $v = $Bound[$k]
        if ($k -eq 'Relaunched' -or $k -eq 'NoElevate') { continue }
        if ($v -is [switch] -or $v -is [bool]) { if ([bool]$v) { $argList += ('-' + $k) } }
        elseif ($v -is [array]) { $argList += ('-' + $k); $argList += ('"' + ((@($v) | ForEach-Object { [string]$_ }) -join ',') + '"') }
        else { $argList += ('-' + $k); $argList += [string]$v }
    }
    try {
        $exe = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        Start-Process -FilePath $exe -ArgumentList $argList -Verb RunAs -ErrorAction Stop
        SayPlain 'elev_started'
        return $true
    } catch {
        Write-Host ((Tx 'elevate_failed') + ': ' + (ErrText $_))
        return $false
    }
}

function Do-Start {
    if ([Environment]::OSVersion.Version.Major -lt 10) { SayPlain 'need_win10'; return }
    if (-not $IsAdmin) {
        if (Request-TestElevation) { return }
        SayPlain 'need_admin_run'
        return
    }
    Prepare-Root
    if (-not (Get-Lock)) { SayPlain 'already_running'; return }
    try { Use-Type 'Z3Pwr' $PwrCode } catch { }
    try { Build-Tokens } catch { }
    $old = Current-Run
    if ($old) {
        SayPlain 'stale_found' $old
        Open-Run $old
        if (-not $script:State['stopped'] -and [string]$script:State['phase'] -ne 'final' -and [string]$script:State['phase'] -ne 'done') {
            $script:State['stopped'] = [string]$script:State['phase']
            Verdict 'WARN' 'v_broke_off' ('@@w_ph_' + [string]$script:State['phase'])
        }
        Finish-Run
        $script:RunDir = $null
        $script:State = @{}
        $script:InFinish = $false
        $script:StopNow = $false
        Write-Host ''
    }
    Clear-Leftovers

    $plan = Get-Plan
    $caps = Get-PowerCaps
    $bl = Get-BitLockerBlock
    $fs = RegVal 'SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled'
    Write-Host ''
    SayPlain 'intro_title' (FR ('mode_' + $plan.mode)) (FE ('mode_' + $plan.mode)) $plan.minutes
    SayPlain 'intro_plan' $plan.sleep_total $plan.sleep_secs $plan.load_min $plan.idle_min $plan.reboot_total
    if ($caps.ok -and ($caps.AoAc -or -not $caps.S3) -and $plan.sleep_total -gt 0) { SayPlain 'intro_nos3' }
    Write-Host ''
    SayPlain 'intro_before'
    SayPlain 'intro_1'
    SayPlain 'intro_2'
    if ($fs -eq 1) { SayPlain 'intro_3_on' } else { SayPlain 'intro_3_off' }
    $block = ''
    if ($bl.block -and $plan.reboot_total -gt 0) { $block = $bl.block; SayPlain 'intro_4_block' $bl.block }
    elseif ($bl.on) { SayPlain 'intro_4_on' }
    else { SayPlain 'intro_4_off' }
    SayPlain 'intro_5'
    SayPlain 'intro_6'
    Write-Host ''
    SayPlain 'intro_stop'
    SayPlain 'intro_result'
    Write-Host ''
    if (-not $Yes) {
        if (-not (Test-Interactive)) { SayPlain 'need_yes'; return }
        SayPlain 'intro_go'
        $ans = $null
        try { $ans = Read-Host '>' } catch { return }
        $a = ([string]$ans).Trim().ToLowerInvariant()
        $yes = @('') + @((TR 'yes_words') -split ' ') + @((TE 'yes_words') -split ' ')
        if ($yes -notcontains $a) { SayPlain 'cancelled'; return }
    }

    # The run folder, its state and the startup task.
    $stamp = (Get-Date).ToString('yyyy-MM-dd-HHmmss', $Inv)
    $dir = Join-Path $Root ('run-' + $stamp)
    [void](New-Item -ItemType Directory -Path $dir -Force)
    $script:RunDir = $dir
    $script:InFinish = $false
    $desk = ''
    try { $desk = [Environment]::GetFolderPath('Desktop') } catch { }
    $script:State = @{
        version = $TestVersion; stamp = $stamp; mode = $plan.mode; started = (Now-Epoch); phase = 'snapshot'; phase_started = (Now-Epoch)
        user = ($env:USERDOMAIN + '\' + $env:USERNAME); user_name = $env:USERNAME; desktop = $desk
        sleep_total = $plan.sleep_total; sleep_secs = $plan.sleep_secs; load_min = $plan.load_min; idle_min = $plan.idle_min
        reboot_total = $plan.reboot_total; reboot_block = $block; bitlocker = $bl.text; faststartup = $fs; est_min = $plan.minutes
    }
    Save-State
    Copy-Item -LiteralPath $ScriptPath -Destination (Join-Path $dir 'z3test.ps1') -Force
    [IO.File]::WriteAllText($CurrentFile, $dir, $Utf8NoBom)
    $script:Phase = 'start'
    Log 'progress.txt' (F 'z3test.ps1 {0}, mode {1}: sleep {2} x {3} s, load {4} min, idle {5} min, restarts {6}, about {11} min; BitLocker {7}; Fast Startup {8}; S3 {9}, modern standby {10}' `
            $TestVersion $plan.mode $plan.sleep_total $plan.sleep_secs $plan.load_min $plan.idle_min $plan.reboot_total $bl.text $fs $caps.S3 $caps.AoAc $plan.minutes)
    Register-ResumeTask
    try { [Z3Pwr]::KeepAwake($true) } catch { }
    try { [Console]::TreatControlCAsInput = $true } catch { }
    Run-Phases
}

function Do-Stop {
    if (-not $IsAdmin) {
        # Without rights: the flag on the Desktop stops a running test just as well.
        try {
            [IO.File]::WriteAllText((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Z3TEST-STOP.txt'), 'stop', $Utf8NoBom)
            SayPlain 'stop_flag'
        } catch { }
        if (Request-TestElevation) { return }
        return
    }
    if (-not (Test-Path -LiteralPath $Root)) { SayPlain 'stop_nothing'; return }
    Prepare-Root
    if (Get-Lock) {
        try { Build-Tokens } catch { }
        $d = Current-Run
        if (-not $d) {
            Clear-Leftovers
            SayPlain 'stop_nothing'
            return
        }
        Open-Run $d
        if (-not $script:State['stopped']) { $script:State['stopped'] = [string]$script:State['phase'] }
        Finish-Run
        Clear-Leftovers
        return
    }
    $d = Current-Run
    if ($d) { [IO.File]::WriteAllText((Join-Path $d 'STOP'), 'stop', $Utf8NoBom) }
    SayPlain 'stop_sent'
    for ($i = 0; $i -lt 300; $i++) {
        if (-not (Test-Path -LiteralPath $CurrentFile)) { SayPlain 'stop_done'; return }
        Start-Sleep -Seconds 1
    }
    SayPlain 'stop_slow'
}

function Do-Resume {
    if (-not (Test-Path -LiteralPath $Root)) { return }
    if (-not (Get-Lock)) { return }
    $d = Current-Run
    if (-not $d) {
        # Nothing to go on with: only remove what a run may have left.
        try { Remove-Z3Task 'Z3TEST-resume' } catch { }
        try { Remove-Z3Task 'Z3TEST-wake' } catch { }
        Remove-Z3TaskFolder
        return
    }
    try { Build-Tokens } catch { }
    Open-Run $d
    try {
        Use-Type 'Z3Pwr' $PwrCode
        [Z3Pwr]::KeepAwake($true)
    } catch { }
    $ph = [string]$script:State['phase']
    Log 'progress.txt' ('[' + $ph + '] Windows started; the startup task runs z3test.ps1 -Resume as SYSTEM')
    if ($ph -eq 'done') {
        Remove-Item -LiteralPath $CurrentFile -Force -ErrorAction SilentlyContinue
        try { Undo-Changes $d $null } catch { }
        return
    }
    if ($ph -eq 'final') { Finish-Run; return }
    $boot = Get-BootEpoch
    $issued = StateNum 'reboot_issued'
    if ($ph -eq 'reboot' -and $issued -gt 0 -and $boot -ge $issued) {
        # Let the devices come up before they are compared with the start.
        if (-not (Wait-Step 45 'settling after the start')) { $script:State['stopped'] = 'reboot'; Save-State; Check-Reboot; Finish-Run; return }
        Check-Reboot
        Run-Phases
        return
    }
    Check-Unexpected
    Finish-Run
}

# ================================================================ run

$script:Interactive = (Test-Interactive) -and -not $Resume
$fatal = ''
$finished = $false
try {
    if ($Stop) { Do-Stop } elseif ($Resume) { Do-Resume } else { Do-Start }
    $finished = $true
} catch {
    $fatal = (ErrText $_) + ' (line ' + $_.InvocationInfo.ScriptLineNumber + ')'
} finally {
    if (-not $finished -and -not $script:Handoff -and $script:RunDir -and [string]$script:State['phase'] -ne 'done') {
        try {
            if ($fatal) { Verdict 'ERR' 'v_script_error' $fatal }
            elseif (-not $script:State['stopped']) { $script:State['stopped'] = 'stop' }
            if ($script:InFinish) { Undo-Changes $script:RunDir $null } else { Finish-Run }
        } catch {
            try { Undo-Changes $script:RunDir $null } catch { }
        }
    }
    if ($fatal) {
        if ($script:Interactive) { Write-Host ('z3test: ' + $fatal) -ForegroundColor Red }
        try { Add-Line (Join-Path $Root 'errors.txt') ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss', $Inv) + '  ' + $fatal) } catch { }
    }
    if (-not $script:Handoff) {
        try { [Z3Pwr]::KeepAwake($false) } catch { }
    }
    try { [Console]::TreatControlCAsInput = $false } catch { }
    Release-Lock
}
if ($script:Interactive -and -not $script:Handoff -and ($Relaunched -or [Environment]::CommandLine -match 'Set-ExecutionPolicy -Scope Process')) {
    try { [void](Read-Host ((TR 'close') + ' / ' + (TE 'close'))) } catch { }
}
