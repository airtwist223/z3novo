#!/usr/bin/env bash
# z3test.sh: an unattended test for testers of the Z3NOVO firmware (Lenovo ThinkCentre M715s, board AM4P2MS), in their own
# Linux.
#
#   sudo bash z3test.sh              short run, about 30 minutes
#   sudo bash z3test.sh --long       long run, about 1 h 20 min
#   sudo bash z3test.sh --stop       stop a run and undo its changes (or touch ~/Z3TEST-STOP)
#   sudo bash z3test.sh --deep       also the fan check after sleep (Z3NOVO on an M715s only; writes one CMOS bit, see README)
#
# What it does, in this order: a snapshot (the whole z3report.sh report plus memory set and running, PCIe links, NVMe
# drives, Secure Boot and TPM); sleep and wake N times with rtcwake; load on all cores and on the memory with pattern
# checks (coreutils only: the patterns go through a tmpfs, that is RAM: /dev/shm, or one of the test's own when there is
# none); idle (long run); N restarts in a row, continued
# by a systemd unit after each start (no automatic logon needed); then the kernel log of the test window (machine
# checks, panics, lockups, GPU resets, disk, NVMe and USB errors) and a plain-words SUMMARY. Everything goes into ONE zip
# (or .tar.gz when no zip tool is there) in the home folder of the user who started it.
#
# Needs root. Temporary changes, each written to a journal and undone at the end, on a stop, on Ctrl+C, or at the next
# start after a run that broke off: the unit /etc/systemd/system/z3test-resume.service, /sys/power/mem_sleep (only if it
# was not "deep"), the RTC wake alarm, a tmpfs of its own for the load when the system has no /dev/shm, the folder
# /var/lib/z3test; a sleep inhibitor lives only as long as the script. One line "z3test: run ... started" goes into the
# kernel log, so that the end reads only the kernel log of the test.
#
# Never done here: writing firmware variables or BIOS settings; /dev/mem, i2c/SMBus, the Super I/O chip, ACPI thermal
# zones, sensors-detect, loading modules; the network; installing anything. The one exception is --deep (root, on the
# M715s with Z3NOVO only): it reads extended CMOS byte DEh through ports 72h/73h before and after sleep, and clears
# bit 7 of it once to see whether the firmware's fan driver sets it again (the README explains why).
#
# Made by a build script from the z3test sources and z3report.sh: the part between the two "z3report.sh" marker lines is
# z3report.sh itself, copied unchanged (fix the report there, not here).

# ==== z3report.sh 1.0 (sha256 88413ff76917b3b6...), its lines 2 to 1213, copied unchanged by build.sh: do not edit here ====
# z3report.sh: report for testers of the Z3NOVO firmware (Lenovo ThinkCentre M715s, board AM4P2MS), OS side, Linux.
#
#   bash z3report.sh          as a normal user; in a terminal it offers to run again through sudo (--no-sudo: no offer)
#   sudo bash z3report.sh     adds SMBIOS details (memory modules, CPU), pstore crash logs, rasdaemon/mcelog,
#                             and the system journal when your user may not read it
#
# Writes ONE UTF-8 text file z3report-os-<date>-<time>.txt to your home folder (or the current folder) and prints its
# path. Read-only. Computer and user names, serial numbers, UUIDs, MAC tails, IP addresses, Wi-Fi names and home paths
# are masked in the file. Read the file before sending it.
#
# Never done here: /dev/port, /dev/mem, i2c/SMBus, sensors-detect, loading modules, writing efivars, /sys/class/thermal
# (on the AM4P2MS board reading the ACPI thermal zone makes the firmware access the Super I/O chip), ACPI methods
# (hwmon is read only from drivers on a safe list), the network, installing packages, reading the ACPI MSDM table.

[ -n "${BASH_VERSION:-}" ] || {
    command -v bash >/dev/null 2>&1 && exec bash "$0" "$@"
    echo "z3report.sh: needs bash / нужен bash" >&2
    exit 1
}

VERSION=1.0
export LC_ALL=C
export PATH="$PATH:/usr/sbin:/sbin"
umask 077

STAMP=$(date +%Y-%m-%d-%H%M%S)
NOW_TEXT=$(date '+%Y-%m-%d %H:%M:%S %z')
EV=${Z3REPORT_EFIVARS:-/sys/firmware/efi/efivars} # test hook: a folder laid out like efivarfs
GUID_CHIP=7a3c5d11-42e9-4f60-9d1b-5e7713a8c402  # Z3Chip, the firmware driver's log
GUID_APP=7c9d3f2a-41b6-4e1d-9a57-2f8e116cd4a0   # Z3Novo*, the setup app's variables
GUID_EFI=8be4df61-93ca-11d2-aa0d-00e098032b8c   # EFI global variables (SecureBoot)
IS_ROOT=0
[ "$(id -u)" = 0 ] && IS_ROOT=1

# hwmon drivers that read only the CPU, the GPU or a drive through their own driver. Everything else (acpitz, it87,
# nct*, spd5118, jc42, ACPI battery and power drivers, WMI drivers) is skipped: those go through ACPI methods, the
# Super I/O chip or the SMBus.
SAFE_HWMON=" k10temp zenpower amdgpu radeon nouveau nvme coretemp fam15h_power "

# Kernel log lines worth showing even at info level.
BOOT_RE='DMI: |efi: EFI v|SMBIOS [0-9]|Command line:|microcode|reset reason|smpboot: CPU0|Memory: [0-9]+K/|ACPI: (RSDP|XSDT|FACP|DSDT) |AMD-Vi: (Found|Extended|Interrupt)|of VRAM memory ready|of GTT memory ready|amdgpu: VRAM|r8169 .*XID|Secure boot|secureboot|Lockdown:'
DEV_RE='probe.*fail|failed with error|direct firmware load|firmware.*(fail|error|not found)|failed to load|cannot (enable|reset|claim|assign)|can.t (assign|claim|enable)|no space for|BAR [0-9]+.*(fail|no space)|not responding|timed out|timeout|disabled by hub|device descriptor read|unable to enumerate|not accepting address|over-current|NETDEV WATCHDOG|AER:|PCIe Bus Error|Firmware Bug|BIOS Error|ACPI Error|AE_[A-Z_]+|reset (adapter|controller) |reset failed'
HIST_RE='mce: |machine check|hardware error|kernel panic|Oops|BUG: |soft lockup|hard LOCKUP|hung_task|blocked for more than|rcu.*(stall|self-detected)|watchdog: |NMI watchdog|GPU reset|ring .* timeout|amdgpu.*(hang|timeout|GPU fault)|reset reason|thermal shutdown|critical temperature|PCIe Bus Error|AER: .*(Uncorrected|Fatal)|EDAC .*(CE|UE)'
MOD_RE='it87|nct6775|nct6683|w83627ehf|w83627hf|f71882fg|sch5627|sp5100_tco|i2c_piix4|ee1004|spd5118|jc42|at24|k10temp|zenpower|amdgpu|radeon|nvidia|nouveau|i915|xe|r8169|r8168|r8125|ec_sys|msr|cpuid|acpi_cpufreq|amd_pstate|kvm_amd|kvm_intel|vfio_pci|ccp|asus_wmi_sensors|asus_ec_sensors|thinkpad_acpi'

# ---------------------------------------------------------------- small helpers

have() { command -v "$1" >/dev/null 2>&1; }
# T SECONDS COMMAND...: run with a time limit when timeout(1) exists
T() {
    local s=$1
    shift
    if have timeout; then timeout "$s" "$@"; else "$@"; fi
}
# One read of a file that might block (hwmon, efivars), with a time limit.
rd() { [ -r "$1" ] && T 5 cat -- "$1" 2>/dev/null; }
# First line of a sysfs attribute, read by the shell itself.
sv() {
    local v=""
    [ -r "$1" ] && read -r v <"$1" 2>/dev/null
    printf '%s' "$v"
}
kv() {
    [ -n "$2" ] && printf '  %-30s %s\n' "$1:" "$2"
    return 0
}
note() { printf '  %s\n' "$*"; }
skip() { printf '  skipped / пропущено: %s\n' "$*"; }
ind() { sed 's/^/    /'; }
say() { printf '%s\n' "$*"; }
# Pass stdin through; when it is empty print "none" (or the given text) instead.
none_if_empty() {
    local f=$TMPD/nie
    cat >"$f"
    if [ -s "$f" ]; then cat "$f"; else printf '    %s\n' "${1:-none / нет}"; fi
}
# Value of a fact, or the given text when the step could not find it out.
fv() {
    local v
    v=$(getfact "$1")
    printf '%s' "${v:-$2}"
}
# Drop firewall and audit records: noise, and full of addresses.
nofw() { grep -v -E '\[UFW |IN=[^ ]* OUT=|audit: type=|audit\[[0-9]+\]'; }
drvname() {
    local l
    l=$(readlink "$1/driver" 2>/dev/null)
    printf '%s' "${l##*/}"
}
mib() { awk -v b="$1" 'BEGIN { if (b != "") printf "%d MiB", b / 1048576 }'; }
osr() { sed -n "s/^$1=//p" /etc/os-release 2>/dev/null | head -n 1 | sed 's/^"//; s/"$//'; }
cpuf() { awk -F': *' -v k="$1" '{ key = $1; sub(/[ \t]+$/, "", key) } key == k { print $2; exit }' /proc/cpuinfo 2>/dev/null; }
# SMBIOS strings (BIOS, board, system, chassis): vendors sometimes put a unique number into a "Version" or similar
# field (a Lenovo board: "SDK0J40697 WIN 1234567890123"). Every run of 8+ digits, and every letters-and-digits run of
# 10+ characters that is not a Lenovo machine type and model (10MCS02600), part number (SDK0J40697) or notebook board
# model (LNVNB161216), becomes <serial>: "SDK0J40697 WIN 1234567890123" -> "SDK0J40697 WIN <serial>". The same rule
# is in z3report.ps1 (SmbSafe).
# smbsafe [TEXT]: only lines containing TEXT are changed (used for the kernel's "DMI:" line), others pass as they are.
smbsafe() {
    LC_ALL=C awk -v only="${1:-}" '
        function safe(r) {
            if (r ~ /^[0-9]+$/ && length(r) >= 8) return "<serial>"
            if (length(r) >= 10 && r ~ /[A-Za-z]/ && r ~ /[0-9]/) {
                if (r ~ /^[0-9][0-9][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z]$/) return r
                if (r ~ /^[0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][A-Z][0-9][0-9][0-9][0-9][0-9]$/) return r
                if (r ~ /^LNVNB[0-9][0-9][0-9][0-9][0-9][0-9]$/) return r   # Lenovo notebook board model
                return "<serial>"
            }
            return r
        }
        only != "" && index($0, only) == 0 { print; next }
        {
            s = $0; out = ""
            while (match(s, /[A-Za-z0-9]+/)) {
                out = out substr(s, 1, RSTART - 1) safe(substr(s, RSTART, RLENGTH))
                s = substr(s, RSTART + RLENGTH)
            }
            print out s
        }'
}
fact() { printf '%s=%s\n' "$1" "$2" >>"$FACTS"; }
getfact() { sed -n "s/^$1=//p" "$FACTS" 2>/dev/null | tail -n 1; }

# ---------------------------------------------------------------- log sources

KSRC=""
JOK=0
log_init() {
    if T 10 dmesg >/dev/null 2>&1; then
        KSRC=dmesg
    elif have journalctl && [ -n "$(T 20 journalctl -k -b 0 -n 1 -q --no-pager 2>/dev/null)" ]; then
        KSRC=journal
    fi
    if have journalctl && [ -n "$(T 20 journalctl --system -n 1 -q --no-pager 2>/dev/null)" ]; then
        JOK=1
    fi
}
# journalctl -o short-monotonic lines look like dmesg once the host name and "kernel:" are cut
ksed() { sed -E 's/^(\[[^]]*\]) [^ ]+ kernel: /\1 /'; }
# This boot's kernel log, "[seconds] message".
klog() {
    case $KSRC in
    dmesg) T 20 dmesg 2>/dev/null ;;
    journal) T 40 journalctl -k -b 0 -o short-monotonic -q --no-pager 2>/dev/null | ksed ;;
    esac
}
# This boot's kernel warnings and worse.
klog_warn() {
    case $KSRC in
    dmesg) T 20 dmesg -l emerg,alert,crit,err,warn 2>/dev/null || klog | grep -i -E 'error|fail|warn' ;;
    journal) T 40 journalctl -k -b 0 -p warning -o short-monotonic -q --no-pager 2>/dev/null | ksed ;;
    esac
}

# ---------------------------------------------------------------- PCI names from pci.ids

pci_names_build() {
    local ids="" d f
    for d in /sys/bus/pci/devices/*; do
        [ -r "$d/vendor" ] || continue
        f=$(sv "$d/vendor"):$(sv "$d/device")
        ids="$ids ${f//0x/}"
    done
    for f in /usr/share/hwdata/pci.ids /usr/share/misc/pci.ids /usr/share/pci.ids /var/lib/pciutils/pci.ids; do
        if [ -r "$f" ]; then
            pci_ids_awk "$ids" <"$f" >"$TMPD/pcinames"
            return 0
        fi
    done
    for f in /usr/share/misc/pci.ids.gz /usr/share/hwdata/pci.ids.gz; do
        if [ -r "$f" ] && have gzip; then
            gzip -dc "$f" 2>/dev/null | pci_ids_awk "$ids" >"$TMPD/pcinames"
            return 0
        fi
    done
    : >"$TMPD/pcinames"
}
pci_ids_awk() {
    awk -v want="$1" '
        BEGIN { n = split(want, w, " "); for (i = 1; i <= n; i++) need[w[i]] = 1 }
        /^#/ || /^$/ { next }
        /^C [0-9a-f][0-9a-f]  / { incls = 1; cc = substr($0, 3, 2); cname[cc] = substr($0, 7); next }
        incls && /^\t[0-9a-f][0-9a-f]  / { sname[cc ":" substr($0, 2, 2)] = substr($0, 6); next }
        incls { next }
        /^[0-9a-f][0-9a-f][0-9a-f][0-9a-f]  / { v = substr($0, 1, 4); vname[v] = substr($0, 7); next }
        /^\t[0-9a-f][0-9a-f][0-9a-f][0-9a-f]  / { k = v ":" substr($0, 2, 4); if (k in need) dname[k] = substr($0, 8); next }
        END {
            for (k in need) printf "%s\t%s\t%s\n", k, ((substr(k, 1, 4) in vname) ? vname[substr(k, 1, 4)] : "?"), ((k in dname) ? dname[k] : "?")
            for (k in sname) printf "C%s\t%s\t%s\n", k, cname[substr(k, 1, 2)], sname[k]
        }'
}
# The maker by vendor id, for when pci.ids is missing or does not know the device.
vendor_name() {
    case $1 in
    10de) printf 'NVIDIA' ;; 1002 | 1022) printf 'AMD' ;; 8086) printf 'Intel' ;; 1a03) printf 'ASPEED' ;;
    102b) printf 'Matrox' ;; 15ad) printf 'VMware' ;; 1234) printf 'QEMU/Bochs' ;; 1af4 | 1b36) printf 'Red Hat (QEMU)' ;;
    1414) printf 'Microsoft (Hyper-V)' ;; 80ee) printf 'VirtualBox' ;; 10ec) printf 'Realtek' ;; 14e4) printf 'Broadcom' ;;
    1b21) printf 'ASMedia' ;; 144d) printf 'Samsung' ;; *) printf 'unknown vendor %s' "$1" ;;
    esac
}
pci_name() {
    local n
    n=$(awk -F'\t' -v k="$1" '$1 == k { print $2 " " $3; exit }' "$TMPD/pcinames" 2>/dev/null)
    case $n in '' | '? '*) n="$(vendor_name "${1%%:*}") device ${1#*:}" ;; esac
    printf '%s' "$n"
}
pci_class() { awk -F'\t' -v k="C$1" '$1 == k { print $3; exit }' "$TMPD/pcinames" 2>/dev/null; }
pci_id() {
    local v d
    v=$(sv "$1/vendor")
    d=$(sv "$1/device")
    printf '%s:%s' "${v#0x}" "${d#0x}"
}
# PCIe link as the kernel sees it (a read of the link status register through the kernel; skipped in D3cold).
pcilink() {
    local s m
    [ "$(sv "$1/power_state")" = D3cold ] && {
        printf 'not read (device in D3cold)'
        return 0
    }
    s=$(rd "$1/current_link_speed")
    m=$(rd "$1/max_link_speed")
    case "$s|$m" in "|"* | "Unknown|Unknown") return 0 ;; esac # no PCIe link: built into the chip
    printf '%s x%s (max %s x%s)' "$s" "$(rd "$1/current_link_width")" "$m" "$(rd "$1/max_link_width")"
}

# ---------------------------------------------------------------- report steps

s_os() {
    local n bt up
    if [ -r /etc/os-release ]; then
        n=$(osr PRETTY_NAME)
        [ -n "$n" ] || n="$(osr NAME) $(osr VERSION)"
        kv "Distribution" "$n"
        kv "ID, version" "$(printf '%s %s %s' "$(osr ID)" "$(osr VERSION_ID)" "$(osr BUILD_ID)" | tr -s ' ' | sed 's/ $//')"
    else
        n="unknown"
        kv "Distribution" "unknown (no /etc/os-release)"
    fi
    kv "Kernel" "$(uname -r) $(uname -m)"
    kv "Kernel build" "$(uname -v)"
    bt=$(awk '/^btime / { print $2 }' /proc/stat 2>/dev/null)
    [ -n "$bt" ] && kv "Boot time" "$(date -d "@$bt" '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || printf 'epoch %s' "$bt")"
    up=$(cut -d' ' -f1 /proc/uptime 2>/dev/null)
    [ -n "$up" ] && kv "Uptime" "$(awk -v s="$up" 'BEGIN { s = int(s); printf "%dd %02dh %02dm (%d s)", s / 86400, s % 86400 / 3600, s % 3600 / 60, s }')"
    kv "Kernel command line" "$(rd /proc/cmdline)"
    have systemd-detect-virt && kv "Virtualization" "$(T 5 systemd-detect-virt 2>/dev/null)"
    kv "Desktop session" "${XDG_CURRENT_DESKTOP:-?} ${XDG_SESSION_TYPE:-?}"
    kv "Run as" "$RUNAS"
    fact os "$n"
    fact kernel "$(uname -r)"
}

dmi() {
    have dmidecode || {
        note "dmidecode is not installed / dmidecode не установлен"
        return 0
    }
    [ -r /sys/firmware/dmi/tables/DMI ] || {
        note "no SMBIOS table in /sys/firmware/dmi / нет таблицы SMBIOS"
        return 0
    }
    # -d /dev/null: even dmidecode's fallback path never reads /dev/mem
    T 15 dmidecode -q -d /dev/null "$@" 2>/dev/null | grep -v -i -E 'serial|uuid|asset tag' |
        grep -v "$(printf '^\t\t')" | sed "s/^$(printf '\t')/      /; s/^\([^ ]\)/    \1/"
}

s_fw() {
    local d=/sys/class/dmi/id k v
    # every SMBIOS string goes through smbsafe (unique numbers -> <serial>)
    for k in bios_vendor bios_version bios_date bios_release ec_firmware_release board_vendor board_name board_version \
        sys_vendor product_name product_version product_family product_sku chassis_vendor chassis_version; do
        kv "$k" "$(sv "$d/$k" | smbsafe)"
    done
    fact bios "$(printf '%s %s (%s)' "$(sv $d/bios_vendor)" "$(sv $d/bios_version)" "$(sv $d/bios_date)" | smbsafe)"
    fact board "$(printf '%s %s %s' "$(sv $d/board_vendor)" "$(sv $d/board_name)" "$(sv $d/board_version)" | smbsafe)"
    if [ -d /sys/firmware/efi ]; then
        kv "Boot mode" "UEFI, $(sv /sys/firmware/efi/fw_platform_size)-bit"
        v=$(efivar_bytes "SecureBoot-$GUID_EFI" | cut -d' ' -f1)
        case $v in
        01) kv "Secure Boot" "on" ;;
        00) kv "Secure Boot" "off" ;;
        *) kv "Secure Boot" "unknown" ;;
        esac
    else
        kv "Boot mode" "legacy BIOS (CSM)"
    fi
    if [ -e "$EV/Z3Chip-$GUID_CHIP" ]; then
        kv "Z3Chip variable" "present: the Z3NOVO firmware driver ran this boot / есть"
        fact z3chip "present"
    else
        kv "Z3Chip variable" "absent / нет"
        fact z3chip "absent"
    fi
    if [ "$IS_ROOT" = 1 ]; then
        note "SMBIOS types 0, 1, 2, 3 (dmidecode, no serial numbers or UUID):"
        dmi -t 0 -t 1 -t 2 -t 3 | smbsafe
    else
        note "SMBIOS details from dmidecode: need sudo / нужен sudo"
    fi
}

s_cpu() {
    local f=/sys/devices/system/cpu/cpu0/cpufreq mx mn mc
    kv "Model" "$(cpuf 'model name')"
    kv "Family / model / stepping" "$(cpuf 'cpu family') / $(cpuf model) / $(cpuf stepping)"
    mc=$(cpuf microcode)
    kv "Microcode" "$mc"
    kv "Logical CPUs" "$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)"
    kv "Cores per socket" "$(cpuf 'cpu cores')"
    if grep -q -w svm /proc/cpuinfo 2>/dev/null; then
        kv "SVM (AMD-V)" "on"
    elif grep -q -w vmx /proc/cpuinfo 2>/dev/null; then
        kv "VMX (VT-x)" "on"
    else
        kv "Virtualization flag" "off (no svm or vmx in cpuinfo)"
    fi
    kv "cpufreq driver" "$(sv $f/scaling_driver)"
    kv "Governor" "$(sv $f/scaling_governor)"
    kv "amd_pstate" "$(sv /sys/devices/system/cpu/amd_pstate/status)"
    kv "Boost" "$(sv /sys/devices/system/cpu/cpufreq/boost)$(sv $f/boost)"
    mx=$(sv $f/cpuinfo_max_freq)
    mn=$(sv $f/cpuinfo_min_freq)
    [ -n "$mx" ] && kv "Max / min MHz" "$((mx / 1000)) / $((${mn:-0} / 1000))"
    fact cpu "$(cpuf 'model name')"
    fact microcode "$mc"
    if [ "$IS_ROOT" = 1 ]; then
        note "SMBIOS type 4 (dmidecode):"
        dmi -t 4 | grep -E 'Information|Socket Designation|Version|Voltage|External Clock|Max Speed|Current Speed|Core Count|Core Enabled|Thread Count|Status'
    fi
}

mem_from_udev() {
    awk -F= -v facts="$FACTS" '
        function gib(b) { return (b == "" ? "?" : sprintf("%g GiB", b / 1073741824)) }
        function loc(n) { return val[n, "LOCATOR"] (val[n, "BANK_LOCATOR"] != "" ? " / " val[n, "BANK_LOCATOR"] : "") }
        /^MEMORY_ARRAY_NUM_DEVICES=/ { slots = $2 }
        /^MEMORY_ARRAY_MAX_CAPACITY=/ { maxcap = $2 }
        /^MEMORY_ARRAY_EC_TYPE=/ { ec = $2 }
        /^MEMORY_DEVICE_[0-9]+_/ {
            k = $1; sub(/^MEMORY_DEVICE_/, "", k); n = k; sub(/_.*/, "", n); sub(/^[0-9]+_/, "", k)
            if (!(n in seen)) { seen[n] = 1; ord[++cnt] = n }
            val[n, k] = substr($0, index($0, "=") + 1)
        }
        END {
            if (slots != "") printf "    slots %s, max capacity %s, error correction: %s\n", slots, gib(maxcap), (ec == "" ? "?" : ec)
            for (i = 1; i <= cnt; i++) {
                n = ord[i]
                if (val[n, "PRESENT"] == "0" || val[n, "SIZE"] == "") { printf "    %-32s empty / пусто\n", loc(n); continue }
                tot += val[n, "SIZE"]; mods++
                printf "    %-32s %s %s %s, %s MT/s (configured %s), %s %s, rank %s, %s V\n", loc(n), gib(val[n, "SIZE"]),
                    val[n, "TYPE"], val[n, "FORM_FACTOR"], val[n, "SPEED_MTS"], val[n, "CONFIGURED_SPEED_MTS"],
                    val[n, "MANUFACTURER"], val[n, "PART_NUMBER"], val[n, "RANK"], val[n, "CONFIGURED_VOLTAGE"]
            }
            print "mem_installed=" tot >> facts
            print "mem_modules=" mods >> facts
        }'
}

mem_from_dmi() {
    awk -v facts="$FACTS" '
        function bytes(s, a) { split(s, a, " "); return a[1] * (a[2] ~ /^T/ ? 1099511627776 : a[2] ~ /^G/ ? 1073741824 : a[2] ~ /^M/ ? 1048576 : a[2] ~ /^[kK]/ ? 1024 : 0) }  # dmidecode prints GB or, newer ones, GiB
        /^Physical Memory Array/ { sec = "arr"; next }
        /^Memory Device/ { sec = "dev"; n++; next }
        /^[^\t]/ { sec = ""; next }
        sec != "" && /^\t[^\t]/ {
            line = substr($0, 2); p = index(line, ": "); if (!p) next
            k = substr(line, 1, p - 1); v = substr(line, p + 2)
            if (sec == "arr") arr[k] = v; else d[n, k] = v
        }
        END {
            if ("Number Of Devices" in arr) printf "    slots %s, max capacity %s, error correction: %s\n", arr["Number Of Devices"], arr["Maximum Capacity"], arr["Error Correction Type"]
            for (i = 1; i <= n; i++) {
                loc = d[i, "Locator"] (d[i, "Bank Locator"] != "" ? " / " d[i, "Bank Locator"] : "")
                if (d[i, "Size"] == "" || d[i, "Size"] ~ /^No Module|^0 /) { printf "    %-32s empty / пусто\n", loc; continue }
                mods++; tot += bytes(d[i, "Size"])
                printf "    %-32s %s %s %s, %s (configured %s), %s %s, rank %s, %s\n", loc, d[i, "Size"], d[i, "Type"],
                    d[i, "Form Factor"], d[i, "Speed"], d[i, "Configured Memory Speed"], d[i, "Manufacturer"],
                    d[i, "Part Number"], d[i, "Rank"], d[i, "Configured Voltage"]
            }
            print "mem_installed=" tot >> facts
            print "mem_modules=" mods >> facts
        }'
}

s_mem() {
    local mt sw
    mt=$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo 2>/dev/null)
    sw=$(awk '/^SwapTotal:/ { print $2 }' /proc/meminfo 2>/dev/null)
    kv "Seen by the OS (MemTotal)" "$(awk -v k="$mt" 'BEGIN { printf "%.2f GiB", k / 1048576 }')"
    kv "Swap" "$(awk -v k="$sw" 'BEGIN { printf "%.2f GiB", k / 1048576 }')"
    fact mem_os_kb "$mt"
    if [ "$IS_ROOT" = 1 ] && have dmidecode && [ -r /sys/firmware/dmi/tables/DMI ]; then
        note "Modules (SMBIOS types 16 and 17, dmidecode; no serial numbers):"
        T 15 dmidecode -q -d /dev/null -t 16 -t 17 2>/dev/null | mem_from_dmi
    elif have udevadm; then
        note "Modules (SMBIOS type 17 from the udev database; no serial numbers):"
        T 10 udevadm info -q property -p /sys/devices/virtual/dmi/id 2>/dev/null | mem_from_udev
    else
        note "Modules: need udevadm or sudo with dmidecode / нужен udevadm или sudo"
    fi
}

s_gpu() {
    local d n=0 id drv name v vram sum=""
    for d in /sys/bus/pci/devices/*; do
        case $(sv "$d/class") in 0x03*) ;; *) continue ;; esac
        n=$((n + 1))
        id=$(pci_id "$d")
        drv=$(drvname "$d")
        name=$(pci_name "$id")
        note "GPU $n: ${d##*/} [$id] $name"
        kv "  vendor" "$(vendor_name "${id%%:*}")"
        if [ -n "$drv" ]; then
            kv "  driver" "$drv"
        else
            kv "  driver" "none: no driver is bound, the vendor's driver is not loaded / драйвер производителя не загружен"
        fi
        [ "$(sv "$d/boot_vga")" = 1 ] && kv "  boot display" "yes (the firmware showed its screens here)"
        kv "  VBIOS" "$(sv "$d/vbios_version")"
        v=$(sv "$d/mem_info_vram_total")
        vram=$(mib "$v")
        [ -n "$v" ] && kv "  VRAM (dedicated)" "$vram; on an integrated GPU this is the UMA frame buffer set by the firmware"
        v=$(sv "$d/mem_info_vis_vram_total")
        [ -n "$v" ] && kv "  CPU-visible VRAM" "$(mib "$v")"
        v=$(sv "$d/mem_info_gtt_total")
        [ -n "$v" ] && kv "  GTT (shared system memory)" "$(mib "$v")"
        kv "  PCIe link" "$(pcilink "$d")"
        sum="$sum${sum:+; }$name [${drv:-no driver}${vram:+, VRAM $vram}]"
    done
    [ "$n" -gt 0 ] || note "no display controller on PCI / видеоадаптер на PCI не найден"
    [ -r /proc/driver/nvidia/version ] && kv "NVIDIA driver" "$(head -n 1 /proc/driver/nvidia/version)"
    if [ "$IS_ROOT" = 0 ] && have glxinfo && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; }; then
        note "glxinfo -B (OpenGL as the desktop sees it):"
        T 15 glxinfo -B 2>/dev/null | grep -E 'renderer string|core profile version string|^OpenGL version string|Video memory|Dedicated video memory|Total available memory|Unified memory|Device:|Version:' |
            sed 's/^ *//' | ind
    else
        note "glxinfo: not run (not installed, no desktop session, or run with sudo) / не запускался"
    fi
    fact gpu "$sum"
}

# Manufacturer code, product code and model name from a cached EDID; never the serial number.
edid_name() {
    rd "$1" | od -An -tu1 -v | awk '
        { for (i = 1; i <= NF; i++) b[n++] = $i }
        END {
            if (n < 128) exit
            m = b[8] * 256 + b[9]
            printf "%c%c%c %04X", 64 + int(m / 1024) % 32, 64 + int(m / 32) % 32, 64 + m % 32, b[10] + 256 * b[11]
            for (o = 54; o <= 108; o += 18)
                if (b[o] == 0 && b[o + 1] == 0 && b[o + 2] == 0 && b[o + 3] == 252) {
                    s = ""
                    for (i = o + 5; i < o + 18 && b[i] != 10; i++) s = s sprintf("%c", (b[i] >= 32 && b[i] < 127) ? b[i] : 46)
                    sub(/ +$/, "", s)
                    printf " %s", s
                }
        }'
}

# Connection type from the DRM connector name (card0-HDMI-A-1 and so on).
conn_type() {
    case $1 in
    *-eDP-* | *-LVDS-* | *-DSI-*) printf 'internal' ;;
    *-DP-*) printf 'DisplayPort' ;;
    *-HDMI-*) printf 'HDMI' ;;
    *-DVI-*) printf 'DVI' ;;
    *-VGA-*) printf 'VGA' ;;
    *-Virtual-*) printf 'virtual' ;;
    *) printf 'other' ;;
    esac
}
s_display() {
    local c st mode mon n=0
    for c in /sys/class/drm/card[0-9]*-*; do
        [ -r "$c/status" ] || continue
        case ${c##*/} in *-Writeback-*) continue ;; esac # not a socket
        n=$((n + 1))
        st=$(sv "$c/status")
        mode=$(sv "$c/modes")
        mon=""
        [ "$st" = connected ] && mon=$(edid_name "$c/edid")
        printf '  %-18s %-12s %-13s %s%s\n' "${c##*/}" "$(conn_type "${c##*/}")" "$st" "${mode:+preferred mode $mode}" "${mon:+, monitor $mon}"
    done
    [ "$n" -gt 0 ] || note "no DRM connectors / разъёмов DRM нет"
}

s_problems() {
    local d drv n=0
    note "PCI devices without a driver (bridges and host bridges without one are normal) / Устройства PCI без драйвера:"
    for d in /sys/bus/pci/devices/*; do
        [ -r "$d/vendor" ] || continue
        drv=$(drvname "$d")
        [ -n "$drv" ] && continue
        printf '    %s [%s] %s\n' "${d##*/}" "$(sv "$d/class" | cut -c3-6)" "$(pci_name "$(pci_id "$d")")"
        n=$((n + 1))
    done
    [ "$n" -gt 0 ] || note "  none / нет"
    fact pci_nodriver "$n"
    if [ -z "$KSRC" ]; then
        skip "kernel log is not readable for this user (run with sudo) / журнал ядра недоступен (запустите с sudo)"
        return 0
    fi
    note "Driver, firmware and bus failures in the kernel log, this boot (last 80) / Сбои драйверов, прошивок и шин:"
    klog | grep -i -E "$DEV_RE" | nofw >"$TMPD/devfail"
    tail -n 80 "$TMPD/devfail" | ind | none_if_empty
    fact dev_fail "$(wc -l <"$TMPD/devfail")"
}

# Reads the last journal lines of one boot on stdin and says how that boot ended.
classify_end() {
    awk '
        /Journal stopped|Reached target (System )?(Reboot|Power-?[Oo]ff|Shutdown|Halt|Kexec)|Shutting down\.|System is (rebooting|powering down|powering off|halting)|reboot: (Restarting|Power down)|systemd-shutdown/ { clean = 1 }
        /Kernel panic|Oops|BUG: / { panic = 1 }
        /PM: suspend entry|PM: hibernation entry|Entering sleep state|Performing sleep operation/ { sleep = 1 }
        /PM: suspend exit|PM: hibernation exit|System returned from sleep|Waking up from system sleep/ { sleep = 0 }
        END {
            if (clean) print "clean shutdown or reboot / штатно"
            else if (panic) print "ABRUPT after a kernel panic or oops / оборвалась после паники ядра"
            else if (sleep) print "ABRUPT while asleep, no resume record / оборвалась во сне"
            else print "ABRUPT: no shutdown record (freeze, crash, power loss or reset) / ОБОРВАЛАСЬ"
        }'
}

s_history() {
    local cutoff i tail last end checked=0 abrupt=0
    if have last; then
        note "Reboot and shutdown records, 30 days (last -x; a boot with no shutdown before the next one ended abruptly) / Записи о перезагрузках:"
        { T 10 last -x -F --since -30days reboot shutdown 2>/dev/null || T 10 last -x -F reboot shutdown 2>/dev/null; } |
            grep -E '^(reboot|shutdown) ' | head -n 40 | ind | none_if_empty
    fi
    if [ "$JOK" != 1 ]; then
        skip "no access to the system journal (run with sudo, or there is no systemd journal) / нет доступа к системному журналу (запустите с sudo)"
        return 0
    fi
    note "Boots in the journal (journalctl --list-boots, last 30) / Загрузки в журнале:"
    T 30 journalctl --list-boots --no-pager -q 2>/dev/null | tail -n 30 | ind
    note "How each previous boot ended, newest first (up to 25 boots within 30 days) / Как закончилась каждая прошлая загрузка:"
    cutoff=$(date -d '30 days ago' '+%Y-%m-%dT%H:%M:%S' 2>/dev/null)
    i=1
    while [ "$i" -le 25 ]; do
        tail=$(T 20 journalctl --system -b "-$i" -n 40 -o short-iso -q --no-pager 2>/dev/null) || break
        [ -n "$tail" ] || break
        last=$(printf '%s\n' "$tail" | tail -n 1 | cut -d' ' -f1)
        [ -n "$cutoff" ] && [[ "$last" < "$cutoff" ]] && break
        end=$(printf '%s\n' "$tail" | classify_end)
        checked=$((checked + 1))
        case $end in ABRUPT*) abrupt=$((abrupt + 1)) ;; esac
        printf '    boot -%-3s last entry %-26s %s\n' "$i" "$last" "$end"
        i=$((i + 1))
    done
    [ "$checked" -gt 0 ] || note "  no previous boots in the journal (it may be kept in RAM only) / прошлых загрузок в журнале нет"
    fact boots_checked "$checked"
    fact boots_abrupt "$abrupt"
    note "Kernel events over 30 days: machine checks, panics, lockups, GPU hangs, reset reasons (last 120) / События ядра за 30 дней:"
    T 120 journalctl --system -k --since=-30d -o short-iso -q --no-pager 2>/dev/null | grep -i -E "$HIST_RE" | nofw >"$TMPD/hist"
    tail -n 120 "$TMPD/hist" | ind | none_if_empty
    fact hist_mce "$(grep -c -i -E 'mce: |machine check|hardware error' "$TMPD/hist")"
    fact hist_crash "$(grep -c -i -E 'kernel panic|Oops|BUG: |lockup|hung_task|blocked for more than|rcu.*(stall|self-detected)' "$TMPD/hist")"
    fact hist_gpu "$(grep -c -i -E 'GPU reset|ring .* timeout|amdgpu.*(hang|timeout|GPU fault)' "$TMPD/hist")"
}

s_mce() {
    local m f n
    if [ -d /sys/devices/system/machinecheck ]; then
        kv "Machine check driver" "present"
    else
        kv "Machine check driver" "absent"
    fi
    for m in /sys/devices/system/edac/mc/mc[0-9]*; do
        [ -d "$m" ] && kv "EDAC ${m##*/}" "corrected $(sv "$m/ce_count"), uncorrected $(sv "$m/ue_count")"
    done
    if [ -n "$KSRC" ]; then
        note "Machine check lines in this boot's kernel log / Строки MCE в журнале ядра:"
        klog | grep -i -E 'mce: |machine check|hardware error' | tail -n 40 | ind | none_if_empty
    fi
    if [ "$IS_ROOT" != 1 ]; then
        note "pstore, rasdaemon and mcelog: need sudo / нужен sudo"
        return 0
    fi
    if have ras-mc-ctl; then
        note "rasdaemon summary:"
        T 20 ras-mc-ctl --summary 2>/dev/null | ind
        note "rasdaemon errors (last 40):"
        T 20 ras-mc-ctl --errors 2>/dev/null | tail -n 40 | ind
    fi
    [ -r /var/log/mcelog ] && {
        note "/var/log/mcelog (last 40):"
        tail -n 40 /var/log/mcelog | ind
    }
    note "pstore (kernel logs saved across a crash) / журналы ядра, сохранённые при сбое:"
    n=0
    for f in /sys/fs/pstore/*; do
        [ -e "$f" ] || continue
        n=$((n + 1))
        printf '    %s %s bytes\n' "${f##*/}" "$(wc -c <"$f" 2>/dev/null)"
    done
    for f in $(ls -1d /sys/fs/pstore/dmesg-* 2>/dev/null | tail -n 2); do
        note "  last 40 lines of ${f##*/}:"
        T 5 tail -n 40 "$f" 2>/dev/null | ind
    done
    if [ -d /var/lib/systemd/pstore ]; then
        for f in $(ls -1t /var/lib/systemd/pstore 2>/dev/null | head -n 3); do
            n=$((n + 1))
            note "  /var/lib/systemd/pstore/$f: $(ls /var/lib/systemd/pstore/"$f" 2>/dev/null | tr '\n' ' ')"
        done
        f=$(ls -1t /var/lib/systemd/pstore 2>/dev/null | head -n 1)
        if [ -n "$f" ] && [ -r "/var/lib/systemd/pstore/$f/dmesg.txt" ]; then
            note "  last 40 lines of the newest saved dmesg.txt:"
            tail -n 40 "/var/lib/systemd/pstore/$f/dmesg.txt" | ind
        fi
    fi
    [ "$n" -gt 0 ] || note "  empty / пусто"
    fact pstore "$n"
}

s_kernel() {
    if [ -z "$KSRC" ]; then
        skip "kernel log is not readable for this user (run with sudo) / журнал ядра недоступен (запустите с sudo)"
        return 0
    fi
    kv "Source" "$KSRC"
    note "Boot, firmware and memory lines / Строки о загрузке, прошивке и памяти:"
    klog | grep -E "$BOOT_RE" | head -n 60 | smbsafe 'DMI: ' | ind | none_if_empty "not in the log any more (it keeps only recent lines) / в журнале их уже нет"
    note "Warnings and errors, this boot (last 150) / Предупреждения и ошибки:"
    klog_warn | nofw >"$TMPD/kwarn"
    tail -n 150 "$TMPD/kwarn" | ind | none_if_empty
    fact kwarn "$(wc -l <"$TMPD/kwarn")"
}

s_journal() {
    if [ "$JOK" != 1 ]; then
        skip "no access to the system journal (run with sudo, or there is no systemd journal) / нет доступа к системному журналу (запустите с sudo)"
        if [ -r /var/log/syslog ] || [ -r /var/log/messages ]; then
            note "syslog errors (last 80):"
            grep -h -i -E 'error|fail|critical|panic' /var/log/syslog /var/log/messages 2>/dev/null | nofw | tail -n 80 | ind
        fi
        return 0
    fi
    note "This boot: errors of services, not the kernel (priority err and worse, last 120) / Текущая загрузка: ошибки служб:"
    T 40 journalctl --system -b 0 -p err -n 500 -o short-iso -q --no-pager 2>/dev/null | grep -v ' kernel: ' | nofw |
        tail -n 120 | ind | none_if_empty
    if [ -n "$(T 20 journalctl --system -b -1 -n 1 -q --no-pager 2>/dev/null)" ]; then
        note "Previous boot (-1): errors, kernel included (last 60) / Прошлая загрузка: ошибки:"
        T 40 journalctl --system -b -1 -p err -n 60 -o short-iso -q --no-pager 2>/dev/null | nofw | ind | none_if_empty
        note "Previous boot (-1): its last 100 lines, how it ended / Прошлая загрузка: последние 100 строк:"
        T 40 journalctl --system -b -1 -n 100 -o short-iso -q --no-pager 2>/dev/null | nofw | ind
    else
        note "No previous boot in the journal (it may be kept in RAM only) / Прошлой загрузки в журнале нет"
    fi
}

taint_letters() {
    awk -v t="${1:-0}" 'BEGIN {
        split("P F S R M B U D A W C I O E L K X T N", L, " ")
        split("proprietary-module forced-load smp-unsafe forced-unload machine-check bad-page user-request died-oops-or-bug acpi-table-overridden kernel-warning staging firmware-workaround out-of-tree-module unsigned-module soft-lockup live-patched auxiliary randstruct test", D, " ")
        s = ""
        for (i = 0; i < 19; i++) if (int(t / 2 ^ i) % 2) s = s (s == "" ? "" : ", ") L[i + 1] " " D[i + 1]
        print (s == "" ? "none" : s)
    }'
}

s_taint() {
    local t m v
    t=$(sv /proc/sys/kernel/tainted)
    kv "Kernel taint" "${t:-?}: $(taint_letters "$t")"
    fact taint "${t:-?} ($(taint_letters "$t"))"
    note "Modules that taint the kernel / Модули с метками:"
    for m in /sys/module/*/taint; do
        v=$(sv "$m")
        [ -n "$v" ] && printf '    %s %s\n' "$(basename "$(dirname "$m")")" "$v"
    done | none_if_empty
    note "Loaded modules that matter here / Загруженные модули, важные для разбора:"
    awk '{ print $1 }' /proc/modules 2>/dev/null | grep -x -E "$MOD_RE" | sort | tr '\n' ' ' | fold -s -w 110 | ind
    echo
    if grep -q -E '^(it87|nct6775|nct6683|w83627ehf|w83627hf|f71882fg|sch5627) ' /proc/modules 2>/dev/null; then
        note "note: a Super I/O monitoring driver is loaded, so the OS reads the board's monitoring chip / примечание: загружен драйвер микросхемы мониторинга Super I/O"
    fi
}

s_sensors() {
    local h n f v lab any=0
    note "Only CPU, GPU and drive drivers are read; Super I/O fan and voltage chips, ACPI thermal zones and SMBus sensors are skipped on purpose."
    note "Читаются только драйверы процессора, видео и дисков; Super I/O, термозоны ACPI и датчики на SMBus пропущены намеренно."
    for h in /sys/class/hwmon/hwmon*; do
        [ -r "$h/name" ] || continue
        n=$(sv "$h/name")
        case "$SAFE_HWMON" in
        *" $n "*) ;;
        *)
            case $n in
            acpitz) note "$n: skipped, ACPI thermal zone (its read runs firmware code that accesses the Super I/O chip)" ;;
            *) note "$n: skipped, not on the safe list / не в списке безопасных" ;;
            esac
            continue
            ;;
        esac
        any=1
        note "$n (${h##*/}):"
        for f in "$h"/temp*_input "$h"/in*_input "$h"/power*_average "$h"/power*_input "$h"/fan*_input "$h"/freq*_input; do
            [ -r "$f" ] || continue
            v=$(rd "$f")
            [ -n "$v" ] || continue
            lab=$(rd "${f%_*}_label")
            case ${f##*/} in
            temp*) v=$(awk -v x="$v" 'BEGIN { printf "%.1f C", x / 1000 }') ;;
            in*) v="$v mV" ;;
            power*) v=$(awk -v x="$v" 'BEGIN { printf "%.1f W", x / 1000000 }') ;;
            fan*) v="$v rpm" ;;
            freq*) v=$(awk -v x="$v" 'BEGIN { printf "%d MHz", x / 1000000 }') ;;
            esac
            printf '    %-16s %-10s %s\n' "${f##*/}" "${lab:--}" "$v"
        done
    done
    [ "$any" = 1 ] || note "no sensors from safe drivers / безопасных датчиков нет"
}

s_pci() {
    local d a cc id drv link n=0
    for d in /sys/bus/pci/devices/*; do
        [ -r "$d/vendor" ] || continue
        n=$((n + 1))
        a=${d##*/}
        cc=$(sv "$d/class")
        cc=${cc#0x}
        id=$(pci_id "$d")
        drv=$(drvname "$d")
        link=$(pcilink "$d")
        printf '  %s [%s] %s rev %s sub %s:%s | %s | %s | driver %s%s\n' "${a#0000:}" "${cc:0:4}" "$id" "$(sv "$d/revision" | cut -c3-)" \
            "$(sv "$d/subsystem_vendor" | cut -c3-)" "$(sv "$d/subsystem_device" | cut -c3-)" "$(pci_class "${cc:0:2}:${cc:2:2}")" \
            "$(pci_name "$id")" "${drv:--}" "${link:+ | link $link}"
    done
    [ "$n" -gt 0 ] || note "no PCI devices in sysfs / устройств PCI нет"
    fact pci_count "$n"
}

s_usb() {
    local d n=0 i drv
    for d in /sys/bus/usb/devices/*; do
        [ -r "$d/idVendor" ] || continue
        n=$((n + 1))
        drv=""
        for i in "$d"/"${d##*/}":*; do
            [ -e "$i/driver" ] && drv="$drv $(drvname "$i")"
        done
        drv=$(printf '%s\n' $drv | sort -u | tr '\n' ' ')
        printf '  %-10s %s:%s USB %s, %s Mbit/s | %s %s | %s\n' "${d##*/}" "$(sv "$d/idVendor")" "$(sv "$d/idProduct")" \
            "$(sv "$d/version" | tr -d ' ')" "$(sv "$d/speed")" "$(sv "$d/manufacturer")" "$(sv "$d/product")" "${drv:--}"
    done
    [ "$n" -gt 0 ] || note "no USB devices in sysfs / устройств USB нет"
}

s_net() {
    local n i drv mac virt=0 wl spd
    for n in /sys/class/net/*; do
        i=${n##*/}
        [ "$i" = lo ] && continue
        if [ ! -e "$n/device" ]; then
            virt=$((virt + 1))
            continue
        fi
        drv=$(drvname "$n/device")
        mac=$(sv "$n/address")
        mac="${mac:0:8}:xx:xx:xx"
        wl=""
        { [ -d "$n/wireless" ] || [ -e "$n/phy80211" ]; } && wl=", wireless"
        spd=$(rd "$n/speed")
        case $spd in '' | -1) spd="?" ;; esac
        printf '  %-16s driver %s%s | bus %s | MAC %s | state %s, carrier %s, speed %s Mbit/s\n' "$i" "${drv:--}" "$wl" \
            "$(basename "$(readlink "$n/device" 2>/dev/null)")" "$mac" "$(sv "$n/operstate")" "$(rd "$n/carrier")" "$spd"
        if have ethtool; then
            T 5 ethtool -i "$i" 2>/dev/null | grep -E '^(driver|version|firmware-version):' | ind
        fi
    done
    note "virtual interfaces (not listed): $virt / виртуальных интерфейсов: $virt"
    note "IP addresses and Wi-Fi network names are not collected / IP-адреса и имена сетей Wi-Fi не собираются"
}

s_disks() {
    local d
    if have lsblk; then
        T 15 lsblk -d -n -e 1,7 -o NAME,TYPE,SIZE,ROTA,TRAN,MODEL 2>/dev/null | grep -v -E '^(zram|loop)' | ind
    fi
    for d in /sys/class/nvme/nvme*; do
        [ -e "$d/model" ] && kv "${d##*/}" "$(sv "$d/model"), firmware $(sv "$d/firmware_rev")"
    done
    for d in /sys/block/sd*; do
        [ -e "$d/device/model" ] && kv "${d##*/}" "$(sv "$d/device/vendor") $(sv "$d/device/model"), firmware $(sv "$d/device/rev")"
    done
    return 0
}

efivar_bytes() {
    [ -r "$EV/$1" ] || return 1
    T 5 cat -- "$EV/$1" 2>/dev/null | od -An -tx1 -v | tr -s ' \n' '  ' | sed 's/^ //' | cut -d' ' -f5-
}
# od -tx1 output on stdin -> "    0000: xx xx ...  |ascii|"
hexfmt() {
    awk '
        function hv(x, d, i) { d = 0; for (i = 1; i <= length(x); i++) d = d * 16 + index("0123456789abcdef", substr(x, i, 1)) - 1; return d }
        { for (i = 1; i <= NF; i++) b[n++] = $i }
        END {
            for (o = 0; o < n; o += 16) {
                h = ""; a = ""
                for (i = o; i < o + 16 && i < n; i++) { h = h " " b[i]; c = hv(b[i]); a = a ((c >= 32 && c < 127) ? sprintf("%c", c) : ".") }
                printf "    %04x:%-48s  |%s|\n", o, h, a
            }
        }'
}
dumpvar() {
    local f=$1 b=${1##*/} tmp=$TMPD/var size attr
    if ! T 5 cat -- "$f" >"$tmp" 2>"$TMPD/varerr"; then
        printf '  var %s\n    failed / не удалось: %s\n' "$b" "$(head -n 1 "$TMPD/varerr")"
        return 0
    fi
    size=$(($(wc -c <"$tmp") - 4))
    if [ "$size" -lt 0 ]; then
        printf '  var %s\n    empty read / пустое чтение\n' "$b"
        return 0
    fi
    attr=$(od -An -tx1 -N4 "$tmp" | awk '{ printf "0x%s%s%s%s", $4, $3, $2, $1 }')
    printf '  var %s attr=%s size=%d\n' "$b" "$attr" "$size"
    tail -c +5 "$tmp" | head -c 65536 | od -An -tx1 -v | hexfmt
    [ "$size" -le 65536 ] || note "  (first 65536 bytes shown)"
}
s_efivars() {
    local f n=0
    note "Format: 'var NAME-GUID attr=ATTRIBUTES size=BYTES', then 16 bytes per line (offset: hex bytes |ASCII|). Only variables the firmware made visible to the OS (runtime access) appear."
    if [ ! -d "$EV" ] || [ -z "$(ls -A "$EV" 2>/dev/null)" ]; then
        skip "no efivarfs at $EV (legacy BIOS boot or not mounted) / нет efivarfs"
        fact efivars 0
        return 0
    fi
    for f in "$EV"/*-"$GUID_CHIP" "$EV"/*-"$GUID_APP"; do
        [ -e "$f" ] || continue
        n=$((n + 1))
        dumpvar "$f"
    done
    [ "$n" -gt 0 ] || note "no Z3Chip or Z3Novo* variables visible to the OS / переменных Z3Chip и Z3Novo* не видно"
    fact efivars "$n"
}

# ---------------------------------------------------------------- masking

tok() { [ "${#2}" -ge 2 ] && printf '%s\t%s\n' "$1" "$2" >>"$TMPD/tok.raw"; }
host_tok() {
    local h=$1 id
    id=$(osr ID)
    case $h in "" | localhost | localhost.localdomain | localdomain) return 0 ;; esac
    [ "$(printf '%s' "$h" | tr 'A-Z' 'a-z')" = "$id" ] && return 0 # a default host name such as "fedora" is not personal
    tok '<host>' "$h"
    tok '<host>' "${h%%.*}"
    case $h in *-*) tok '<host>' "$(printf '%s' "${h%%.*}" | sed 's/-/--/g')" ;; esac # LVM names double the dashes
}
tokens_build() {
    local u name uid gecos home g l n s f id
    : >"$TMPD/tok.raw"
    id=$(osr ID)
    host_tok "$(uname -n 2>/dev/null)"
    [ -r /etc/hostname ] && host_tok "$(head -n 1 /etc/hostname)"
    [ -r /etc/machine-info ] && host_tok "$(sed -n 's/^PRETTY_HOSTNAME=//p' /etc/machine-info | sed 's/^"//; s/"$//')"
    for u in "${USER:-}" "${LOGNAME:-}" "${SUDO_USER:-}" "$(id -un 2>/dev/null)"; do
        [ "$u" = root ] || [ "$u" = "$id" ] || tok '<user>' "$u"
    done
    # local accounts only (getent could ask a network directory)
    cat /etc/passwd 2>/dev/null |
        while IFS=: read -r name _ uid _ gecos home _; do
            case $uid in '' | *[!0-9]*) continue ;; esac
            [ "$uid" -ge 1000 ] && [ "$uid" -lt 60000 ] || continue
            [ "$name" = "$id" ] || tok '<user>' "$name"
            g=${gecos%%,*}
            [ "${#g}" -ge 3 ] && tok '<user>' "$g"
            case $home in / | /root | /home | /var/home | '') ;; *) tok '~' "$home" ;; esac
        done
    if have nmcli; then
        T 10 nmcli -t -f NAME,TYPE connection show 2>/dev/null | head -n 60 | while IFS= read -r l; do
            case $l in
            *:802-11-wireless)
                n=$(printf '%s' "${l%:802-11-wireless}" | sed 's/\\:/:/g; s/\\\\/\\/g')
                tok '<wifi>' "$n"
                s=$(T 5 nmcli -t -g 802-11-wireless.ssid connection show "$n" 2>/dev/null | head -n 1)
                tok '<wifi>' "$s"
                ;;
            esac
        done
    fi
    # only when the wireless stack is already loaded: on a machine without it, iw's netlink lookup could load cfg80211
    if have iw && [ -d /sys/class/ieee80211 ] && [ -n "$(ls -A /sys/class/ieee80211 2>/dev/null)" ]; then
        T 5 iw dev 2>/dev/null | sed -n 's/^[[:space:]]*ssid //p' | while IFS= read -r s; do tok '<wifi>' "$s"; done
    fi
    if [ "$IS_ROOT" = 1 ]; then
        for f in /var/lib/iwd/*.psk /var/lib/iwd/*.open /var/lib/iwd/*.8021x; do
            [ -e "$f" ] || continue
            n=${f##*/}
            tok '<wifi>' "${n%.*}"
        done
        { grep -h -o 'ssid="[^"]*"' /etc/wpa_supplicant/*.conf 2>/dev/null | sed 's/^ssid="//; s/"$//'
          grep -h '^ssid=' /etc/NetworkManager/system-connections/* 2>/dev/null | sed 's/^ssid=//'; } |
            while IFS= read -r s; do tok '<wifi>' "$s"; done
    fi
    # longest first, so a longer name is masked before a shorter one inside it
    awk -F'\t' '!seen[$0]++ { print length($2) "\t" $0 }' "$TMPD/tok.raw" | sort -t "$(printf '\t')" -k1,1nr | cut -f2- >"$TMPD/tokens"
}

redact_prog() {
    cat <<'AWK'
# Masks personal data in the report. LC_ALL=C: works on bytes. Tokens file: "REPLACEMENT<TAB>TEXT", longest first.
function tokc(c) { return c != "" && index("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_", c) > 0 }
function digc(c) { return c != "" && index("0123456789", c) > 0 }
# Replace a fixed string where it stands as a whole word.
function rep_tok(s, name, repl,    out, p, L, pre, post, okpre, okpost) {
    L = length(name); out = ""
    while ((p = index(s, name)) > 0) {
        pre = (p > 1) ? substr(s, p - 1, 1) : substr(out, length(out), 1)
        post = substr(s, p + L, 1)
        okpre = !tokc(substr(name, 1, 1)) || !tokc(pre)
        okpost = !tokc(substr(name, L, 1)) || !tokc(post)
        if (okpre && okpost) out = out substr(s, 1, p - 1) repl
        else out = out substr(s, 1, p - 1 + L)
        s = substr(s, p + L)
    }
    return out s
}
# Walk every match of re; fix() decides what each one becomes.
function scan(s, re, kind,    out, m, st, ln, pre, post, post2) {
    out = ""
    while (s != "" && match(s, re)) {
        st = RSTART; ln = RLENGTH
        if (ln < 1) { out = out substr(s, 1, st); s = substr(s, st + 1); continue }
        m = substr(s, st, ln)
        pre = (st > 1) ? substr(s, st - 1, 1) : substr(out, length(out), 1)
        post = substr(s, st + ln, 1); post2 = substr(s, st + ln + 1, 1)
        out = out substr(s, 1, st - 1) fix(kind, m, pre, post, post2)
        s = substr(s, st + ln)
    }
    return out s
}
function fix(kind, m, pre, post, post2,    n, i, a, g, sep, r) {
    if (kind == "mac") {                       # keep the maker's first 3 bytes
        n = int((length(m) + 1) / 3)
        if (n < 6) return m
        sep = substr(m, 3, 1); r = substr(m, 1, 8)
        for (i = 4; i <= n; i++) r = r sep "xx"
        return r
    }
    if (kind == "ip4") {
        if (digc(post) || (post == "." && digc(post2)) || pre == "." || digc(pre)) return m
        n = split(m, a, ".")
        for (i = 1; i <= n; i++) if (length(a[i]) > 3 || a[i] + 0 > 255) return m
        return (n == 4) ? "<ip>" : m
    }
    if (kind == "ip6") {                       # "::" with two groups and 4+ hex digits, or the full 8 groups
        if (tokc(pre) || tokc(post)) return m
        n = split(m, a, ":"); g = 0; r = 0
        for (i = 1; i <= n; i++) { if (length(a[i]) > 4) return m; if (a[i] != "") g++; r += length(a[i]) }
        return ((index(m, "::") && g >= 2 && r >= 4) || (n == 8 && g == 8)) ? "<ip>" : m
    }
    if (kind == "uuid") return (tolower(m) in keep) ? m : "<uuid>"
    if (kind == "hex32") return (tokc(pre) || tokc(post)) ? m : "<id>"
    if (kind == "email") return (m ~ /[.](service|socket|target|mount|automount|timer|slice|scope|device|path|swap)$/) ? m : "<email>"
    if (kind == "serial") { match(m, /[:=][ \t]*/); return substr(m, 1, RSTART + RLENGTH - 1) "<serial>" }
    if (kind == "ssid") { match(m, /[Ss][Ss][Ii][Dd]([ \t]*[:=][ \t]*|[ \t]+)/); return substr(m, 1, RSTART + RLENGTH - 1) "<wifi>" }
    return m
}
BEGIN {
    keep["7a3c5d11-42e9-4f60-9d1b-5e7713a8c402"] = 1   # Z3Chip
    keep["7c9d3f2a-41b6-4e1d-9a57-2f8e116cd4a0"] = 1   # Z3Novo* variables
    keep["8be4df61-93ca-11d2-aa0d-00e098032b8c"] = 1   # EFI global variables
    H = "[0-9A-Fa-f]"
    RE_UUID = H H H H H H H H "-" H H H H "-" H H H H "-" H H H H "-" H H H H H H H H H H H H
    RE_HEX32 = ""; for (i = 0; i < 32; i++) RE_HEX32 = RE_HEX32 H
    RE_MAC = H H "[:-]" H H "([:-]" H H ")+"
    RE_IP4 = "[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+"
    RE_IP6 = "[0-9A-Fa-f:]*:[0-9A-Fa-f:]*"
    RE_EMAIL = "[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+([.][A-Za-z0-9-]+)*[.][A-Za-z][A-Za-z]+"
    RE_SERIAL = "([Ss][Ee][Rr][Ii][Aa][Ll]([ _-]?([Nn][Uu][Mm][Bb][Ee][Rr]|[Nn][Oo]))?|S/N)[ \t]*[:=][ \t]*[^ \t,;]+"
    RE_SSID = "[Ss][Ss][Ii][Dd]([ \t]*[:=][ \t]*|[ \t]+)('[^']*'|\"[^\"]*\"|[^ \t,;]+)"
    K5 = "[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]"
    RE_KEY = K5 "-" K5 "-" K5 "-" K5 "-" K5
    nt = 0
    if (tokfile != "")
        while ((getline line < tokfile) > 0) {
            t = index(line, "\t")
            if (t > 1 && t < length(line)) { nt++; trep[nt] = substr(line, 1, t - 1); tname[nt] = substr(line, t + 1) }
        }
}
/^    [0-9a-f][0-9a-f][0-9a-f][0-9a-f]: / { print; next }   # hex dumps of UEFI variables stay as they are
{
    s = $0
    gsub(/[A-Za-z][A-Za-z0-9+.-]*:\/\/[^ \t'"<>]+/, "<url>", s)
    gsub(/COMMAND=.*/, "COMMAND=<cmd>", s)
    s = scan(s, RE_EMAIL, "email")
    # names before paths, so a home folder with a space in its name goes as a whole
    for (i = 1; i <= nt; i++) s = rep_tok(s, tname[i], trep[i])
    gsub(/\/(var\/)?home\/[^\/ \t'":;,)]+/, "~", s)
    gsub(/\/Users\/[^\/ \t'":;,)]+/, "~", s)
    gsub(/\\Users\\[^\\ \t'":;,)]+/, "~", s)
    gsub(/\/(run\/)?media\/[^\/ \t'"]+\/[^ \t'"]+/, "/media/<user>/<label>", s)
    gsub(/by-id\/[^ \t'"]+/, "by-id/<id>", s)
    gsub(/wwn-0x[0-9A-Fa-f]+/, "wwn-<id>", s)
    gsub(/nvme-eui[.][0-9A-Fa-f]+/, "nvme-eui.<id>", s)
    s = scan(s, RE_SERIAL, "serial")
    s = scan(s, RE_SSID, "ssid")
    gsub(/[Cc]onnection '[^']*'/, "connection '<wifi>'", s)
    gsub(/'ssid' value '[^']*'/, "'ssid' value '<wifi>'", s)
    gsub(RE_KEY, "<key>", s)
    s = scan(s, RE_UUID, "uuid")
    s = scan(s, RE_MAC, "mac")
    s = scan(s, RE_IP4, "ip4")
    s = scan(s, RE_IP6, "ip6")
    s = scan(s, RE_HEX32, "hex32")
    print s
}
AWK
}
redact() { LC_ALL=C awk -v tokfile="$TMPD/tokens" -f "$TMPD/redact.awk"; }

# ---------------------------------------------------------------- report frame

header() {
    printf '%s\n' "Z3NOVO OS report / Отчёт ОС для Z3NOVO"
    printf '%s\n' "script z3report.sh $VERSION (Linux) | created $NOW_TEXT | run as $RUNAS"
    printf '%s\n' "Собрано: ОС и ядро, время загрузки и аптайм; SMBIOS (BIOS, плата, процессор, модули памяти); микрокод; видео и его память; мониторы; устройства PCI и USB; сетевые адаптеры (без адресов); диски (модель и объём); ошибки ядра и журнала; загрузки, сбои и аппаратные ошибки (MCE) за 30 дней; метки ядра; температуры только от безопасных драйверов (k10temp, amdgpu, nvme); переменные UEFI Z3Chip и Z3Novo* (hex)."
    printf '%s\n' "Исключено: имя компьютера, имена пользователей, серийные номера (и похожие на них уникальные номера в строках SMBIOS), UUID, MAC-адреса (оставлены первые 3 байта), IP-адреса, имена сетей Wi-Fi, пути в домашних папках (заменены на ~), ключ Windows (таблица ACPI MSDM не читается). Скрипт ничего не пишет в систему и не обращается к железу напрямую (порты, /dev/mem, SMBus, микросхема Super I/O, термозоны ACPI)."
    printf '%s\n' "Collected: OS and kernel, boot time and uptime; SMBIOS (BIOS, board, CPU, memory modules); microcode; graphics and its memory; displays; PCI and USB devices; network adapters (no addresses); disks (model and size); kernel and journal errors; boots, crashes and machine checks over 30 days; kernel taint; temperatures from safe drivers only (k10temp, amdgpu, nvme); UEFI variables Z3Chip and Z3Novo* (hex)."
    printf '%s\n' "Excluded: computer name, user names, serial numbers (and serial-like unique numbers in SMBIOS strings), UUIDs, MAC addresses (first 3 bytes kept), IP addresses, Wi-Fi names, home folder paths (shown as ~), the Windows key (ACPI table MSDM is not read). The script writes nothing to the system and does not touch hardware directly (I/O ports, /dev/mem, SMBus, the Super I/O chip, ACPI thermal zones)."
    printf '%s\n' "Masks / Замены: <host> <user> <serial> <uuid> <id> <ip> <email> <wifi> <url> <cmd> <key>, ~ = home folder / домашняя папка, aa:bb:cc:xx:xx:xx = MAC."
}

summary() {
    local mi mm mo
    printf '\n=== [summary] Summary / Кратко\n'
    kv "BIOS" "$(getfact bios)"
    kv "Board" "$(getfact board)"
    kv "CPU" "$(getfact cpu), microcode $(getfact microcode)"
    mi=$(getfact mem_installed)
    mm=$(getfact mem_modules)
    mo=$(getfact mem_os_kb)
    kv "Memory" "$(awk -v i="$mi" -v m="$mm" -v o="$mo" 'BEGIN { if (i != "" && i > 0) printf "%g GiB in %s module(s), ", i / 1073741824, m; printf "the OS sees %.2f GiB", o / 1048576 }')"
    kv "Graphics" "$(fv gpu '?')"
    kv "OS" "$(getfact os), kernel $(getfact kernel)"
    kv "Z3Chip variable" "$(fv z3chip '?')"
    kv "Z3 UEFI variables dumped" "$(fv efivars '?')"
    if [ -z "$(getfact boots_checked)" ]; then
        kv "Abrupt ends of past boots" "unknown, no journal access / неизвестно, нет доступа к журналу"
    elif [ "$(getfact boots_checked)" = 0 ]; then
        kv "Abrupt ends of past boots" "no previous boots in the journal / прошлых загрузок в журнале нет"
    else
        kv "Abrupt ends of past boots" "$(getfact boots_abrupt) of $(getfact boots_checked) checked (30 days)"
    fi
    kv "Machine check lines, 30 days" "$(fv hist_mce 'unknown')"
    kv "Panic/oops/lockup lines, 30d" "$(fv hist_crash 'unknown')"
    kv "GPU hang/reset lines, 30 days" "$(fv hist_gpu 'unknown')"
    kv "Kernel warn+err, this boot" "$(fv kwarn 'unknown, kernel log not readable')"
    kv "Device failure lines, boot" "$(fv dev_fail 'unknown, kernel log not readable')"
    kv "PCI devices without driver" "$(getfact pci_nodriver) of $(getfact pci_count)"
    kv "Kernel taint" "$(fv taint '?')"
    kv "Saved crash logs (pstore)" "$(fv pstore 'not checked, needs sudo')"
}

footer() {
    printf '\n=== [end] End / Конец\n'
    note "Проверьте файл перед отправкой: замазанные места выглядят как <host>, <user>, <ip>, ~ и так далее. Если увидите то, чем не хотите делиться, удалите эту строку."
    note "Check this file before sending it: masked values look like <host>, <user>, <ip>, ~ and so on. If you see anything you do not want to share, delete that line."
}

STEPS_TOTAL=18
STEP_NO=0
run() { # run TAG "TITLE" FUNCTION
    local rc reason
    STEP_NO=$((STEP_NO + 1))
    printf '  [%2d/%d] %s\n' "$STEP_NO" "$STEPS_TOTAL" "$2"
    {
        printf '\n=== [%s] %s\n' "$1" "$2"
        ("$3") 2>"$TMPD/err"
        rc=$?
        if [ "$rc" -ne 0 ]; then
            reason=$(grep -v '^[[:space:]]*$' "$TMPD/err" 2>/dev/null | tail -n 1 | cut -c1-200)
            printf '  failed / не удалось: %s\n' "${reason:-exit code $rc}"
        fi
    } >>"$BODY"
}

out_dir() {
    local d="" c
    if [ "$IS_ROOT" = 1 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
        d=$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)
    fi
    [ -n "$d" ] || d=${HOME:-}
    for c in "$d" "$PWD" "${TMPDIR:-/tmp}"; do
        if [ -n "$c" ] && [ -d "$c" ] && [ -w "$c" ]; then
            printf '%s' "$c"
            return 0
        fi
    done
    printf '/tmp'
}

# Started by a person without root: offer to run again through sudo (sudo asks for the password itself). Yes and sudo
# worked: that run made the report and this one stops. No, no sudo, no terminal, or sudo failed: go on as now.
offer_sudo() {
    local ans=""
    [ "$IS_ROOT" = 1 ] && return 1
    have sudo || return 1
    { [ -t 0 ] && [ -t 1 ]; } || return 1
    say ""
    say "Для полного отчёта нужны права root: модули памяти из SMBIOS, журналы сбоев (pstore), журнал системы. Перезапустить через sudo? Enter или д — да, н — нет."
    say "A full report needs root: memory modules from SMBIOS, saved crash logs (pstore), the system journal. Run again through sudo? Enter or y for yes, n for no."
    printf '[Y/n] '
    read -r ans || return 1
    case $(printf '%s' "$ans" | tr 'A-Z' 'a-z') in
    '' | y | yes | 'д' | 'да' | 'Д' | 'Да' | 'ДА') ;;
    *)
        say "Продолжаю без sudo. / Going on without sudo."
        return 1
        ;;
    esac
    if sudo bash "$0" --no-sudo; then return 0; fi
    say "sudo не сработал, продолжаю без него. / sudo did not work, going on without it."
    return 1
}

main() {
    local no_sudo=0
    case ${1:-} in
    -h | --help)
        say "z3report.sh $VERSION: collects a read-only OS report for Z3NOVO firmware testers into one text file."
        say "Usage: bash z3report.sh [--no-sudo]   (more details: sudo bash z3report.sh)"
        say "  Started without root in a terminal, it offers to run again through sudo; --no-sudo skips the offer."
        say "Собирает отчёт ОС для тестеров прошивки Z3NOVO в один текстовый файл, только чтение."
        say "  Без root в терминале предлагает перезапуститься через sudo; --no-sudo отключает вопрос."
        return 0
        ;;
    -V | --version)
        say "$VERSION"
        return 0
        ;;
    --no-sudo) no_sudo=1 ;;
    esac
    if [ "$no_sudo" = 0 ] && offer_sudo; then
        return 0
    fi

    TMPD=$(mktemp -d "${TMPDIR:-/tmp}/z3report.XXXXXX" 2>/dev/null) || {
        TMPD=${TMPDIR:-/tmp}/z3report.$$
        mkdir -m 700 "$TMPD" || {
            say "cannot create a temporary folder / не удалось создать временную папку"
            return 1
        }
    }
    trap 'rm -rf "${TMPD:?}"' EXIT
    trap 'exit 130' INT TERM
    BODY=$TMPD/body
    FACTS=$TMPD/facts
    : >"$BODY"
    : >"$FACTS"

    if [ "$IS_ROOT" = 1 ]; then
        if [ -n "${SUDO_USER:-}" ]; then RUNAS="root via sudo"; else RUNAS="root"; fi
    else
        RUNAS="normal user (some parts need sudo)"
    fi
    OUT_DIR=$(out_dir)
    OUT=$OUT_DIR/z3report-os-$STAMP.txt

    say "Z3NOVO: собираю отчёт ОС, это займёт до пары минут / collecting the OS report, up to a couple of minutes..."
    if [ "$IS_ROOT" != 1 ]; then
        say "  Без sudo часть сведений недоступна; полнее так / Without sudo some details are missing; fuller:  sudo bash $0"
    fi
    pci_names_build
    log_init

    run os "OS / ОС" s_os
    run firmware "Firmware and board (SMBIOS) / Прошивка и плата" s_fw
    run cpu "CPU / Процессор" s_cpu
    run memory "Memory / Память" s_mem
    run graphics "Graphics and its memory / Видео и его память" s_gpu
    run display "Displays / Мониторы" s_display
    run problems "Devices with problems / Устройства с ошибками" s_problems
    run history "Boots, crashes and hangs over 30 days / Загрузки, сбои и зависания за 30 дней" s_history
    run mce "Machine checks and saved crash logs / Аппаратные ошибки (MCE) и сохранённые журналы сбоев" s_mce
    run kernel "Kernel log, this boot / Журнал ядра, текущая загрузка" s_kernel
    run journal "System journal / Системный журнал" s_journal
    run taint "Kernel taint and modules / Метки ядра и модули" s_taint
    run sensors "Sensors, safe drivers only / Датчики, только безопасные" s_sensors
    run pci "PCI devices / Устройства PCI" s_pci
    run usb "USB devices / Устройства USB" s_usb
    run network "Network adapters, no addresses / Сетевые адаптеры, без адресов" s_net
    run disks "Disks / Диски" s_disks
    run efivars "UEFI variables Z3Chip and Z3Novo*, read only / Переменные UEFI Z3Chip и Z3Novo*, только чтение" s_efivars

    tokens_build
    redact_prog >"$TMPD/redact.awk"
    # The header and footer are fixed text; everything collected goes through the masking.
    if ! { header; { summary; cat "$BODY"; } | redact; footer; } >"$OUT.part"; then
        say "failed to write the report / не удалось записать отчёт: $OUT"
        rm -f "$OUT.part"
        return 1
    fi
    mv -f "$OUT.part" "$OUT" || return 1
    if [ "$IS_ROOT" = 1 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
        chown "$SUDO_USER" "$OUT" 2>/dev/null
    fi

    say ""
    say "Готово / Done:"
    say "  $OUT"
    say "Перед отправкой откройте файл и проверьте его: имена, адреса и серийные номера замазаны, но убедитесь сами."
    say "Before sending, open the file and check it: names, addresses and serial numbers are masked, but please make sure."
    say "Отправьте этот файл тому, кто ведёт тест прошивки. / Send this file to the person running the firmware test."
}

# ==== end of the z3report.sh part ====

# ================================================================ z3test: base

T_VERSION=1.0
Z3T_ROOT=${Z3TEST_ROOT:-/var/lib/z3test}          # test hook: another folder for the runs
UNIT_DIR=${Z3TEST_UNIT_DIR:-/etc/systemd/system}  # test hook: another folder for the unit
UNIT=z3test-resume.service
CURRENT=$Z3T_ROOT/current
FIXED=$(printf '\002') # marks a line of fixed text: it is not masked (only collected values are)
RUN=""
OUT_HOME=""
STOPNOW=0
HANDOFF=0
INTERACTIVE=0
PHASE=start
BEAT_WALL=0
BEAT_UP=0
TMPD=""
DEEP=0
BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null)

uptime_s() { awk '{ printf "%d", $1 }' /proc/uptime 2>/dev/null; }
now() { date +%s; }
tlocal() { [ "${1:-0}" -gt 0 ] 2>/dev/null && date -d "@$1" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf '?'; }
ttime() { [ "${1:-0}" -gt 0 ] 2>/dev/null && date -d "@$1" '+%H:%M:%S' 2>/dev/null || printf '?'; }
dur() { awk -v s="${1:-0}" 'BEGIN { s = int(s); if (s < 0) s = 0; if (s >= 3600) printf "%d h %02d min", s / 3600, (s % 3600) / 60; else if (s >= 120) printf "%d min %02d s", s / 60, s % 60; else printf "%d s", s }'; }
durr() { awk -v s="${1:-0}" 'BEGIN { s = int(s); if (s < 0) s = 0; if (s >= 3600) printf "%d ч %02d мин", s / 3600, (s % 3600) / 60; else if (s >= 120) printf "%d мин %02d с", s / 60, s % 60; else printf "%d с", s }'; }
# The average of the numbers on stdin (one or more per line), or nothing.
avg() { tr ' ' '\n' | awk '$1 ~ /^-?[0-9]+$/ { s += $1; n++ } END { if (n) printf "%.0f", s / n }'; }

# Logs of the run (raw; masked when the archive is made).
logp() { [ -n "$RUN" ] && printf '%s  [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$PHASE" "$*" >>"$RUN/progress.txt"; return 0; }
logf() {
    local f=$1
    shift
    [ -n "$RUN" ] && printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$RUN/$f"
    return 0
}
# Progress on the screen (Russian, then English) and in progress.txt (English).
say2() {
    [ "$INTERACTIVE" = 1 ] && printf '%s  %s\n          %s\n' "$(date +%H:%M:%S)" "$1" "$2"
    logp "$2"
}
plain2() {
    [ "$INTERACTIVE" = 1 ] && printf '%s\n%s\n' "$1" "$2"
    return 0
}
# One value masked like the report (collected data put into a fixed text).
mv1() { printf '%s\n' "$1" | LC_ALL=C awk -v tokfile="$TMPD/tokens" -f "$TMPD/mask.awk" 2>/dev/null | head -n 1; }
# One line of the result: OK, WARN (a note), ERR (an error), SKIP (left out or not checked), INFO. verdict LEVEL "ru" "en";
# the values in the texts are masked by the caller (mv1).
verdict() {
    local ru=${2//|//} en=${3//|//}
    [ -n "$RUN" ] && printf '%s|%s|%s\n' "$1" "$ru" "$en" >>"$RUN/verdicts.txt"
    logp "$1: $en"
    if [ "$INTERACTIVE" = 1 ] && [ "$1" != OK ] && [ "$1" != INFO ]; then printf '          %s: %s\n' "$1" "$ru"; fi
    return 0
}

# ---------------------------------------------------------------- state of a run (/var/lib/z3test/run-*)

st_get() { [ -n "$RUN" ] && sed -n "s/^$1=//p" "$RUN/state.txt" 2>/dev/null | tail -n 1; }
st_set() {
    local f=$RUN/state.txt
    { grep -v "^$1=" "$f" 2>/dev/null; printf '%s=%s\n' "$1" "$2"; } >"$f.new" && mv -f "$f.new" "$f"
}
st_int() {
    local v
    v=$(st_get "$1")
    case $v in '' | *[!0-9]*) printf 0 ;; *) printf '%s' "$v" ;; esac
}
st_add() { st_set "$1" "$(($(st_int "$1") + ${2:-1}))"; }
st_app() {
    local v
    v=$(st_get "$1")
    st_set "$1" "${v:+$v }$2"
}

# Heartbeat: $RUN/heartbeat holds the last moment the script was alive and its step, so after a hang and a reset the
# next start can tell when it stopped. "gaps": a pause of over a minute between two beats is written down (the system
# stopped answering for a while and went on). /proc/uptime does not jump with the clock.
beat() {
    local up n gap
    up=$(uptime_s)
    if [ "${2:-}" = gaps ] && [ "$BEAT_UP" -gt 0 ]; then
        gap=$((up - BEAT_UP))
        if [ "$gap" -gt 60 ]; then
            logp "STALL: no beat for $gap s"
            st_add stalls
            if [ "$gap" -gt "$(st_int stall_max)" ]; then
                st_set stall_max "$gap"
                st_set stall_at "$(now)"
                st_set stall_phase "$PHASE"
            fi
        fi
    fi
    BEAT_UP=$up
    n=$(now)
    if [ $((n - BEAT_WALL)) -ge 10 ] && [ -n "$RUN" ]; then
        BEAT_WALL=$n
        printf '%s|%s|%s\n' "$n" "$PHASE" "$1" >"$RUN/heartbeat"
        sync "$RUN/heartbeat" 2>/dev/null
    fi
    return 0
}
reset_beat() {
    BEAT_UP=0
    BEAT_WALL=0
}

stop_requested() {
    [ "$STOPNOW" = 1 ] && return 0
    if { [ -n "$RUN" ] && [ -e "$RUN/STOP" ]; } || { [ -n "$OUT_HOME" ] && { [ -e "$OUT_HOME/Z3TEST-STOP" ] || [ -e "$OUT_HOME/Z3TEST-STOP.txt" ]; }; }; then
        STOPNOW=1
        logp "stop requested"
        return 0
    fi
    return 1
}
# wait_step SECONDS DETAIL [gaps]: waits, beating and watching for a stop; 1 when a stop was asked for.
wait_step() {
    local end=$(($(uptime_s) + $1))
    while [ "$(uptime_s)" -lt "$end" ]; do
        stop_requested && return 1
        sleep 1
        beat "$2" "${3:-}"
    done
    return 0
}

# ---------------------------------------------------------------- the change journal: everything the test changes

record() { printf '%s\n' "$1" >>"$RUN/changes.txt"; }

undo_one() { # undo_one LINE: prints what happened
    local kind a b
    IFS='|' read -r kind a b <<<"$1"
    case $kind in
    unit)
        if have systemctl; then systemctl disable "$a" >/dev/null 2>&1; fi
        rm -f "$UNIT_DIR/$a"
        if have systemctl; then systemctl daemon-reload >/dev/null 2>&1; fi
        printf 'removed'
        ;;
    memsleep)
        if [ "$b" = "$BOOT_ID" ]; then
            echo "$a" >/sys/power/mem_sleep 2>/dev/null && printf 'set back to %s' "$a" || printf 'FAILED to set back to %s' "$a"
        else
            printf 'nothing to do: a new boot has its own default'
        fi
        ;;
    wakealarm)
        echo 0 >/sys/class/rtc/rtc0/wakealarm 2>/dev/null
        printf 'alarm cleared'
        ;;
    cmosde)
        # The fan probe cleared bit 7 of DEh and the script stopped before it put it back: put it back, this boot only.
        if [ "$b" = "$BOOT_ID" ]; then de_restore7 "$a" && printf 'bit 7 set back' || printf 'FAILED'; else printf 'nothing to do: a new boot'; fi
        ;;
    shm)
        rm -rf "${a:?}"
        printf 'removed'
        ;;
    mount)
        umount "$a" 2>/dev/null
        rmdir "$a" 2>/dev/null
        if awk -v p="$a" '$2 == p { f = 1 } END { exit !f }' /proc/mounts 2>/dev/null; then printf 'FAILED: still mounted'; else printf 'unmounted'; fi
        ;;
    *) printf 'unknown, left as it is' ;;
    esac
}
# undo_changes DIR [ONLY] [EXCEPT]: undo what the journal lists, newest first; ONLY / EXCEPT: space separated kinds.
undo_changes() {
    local dir=$1 only=${2:-} except=${3:-} f=$1/changes.txt l k keep sel
    [ -f "$f" ] || return 0
    keep=$dir/changes.keep
    : >"$keep"
    tac "$f" | while IFS= read -r l; do
        [ -n "$l" ] || continue
        k=${l%%|*}
        sel=1
        if [ -n "$only" ]; then case " $only " in *" $k "*) ;; *) sel=0 ;; esac; fi
        if [ -n "$except" ]; then case " $except " in *" $k "*) sel=0 ;; esac; fi
        if [ "$sel" = 1 ]; then
            printf '%s  %s  -> %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$l" "$(undo_one "$l")" >>"$dir/changes-undone.txt"
        else
            printf '%s\n' "$l" >>"$keep"
        fi
    done
    if [ -s "$keep" ]; then tac "$keep" >"$f"; else rm -f "$f"; fi
    rm -f "$keep"
}

# ---------------------------------------------------------------- the folder, the lock, masking

take_lock() {
    mkdir -p "$Z3T_ROOT" && chmod 700 "$Z3T_ROOT" || return 1
    exec 9>>"$Z3T_ROOT/lock"
    if have flock; then flock -n 9 || return 1; fi
    return 0
}
current_run() {
    local d
    [ -r "$CURRENT" ] || return 1
    d=$(head -n 1 "$CURRENT")
    [ -n "$d" ] && [ -f "$d/state.txt" ] && { printf '%s' "$d"; return 0; }
    return 1
}
open_run() {
    RUN=$1
    PHASE=$(st_get phase)
    OUT_HOME=$(st_get out_home)
    DEEP=$(st_int deep)
    local u
    u=$(st_get user_name)
    if [ -n "$u" ] && [ -n "$TMPD" ]; then
        printf '<user>\t%s\n' "$u" >>"$TMPD/tok.raw"
        awk -F'\t' '!seen[$0]++ { print length($2) "\t" $0 }' "$TMPD/tok.raw" | sort -t "$(printf '\t')" -k1,1nr | cut -f2- >"$TMPD/tokens"
    fi
}
# Masking: the tokens and the program of z3report.sh, plus one rule in front for lines of fixed text.
mask_init() {
    if [ -z "$TMPD" ]; then
        TMPD=$(mktemp -d "${TMPDIR:-/tmp}/z3test.XXXXXX" 2>/dev/null) || {
            TMPD=${TMPDIR:-/tmp}/z3test.$$
            mkdir -m 700 "$TMPD" || return 1
        }
    fi
    tokens_build
    redact_prog >"$TMPD/redact.awk"
    { printf '%s\n' 'substr($0, 1, 1) == "\002" { print substr($0, 2); next }'; redact_prog; } >"$TMPD/mask.awk"
}
mask_file() { LC_ALL=C awk -v tokfile="$TMPD/tokens" -f "$TMPD/mask.awk" <"$1" >"$2"; }

boot_epoch() { awk '/^btime / { print $2 }' /proc/stat 2>/dev/null; }
# Test hooks for the QEMU checks (tests/run_vm.sh): Z3TEST_FAKE_SYSTEMD=1 acts as if a unit can go on after a restart
# (the test system starts the copy itself), Z3TEST_REBOOT_CMD= restarts in place of systemctl reboot.
have_systemd() { [ -n "${Z3TEST_FAKE_SYSTEMD:-}" ] && return 0; [ -d /run/systemd/system ] && have systemctl; }
journal_persistent() { [ -d /var/log/journal ] && have journalctl; }

# ================================================================ z3test: the snapshot

# Devices that matter for "lost after a sleep or a restart": one line each, the first three fields are the key.
#   pci ADDRESS VENDOR:DEVICE drv=DRIVER w=LINKWIDTH NAME
#   usb PORTPATH VENDOR:PRODUCT - - NAME
#   blk MODEL SECTORS - - NAME
#   net INTERFACE - - - (network interfaces with a device behind them)
devices_list() {
    local d m s
    for d in /sys/bus/pci/devices/*; do
        [ -r "$d/vendor" ] || continue
        printf 'pci %s %s drv=%s w=%s %s\n' "${d##*/}" "$(pci_id "$d")" "$(drvname "$d")" "$(sv "$d/current_link_width")" "$(pci_name "$(pci_id "$d")")"
    done
    for d in /sys/bus/usb/devices/*; do
        [ -r "$d/idVendor" ] || continue
        printf 'usb %s %s:%s - - %s %s\n' "${d##*/}" "$(sv "$d/idVendor")" "$(sv "$d/idProduct")" "$(sv "$d/manufacturer")" "$(sv "$d/product")"
    done
    for d in /sys/block/*; do
        case ${d##*/} in loop* | ram* | zram* | dm-* | md* | sr* | nbd* | fd*) continue ;; esac
        [ -e "$d/device" ] || continue
        m=$(sv "$d/device/model")
        s=$(sv "$d/size")
        printf 'blk %s %s - - %s\n' "$(printf '%s' "${m:-?}" | tr -s ' ' '_' | sed 's/_$//')" "${s:-0}" "${d##*/}"
    done
    for d in /sys/class/net/*; do
        [ -e "$d/device" ] && printf 'net %s - - -\n' "${d##*/}"
    done
    return 0
}
# devices_diff BEFORE AFTER: "missing KEY NAME", "nodriver KEY NAME", "narrower KEY xOLD -> xNEW NAME", "added KEY".
devices_diff() {
    awk '
        function key(a) { return a[1] " " a[2] " " a[3] }
        function rest(s, n,    i, a, r) { split(s, a, " "); r = ""; for (i = n; i in a; i++) r = r (r == "" ? "" : " ") a[i]; return r }
        NR == FNR { split($0, a, " "); k = key(a); b[k] = $0; next }
        { split($0, a, " "); k = key(a); n[k] = $0 }
        END {
            for (k in b) {
                split(b[k], x, " ")
                if (!(k in n)) { print "missing " k " " rest(b[k], 6); continue }
                split(n[k], y, " ")
                if (x[1] == "pci") {
                    if (x[4] != "drv=" && y[4] == "drv=") print "nodriver " k " " rest(b[k], 6)
                    wb = substr(x[5], 3) + 0; wa = substr(y[5], 3) + 0
                    if (wb > 0 && wa > 0 && wa < wb) print "narrower " k " x" wb " -> x" wa " " rest(b[k], 6)
                }
            }
            for (k in n) if (!(k in b)) print "added " k
        }' "$1" "$2" | sort
}
# check_devices WHAT_RU WHAT_EN LEVEL: the devices now against the start, as verdicts.
check_devices() {
    local now=$RUN/devices.now diff=$RUN/devices.diff x
    devices_list >"$now"
    devices_diff "$RUN/devices-start.txt" "$now" >"$diff"
    { printf '%s\n' "devices after $2:"; sed 's/^/    /' "$diff"; } >>"$RUN/devices-changes.txt"
    x=$(grep '^missing ' "$diff" | cut -d' ' -f2- | tr '\n' ';' | sed 's/;$//')
    [ -n "$x" ] && x=$(mv1 "$x") && verdict ERR "После $1 пропали устройства: $x" "Devices gone after $2: $x"
    x=$(grep '^nodriver ' "$diff" | cut -d' ' -f2- | tr '\n' ';' | sed 's/;$//')
    [ -n "$x" ] && x=$(mv1 "$x") && verdict "$3" "После $1 устройства остались без драйвера: $x" "Devices without a driver after $2: $x"
    x=$(grep '^narrower ' "$diff" | cut -d' ' -f2- | tr '\n' ';' | sed 's/;$//')
    [ -n "$x" ] && x=$(mv1 "$x") && verdict WARN "После $1 линк PCIe стал уже: $x" "A PCIe link got narrower after $2: $x"
    logp "devices after $2: $(grep -c '^missing ' "$diff") missing, $(grep -c '^nodriver ' "$diff") without a driver, $(grep -c '^narrower ' "$diff") narrower, $(grep -c '^added ' "$diff") added"
    return 0
}

# The whole z3report.sh report, written by its own main into the run folder (already masked by it).
snap_report() {
    local f k v
    (
        out_dir() { printf '%s' "$RUN"; }
        main --no-sudo
    ) >>"$RUN/report.log" 2>&1
    f=$(ls -1t "$RUN"/z3report-os-*.txt 2>/dev/null | head -n 1)
    if [ -z "$f" ]; then
        verdict WARN "Отчёт z3report не получился (report.log)." "The z3report report failed (report.log)."
        return 0
    fi
    mv -f "$f" "$RUN/report-os.txt"
    for k in BIOS Board CPU Memory Graphics OS; do
        v=$(awk -v k="$k:" '/^=== \[summary\]/ { s = 1; next } /^=== / { s = 0 } s && $1 == k { sub(/^ *[^ ]+ +/, ""); print; exit }' "$RUN/report-os.txt")
        st_set "f_$(printf '%s' "$k" | tr 'A-Z' 'a-z')" "$v"
    done
}

# Memory sizes are counted in MiB: mawk and busybox awk print %d (and large integers) in 32 bits, so a sum in bytes over
# 2 GiB came out negative on a board with two 8 GiB modules. Every awk here prints with %.0f or %.Nf.
MEMINFO=${Z3TEST_MEMINFO:-/proc/meminfo}             # test hooks (tests/awkcheck.sh)
DMI_TABLE=${Z3TEST_DMI_TABLE:-/sys/firmware/dmi/tables/DMI}
SYSPCI=${Z3TEST_SYSPCI:-/sys/bus/pci/devices}
dmi_mib() { awk '{ v = $1 + 0; u = $2; printf "%.0f\n", v * (u ~ /^T/ ? 1048576 : u ~ /^G/ ? 1024 : u ~ /^M/ ? 1 : u ~ /^[kK]/ ? 1 / 1024 : 0) }'; }
gib() { awk -v m="$1" -v f="${2:-%.2f GiB}" 'BEGIN { printf f, m / 1024 }'; }
x_mem() {
    local mt sum=0 vram=-1 v d rest speeds n=0 g s o
    mt=$(awk '/^MemTotal:/ { printf "%.0f", $2 / 1024 }' "$MEMINFO")
    note 'Speed: "rated" is what the module says it can do (SMBIOS Speed); "set" is what the firmware runs it at (Configured Memory Speed).'
    if [ "$IS_ROOT" = 1 ] && have dmidecode && [ -r "$DMI_TABLE" ]; then
        T 15 dmidecode -q -d /dev/null -t 17 2>/dev/null | awk '
            /^Memory Device/ { if (n) out(); n = 1; split("", d); next }
            /^\t[^\t]/ { line = substr($0, 2); p = index(line, ": "); if (p) d[substr(line, 1, p - 1)] = substr(line, p + 2) }
            function out() {
                if (d["Size"] == "" || d["Size"] ~ /^No Module|^0 /) { printf "  %-28s empty\n", d["Locator"] " / " d["Bank Locator"]; return }
                printf "  %-28s %s, rated %s, set %s, %s %s\n", d["Locator"] " / " d["Bank Locator"], d["Size"], d["Speed"], d["Configured Memory Speed"], d["Manufacturer"], d["Part Number"]
                print "SIZE " d["Size"] > "/dev/stderr"
                print "SET " d["Configured Memory Speed"] > "/dev/stderr"
            }
            END { if (n) out() }' 2>"$TMPD/memx"
        sum=$(sed -n 's/^SIZE //p' "$TMPD/memx" | dmi_mib | awk '{ s += $1 } END { printf "%.0f", s }')
        n=$(grep -c '^SIZE ' "$TMPD/memx")
        speeds=$(sed -n 's/^SET //p' "$TMPD/memx" | sed 's/ *MT\/s//; s/ *MHz//' | sort -u | tr '\n' '/' | sed 's/\/$//')
    else
        note "Modules and their speed: need root and dmidecode / нужен root и dmidecode"
    fi
    # The graphics memory (on a Ryzen with graphics: the UMA the firmware gave it) is known only from the video driver.
    for d in "$SYSPCI"/*; do
        v=$(sv "$d/mem_info_vram_total")
        case $v in '' | *[!0-9]*) continue ;; esac
        v=$((v / 1048576))
        [ "$v" -gt "$vram" ] && vram=$v
    done
    kv "Installed (SMBIOS)" "$(gib "${sum:-0}") in $n module(s)"
    kv "Seen by Linux (MemTotal)" "$(gib "${mt:-0}")"
    if [ "$vram" -ge 0 ]; then
        rest=$((sum - mt - vram))
        kv "Graphics memory (largest VRAM)" "$(gib "$vram")"
        kv "Not accounted for" "$(gib "$rest") (the firmware and the kernel keep some, usually under 1 GiB)"
    else
        kv "Graphics memory (largest VRAM)" "unknown: no video driver gives it / неизвестно: видеодрайвер её не сообщает"
        kv "Not accounted for" "not counted without the graphics memory / не посчитать без размера видеопамяти"
    fi
    st_set f_mem_set "$speeds"
    [ "$n" -gt 0 ] || return 0
    g=$(gib "$sum" '%.1f')
    o=$(gib "$mt" '%.1f')
    if [ "$vram" -ge 0 ]; then
        s=$(gib "$vram" '%.1f')
        verdict INFO "Память: стоит $g ГБ (планок: $n), Linux видит $o ГБ, частота $speeds, видеопамять $s ГБ." \
            "Memory: $g GB installed ($n module(s)), Linux sees $o GB, speed $speeds, graphics memory $s GB."
    else
        verdict INFO "Память: стоит $g ГБ (планок: $n), Linux видит $o ГБ, частота $speeds, видеопамять неизвестна (нет видеодрайвера)." \
            "Memory: $g GB installed ($n module(s)), Linux sees $o GB, speed $speeds, graphics memory unknown (no video driver)."
    fi
    case $speeds in */*) verdict WARN "Планки работают на разной частоте: $speeds." "The modules run at different speeds: $speeds." ;; esac
    if [ "$vram" -ge 0 ] && [ "$rest" -gt 1536 ]; then
        verdict WARN "Linux видит заметно меньше памяти, чем стоит: стоит $g ГБ, видно $o ГБ, видеопамять $s ГБ. Возможно, одна планка не используется." \
            "Linux sees much less memory than is installed: $g GB installed, $o GB seen, graphics memory $s GB. Maybe one module is not used."
    fi
}

x_pcie() {
    local d id link cls name
    note "now: the link as it runs; max: what the device itself can do. The slot can be narrower than the device (with a Ryzen with graphics the graphics slot is x8), and many devices lower the speed at idle to save power."
    for d in /sys/bus/pci/devices/*; do
        link=$(pcilink "$d")
        [ -n "$link" ] || continue
        id=$(pci_id "$d")
        name=$(pci_name "$id")
        printf '  %s [%s] %s | %s\n' "${d##*/}" "$id" "$name" "$link"
        cls=$(sv "$d/class")
        case $cls in
        0x03* | 0x0108* | 0x02*)
            name=$(mv1 "$name")
            verdict INFO "Линк: $name — $link." "Link: $name: $link."
            ;;
        esac
    done
}

x_nvme() {
    local d pd any=0 m f
    for d in /sys/class/nvme/nvme*; do
        [ -e "$d/model" ] || continue
        any=1
        m=$(sv "$d/model")
        f=$(sv "$d/firmware_rev")
        pd=$(readlink -f "$d/device" 2>/dev/null)
        kv "${d##*/}" "$m, firmware $f, transport $(sv "$d/transport"), state $(sv "$d/state")${pd:+, PCIe $(pcilink "$pd")}"
        if have nvme && [ "$IS_ROOT" = 1 ]; then
            T 10 nvme smart-log "/dev/${d##*/}" 2>/dev/null | grep -i -E '^(critical_warning|temperature|percentage_used|media_errors|num_err_log_entries|unsafe_shutdowns|power_on_hours)' | ind
        fi
        m=$(mv1 "$m")
        verdict INFO "Накопитель NVMe: $m, прошивка $f." "NVMe drive: $m, firmware $f."
    done
    [ "$any" = 1 ] || note "no NVMe drive / накопителей NVMe нет"
    for d in /sys/block/sd*; do
        [ -e "$d/device/model" ] && kv "${d##*/}" "$(sv "$d/device/vendor") $(sv "$d/device/model"), firmware $(sv "$d/device/rev")"
    done
    return 0
}

x_sec() {
    local sb sm t tv desc ld
    sb=$(efivar_bytes "SecureBoot-$GUID_EFI" | cut -d' ' -f1)
    sm=$(efivar_bytes "SetupMode-$GUID_EFI" | cut -d' ' -f1)
    case $sb in 01) sb=on ;; 00) sb=off ;; *) sb=unknown ;; esac
    case $sm in 01) sm=1 ;; 00) sm=0 ;; *) sm=? ;; esac
    kv "Secure Boot" "$sb (SetupMode $sm)"
    have mokutil && kv "mokutil --sb-state" "$(T 10 mokutil --sb-state 2>/dev/null | head -n 1)"
    ld=$(sv /sys/kernel/security/lockdown)
    kv "Kernel lockdown" "${ld:-not available}"
    verdict INFO "Secure Boot: $sb (SetupMode $sm)." "Secure Boot: $sb (SetupMode $sm)."
    t=/sys/class/tpm/tpm0
    if [ -d "$t" ]; then
        tv=$(sv "$t/tpm_version_major")
        desc=$(sv "$t/device/description")
        kv "TPM" "version ${tv:-?}${desc:+, $desc}, $(sv "$t/device/firmware_node/hid")"
        verdict INFO "TPM: есть, версия ${tv:-?}${desc:+ ($desc)}." "TPM: present, version ${tv:-?}${desc:+ ($desc)}."
    else
        kv "TPM" "not visible to Linux"
        verdict INFO "TPM: Linux его не видит." "TPM: not visible to Linux."
    fi
}

x_power() {
    local f
    kv "/sys/power/state" "$(sv /sys/power/state)"
    kv "/sys/power/mem_sleep" "$(sv /sys/power/mem_sleep)"
    for f in /sys/power/suspend_stats/*; do [ -r "$f" ] && kv "suspend_stats/${f##*/}" "$(sv "$f")"; done
    kv "RTC" "$(sv /sys/class/rtc/rtc0/name), wakealarm $([ -e /sys/class/rtc/rtc0/wakealarm ] && echo present || echo absent)"
    for f in /sys/firmware/acpi/fpdt/boot/* /sys/firmware/acpi/fpdt/suspend/*; do
        [ -r "$f" ] && kv "fpdt ${f#/sys/firmware/acpi/fpdt/}" "$(sv "$f")"
    done
    if have systemd-inhibit; then
        note "systemd-inhibit --list:"
        T 10 systemd-inhibit --list --no-pager 2>/dev/null | ind
    fi
}

snap_extras() {
    {
        printf '%sZ3NOVO z3test: snapshot / снимок системы, z3test.sh %s\n' "$FIXED" "$T_VERSION"
        printf '\n%s=== [memory_set] Memory: set and running / Память: задано и работает\n' "$FIXED"
        x_mem
        printf '\n%s=== [pcie] PCIe links: speed and width / Линки PCIe: скорость и ширина\n' "$FIXED"
        x_pcie
        printf '\n%s=== [nvme] Drives: model and firmware / Накопители: модель и прошивка\n' "$FIXED"
        x_nvme
        printf '\n%s=== [security] Secure Boot and TPM\n' "$FIXED"
        x_sec
        printf '\n%s=== [activation] Windows activation / Активация Windows\n' "$FIXED"
        printf '%s  not on Linux / в Linux не проверяется\n' "$FIXED"
        printf '\n%s=== [power] Sleep and power / Сон и питание\n' "$FIXED"
        x_power
    } >"$RUN/snapshot.txt" 2>>"$RUN/errors.log"
}

ph_snapshot() {
    say2 "Снимок системы: сведения, как у z3report, и ещё память, линки PCIe, NVMe, Secure Boot, TPM." \
        "System snapshot: the z3report details plus memory, PCIe links, NVMe, Secure Boot and TPM."
    snap_report
    snap_extras
    devices_list >"$RUN/devices-start.txt"
    return 0
}

# ================================================================ z3test: the fan after sleep (--deep, Linux, root, M715s + Z3NOVO only)
#
# Extended CMOS DEh of the FCH (index port 72h, data port 73h), high half = the fan's (fw/z3chip/z3chip_dxe.c FAN_CMOS,
# fw/z3fan/z3fan_smm.c): bit 6 "armed" (Z3Chip switched the CPU fan to software mode this boot and Z3Fan may drive it),
# bit 7 "confirmed" (Z3Fan's SMM tick runs: from its 4th tick it sets bit 7 whenever it finds it clear), bits 5:4 a count
# of boots armed but not confirmed; the low half is another counter and is never touched here. Reading tells whether the
# bits survived the sleep; only clearing bit 7 tells whether the tick still runs: twice a second Z3Fan sets it again, so
# after 3 s it is back if the tick runs, and stays clear if it does not (the T2.0 bug: the fan stops following the
# temperature after a wake). A bit 7 that did not come back is set again at once, so the byte ends as it was found.
# The index port is read first and written back after each access, as Z3Fan itself does.
# Test hook: Z3TEST_FAKE_CMOS=DIR (files DIR/index, decimal, and DIR/cmos, 256 bytes) in place of the ports.

DEVPORT=/dev/port
port_in() {
    if [ -n "${Z3TEST_FAKE_CMOS:-}" ]; then
        case $1 in
        114) cat "$Z3TEST_FAKE_CMOS/index" ;;
        115) od -An -tu1 -j "$(cat "$Z3TEST_FAKE_CMOS/index")" -N1 "$Z3TEST_FAKE_CMOS/cmos" | tr -d ' \n' ;;
        esac
        return 0
    fi
    if have od; then
        dd if="$DEVPORT" bs=1 skip="$1" count=1 2>/dev/null | od -An -tu1 | { read -r v; printf '%s' "$v"; }
    else
        # no od (a minimal busybox): the byte read by bash itself; a NUL byte reads as empty, that is 0
        dd if="$DEVPORT" bs=1 skip="$1" count=1 2>/dev/null | { IFS= LC_ALL=C read -r -d '' -n 1 c; printf '%d' "'$c"; }
    fi
}
port_out() {
    if [ -n "${Z3TEST_FAKE_CMOS:-}" ]; then
        case $1 in
        114) printf '%s' "$2" >"$Z3TEST_FAKE_CMOS/index" ;;
        115) printf "\\$(printf '%03o' "$2")" | dd of="$Z3TEST_FAKE_CMOS/cmos" bs=1 seek="$(cat "$Z3TEST_FAKE_CMOS/index")" count=1 conv=notrunc 2>/dev/null ;;
        esac
        return 0
    fi
    printf "\\$(printf '%03o' "$2")" | dd of="$DEVPORT" bs=1 seek="$1" count=1 conv=notrunc 2>/dev/null
}
de_read() {
    local old v
    old=$(port_in 114)
    port_out 114 222
    v=$(port_in 115)
    [ -n "$old" ] && port_out 114 "$old"
    printf '%s' "$v"
}
# de_write_bit7 0|1: read-modify-write of DEh, bit 7 only.
de_write_bit7() {
    local old v
    old=$(port_in 114)
    port_out 114 222
    v=$(port_in 115)
    [ -n "$v" ] || return 1
    if [ "$1" = 1 ]; then v=$((v | 128)); else v=$((v & 127)); fi
    port_out 114 222
    port_out 115 "$v"
    [ -n "$old" ] && port_out 114 "$old"
    return 0
}
de_restore7() { [ "$((${1:-0} & 128))" -ne 0 ] && de_write_bit7 1; }
de_text() { [ -n "$1" ] && printf 'DEh=%02Xh (bit 7 confirmed %d, bit 6 armed %d, bits 5:4 count %d)' "$1" $(($1 >> 7 & 1)) $(($1 >> 6 & 1)) $(($1 >> 4 & 3)); }

# Why --deep cannot run here, or nothing.
deep_blocker() {
    local b
    [ "$IS_ROOT" = 1 ] || { printf 'needs root'; return 0; }
    [ "$(cpuf vendor_id)" = AuthenticAMD ] || { printf 'not an AMD processor'; return 0; }
    b="$(sv /sys/class/dmi/id/board_name) $(sv /sys/class/dmi/id/product_name) $(sv /sys/class/dmi/id/product_version)"
    case $b in *AM4P2MS* | *M715s*) ;; *) printf 'not a ThinkCentre M715s (board AM4P2MS): %s' "$b"; return 0 ;; esac
    [ -e "$EV/Z3Chip-$GUID_CHIP" ] || { printf 'the Z3NOVO firmware is not running (no Z3Chip variable)'; return 0; }
    if [ -z "${Z3TEST_FAKE_CMOS:-}" ]; then
        [ -w "$DEVPORT" ] || { printf 'no %s (kernel without CONFIG_DEVPORT?)' "$DEVPORT"; return 0; }
        case $(sv /sys/kernel/security/lockdown) in '' | *'[none]'*) ;; *) printf 'kernel lockdown is on (Secure Boot): %s' "$(sv /sys/kernel/security/lockdown)"; return 0 ;; esac
    fi
    return 0
}

# deep_probe LABEL_RU LABEL_EN: read DEh, and if armed, clear bit 7 once and look again after 3 s. Sets DEEP_LAST=ok|dead|off|fail.
DEEP_LAST=""
deep_probe() {
    local v v2 b
    v=$(de_read)
    case $v in '' | *[!0-9]*)
        logf fan.txt "$2: DEh not readable"
        DEEP_LAST=fail
        return 0
        ;;
    esac
    logf fan.txt "$2: before the probe $(de_text "$v")"
    if [ $((v >> 6 & 1)) = 0 ]; then
        logf fan.txt "$2: bit 6 is clear: Z3Fan does not drive the fan this boot (the chip's own curve, or the fan setting is off); no write"
        DEEP_LAST=off
        return 0
    fi
    record "cmosde|$v|$BOOT_ID"
    de_write_bit7 0
    sleep 3
    v2=$(de_read)
    logf fan.txt "$2: bit 7 cleared, 3 s later $(de_text "$v2")"
    if [ -n "$v2" ] && [ $((v2 >> 7 & 1)) = 1 ]; then
        DEEP_LAST=ok
    else
        de_restore7 "$v"
        b=$(de_read)
        logf fan.txt "$2: bit 7 did not come back; set back as found: $(de_text "$b")"
        DEEP_LAST=dead
    fi
    # The journal line is spent: the byte is as found again.
    if [ -f "$RUN/changes.txt" ]; then
        grep -v "^cmosde|" "$RUN/changes.txt" >"$RUN/changes.tmp"
        if [ -s "$RUN/changes.tmp" ]; then mv -f "$RUN/changes.tmp" "$RUN/changes.txt"; else rm -f "$RUN/changes.tmp" "$RUN/changes.txt"; fi
    fi
    printf '%s  cmosde|%s  -> probe done, bit 7 as found\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$v" >>"$RUN/changes-undone.txt"
    return 0
}

# ================================================================ z3test: sleep (rtcwake)

ph_sleep() {
    local n secs i ms ok t0 t1 dt rc before after fails lines bios w
    n=$(st_int sleep_total)
    secs=$(st_int sleep_secs)
    if [ "$n" -le 0 ]; then
        verdict SKIP "Сон пропущен по выбору." "Sleep skipped by choice."
        return 0
    fi
    if ! grep -qw mem /sys/power/state 2>/dev/null; then
        verdict WARN "Сон не проверялся: ядро не предлагает сон (нет mem в /sys/power/state)." "Sleep not tested: the kernel offers no sleep (no mem in /sys/power/state)."
        return 0
    fi
    if [ ! -e /sys/class/rtc/rtc0/wakealarm ]; then
        verdict WARN "Сон не проверялся: нет будильника часов (RTC wakealarm)." "Sleep not tested: no RTC wake alarm."
        return 0
    fi
    ms=$(sv /sys/power/mem_sleep)
    if [ "$(st_int sleep_done)" = 0 ]; then
        case $ms in
        *'[deep]'*) ;;
        *deep*)
            record "memsleep|$(printf '%s' "$ms" | sed 's/.*\[\([a-z0-9]*\)\].*/\1/')|$BOOT_ID"
            echo deep >/sys/power/mem_sleep 2>/dev/null
            logf sleep.txt "mem_sleep was \"$ms\": set to deep for the test, set back at the end"
            ;;
        *)
            verdict WARN "Сон не проверялся: прошивка не даёт Linux обычный сон S3 (mem_sleep: $ms)." "Sleep not tested: the firmware gives Linux no ordinary S3 sleep (mem_sleep: $ms)."
            return 0
            ;;
        esac
        if [ "$DEEP" = 1 ]; then
            say2 "Вентилятор: проба до сна (бит 7 байта DEh)." "Fan: the probe before sleep (bit 7 of byte DEh)."
            deep_probe "до сна" "before sleep"
            st_set deep_before "$DEEP_LAST"
        fi
    fi
    i=$(($(st_int sleep_done) + 1))
    record wakealarm
    while [ "$i" -le "$n" ]; do
        stop_requested && return 1
        devices_list >"$RUN/devices.before"
        before=$(sv /sys/power/suspend_stats/success)
        fails=$(sv /sys/power/suspend_stats/fail)
        lines=$(dmesg 2>/dev/null | wc -l)
        st_set sleep_i "$i"
        st_set sleep_entered "$(now)"
        sync
        say2 "Сон $i из $n: компьютер уснёт на $secs с и проснётся сам. Не трогайте мышь и клавиатуру." \
            "Sleep $i of $n: the computer sleeps for $secs s and wakes by itself. Do not touch the mouse or the keyboard."
        wait_step 5 "sleep $i" || return 1
        logf sleep.txt "=== sleep $i of $n, mem_sleep $(sv /sys/power/mem_sleep)"
        t0=$(now)
        if have rtcwake; then
            T $((secs + 600)) rtcwake -m mem -s "$secs" >>"$RUN/sleep.txt" 2>&1
            rc=$?
        else
            echo 0 >/sys/class/rtc/rtc0/wakealarm 2>/dev/null
            echo "+$secs" >/sys/class/rtc/rtc0/wakealarm
            echo mem >/sys/power/state 2>>"$RUN/sleep.txt"
            rc=$?
        fi
        t1=$(now)
        reset_beat
        dt=$((t1 - t0))
        echo 0 >/sys/class/rtc/rtc0/wakealarm 2>/dev/null
        say2 "Проснулся после сна $i: спал и просыпался $dt с." "Back from sleep $i: asleep and back in $dt s."
        wait_step 10 "after sleep $i" || STOPNOW=1
        after=$(sv /sys/power/suspend_stats/success)
        bios=$(sv /sys/firmware/acpi/fpdt/suspend/resume_prev_ns)
        [ -n "$bios" ] && [ "$bios" -gt 0 ] 2>/dev/null && st_app sleep_fw_ms "$((bios / 1000000))"
        st_app sleep_secs_list "$dt"
        {
            printf 'command exit %s; asleep and back %d s (%s to %s); suspend_stats success %s -> %s, fail %s -> %s\n' "$rc" "$dt" "$(ttime "$t0")" "$(ttime "$t1")" \
                "$before" "$after" "$fails" "$(sv /sys/power/suspend_stats/fail)"
            printf 'last failed: dev %s, step %s, errno %s; firmware resume (FPDT) %s ns; wakeup IRQ %s\n' "$(sv /sys/power/suspend_stats/last_failed_dev)" \
                "$(sv /sys/power/suspend_stats/last_failed_step)" "$(sv /sys/power/suspend_stats/last_failed_errno)" "${bios:-?}" "$(sv /sys/power/pm_wakeup_irq)"
            printf 'kernel log of this sleep:\n'
            dmesg 2>/dev/null | tail -n +$((lines + 1)) | grep -i -E 'PM: |ACPI: (PM|Waking|Low-level)|suspend|resume|wake|error|fail|timeout|Freezing|Restarting' | tail -n 80 | ind
        } >>"$RUN/sleep.txt"
        # (not the clocksource watchdog's "read timed out": it comes in VMs and on boards alike and the clock stays)
        dmesg 2>/dev/null | tail -n +$((lines + 1)) | grep -E 'error in resume|resume failed|failed to resume|[Rr]einit|timed out|not responding|HC died' |
            grep -v 'clocksource' | sed 's/^\[[^]]*\] *//' | awk -v i="$i" '{ print i "\t" $0 }' >>"$RUN/resume-errors"
        ok=1
        if [ "${after:-0}" = "${before:-0}" ]; then
            verdict ERR "Сон $i: компьютер не уснул (код $rc, ошибок сна: $(sv /sys/power/suspend_stats/fail); sleep.txt)." \
                "Sleep $i: the computer did not go to sleep (exit $rc, failed sleeps: $(sv /sys/power/suspend_stats/fail); sleep.txt)."
            ok=0
        elif [ "$dt" -lt $((secs - 20)) ]; then
            w=$(sv /sys/power/pm_wakeup_irq)
            verdict WARN "Сон $i: проснулся раньше будильника, через $dt с${w:+ (прерывание $w)}." "Sleep $i: woke before the alarm, after $dt s${w:+ (IRQ $w)}."
            ok=0
        elif [ "$dt" -gt $((secs + 90)) ]; then
            verdict WARN "Сон $i: будильник не разбудил компьютер; проснулся только через $(durr "$dt") (нажали кнопку?)." \
                "Sleep $i: the alarm did not wake the computer; it woke only after $(dur "$dt") (a button press?)."
            ok=0
        fi
        devices_list >"$RUN/devices.after"
        devices_diff "$RUN/devices.before" "$RUN/devices.after" >"$RUN/devices.diff"
        { printf 'devices after sleep %d:\n' "$i"; sed 's/^/    /' "$RUN/devices.diff"; } >>"$RUN/devices-changes.txt"
        w=$(grep '^missing ' "$RUN/devices.diff" | cut -d' ' -f2- | tr '\n' ';' | sed 's/;$//')
        if [ -n "$w" ]; then
            w=$(mv1 "$w")
            verdict ERR "После сна $i пропали устройства: $w" "Devices gone after sleep $i: $w"
            ok=0
        fi
        w=$(grep -E '^(nodriver|narrower) ' "$RUN/devices.diff" | cut -d' ' -f1- | tr '\n' ';' | sed 's/;$//')
        if [ -n "$w" ]; then
            w=$(mv1 "$w")
            verdict WARN "После сна $i: $w" "After sleep $i: $w"
            ok=0
        fi
        if [ "$DEEP" = 1 ] && { [ "$i" = 1 ] || [ "$i" = "$n" ]; }; then
            deep_probe "после сна $i" "after sleep $i"
            st_set "deep_after_$i" "$DEEP_LAST"
        fi
        [ "$ok" = 1 ] && st_add sleep_ok
        st_set sleep_done "$i"
        [ "$STOPNOW" = 1 ] && break
        [ "$i" -lt "$n" ] && { wait_step 5 "between sleeps" || break; }
        i=$((i + 1))
    done
    undo_changes "$RUN" "memsleep wakealarm"
    deep_verdicts
    # Device errors the kernel logged while waking, one line per message with the sleeps it came in.
    if [ -s "$RUN/resume-errors" ]; then
        w=$(awk -F'\t' '{ m = $2; if (!(m in n)) o[++k] = m; n[m]++; s[m] = s[m] (s[m] == "" ? "" : ",") $1 }
            END { for (j = 1; j <= k && j <= 3; j++) printf "%s%s (%s)", (j > 1 ? "; " : ""), o[j], s[o[j]] }' "$RUN/resume-errors")
        w=$(mv1 "$w")
        verdict WARN "При пробуждении ядро сообщало об ошибках устройств (номера снов в скобках): $w" \
            "While waking, the kernel reported device errors (the sleeps in brackets): $w"
    fi
    local ndone okn avg
    ndone=$(st_int sleep_done)
    okn=$(st_int sleep_ok)
    if [ "$ndone" -gt 0 ] && [ "$okn" = "$ndone" ]; then
        verdict OK "Сон: $okn из $ndone раз уснул и проснулся по будильнику, устройства на месте." \
            "Sleep: $okn of $ndone times went to sleep and woke by the alarm, devices all there."
    fi
    avg=$(st_get sleep_fw_ms | avg)
    if [ -n "$avg" ]; then
        verdict INFO "Прошивка при пробуждении из сна: в среднем $avg мс (FPDT)." "The firmware part of waking from sleep: $avg ms on average (FPDT)."
    fi
    [ "$STOPNOW" = 1 ] && return 1
    return 0
}

deep_verdicts() {
    local b a1 an
    [ "$DEEP" = 1 ] || return 0
    b=$(st_get deep_before)
    a1=$(st_get deep_after_1)
    an=$(st_get "deep_after_$(st_int sleep_done)")
    case $b in
    off)
        verdict SKIP "Вентилятор после сна: в этой загрузке им управляет не Z3Fan (бит 6 DEh = 0), проба не делалась (fan.txt)." \
            "The fan after sleep: Z3Fan does not drive it this boot (DEh bit 6 = 0), no probe (fan.txt)."
        return 0
        ;;
    dead | fail | '')
        verdict WARN "Вентилятор: проба до сна не прошла (${b:-нет}): Z3Fan не подтвердил работу ещё до сна; итог после сна ненадёжен (fan.txt)." \
            "The fan: the probe before sleep failed (${b:-none}): Z3Fan did not confirm even before sleep, so the result after sleep is not reliable (fan.txt)."
        return 0
        ;;
    esac
    if [ "$a1" = dead ] || [ "$an" = dead ]; then
        verdict ERR "Вентилятор после сна: Z3Fan не работает — до сна бит 7 DEh возвращался, после сна нет. Это ошибка T2.0 «обороты не регулируются после пробуждения» (fan.txt)." \
            "The fan after sleep: Z3Fan does not run: before sleep DEh bit 7 came back, after sleep it does not. This is the T2.0 bug \"no fan control after waking\" (fan.txt)."
    elif [ "$a1" = ok ]; then
        verdict OK "Вентилятор после сна: Z3Fan работает (бит 7 DEh возвращается и до, и после сна)." \
            "The fan after sleep: Z3Fan runs (DEh bit 7 comes back both before and after sleep)."
    elif [ "$a1" = off ]; then
        verdict ERR "Вентилятор после сна: бит 6 DEh («Z3Fan включён») пропал после сна (fan.txt)." "The fan after sleep: DEh bit 6 (\"Z3Fan armed\") is gone after sleep (fan.txt)."
    else
        verdict WARN "Вентилятор после сна: проба не получилась (${a1:-нет}, fan.txt)." "The fan after sleep: the probe did not work (${a1:-none}, fan.txt)."
    fi
}

# ================================================================ z3test: load and idle
#
# Built-in tools only. Memory: every logical CPU gets a worker that writes a pattern over its share of memory in a RAM
# file system and reads it back against the same pattern made again (cmp, or a hash of both where there is no cmp),
# pattern after pattern. CPU: between patterns each worker repeats a fixed calculation (gzip of a fixed stream and a sum
# in awk) whose result must come out the same as at the start.

LOAD_PATTERNS="00 ff 55 aa 33 cc txt"
LOAD_DIR=""
# What the system has: a minimal Linux (busybox) may lack cmp, tr, cksum or awk's sqrt (seen on the owner's board).
# LOAD_CMP: cmp, or "hash" (the same stream through a hasher both times), or nothing (no memory patterns then).
LOAD_CMP=""
LOAD_HASH=""
LOAD_TR=1
LOAD_FP=1
load_tools() {
    local h
    LOAD_HASH=""
    for h in cksum sha256sum md5sum sum; do
        if have "$h"; then
            LOAD_HASH=$h
            break
        fi
    done
    if have cmp; then LOAD_CMP=cmp; elif [ -n "$LOAD_HASH" ]; then LOAD_CMP=hash; else LOAD_CMP=""; fi
    if have tr; then LOAD_TR=1; else LOAD_TR=0; fi
    if [ "$(awk 'BEGIN { printf "%.0f", sqrt(16) }' 2>/dev/null)" = 4 ]; then LOAD_FP=1; else LOAD_FP=0; fi
}
hashed() { if [ -n "$LOAD_HASH" ]; then "$LOAD_HASH"; else wc -c; fi; }
# Without tr: a 1 MiB block of each byte pattern, made once in the RAM folder by doubling, then repeated by cat.
make_blocks() {
    local b f k
    for b in ff 55 aa 33 cc; do
        f=$1/block-$b
        printf "\\$(printf '%03o' "0x$b")" >"$f"
        k=0
        while [ "$k" -lt 20 ]; do
            cat "$f" "$f" >"$f.2" && mv -f "$f.2" "$f"
            k=$((k + 1))
        done
    done
}
gen() { # gen PATTERN MIB PASS: MIB MiB of the pattern on stdout
    local k
    case $1 in
    00) head -c "$(($2 * 1048576))" /dev/zero ;;
    # a text line that changes with the pass (yes and head are in coreutils and in busybox; busybox seq has no -f)
    txt) yes "z3test pass $3 $(printf '%07d' "$3") ~" | head -c "$(($2 * 1048576))" ;;
    *)
        if [ "$LOAD_TR" = 1 ]; then
            head -c "$(($2 * 1048576))" /dev/zero | tr '\000' "\\$(printf '%03o' "0x$1")"
        else
            k=0
            while [ "$k" -lt "$2" ]; do
                cat "$LOAD_DIR/block-$1"
                k=$((k + 1))
            done
        fi
        ;;
    esac
}
fsize() { stat -c %s "$1" 2>/dev/null || wc -c <"$1" 2>/dev/null; }
# The fixed calculation: gzip of a fixed stream (hashed), and a floating point sum in awk (an integer one where this awk
# has no sqrt). Must come out the same every time.
calc() {
    local a="" b
    if have gzip; then a=$(seq 1 400000 | gzip -1 -c | hashed); fi
    if [ "$LOAD_FP" = 1 ]; then
        b=$(awk 'BEGIN { s = 0; for (i = 1; i <= 1500000; i++) s += sqrt(i) / (i + 0.5); printf "%.17g", s }')
    else
        b=$(awk 'BEGIN { h = 7; for (i = 1; i <= 3000000; i++) h = (h * 31 + i) % 1000000007; printf "%.0f", h }')
    fi
    printf '%s|%s' "$a" "$b"
}
load_worker() { # load_worker ID MIB END_UPTIME DIR GOLD (MIB 0: the calculation only, no memory patterns)
    local id=$1 mb=$2 end=$3 dir=$4 gold=$5 f=$4/w$1 pass=0 p want got h same
    want=$((mb * 1048576))
    while [ "$mb" = 0 ]; do
        if [ "$(uptime_s)" -ge "$end" ] || [ -e "$dir/stop" ]; then return 0; fi
        h=$(calc)
        if [ "$h" = "$gold" ]; then echo "CALC $id" >>"$dir/log"; else echo "CPUERR $id [$h] [$gold]" >>"$dir/log"; fi
    done
    while :; do
        for p in $LOAD_PATTERNS; do
            if [ "$(uptime_s)" -ge "$end" ] || [ -e "$dir/stop" ]; then
                rm -f "$f"
                return 0
            fi
            gen "$p" "$mb" "$pass" >"$f" 2>/dev/null
            got=$(fsize "$f")
            if [ "$got" != "$want" ]; then
                echo "WRITEFAIL $id $p ${got:-0} of $want" >>"$dir/log"
                rm -f "$f"
                sleep 5
                continue
            fi
            if [ "$LOAD_CMP" = cmp ]; then
                gen "$p" "$mb" "$pass" | cmp -s - "$f" && same=1 || same=0
            else
                [ "$(gen "$p" "$mb" "$pass" | hashed)" = "$(hashed <"$f")" ] && same=1 || same=0
            fi
            if [ "$same" = 1 ]; then
                echo "PASS $id $p $mb" >>"$dir/log"
            else
                echo "MEMERR $id $p $pass" >>"$dir/log"
                if [ "$LOAD_CMP" = cmp ]; then
                    gen "$p" "$mb" "$pass" | cmp -l - "$f" 2>/dev/null | head -n 8 |
                        awk -v id="$id" -v p="$p" '{ printf "  worker %s pattern %s: byte %s, want %s, got %s (octal)\n", id, p, $1, $2, $3 }' >>"$dir/log"
                fi
            fi
            h=$(calc)
            if [ "$h" = "$gold" ]; then echo "CALC $id" >>"$dir/log"; else echo "CPUERR $id [$h] [$gold]" >>"$dir/log"; fi
        done
        pass=$((pass + 1))
    done
}
LOAD_PIDS=""
load_stop() {
    [ -n "$LOAD_DIR" ] || return 0
    : >"$LOAD_DIR/stop" 2>/dev/null
    local k=0 p alive=1
    while [ "$alive" = 1 ] && [ "$k" -lt 120 ]; do
        alive=0
        for p in $LOAD_PIDS; do kill -0 "$p" 2>/dev/null && alive=1; done
        [ "$alive" = 1 ] && sleep 1
        k=$((k + 1))
    done
    for p in $LOAD_PIDS; do kill "$p" 2>/dev/null; done
    for p in $LOAD_PIDS; do wait "$p" 2>/dev/null; done
    LOAD_PIDS=""
}
# A place in RAM for the memory patterns: a tmpfs with room. /dev/shm first, then /run/shm, /tmp and /run when they are
# tmpfs (a /dev/shm that is a plain folder on a disk does not count: the patterns would wear the disk); else a tmpfs of the
# test's own, mounted under the run folder (written to the journal first, unmounted right after the load). Prints
# "FOLDER|FREE_MIB|WHAT" or nothing.
fs_type() { awk -v p="$1" '$2 == p { t = $3 } END { print t }' /proc/mounts 2>/dev/null; }
fs_free_mib() { df -Pm "$1" 2>/dev/null | awk 'NR == 2 { print $4 }'; }
load_place() {
    local p f
    for p in ${Z3TEST_LOAD_PLACES:-/dev/shm /run/shm /tmp /run}; do
        [ -d "$p" ] && [ "$(fs_type "$p")" = tmpfs ] || continue
        f=$(fs_free_mib "$p")
        case $f in '' | *[!0-9]*) continue ;; esac
        if [ "$f" -ge 256 ]; then
            printf '%s|%s|%s' "$p" "$f" "$p"
            return 0
        fi
    done
    p=$RUN/ram
    mkdir -p "$p" || return 1
    record "mount|$p"
    if mount -t tmpfs -o "size=${1}m,mode=700" z3test "$p" 2>>"$RUN/load.txt"; then
        printf '%s|%s|%s' "$p" "$1" "own tmpfs"
        return 0
    fi
    undo_changes "$RUN" mount
    return 1
}

# Tctl from k10temp or zenpower only (the processor's own sensor through its own driver), in degrees.
tctl() {
    local h
    for h in /sys/class/hwmon/hwmon*; do
        case $(sv "$h/name") in k10temp | zenpower)
            awk '{ printf "%.1f", $1 / 1000 }' "$h/temp1_input" 2>/dev/null
            return 0
            ;;
        esac
    done
}
sample() { printf '%s,%s,%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$PHASE" "$(tctl)" >>"$RUN/sensors.csv"; }

ph_load() {
    local min np avail shm total per end gold i t0 el nextlog=60 stopped=0 c_pass c_mem c_cpu c_calc c_wf gb tmax where place how
    min=$(st_int load_min)
    if [ "$min" -le 0 ]; then
        verdict SKIP "Нагрузка пропущена по выбору." "Load skipped by choice."
        return 0
    fi
    np=$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo)
    load_tools
    avail=$(awk '/^MemAvailable:/ { printf "%.0f", $2 / 1024 }' /proc/meminfo)
    total=$((avail * 6 / 10))
    [ "$total" -gt $((np * 1024)) ] && total=$((np * 1024))
    per=0
    where=""
    if [ -z "$LOAD_CMP" ]; then
        how="no program to compare the patterns with (cmp, cksum, sha256sum, md5sum)"
    else
        where=$(load_place "$total")
        [ -n "$where" ] || how="no tmpfs (no /dev/shm) and an own tmpfs could not be mounted"
    fi
    if [ -n "$where" ]; then
        place=${where%%|*}
        shm=${where#*|}
        how=${shm#*|}
        shm=${shm%%|*}
        [ "$total" -gt $((shm * 9 / 10)) ] && total=$((shm * 9 / 10))
        per=$((total / np))
        [ "$per" -gt 1024 ] && per=1024
        if [ "$per" -lt 16 ]; then
            per=0
            how="too little room: $shm MiB free in $place"
        else
            LOAD_DIR=$place/z3test-load.$$
            record "shm|$LOAD_DIR"
            if ! mkdir -m 700 "$LOAD_DIR" 2>/dev/null; then
                per=0
                how="cannot make a folder in $place"
            elif [ "$LOAD_TR" = 0 ]; then
                make_blocks "$LOAD_DIR"
            fi
        fi
    fi
    if [ "$per" = 0 ]; then
        # No room in RAM for the patterns: the CPU half of the load still runs, and the result says what was not checked.
        LOAD_DIR=$RUN/cpuload
        mkdir -p "$LOAD_DIR"
        verdict WARN "Память под нагрузкой не проверялась: нет места в ОЗУ для шаблонов ($how); проверялись только вычисления процессора." \
            "Memory was not checked under load: no room in RAM for the patterns ($how); only the CPU calculations were checked."
    fi
    gold=$(calc)
    st_set load_started "$(now)"
    if [ "$per" -gt 0 ]; then
        say2 "Нагрузка $min мин, потоков: $np; проверка $(gib $((per * np)) '%.1f') ГБ памяти по шаблонам ($how) и вычислений процессора." \
            "Load for $min min: $np threads, pattern checks over $(gib $((per * np)) '%.1f') GB of memory ($how) and CPU calculation checks."
    else
        say2 "Нагрузка $min мин, потоков: $np; только вычисления процессора." "Load for $min min: $np threads, CPU calculations only."
    fi
    logf load.txt "workers $np, $per MiB each in $LOAD_DIR (${how:-?}), MemAvailable $avail MiB, free there ${shm:-?} MiB; compare ${LOAD_CMP:-none}, hash ${LOAD_HASH:-wc -c}, tr $LOAD_TR, awk sqrt $LOAD_FP; reference calculation [$gold]"
    end=$(($(uptime_s) + min * 60))
    for i in $(seq 0 $((np - 1))); do
        (
            trap '' HUP INT
            load_worker "$i" "$per" "$end" "$LOAD_DIR" "$gold"
        ) &
        LOAD_PIDS="$LOAD_PIDS $!"
        renice -n 10 -p $! >/dev/null 2>&1
    done
    reset_beat
    t0=$(uptime_s)
    while [ "$(uptime_s)" -lt "$end" ]; do
        if ! wait_step 5 "load $((($(uptime_s) - t0) / 60)) min" gaps; then
            stopped=1
            break
        fi
        el=$(($(uptime_s) - t0))
        if [ "$el" -ge "$nextlog" ]; then
            nextlog=$((nextlog + 60))
            sample
            logf load.txt "minute $((el / 60)): pattern passes $(grep -c '^PASS ' "$LOAD_DIR/log" 2>/dev/null), memory errors $(grep -c '^MEMERR ' "$LOAD_DIR/log" 2>/dev/null), calculations $(grep -c '^CALC ' "$LOAD_DIR/log" 2>/dev/null), CPU errors $(grep -c '^CPUERR ' "$LOAD_DIR/log" 2>/dev/null), Tctl $(t=$(tctl); printf '%s' "${t:-?}") C"
        fi
    done
    load_stop
    el=$(awk -v s="$(($(uptime_s) - t0))" 'BEGIN { printf "%.1f", s / 60 }')
    c_pass=$(grep -c '^PASS ' "$LOAD_DIR/log" 2>/dev/null)
    c_mem=$(grep -c '^MEMERR ' "$LOAD_DIR/log" 2>/dev/null)
    c_cpu=$(grep -c '^CPUERR ' "$LOAD_DIR/log" 2>/dev/null)
    c_calc=$(grep -c '^CALC ' "$LOAD_DIR/log" 2>/dev/null)
    c_wf=$(grep -c '^WRITEFAIL ' "$LOAD_DIR/log" 2>/dev/null)
    gb=$(grep '^PASS ' "$LOAD_DIR/log" 2>/dev/null | awk '{ s += $4 } END { printf "%.0f", s / 1024 }')
    grep -v -E '^(PASS|CALC) ' "$LOAD_DIR/log" 2>/dev/null | head -n 200 | sed 's/^/    /' >>"$RUN/load.txt"
    logf load.txt "end: pattern passes ${c_pass:-0} ($gb GB checked), memory errors ${c_mem:-0}, calculations ${c_calc:-0}, CPU errors ${c_cpu:-0}, write failures ${c_wf:-0}"
    LOAD_DIR=""
    undo_changes "$RUN" "shm mount"
    rm -rf "${RUN:?}/cpuload"
    tmax=$(awk -F, '$2 == "load" && $3 != "" { if ($3 + 0 > m) m = $3 + 0 } END { if (m) printf "%.0f", m }' "$RUN/sensors.csv" 2>/dev/null)
    [ "${c_mem:-0}" -gt 0 ] && verdict ERR "Ошибки памяти под нагрузкой: $c_mem (подробно — load.txt). Это серьёзно: память или её настройки нестабильны." \
        "Memory errors under load: $c_mem (details in load.txt). This is serious: the memory or its settings are unstable."
    [ "${c_cpu:-0}" -gt 0 ] && verdict ERR "Ошибки вычислений процессора под нагрузкой: $c_cpu (load.txt). Похоже на нестабильность: разгон, Curve Optimizer или напряжение." \
        "CPU calculation errors under load: $c_cpu (load.txt). Looks like instability: overclocking, Curve Optimizer or voltage."
    [ "${c_wf:-0}" -gt 0 ] && verdict WARN "Нагрузке не хватило места в памяти ($how): $c_wf раз (load.txt)." "The load ran out of room in RAM ($how): $c_wf times (load.txt)."
    if [ "$per" = 0 ] && [ "${c_cpu:-0}" = 0 ]; then
        verdict OK "Нагрузка $el мин, потоков: $np; вычислений ${c_calc:-0}, ошибок нет (память не проверялась, см. выше)." \
            "Load for $el min on $np threads: ${c_calc:-0} calculations, no errors (memory not checked, see above)."
    elif [ "${c_mem:-0}" = 0 ] && [ "${c_cpu:-0}" = 0 ]; then
        verdict OK "Нагрузка $el мин, потоков: $np; проверено $gb ГБ памяти по шаблонам, вычислений ${c_calc:-0}, ошибок нет." \
            "Load for $el min on $np threads: $gb GB of memory checked by patterns, ${c_calc:-0} calculations, no errors."
    fi
    [ -n "$tmax" ] && verdict INFO "Температура процессора под нагрузкой: до $tmax °C (Tctl, k10temp)." "CPU temperature under load: up to $tmax °C (Tctl, k10temp)."
    [ "$stopped" = 1 ] && return 1
    return 0
}

ph_idle() {
    local min t0 k=0
    min=$(st_int idle_min)
    if [ "$min" -le 0 ]; then
        verdict SKIP "Простой пропущен по выбору." "Idling skipped by choice."
        return 0
    fi
    say2 "Простой $min мин: компьютер ничего не делает (часть зависаний Ryzen бывает именно так)." \
        "Idling for $min min: the computer does nothing (some Ryzen hangs happen just like this)."
    st_set idle_started "$(now)"
    reset_beat
    t0=$(uptime_s)
    while [ "$(($(uptime_s) - t0))" -lt $((min * 60)) ]; do
        wait_step 10 "idle $((($(uptime_s) - t0) / 60)) min" gaps || return 1
        k=$((k + 1))
        [ $((k % 6)) = 0 ] && sample
    done
    verdict OK "Простой $min мин прошёл без зависаний." "$min min of idling went without a hang."
    return 0
}

# ================================================================ z3test: restarts

# The systemd unit that runs the copy of this script after every start while a run is on.
install_unit() {
    local b
    b=$(command -v bash)
    record "unit|$UNIT"
    cat >"$UNIT_DIR/$UNIT" <<EOF
# Z3NOVO firmware test (z3test.sh): goes on after each restart of the test, then removes itself.
[Unit]
Description=Z3NOVO firmware test (z3test.sh), goes on after a restart
After=local-fs.target systemd-journald.service

[Service]
Type=simple
ExecStart=$b $RUN/z3test.sh --resume

[Install]
WantedBy=multi-user.target
EOF
    if [ -z "${Z3TEST_UNIT_DIR:-}" ]; then
        systemctl daemon-reload >/dev/null 2>&1
        systemctl enable "$UNIT" >/dev/null 2>&1 || return 1
    fi
    return 0
}

# The boot id as journalctl --list-boots prints it (no dashes).
boot_id_plain() { printf '%s' "${1//-/}"; }
# journalctl index of a boot (0 = this one, -1 the one before), or nothing.
boot_index() { T 30 journalctl --list-boots --no-pager -q 2>/dev/null | awk -v id="$(boot_id_plain "$1")" '{ for (i = 1; i <= 2; i++) if ($i == id) { print $1; exit } }'; }

ph_reboot() {
    local n i ndone avg
    n=$(st_int reboot_total)
    if [ "$n" -le 0 ]; then
        verdict SKIP "Перезагрузки пропущены по выбору." "Restarts skipped by choice."
        return 0
    fi
    if [ -n "$(st_get reboot_block)" ]; then
        verdict SKIP "Перезагрузки пропущены: $(st_get reboot_block)." "Restarts skipped: $(st_get reboot_block)."
        return 0
    fi
    ndone=$(st_int reboot_done)
    if [ "$ndone" -ge "$n" ]; then
        if [ "$(st_int reboot_bad)" = 0 ]; then
            avg=$(st_get reboot_secs_list | avg)
            verdict OK "Перезагрузки: $ndone из $n прошли чисто; от команды до старта системы в среднем $(durr "${avg:-0}")." \
                "Restarts: $ndone of $n went cleanly; from the command to the system starting $(dur "${avg:-0}") on average."
        fi
        return 0
    fi
    i=$((ndone + 1))
    if [ "$i" = 1 ]; then
        say2 "Перезагрузки подряд: $n. Сейчас система перезагрузится, проверка продолжится сама; входить в систему не нужно." \
            "Restarts: $n in a row. The system restarts now and the test goes on by itself; you do not need to log in."
    else
        say2 "Перезагрузка $i из $n." "Restart $i of $n."
    fi
    have wall && wall "Z3NOVO z3test: перезагрузка $i из $n через минуту. Остановить: файл ~/Z3TEST-STOP или sudo bash z3test.sh --stop. / Restart $i of $n in a minute. To stop: a file ~/Z3TEST-STOP." 2>/dev/null
    wait_step 60 "before restart $i" || return 1
    st_set reboot_i "$i"
    st_set reboot_issued "$(now)"
    st_set reboot_bootid "$BOOT_ID"
    logf reboots.txt "restart $i of $n: systemctl reboot at $(date '+%H:%M:%S')"
    sync
    HANDOFF=1
    if [ -n "${Z3TEST_REBOOT_CMD:-}" ]; then "$Z3TEST_REBOOT_CMD"; else systemctl reboot >>"$RUN/reboots.txt" 2>&1; fi
    # The system ends this process while it goes down. Still here after ten minutes: the restart did not happen.
    if wait_step 600 "restart $i under way"; then
        HANDOFF=0
        st_set reboot_issued 0
        verdict WARN "Перезагрузка $i не случилась (её отменили?); остальные пропущены." "Restart $i did not happen (cancelled?); the rest were skipped."
        return 0
    fi
    HANDOFF=0
    st_set reboot_issued 0
    return 1
}

# After a restart the test asked for: how it went.
check_reboot() {
    local i n issued boot down idx end extra bad=0
    i=$(st_int reboot_i)
    n=$(st_int reboot_total)
    issued=$(st_int reboot_issued)
    boot=$(boot_epoch)
    down=$((boot - issued))
    st_app reboot_secs_list "$down"
    end="unknown: the journal is kept in RAM only"
    extra=0
    if journal_persistent; then
        idx=$(boot_index "$(st_get reboot_bootid)")
        if [ -n "$idx" ]; then
            end=$(T 20 journalctl -b "$idx" -n 40 -o short-iso -q --no-pager 2>/dev/null | classify_end)
            extra=$((-idx - 1))
            {
                printf 'the last lines of the boot that was restarted (journal boot %s):\n' "$idx"
                T 20 journalctl -b "$idx" -n 25 -o short-iso -q --no-pager 2>/dev/null | ind
            } >>"$RUN/reboots.txt"
        else
            end="unknown: the restarted boot is not in the journal"
        fi
    fi
    logf reboots.txt "restart $i of $n: the system started at $(ttime "$boot"), $(dur "$down") after the command; the boot before ended: $end; starts in between: $((extra + 1)); this script back at $(date '+%H:%M:%S')"
    case $end in
    ABRUPT*)
        verdict ERR "Перезагрузка $i прошла не чисто: прошлый запуск оборвался без штатного выключения — похоже, завис и его включили заново." \
            "Restart $i was not clean: the boot before it ended without a proper shutdown; it seems to have hung and was powered on again."
        bad=1
        ;;
    esac
    if [ "$extra" -gt 0 ]; then
        verdict WARN "Перезагрузка $i: система стартовала несколько раз ($((extra + 1))) вместо одного." "Restart $i: the system started $((extra + 1)) times instead of once."
        bad=1
    fi
    if [ "$down" -gt 300 ]; then
        verdict WARN "Перезагрузка $i заняла $(durr "$down") — долго (зависание, которое кто-то сбросил?)." "Restart $i took $(dur "$down"), which is long (a hang somebody reset?)."
        bad=1
    fi
    [ "$bad" = 1 ] && st_add reboot_bad
    st_set reboot_done "$i"
    st_set reboot_issued 0
    check_devices "перезагрузки $i" "restart $i" WARN
}

# After a start nobody asked for, in the middle of a step: a hang, a kernel panic, a power cut, or a person.
check_unexpected() {
    local ph boot beat bwhat end end_ru end_en what_ru what_en idx gap gap_en
    ph=$(st_get phase)
    boot=$(boot_epoch)
    beat=0
    bwhat=""
    [ -r "$RUN/heartbeat" ] && IFS='|' read -r beat _ bwhat <"$RUN/heartbeat"
    case $beat in '' | *[!0-9]*) beat=0 ;; esac
    end="unknown"
    if journal_persistent; then
        idx=$(boot_index "$(st_get boot_id)")
        [ -n "$idx" ] || idx=-1
        end=$(T 20 journalctl -b "$idx" -n 60 -o short-iso -q --no-pager 2>/dev/null | classify_end)
        {
            printf 'the last lines of the boot that broke off (journal boot %s):\n' "$idx"
            T 20 journalctl -b "$idx" -n 60 -o short-iso -q --no-pager 2>/dev/null | ind
        } >>"$RUN/progress.txt"
    fi
    # classify_end (z3report) answers "English / Russian"; without a journal the answer is unknown.
    case $end in
    *' / '*)
        end_en=${end%% / *}
        end_ru=${end#* / }
        ;;
    *)
        end_en="unknown, the journal is kept in RAM only"
        end_ru="неизвестно: журнал системы хранится только в памяти"
        ;;
    esac
    gap="?"
    gap_en="?"
    [ "$beat" -gt 0 ] && gap=$(durr $((boot - beat))) && gap_en=$(dur $((boot - beat)))
    logp "started again at $(tlocal "$boot") without being asked: last beat $(tlocal "$beat") ($bwhat), the boot before ended: $end"
    st_set unexpected "$ph"
    case $ph in
    snapshot) what_ru="снимок системы"; what_en="the system snapshot" ;;
    sleep) what_ru="сон"; what_en="sleep" ;;
    load) what_ru="нагрузка"; what_en="load" ;;
    idle) what_ru="простой"; what_en="idling" ;;
    reboot) what_ru="перезагрузки"; what_en="restarts" ;;
    *) what_ru=$ph; what_en=$ph ;;
    esac
    if [ "$ph" = sleep ] && case $end in clean*) false ;; *) true ;; esac; then
        verdict ERR "КОМПЬЮТЕР НЕ ПРОСНУЛСЯ из сна $(st_int sleep_i) (уснул в $(ttime "$(st_int sleep_entered)")): его включили заново, система стартовала в $(ttime "$boot") (конец прошлого запуска: $end_ru)." \
            "THE COMPUTER DID NOT WAKE from sleep $(st_int sleep_i) (asleep at $(ttime "$(st_int sleep_entered)")): it was powered on again, the system started at $(ttime "$boot") (the boot before ended: $end_en)."
    else
        case $end in
        clean*)
            verdict WARN "Проверку прервал штатный перезапуск или выключение во время шага «$what_ru» (последняя отметка в $(ttime "$beat"), старт в $(ttime "$boot"))." \
                "A normal restart or shutdown cut the test short during \"$what_en\" (last sign of life at $(ttime "$beat"), started at $(ttime "$boot"))."
            ;;
        *panic*)
            verdict ERR "Сбой ядра (паника) во время шага «$what_ru»: последняя отметка «жив» в $(ttime "$beat"), система снова стартовала в $(ttime "$boot")." \
                "A kernel panic during \"$what_en\": last sign of life at $(ttime "$beat"), the system started again at $(ttime "$boot")."
            ;;
        *)
            verdict ERR "Компьютер завис или выключился во время шага «$what_ru»: последняя отметка «жив» в $(ttime "$beat"), система снова стартовала в $(ttime "$boot") (через $gap); конец прошлого запуска: $end_ru." \
                "The computer hung or lost power during \"$what_en\": last sign of life at $(ttime "$beat"), the system started again at $(ttime "$boot") ($gap_en later); the boot before ended: $end_en."
            ;;
        esac
    fi
}

# ================================================================ z3test: the end of a run

# The kernel log of the test window (every boot of it when the journal is kept on disk, else this boot only), sorted
# into plain categories as the test stick does.
final_kernel() {
    local since f=$RUN/kernel.txt src x mark
    since=$(st_int started)
    if journal_persistent; then
        src="journal, every boot since $(tlocal "$since")"
        T 120 journalctl -k --since "@$since" -o short-iso -q --no-pager 2>/dev/null | nofw >"$TMPD/klog"
        T 120 journalctl -k -p warning --since "@$since" -o short-iso -q --no-pager 2>/dev/null | nofw | tail -n 400 >"$TMPD/kwarn"
    else
        # dmesg -r: "<N>[time] text", N % 8 the level (4 warning and worse); util-linux and busybox both have it.
        T 20 dmesg -r 2>/dev/null | nofw >"$TMPD/kraw"
        mark=$(st_get kmsg_mark)
        if [ -n "$mark" ] && grep -q -F "$mark" "$TMPD/kraw"; then
            awk -v m="$mark" 'f; index($0, m) { f = 1 }' "$TMPD/kraw" >"$TMPD/kraw.cut"
            mv -f "$TMPD/kraw.cut" "$TMPD/kraw"
            src="dmesg since the start of the test (the journal is kept in RAM only)"
        elif [ "$(boot_epoch)" -ge "$since" ]; then
            src="dmesg of this boot, which began during the test (the journal is kept in RAM only)"
        else
            src="dmesg of this boot, including the time before the test (no start mark in the kernel log)"
        fi
        sed 's/^<[0-9]*>//' "$TMPD/kraw" >"$TMPD/klog"
        awk '{ if (match($0, /^<[0-9]+>/)) { l = substr($0, 2, RLENGTH - 2) % 8; if (l <= 4) print substr($0, RLENGTH + 1) } }' "$TMPD/kraw" | tail -n 400 >"$TMPD/kwarn"
    fi
    {
        printf '%sZ3NOVO z3test: kernel log of the test window / журнал ядра за время проверки (%s)\n' "$FIXED" "$src"
        printf '\n%s=== [boots] Starts and sleeps / Запуски и сны\n' "$FIXED"
        grep -E 'Linux version|PM: suspend (entry|exit)|ACPI: PM: (Waking|Low-level)|Restarting system|reboot: ' "$TMPD/klog" | tail -n 200 | ind
        printf '\n%s=== [problems] Machine checks, panics, lockups, PCIe, GPU, disks, USB, ACPI / Ошибки\n' "$FIXED"
    } >"$f"
    awk '
        function hit(c, l) { n[c]++; if (n[c] <= 40) print "    [" c "] " substr(l, 1, 300) }
        {
            l = $0
            if (l ~ /mce: \[Hardware Error\]|Machine check events logged|\[Hardware Error\]/) hit("mce", l)
            if (l ~ /soft lockup|hard LOCKUP|self-detected stall|rcu_.*detected stall|rcu: INFO: |blocked for more than [0-9]+ seconds/) hit("lockup", l)
            if (l ~ /Oops|BUG: |kernel BUG|general protection fault|Kernel panic/) hit("oops", l)
            else if (l ~ /WARNING: CPU: [0-9]+ PID/) hit("kwarn", l)
            if (l ~ /AER: .*(Uncorrect|Fatal)/) hit("aer_bad", l); else if (l ~ /AER: .*Correct|PCIe Bus Error/) hit("aer_cor", l)
            if (l ~ /amdgpu.*(timeout|GPU reset|hang|GPU fault|page fault)|ring [a-z_0-9.]+ timeout|nouveau.*(timeout|fault)|NVRM: Xid/) hit("gpu_hang", l)
            if (l ~ /usb .*(device descriptor read.*error|not accepting address|unable to enumerate|over-current|cannot reset)|xhci_hcd.*(HC died|Host halt|not responding)/) hit("usb", l)
            if (l ~ /ata[0-9.]+: .*(exception Emask|failed command|SError|hard resetting link|link is slow|limiting SATA link|revalidation failed)|nvme[0-9]+.*(I\/O [0-9]+ QID|timeout|resetting controller|controller is down|Device not ready|Abort status)/) hit("disk", l)
            else if (l ~ /(I\/O error|Buffer I\/O error|blk_update_request|critical medium error)/) hit("io", l)
            if (l ~ /ACPI (BIOS )?Error|ACPI Exception|\(AE_[A-Z_]+\)/) hit("acpi", l)
            if (l ~ /clocksource: .*unstable|Marking TSC unstable/) hit("clock", l)
            if (l ~ /Out of memory|oom-kill|Killed process/) hit("oom", l)
            if (l ~ /thermal|THERMTRIP|temperature above/ && l ~ /critical|shutdown|throttl/) hit("thermal", l)
        }
        END { for (c in n) printf "%s %d\n", c, n[c] > "/dev/stderr" }' "$TMPD/klog" >>"$f" 2>"$TMPD/kcount"
    {
        printf '\n%s=== [warnings] Kernel warnings and errors, last 400 / Предупреждения и ошибки ядра\n' "$FIXED"
        ind <"$TMPD/kwarn"
    } >>"$f"
    kc() { awk -v c="$1" '$1 == c { print $2 }' "$TMPD/kcount"; }
    x=$(kc mce); [ -n "$x" ] && verdict ERR "Аппаратные ошибки процессора или памяти (MCE): строк $x (kernel.txt)." "CPU or memory hardware errors (MCE): $x lines (kernel.txt)."
    x=$(kc lockup); [ -n "$x" ] && verdict ERR "Подвисания: ядро отметило, что процессор или задача надолго застряли (сообщений: $x, kernel.txt)." "Stalls: the kernel saw a CPU or a task stuck for a long time ($x messages, kernel.txt)."
    x=$(kc oops); [ -n "$x" ] && verdict ERR "Сбой ядра Linux (Oops/BUG/panic; сообщений: $x, kernel.txt)." "Linux kernel crash (Oops/BUG/panic; $x messages, kernel.txt)."
    x=$(kc kwarn); [ -n "$x" ] && verdict WARN "Предупреждения ядра (WARNING; сообщений: $x, kernel.txt)." "Kernel warnings (WARNING; $x messages, kernel.txt)."
    x=$(kc aer_bad); [ -n "$x" ] && verdict ERR "Неисправимые ошибки шины PCIe (сообщений: $x, kernel.txt)." "Uncorrectable PCIe bus errors ($x messages, kernel.txt)."
    x=$(kc aer_cor); [ -n "$x" ] && verdict WARN "Исправленные ошибки шины PCIe (сообщений: $x, kernel.txt)." "Corrected PCIe bus errors ($x messages, kernel.txt)."
    x=$(kc gpu_hang); [ -n "$x" ] && verdict WARN "Видео: зависания или сбросы графики (сообщений: $x, kernel.txt)." "Graphics hangs or resets ($x messages, kernel.txt)."
    x=$(kc usb); [ -n "$x" ] && verdict WARN "Ошибки USB: устройство не отвечало или не опозналось (сообщений: $x, kernel.txt)." "USB errors: a device did not answer or enumerate ($x messages, kernel.txt)."
    x=$(kc disk); [ -n "$x" ] && verdict ERR "Ошибки дисков SATA или NVMe (сообщений: $x, kernel.txt)." "SATA or NVMe disk errors ($x messages, kernel.txt)."
    x=$(kc io); [ -n "$x" ] && verdict WARN "Ошибки чтения или записи дисков (сообщений: $x, kernel.txt)." "Disk read or write errors ($x messages, kernel.txt)."
    x=$(kc acpi); [ -n "$x" ] && verdict WARN "Ошибки ACPI прошивки (строк: $x, kernel.txt)." "Firmware ACPI errors ($x lines, kernel.txt)."
    x=$(kc clock); [ -n "$x" ] && verdict WARN "Часы процессора сочтены ненадёжными (часто из-за долгих SMI прошивки; kernel.txt)." "The CPU clock was judged unreliable (often from long firmware SMIs; kernel.txt)."
    x=$(kc oom); [ -n "$x" ] && verdict WARN "Не хватило памяти, ядро остановило программу (kernel.txt)." "Out of memory, the kernel stopped a program (kernel.txt)."
    x=$(kc thermal); [ -n "$x" ] && verdict WARN "Ядро сообщило о перегреве (kernel.txt)." "The kernel reported overheating (kernel.txt)."
    [ -s "$TMPD/kcount" ] || verdict OK "Журнал ядра за время проверки чистый: нет аппаратных ошибок, паник, подвисаний, сбросов видео, ошибок дисков и USB." \
        "The kernel log of the test is clean: no hardware errors, panics, stalls, graphics resets, disk or USB errors."
    journal_persistent || verdict INFO "Журнал системы хранится только в памяти: после сбоя прошлый запуск не виден. Постоянный журнал (по желанию): sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald." \
        "The system journal lives in RAM only: after a crash the previous boot is not visible. A persistent journal (if you like): sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald."
    return 0
}

# Kernel crash logs saved during the test (pstore), and the EDAC error counters against the start.
final_pstore() {
    local since f n=0 c
    since=$(st_int started)
    for f in /sys/fs/pstore/* /var/lib/systemd/pstore/*; do
        [ -e "$f" ] || continue
        [ "$(stat -c %Y "$f" 2>/dev/null || echo 0)" -ge "$since" ] || continue
        n=$((n + 1))
        logp "pstore: $f"
    done
    [ "$n" -gt 0 ] && verdict ERR "Ядро сохранило журнал сбоя (pstore) за время проверки: $n (имена — progress.txt)." "The kernel saved a crash log (pstore) during the test: $n (names in progress.txt)."
    c=$(cat /sys/devices/system/edac/mc/mc*/ce_count 2>/dev/null | awk '{ s += $1 } END { printf "%.0f", s }')
    if [ -n "$(st_get edac_ce)" ] && [ "${c:-0}" -gt "$(st_int edac_ce)" ]; then
        verdict ERR "Исправленные ошибки памяти (EDAC) за время проверки: $((c - $(st_int edac_ce)))." "Corrected memory errors (EDAC) during the test: $((c - $(st_int edac_ce)))."
    fi
    return 0
}

write_summary() {
    local f=$1 nerr nwarn res_ru res_en t0 t1 mode_ru mode_en lv sec_ru sec_en
    nerr=$(grep -c '^ERR|' "$RUN/verdicts.txt" 2>/dev/null)
    nwarn=$(grep -c '^WARN|' "$RUN/verdicts.txt" 2>/dev/null)
    res_ru="ИТОГ: ВСЁ В ПОРЯДКЕ"
    res_en="RESULT: ALL GOOD"
    if [ "${nerr:-0}" -gt 0 ]; then
        res_ru="ИТОГ: ЕСТЬ ОШИБКИ"
        res_en="RESULT: ERRORS FOUND"
    elif [ "${nwarn:-0}" -gt 0 ]; then
        res_ru="ИТОГ: ЕСТЬ ЗАМЕЧАНИЯ"
        res_en="RESULT: SOME NOTES"
    fi
    st_set result "$res_en"
    t0=$(st_int started)
    t1=$(st_int finished)
    if [ "$(st_get mode)" = long ]; then mode_ru=долгий; mode_en=long; else mode_ru=короткий; mode_en=short; fi
    {
        printf '%s\n' "Z3NOVO: проверка в системе (z3test) — ИТОГ"
        printf '%s\n' "Скрипт z3test.sh $T_VERSION, режим «$mode_ru» (по плану около $(st_int est_min) мин); начало $(tlocal "$t0"), конец $(tlocal "$t1"), шло $(durr $((t1 - t0)))."
        printf 'Компьютер: %s\nBIOS: %s\nПроцессор: %s\nПамять: %s\nВидео: %s\nСистема: %s\n' "$(mv1 "$(st_get f_board)")" "$(mv1 "$(st_get f_bios)")" \
            "$(mv1 "$(st_get f_cpu)")" "$(mv1 "$(st_get f_memory)")" "$(mv1 "$(st_get f_graphics)")" "$(mv1 "$(st_get f_os)")"
        printf '\n==== %s ====\n' "$res_ru"
        for lv in ERR:ОШИБКИ WARN:ЗАМЕЧАНИЯ OK:'В ПОРЯДКЕ' SKIP:'ПРОПУЩЕНО ИЛИ НЕ ПРОВЕРЯЕТСЯ' INFO:СВЕДЕНИЯ; do
            grep -q "^${lv%%:*}|" "$RUN/verdicts.txt" 2>/dev/null || continue
            printf '\n%s:\n' "${lv#*:}"
            awk -F'|' -v l="${lv%%:*}" '$1 == l { print "  - " $2 }' "$RUN/verdicts.txt"
        done
        printf '\n%s\n' "Что отправить: этот архив целиком (Z3TEST-...) — в Telegram-бот @z3novo_bot («Проблема» или «Всё работает») или на GitHub: Issues → New issue."
        printf '%s\n' "Напишите версию Z3NOVO (в заголовке меню BIOS) и что было необычного. Есть ошибки — приложите и отчёт из BIOS: Del → F11."
        printf '%s\n' "Перед отправкой можно просмотреть файлы: имена, адреса и серийные номера замазаны (<host>, <user>, <serial>...)."
        printf '\n------------------------------------------------------------------------\n\n'
        printf '%s\n' "Z3NOVO in-system test (z3test): RESULT"
        printf '%s\n' "Script z3test.sh $T_VERSION, $mode_en run (about $(st_int est_min) min as planned); started $(tlocal "$t0"), ended $(tlocal "$t1"), took $(dur $((t1 - t0)))."
        printf 'Computer: %s\nBIOS: %s\nCPU: %s\nMemory: %s\nGraphics: %s\nSystem: %s\n' "$(mv1 "$(st_get f_board)")" "$(mv1 "$(st_get f_bios)")" \
            "$(mv1 "$(st_get f_cpu)")" "$(mv1 "$(st_get f_memory)")" "$(mv1 "$(st_get f_graphics)")" "$(mv1 "$(st_get f_os)")"
        printf '\n==== %s ====\n' "$res_en"
        for lv in ERR:ERRORS WARN:NOTES OK:OK SKIP:'SKIPPED OR NOT CHECKED' INFO:DETAILS; do
            grep -q "^${lv%%:*}|" "$RUN/verdicts.txt" 2>/dev/null || continue
            printf '\n%s:\n' "${lv#*:}"
            awk -F'|' -v l="${lv%%:*}" '$1 == l { print "  - " $3 }' "$RUN/verdicts.txt"
        done
        printf '\n%s\n' "What to send: this whole archive (Z3TEST-...), to the Telegram bot @z3novo_bot (\"Problem\" or \"Everything works\") or on GitHub: Issues → New issue."
        printf '%s\n' "Say which Z3NOVO version (in the BIOS menu title) and anything unusual. With errors, attach the BIOS report as well: Del, then F11."
        printf '%s\n' "You may look through the files before sending: names, addresses and serial numbers are masked (<host>, <user>, <serial>...)."
        printf '\n------------------------------------------------------------------------\n'
        printf '%s\n' "Файлы в архиве / Files in the archive:"
        printf '  %s\n' "SUMMARY.txt: этот итог / this result" \
            "report-os.txt: отчёт z3report (система, сбои за 30 дней) / the z3report report (system, crashes over 30 days)" \
            "snapshot.txt: память, линки PCIe, накопители, Secure Boot, TPM, питание / memory, PCIe links, drives, Secure Boot, TPM, power" \
            "progress.txt: все шаги по времени / every step by time" \
            "sleep.txt, fan.txt: каждый сон; вентилятор (--deep) / each sleep; the fan (--deep)" \
            "load.txt, sensors.csv: нагрузка и температура / the load and the temperature" \
            "reboots.txt: каждая перезагрузка / each restart" \
            "kernel.txt: журнал ядра за время проверки / the kernel log of the test" \
            "devices-start.txt, devices-end.txt, devices-changes.txt: устройства / devices" \
            "changes-undone.txt, state.txt: временные изменения и их откат; служебная запись / the temporary changes and how they were undone; the test's own record"
    } | sed "s/^/$FIXED/" >"$f"
}

# Masks the files of the run into a folder and packs it into the home folder of the user who started the test.
pack_run() {
    local name stage f dest out uid gid
    name="Z3TEST-linux-$(st_get stamp)"
    stage=$Z3T_ROOT/$name
    rm -rf "$stage"
    mkdir -p "$stage"
    for f in SUMMARY.txt snapshot.txt progress.txt sleep.txt fan.txt load.txt sensors.csv reboots.txt kernel.txt devices-start.txt devices-end.txt \
        devices-changes.txt changes-undone.txt state.txt; do
        [ -f "$RUN/$f" ] && mask_file "$RUN/$f" "$stage/$f"
    done
    # z3report masked its own report already.
    [ -f "$RUN/report-os.txt" ] && cp "$RUN/report-os.txt" "$stage/"
    dest=$OUT_HOME
    [ -n "$dest" ] && [ -d "$dest" ] && [ -w "$dest" ] || dest=$Z3T_ROOT
    out=""
    if have zip; then
        (cd "$Z3T_ROOT" && zip -qr "$dest/$name.zip" "$name") && out=$dest/$name.zip
    fi
    if [ -z "$out" ] && have python3; then
        (cd "$Z3T_ROOT" && python3 -I -m zipfile -c "$dest/$name.zip" "$name") >/dev/null 2>&1 && out=$dest/$name.zip
    fi
    if [ -z "$out" ] && have 7z; then
        (cd "$Z3T_ROOT" && 7z a -tzip "$dest/$name.zip" "$name") >/dev/null 2>&1 && out=$dest/$name.zip
    fi
    if [ -z "$out" ] && have bsdtar; then
        (cd "$Z3T_ROOT" && bsdtar -a -cf "$dest/$name.zip" "$name") >/dev/null 2>&1 && out=$dest/$name.zip
    fi
    if [ -z "$out" ]; then
        (cd "$Z3T_ROOT" && tar czf "$dest/$name.tar.gz" "$name") && out=$dest/$name.tar.gz
    fi
    if [ -n "$out" ]; then
        rm -rf "$stage"
        uid=$(st_get out_uid)
        gid=$(st_get out_gid)
        [ -n "$uid" ] && chown "$uid:${gid:-$uid}" "$out" 2>/dev/null
        chmod 644 "$out" 2>/dev/null
        printf '%s' "$out"
    else
        printf '%s' "$stage"
    fi
}

IN_FINISH=0
finish_run() {
    local out st h
    [ "$IN_FINISH" = 1 ] && return 0
    IN_FINISH=1
    PHASE=final
    st_set phase final
    st_set finished "$(now)"
    say2 "Итог: собираю журналы, откатываю временные изменения, делаю архив." "Finishing: collecting the logs, undoing the temporary changes, making the archive."
    [ -n "$LOAD_DIR" ] && load_stop
    # The unit goes last, after the archive: this very process may be its service.
    undo_changes "$RUN" "" "unit"
    final_kernel
    final_pstore
    devices_list >"$RUN/devices-end.txt"
    check_devices "конца проверки" "the end of the test" WARN
    if [ "$(st_int stalls)" -gt 0 ]; then
        verdict WARN "Система замирала (раз: $(st_int stalls)), самая долгая пауза $(st_int stall_max) с (шаг «$(st_get stall_phase)», в $(ttime "$(st_int stall_at)"))." \
            "The system froze for a while: $(st_int stalls) times, the longest pause $(st_int stall_max) s (\"$(st_get stall_phase)\", at $(ttime "$(st_int stall_at)"))."
    fi
    st=$(st_get stopped)
    if [ -n "$st" ] && [ -z "$(st_get unexpected)" ]; then
        verdict WARN "Проверка остановлена на шаге «$st», остальные шаги не выполнены." "The test was stopped at \"$st\"; the remaining steps did not run."
    fi
    if [ "$DEEP" != 1 ]; then
        verdict SKIP "Вентилятор после сна (ошибка T2.0 на 5600G) не проверялся: нужен запуск с --deep (root, только M715s с Z3NOVO; см. README)." \
            "The fan after sleep (a T2.0 bug on a 5600G) was not checked: it needs --deep (root, an M715s with Z3NOVO only; see the README)."
    fi
    st_set finished "$(now)"
    write_summary "$RUN/SUMMARY.txt"
    [ -f "$RUN/changes.txt" ] && printf '%s  unit|%s  -> removed right after this archive was made\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$UNIT" >>"$RUN/changes-undone.txt"
    out=$(pack_run)
    undo_changes "$RUN"
    st_set phase done
    st_set archive "$out"
    for h in "$OUT_HOME/Z3TEST-STOP" "$OUT_HOME/Z3TEST-STOP.txt"; do [ -n "$OUT_HOME" ] && rm -f "$h"; done
    if [ "$INTERACTIVE" = 1 ]; then
        printf '\n'
        sed "s/^$FIXED//" "$RUN/SUMMARY.txt"
        printf '\nАрхив для отправки (бот @z3novo_bot или GitHub Issues) / The archive to send (the @z3novo_bot bot or GitHub Issues):\n  %s\n' "$out"
    elif have wall; then
        wall "Z3NOVO z3test: проверка закончена / the test has finished: $out" 2>/dev/null
    fi
    case $out in
    *.zip | *.tar.gz)
        rm -f "$CURRENT"
        rm -rf "${RUN:?}"
        RUN=""
        ;;
    esac
    return 0
}

# ================================================================ z3test: start, stop, resume

next_phase() {
    local p
    p=$(st_get phase)
    case $p in snapshot) p=sleep ;; sleep) p=load ;; load) p=idle ;; idle) p=reboot ;; *) p=final ;; esac
    st_set phase "$p"
    st_set phase_started "$(now)"
}
run_phases() {
    local ph rc
    while :; do
        ph=$(st_get phase)
        case $ph in final | done | '') break ;; esac
        PHASE=$ph
        if stop_requested; then
            [ -n "$(st_get stopped)" ] || st_set stopped "$ph"
            break
        fi
        "ph_$ph"
        rc=$?
        [ "$HANDOFF" = 1 ] && return 0
        if [ "$rc" != 0 ]; then
            [ -n "$(st_get stopped)" ] || st_set stopped "$ph"
            break
        fi
        next_phase
    done
    finish_run
}

remove_leftover_unit() {
    if [ -f "$UNIT_DIR/$UNIT" ]; then
        if have systemctl; then systemctl disable "$UNIT" >/dev/null 2>&1; fi
        rm -f "$UNIT_DIR/$UNIT"
        if have systemctl; then systemctl daemon-reload >/dev/null 2>&1; fi
    fi
}

finish_stale() { # a run that broke off: undo its changes and make its archive
    local d=$1
    open_run "$d"
    case $(st_get phase) in
    final | done) ;;
    *)
        if [ -z "$(st_get stopped)" ]; then
            st_set stopped "$(st_get phase)"
            verdict WARN "Проверка оборвалась на шаге «$(st_get phase)» (окно закрыли или компьютер выключили), итог собран при следующем запуске." \
                "The test broke off at \"$(st_get phase)\" (the window was closed or the computer switched off); the result was made at the next start."
        fi
        ;;
    esac
    finish_run
    RUN=""
    IN_FINISH=0
    STOPNOW=0
}

do_start() {
    local old sc=$1 ss=$2 rb=$3 lm=$4 im=$5 skip=$6 yes=$7 mode=$8 stamp u h uid gid est ms block="" fs ans
    if ! take_lock; then
        plain2 "Проверка уже идёт (в другом окне или после перезагрузки). Остановить её: sudo bash z3test.sh --stop или файл ~/Z3TEST-STOP." \
            "A test is already running (in another window or after a restart). To stop it: sudo bash z3test.sh --stop, or a file ~/Z3TEST-STOP."
        return 1
    fi
    mask_init || return 1
    pci_names_build
    if old=$(current_run); then
        plain2 "Прошлая проверка не закончилась ($old). Откатываю её изменения и делаю её архив." \
            "The previous test did not finish ($old). Undoing its changes and making its archive."
        finish_stale "$old"
        printf '\n'
    fi
    remove_leftover_unit

    # The plan.
    if [ "$mode" = long ]; then
        set -- 8 90 20 18 8
    else
        set -- 3 60 10 3 3
    fi
    [ "$sc" -ge 0 ] && set -- "$((sc > 50 ? 50 : sc))" "$2" "$3" "$4" "$5"
    [ "$ss" -ge 0 ] && set -- "$1" "$((ss < 30 ? 30 : ss > 3600 ? 3600 : ss))" "$3" "$4" "$5"
    [ "$lm" -ge 0 ] && set -- "$1" "$2" "$((lm > 600 ? 600 : lm))" "$4" "$5"
    [ "$im" -ge 0 ] && set -- "$1" "$2" "$3" "$((im > 600 ? 600 : im))" "$5"
    [ "$rb" -ge 0 ] && set -- "$1" "$2" "$3" "$4" "$((rb > 50 ? 50 : rb))"
    case " $skip " in *" sleep "*) set -- 0 "$2" "$3" "$4" "$5" ;; esac
    case " $skip " in *" load "*) set -- "$1" "$2" 0 "$4" "$5" ;; esac
    case " $skip " in *" idle "*) set -- "$1" "$2" "$3" 0 "$5" ;; esac
    case " $skip " in *" reboot "* | *" reboots "*) set -- "$1" "$2" "$3" "$4" 0 ;; esac
    # Seconds per step as measured in QEMU and on the board: snapshot ~1 min; a sleep is its length plus ~25 s (5 before,
    # ~3 going down and back, 10 settling, 5 between, the fan probes); a restart ~165 s (the 60 s notice, the system going
    # down and up again, 45 s settling); the end ~1 min.
    est=$(((60 + $1 * ($2 + 25) + $3 * 60 + $4 * 60 + $5 * 165 + 60 + 59) / 60))
    [ "$5" -gt 0 ] && ! have_systemd && block="нет systemd: продолжить после перезагрузки нечем / no systemd: nothing to go on after a restart"
    ms=$(sv /sys/power/mem_sleep)
    fs=$(journal_persistent && echo 1 || echo 0)

    if [ "$mode" = long ]; then
        plain2 "Z3NOVO: проверка в системе (z3test), режим «долгий», около $est мин." "Z3NOVO in-system test (z3test), long run, about $est min."
    else
        plain2 "Z3NOVO: проверка в системе (z3test), режим «короткий», около $est мин." "Z3NOVO in-system test (z3test), short run, about $est min."
    fi
    plain2 "Что будет: снимок системы; сон с пробуждением по будильнику: $1 × $2 с; нагрузка на процессор и память $3 мин; простой $4 мин; перезагрузки: $5; итог и архив." \
        "What happens: a system snapshot; sleep $1 times for $2 s, woken by the RTC alarm; load on the CPU and memory for $3 min; idling for $4 min; restarts: $5; the result and the archive."
    [ "$DEEP" = 1 ] && plain2 "С --deep: до и после сна читается байт DEh расширенного CMOS и один раз сбрасывается его бит 7 — проверка, работает ли Z3Fan после сна (подробно — README)." \
        "With --deep: extended CMOS byte DEh is read before and after sleep, and its bit 7 is cleared once: the check whether Z3Fan runs after sleep (the README explains)."
    printf '\n'
    plain2 "Перед началом:" "Before you start:"
    plain2 "  1. Сохраните работу и закройте программы: компьютер будет сам засыпать и перезагружаться." \
        "  1. Save your work and close programs: the computer will go to sleep and restart by itself."
    plain2 "  2. Права root есть. Прошивку, настройки BIOS и железо скрипт не трогает (кроме --deep); временные изменения он запишет и вернёт." \
        "  2. Root: yes. The script does not touch the firmware, the BIOS settings or the hardware (but for --deep); its temporary changes are written down and undone."
    case $ms in *deep*) ;; *) plain2 "  ! Ядро не предлагает обычный сон S3 (mem_sleep: $ms): шаг сна будет пропущен." "  ! The kernel offers no ordinary S3 sleep (mem_sleep: $ms): the sleep step will be skipped." ;; esac
    [ -n "$block" ] && plain2 "  ! Перезагрузки будут пропущены: нет systemd." "  ! Restarts will be skipped: no systemd."
    [ "$fs" = 0 ] && plain2 "  3. Журнал системы хранится только в памяти: если компьютер зависнет, прошлый запуск будет не виден. По желанию: sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald." \
        "  3. The system journal lives in RAM only: after a hang the previous boot is not visible. If you like: sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald."
    plain2 "  4. Если диск зашифрован и при включении спрашивает пароль — перезагрузки без человека не пройдут: остановите проверку или добавьте --skip reboot." \
        "  4. If the disk is encrypted and asks for a password at power-on, restarts cannot go on without a person: stop the test or add --skip reboot."
    plain2 "  5. Если компьютер уснул и не проснулся за 5 минут — нажмите кнопку питания. Не реагирует — держите кнопку 5 секунд и включите снова: скрипт сам допишет итог." \
        "  5. If the computer went to sleep and has not woken within 5 minutes, press the power button. No response: hold it for 5 seconds and power on again; the script finishes the result by itself."
    printf '\n'
    plain2 "Остановить: Ctrl+C в этом окне; или файл ~/Z3TEST-STOP; или sudo bash z3test.sh --stop. Закрыть окно можно: проверка пойдёт дальше." \
        "To stop: Ctrl+C in this window; or a file ~/Z3TEST-STOP; or sudo bash z3test.sh --stop. Closing the window is fine: the test goes on."
    plain2 "Итог: один архив Z3TEST-linux-<дата>-<время>.zip в домашней папке." "The result: one archive Z3TEST-linux-<date>-<time>.zip in the home folder."
    printf '\n'
    if [ "$yes" != 1 ]; then
        if [ "$INTERACTIVE" != 1 ]; then
            say "Не в терминале: чтобы начать без вопроса, добавьте --yes. / Not in a terminal: add --yes to start without the question."
            return 1
        fi
        printf '%s\n%s\n> ' "Enter — начать; н и Enter — отказаться." "Enter to start; n and Enter to cancel."
        read -r ans || return 1
        case $(printf '%s' "$ans" | tr 'A-Z' 'a-z') in
        '' | y | yes | 'д' | 'да' | 'Д' | 'Да' | 'ДА') ;;
        *)
            say "Отменено, ничего не изменено. / Cancelled, nothing changed."
            return 0
            ;;
        esac
    fi

    # The run folder, its state and the unit.
    stamp=$(date +%Y-%m-%d-%H%M%S)
    RUN=$Z3T_ROOT/run-$stamp
    mkdir -p "$RUN" && chmod 700 "$RUN" || return 1
    u=${SUDO_USER:-}
    [ "$u" = root ] && u=""
    if [ -n "$u" ]; then
        h=$(getent passwd "$u" 2>/dev/null | cut -d: -f6)
        uid=${SUDO_UID:-$(id -u "$u" 2>/dev/null)}
        gid=${SUDO_GID:-$(id -g "$u" 2>/dev/null)}
    else
        h=${HOME:-/root}
        uid=""
        gid=""
    fi
    OUT_HOME=$h
    {
        printf 'version=%s\nstamp=%s\nmode=%s\nstarted=%s\nphase=snapshot\nphase_started=%s\nuser_name=%s\nout_home=%s\nout_uid=%s\nout_gid=%s\n' \
            "$T_VERSION" "$stamp" "$mode" "$(now)" "$(now)" "$u" "$h" "$uid" "$gid"
        printf 'sleep_total=%s\nsleep_secs=%s\nload_min=%s\nidle_min=%s\nreboot_total=%s\nreboot_block=%s\ndeep=%s\nboot_id=%s\nest_min=%s\nedac_ce=%s\n' \
            "$1" "$2" "$3" "$4" "$5" "$block" "$DEEP" "$BOOT_ID" "$est" "$(cat /sys/devices/system/edac/mc/mc*/ce_count 2>/dev/null | awk '{ s += $1 } END { printf "%.0f", s }')"
    } >"$RUN/state.txt"
    cp "$SELF" "$RUN/z3test.sh" && chmod 700 "$RUN/z3test.sh"
    printf '%s\n' "$RUN" >"$CURRENT"
    # A line in the kernel log where the test starts, so that the end reads only the kernel log of the test (with the
    # journal kept in RAM, dmesg holds the whole boot, maybe hours before the test).
    st_set kmsg_mark "z3test: run $stamp started"
    printf '%s\n' "z3test: run $stamp started" >/dev/kmsg 2>/dev/null
    PHASE=start
    logp "z3test.sh $T_VERSION, mode $mode: sleep $1 x $2 s, load $3 min, idle $4 min, restarts $5, about $est min; mem_sleep $ms; persistent journal $fs; deep $DEEP"
    if [ "$5" -gt 0 ] && [ -z "$block" ]; then
        install_unit || st_set reboot_block "the unit could not be installed / не удалось поставить службу"
    fi
    run_phases
}

do_stop() {
    local d k
    if [ ! -d "$Z3T_ROOT" ]; then
        remove_leftover_unit
        say "Идущей или оборванной проверки нет. / No test is running or broken off."
        return 0
    fi
    if take_lock; then
        mask_init || return 1
        pci_names_build
        if ! d=$(current_run); then
            remove_leftover_unit
            say "Идущей или оборванной проверки нет; оставшееся убрано. / No test is running or broken off; leftovers removed."
            return 0
        fi
        open_run "$d"
        [ -n "$(st_get stopped)" ] || st_set stopped "$(st_get phase)"
        finish_run
        return 0
    fi
    d=$(current_run) && : >"$d/STOP"
    say "Проверке передана просьба остановиться. Жду, пока она откатит изменения и сделает архив (до 5 минут)..."
    say "The test was asked to stop. Waiting while it undoes its changes and makes the archive (up to 5 minutes)..."
    k=0
    while [ -e "$CURRENT" ] && [ "$k" -lt 300 ]; do
        sleep 1
        k=$((k + 1))
    done
    if [ -e "$CURRENT" ]; then
        say "Проверка ещё не остановилась. Если идёт перезагрузка — она остановится после неё. / The test has not stopped yet. If a restart is under way, it stops after it."
    else
        say "Проверка остановлена, архив в домашней папке. / The test has stopped; the archive is in the home folder."
    fi
}

do_resume() {
    local d ph issued boot
    take_lock || return 0
    if ! d=$(current_run); then
        remove_leftover_unit
        return 0
    fi
    mask_init || return 1
    pci_names_build
    open_run "$d"
    ph=$(st_get phase)
    logp "the system started; the unit runs z3test.sh --resume"
    case $ph in
    done)
        rm -f "$CURRENT"
        undo_changes "$d"
        return 0
        ;;
    final)
        finish_run
        return 0
        ;;
    esac
    issued=$(st_int reboot_issued)
    boot=$(boot_epoch)
    if [ "$ph" = reboot ] && [ "$issued" -gt 0 ] && [ "$boot" -ge "$issued" ]; then
        # Let the devices come up before they are compared with the start.
        if ! wait_step 45 "settling after the start"; then
            st_set stopped reboot
            check_reboot
            st_set boot_id "$BOOT_ID"
            finish_run
            return 0
        fi
        check_reboot
        st_set boot_id "$BOOT_ID"
        run_phases
        return 0
    fi
    check_unexpected
    st_set boot_id "$BOOT_ID"
    finish_run
}

z3test_usage() {
    say "z3test.sh $T_VERSION: an unattended in-system test for Z3NOVO firmware testers; one archive at the end."
    say "Usage: sudo bash z3test.sh [--long] [--deep] [--yes] [--skip sleep,load,idle,reboot]"
    say "       [--sleep-cycles N] [--sleep-seconds S] [--load-minutes M] [--idle-minutes M] [--reboots N]"
    say "       sudo bash z3test.sh --stop      (or create the file ~/Z3TEST-STOP)"
    say "Проверка в системе для тестеров прошивки Z3NOVO: сон, нагрузка, простой, перезагрузки; в конце один архив."
}

on_exit() {
    [ -n "$LOAD_DIR" ] && load_stop
    [ -n "$TMPD" ] && rm -rf "$TMPD"
}
on_int() {
    [ "$HANDOFF" = 1 ] && exit 0
    STOPNOW=1
}
on_term() {
    # The system is going down (or someone killed the script): leave the run as it is; the next start finishes it.
    exit 0
}
on_hup() { INTERACTIVE=0; }

# A sleep inhibitor for exactly as long as this script lives (tail --pid ends with it, however it ends), so the desktop
# does not put the computer to sleep on its own in the middle of a step; the test's own sleeps go to the kernel directly
# and are not blocked by it. It ignores SIGHUP, like the load workers, so closing the terminal does not end it.
start_inhibitor() {
    have systemd-inhibit && [ -d /run/systemd/system ] || return 0
    (
        trap '' HUP INT
        exec systemd-inhibit --what=sleep:idle --who=z3test --why="Z3NOVO firmware test (z3test.sh)" --mode=block tail --pid=$$ -f /dev/null
    ) >/dev/null 2>&1 &
}

z3test_main() {
    local orig=("$@") sc=-1 ss=-1 rb=-1 lm=-1 im=-1 skip="" yes=0 stop=0 resume=0 no_sudo=0 mode=short v
    while [ $# -gt 0 ]; do
        case $1 in
        --long) mode=long ;;
        --short) mode=short ;;
        --sleep-cycles | --sleep-seconds | --reboots | --load-minutes | --idle-minutes)
            v=${2:-}
            case $v in '' | *[!0-9]*)
                say "z3test.sh: $1 needs a number / нужно число"
                return 2
                ;;
            esac
            case $1 in --sleep-cycles) sc=$v ;; --sleep-seconds) ss=$v ;; --reboots) rb=$v ;; --load-minutes) lm=$v ;; --idle-minutes) im=$v ;; esac
            shift
            ;;
        --skip)
            skip="$skip $(printf '%s' "${2:-}" | tr ',' ' ')"
            shift
            ;;
        --deep) DEEP=1 ;;
        -y | --yes) yes=1 ;;
        --stop) stop=1 ;;
        --resume) resume=1 ;;
        --no-sudo) no_sudo=1 ;;
        -h | --help)
            z3test_usage
            return 0
            ;;
        -V | --version)
            say "$T_VERSION"
            return 0
            ;;
        *)
            say "z3test.sh: unknown option / неизвестный ключ: $1"
            z3test_usage
            return 2
            ;;
        esac
        shift
    done
    [ "$resume" = 0 ] && [ -t 0 ] && [ -t 1 ] && INTERACTIVE=1
    SELF=$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")
    if [ "$IS_ROOT" != 1 ]; then
        if [ "$stop" = 1 ] && [ -n "${HOME:-}" ]; then
            : >"$HOME/Z3TEST-STOP" && say "Создан файл ~/Z3TEST-STOP: проверка остановится и сделает архив. / The file ~/Z3TEST-STOP is there now: the test stops and makes its archive."
        fi
        if [ "$no_sudo" = 0 ] && have sudo && [ "$INTERACTIVE" = 1 ]; then
            say "Для проверки нужны права root (сон, перезагрузки, служба systemd). Запускаю через sudo. / The test needs root (sleep, restarts, a systemd unit). Running through sudo."
            exec sudo bash "$SELF" "${orig[@]}" --no-sudo
        fi
        [ "$stop" = 1 ] && return 0
        say "Нужны права root: sudo bash z3test.sh / Needs root: sudo bash z3test.sh"
        return 1
    fi
    trap on_exit EXIT
    trap on_int INT
    trap on_term TERM
    trap on_hup HUP
    if [ "$stop" = 1 ]; then
        do_stop
    elif [ "$resume" = 1 ]; then
        start_inhibitor
        do_resume
    else
        start_inhibitor
        do_start "$sc" "$ss" "$rb" "$lm" "$im" "$skip" "$yes" "$mode"
    fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    z3test_main "$@"
fi
