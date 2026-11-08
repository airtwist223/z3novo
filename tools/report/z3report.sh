#!/usr/bin/env bash
# z3report.sh: report for testers of the Z3NOVO firmware (Lenovo ThinkCentre M715s, board AM4P2MS), OS side, Linux.
#
#   bash z3report.sh          as a normal user
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
pci_name() { awk -F'\t' -v k="$1" '$1 == k { print $2 " " $3; exit }' "$TMPD/pcinames" 2>/dev/null; }
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
    for k in bios_vendor bios_version bios_date bios_release ec_firmware_release board_vendor board_name board_version \
        sys_vendor product_name product_version product_family product_sku chassis_vendor chassis_version; do
        kv "$k" "$(sv "$d/$k")"
    done
    fact bios "$(sv $d/bios_vendor) $(sv $d/bios_version) ($(sv $d/bios_date))"
    fact board "$(sv $d/board_vendor) $(sv $d/board_name) $(sv $d/board_version)"
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
        note "SMBIOS types 0, 1, 2 (dmidecode, no serial numbers or UUID):"
        dmi -t 0 -t 1 -t 2
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
        function bytes(s, a) { split(s, a, " "); return a[1] * (a[2] == "TB" ? 1099511627776 : a[2] == "GB" ? 1073741824 : a[2] == "MB" ? 1048576 : 0) }
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
        kv "  driver" "${drv:-none / нет}"
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

s_display() {
    local c st mode mon n=0
    for c in /sys/class/drm/card[0-9]*-*; do
        [ -r "$c/status" ] || continue
        n=$((n + 1))
        st=$(sv "$c/status")
        mode=$(sv "$c/modes")
        mon=""
        [ "$st" = connected ] && mon=$(edid_name "$c/edid")
        printf '  %-18s %-13s %s%s\n' "${c##*/}" "$st" "${mode:+preferred mode $mode}" "${mon:+, monitor $mon}"
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
    klog | grep -E "$BOOT_RE" | head -n 60 | ind | none_if_empty "not in the log any more (it keeps only recent lines) / в журнале их уже нет"
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
    printf '%s\n' "Исключено: имя компьютера, имена пользователей, серийные номера, UUID, MAC-адреса (оставлены первые 3 байта), IP-адреса, имена сетей Wi-Fi, пути в домашних папках (заменены на ~), ключ Windows (таблица ACPI MSDM не читается). Скрипт ничего не пишет в систему и не обращается к железу напрямую (порты, /dev/mem, SMBus, микросхема Super I/O, термозоны ACPI)."
    printf '%s\n' "Collected: OS and kernel, boot time and uptime; SMBIOS (BIOS, board, CPU, memory modules); microcode; graphics and its memory; displays; PCI and USB devices; network adapters (no addresses); disks (model and size); kernel and journal errors; boots, crashes and machine checks over 30 days; kernel taint; temperatures from safe drivers only (k10temp, amdgpu, nvme); UEFI variables Z3Chip and Z3Novo* (hex)."
    printf '%s\n' "Excluded: computer name, user names, serial numbers, UUIDs, MAC addresses (first 3 bytes kept), IP addresses, Wi-Fi names, home folder paths (shown as ~), the Windows key (ACPI table MSDM is not read). The script writes nothing to the system and does not touch hardware directly (I/O ports, /dev/mem, SMBus, the Super I/O chip, ACPI thermal zones)."
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

main() {
    case ${1:-} in
    -h | --help)
        say "z3report.sh $VERSION: collects a read-only OS report for Z3NOVO firmware testers into one text file."
        say "Usage: bash z3report.sh   (more details: sudo bash z3report.sh)"
        say "Собирает отчёт ОС для тестеров прошивки Z3NOVO в один текстовый файл, только чтение."
        return 0
        ;;
    -V | --version)
        say "$VERSION"
        return 0
        ;;
    esac

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

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
