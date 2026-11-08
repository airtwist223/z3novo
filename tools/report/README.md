# Отчёт для тестеров прошивки Z3NOVO / Z3NOVO firmware tester report

[Русский](#русский) · [English](#english)

---

## Русский

Прошивка Z3NOVO (ThinkCentre M715s, плата AM4P2MS) проходит открытый тест. Если что-то пошло не так (компьютер завис, перезагрузился сам, выключился, не нашёл устройство, показал синий экран), запустите скрипт из этой папки в работающей системе. Он соберёт сведения о железе и о сбоях в один текстовый файл, а этот файл нужно отправить тому, кто ведёт тест.

Скрипт только читает. Он ничего не меняет в системе, не ставит программы и драйверы, не ходит в сеть, не обращается к железу напрямую (порты, SMBus, микросхема Super I/O, термозоны ACPI) и не читает ключ Windows.

### Что попадёт в файл

- версия системы, время загрузки, сколько компьютер работает;
- BIOS (версия и дата), плата, процессор и его микрокод, модули памяти (слот, объём, частота, производитель, модель);
- видеокарта, версия драйвера и сколько памяти у встроенной графики;
- устройства с ошибками, список устройств PCI, сетевые адаптеры (без адресов), диски (модель и объём);
- сбои и зависания за последние 30 дней: внезапные выключения и перезагрузки, синие экраны, аппаратные ошибки, ошибки дисков и видеодрайвера;
- на Linux: температуры процессора, видеокарты и дисков (только от безопасных драйверов);
- служебные переменные прошивки Z3NOVO (Z3Chip, Z3Novo*) в шестнадцатеричном виде.

### Что замазывается

Имя компьютера, имена пользователей, серийные номера, UUID, MAC-адреса (остаются первые 3 байта, по ним виден только производитель), IP-адреса, имена сетей Wi-Fi, пути в домашних папках (заменяются на `~`). В строках SMBIOS (BIOS, плата, система, корпус) замазываются и похожие на серийные уникальные номера: например, версия платы `SDK0J40697 WIN 1234567890123` станет `SDK0J40697 WIN <serial>`. Замазанные места выглядят как `<host>`, `<user>`, `<serial>`, `<uuid>`, `<id>`, `<ip>`, `<email>`, `<wifi>`, `<url>`, `<key>`, `~`, `aa:bb:cc:xx:xx:xx`.

### Windows 10 и 11

1. Скачайте файл `z3report.ps1` целиком (не копируйте его текст в Блокнот).
2. Самый простой способ: щёлкните по файлу правой кнопкой и выберите «Выполнить с помощью PowerShell». Скрипт спросит, перезапуститься ли с правами администратора (они добавляют служебные переменные прошивки, аварийные дампы и тип подключения мониторов): Enter или «Д» — да, Windows покажет окно подтверждения, и отчёт соберётся в новом окне; «Н» — нет, отчёт соберётся без них. Когда появится «Готово», нажмите Enter.
3. Или сразу с правами администратора:
   - нажмите «Пуск», наберите `PowerShell`, щёлкните правой кнопкой по «Windows PowerShell» и выберите «Запуск от имени администратора»;
   - перейдите в папку со скриптом, например: `cd $HOME\Downloads`;
   - запустите: `powershell -ExecutionPolicy Bypass -File .\z3report.ps1`
4. Через одну-две минуты на Рабочем столе появится файл `z3report-os-<дата>-<время>.txt`, его путь скрипт напишет в конце.

`-ExecutionPolicy Bypass` разрешает запустить этот скрипт один раз и ничего не меняет в настройках Windows. Чтобы скрипт не спрашивал про права администратора, добавьте в конце `-NoElevate`.

### Linux

1. Скачайте файл `z3report.sh`.
2. Откройте терминал в папке со скриптом и запустите: `bash z3report.sh`
3. Скрипт предложит перезапуститься через sudo. Так отчёт будет полнее: модули памяти из SMBIOS, журналы ядра, сохранённые при сбое, журнал системы, если у вашего пользователя нет к нему доступа. Enter или «д» — да, sudo спросит пароль; «н» — нет. Можно и сразу `sudo bash z3report.sh`, а `bash z3report.sh --no-sudo` не задаёт вопрос.
4. Файл `z3report-os-<дата>-<время>.txt` появится в домашней папке (если туда нельзя писать, в текущей), путь скрипт напишет в конце.

Если в отчёте написано «прошлых загрузок в журнале нет», ваша система хранит журнал только в памяти и после сбоя он пропадает. По желанию включите постоянный журнал (это делаете вы, не скрипт): `sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald`. Следующий сбой тогда будет виден.

### Что отправлять

1. Лучше запускать скрипт сразу после сбоя: включите компьютер, дождитесь системы и запустите. Сведения о прошлой загрузке и о сбоях за 30 дней сохраняются в журналах.
2. Откройте получившийся `.txt` и просмотрите его. Если увидите то, чем не хотите делиться, удалите эту строку.
3. Отправьте один этот файл тому, кто ведёт тест. В сообщении напишите, что случилось, когда (дата и время) и что вы в этот момент делали.

Если вас попросят, приложите и отчёт из самой прошивки: он делается отдельно, по своей инструкции.

---

## English

The Z3NOVO firmware (ThinkCentre M715s, board AM4P2MS) is in public testing. If something went wrong (the computer froze, restarted or powered off by itself, lost a device, showed a blue screen), run the script from this folder in the running system. It collects hardware and crash details into one text file; send that file to the person running the test.

The script only reads. It changes nothing in the system, installs no programs or drivers, does not use the network, does not touch hardware directly (I/O ports, SMBus, the Super I/O chip, ACPI thermal zones) and never reads the Windows key.

### What goes into the file

- OS version, boot time, uptime;
- BIOS (version and date), board, CPU and its microcode, memory modules (slot, size, speed, maker, model);
- graphics card, driver version, and how much memory the integrated graphics has;
- devices with problems, the PCI device list, network adapters (no addresses), disks (model and size);
- crashes and hangs over the last 30 days: sudden power-offs and restarts, blue screens, hardware errors, disk and display driver errors;
- on Linux: CPU, GPU and drive temperatures (from safe drivers only);
- the Z3NOVO firmware's own variables (Z3Chip, Z3Novo*) as hex.

### What is masked

Computer name, user names, serial numbers, UUIDs, MAC addresses (the first 3 bytes stay, they only tell the maker), IP addresses, Wi-Fi network names, home folder paths (shown as `~`). In SMBIOS strings (BIOS, board, system, chassis) serial-like unique numbers are masked too: a board version `SDK0J40697 WIN 1234567890123` becomes `SDK0J40697 WIN <serial>`. Masked values look like `<host>`, `<user>`, `<serial>`, `<uuid>`, `<id>`, `<ip>`, `<email>`, `<wifi>`, `<url>`, `<key>`, `~`, `aa:bb:cc:xx:xx:xx`.

### Windows 10 and 11

1. Download the file `z3report.ps1` itself (do not copy its text into Notepad).
2. The simplest way: right-click the file and choose "Run with PowerShell". The script asks whether to restart with administrator rights (they add the firmware variables, crash dumps and the monitors' connection types): Enter or "Y" for yes, Windows shows a confirmation and the report is collected in a new window; "N" for no, the report is collected without them. When it says "Done", press Enter.
3. Or start with administrator rights right away:
   - press Start, type `PowerShell`, right-click "Windows PowerShell" and choose "Run as administrator";
   - go to the folder with the script, for example: `cd $HOME\Downloads`;
   - run: `powershell -ExecutionPolicy Bypass -File .\z3report.ps1`
4. After a minute or two the file `z3report-os-<date>-<time>.txt` appears on the Desktop; the script prints its path at the end.

`-ExecutionPolicy Bypass` lets this one script run once and changes no Windows settings. Add `-NoElevate` at the end if you do not want the question about administrator rights.

### Linux

1. Download the file `z3report.sh`.
2. Open a terminal in its folder and run: `bash z3report.sh`
3. The script offers to run again through sudo, which gives more details: memory modules from SMBIOS, kernel logs saved across a crash, and the system journal if your user may not read it. Enter or "y" for yes, sudo asks for your password; "n" for no. You can also start with `sudo bash z3report.sh` right away; `bash z3report.sh --no-sudo` skips the question.
4. The file `z3report-os-<date>-<time>.txt` appears in your home folder (or the current folder if home is not writable); the script prints its path at the end.

If the report says "no previous boots in the journal", your system keeps the journal in RAM only and loses it at a crash. If you like, turn on the persistent journal (you do this, not the script): `sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald`. The next crash will then be visible.

### What to send

1. Run the script soon after a problem: power on, let the system start, run it. The previous boot and the last 30 days of crashes stay in the logs.
2. Open the `.txt` file and look through it. If you see anything you do not want to share, delete that line.
3. Send that one file to the person running the test. Say what happened, when (date and time), and what you were doing.

If you are asked to, also attach the report from the firmware itself: it is made separately, by its own instructions.

---

## For developers / Для разработчиков

- Report layout: a fixed header (what was collected and what was masked), then sections `=== [tag] English title / Русское название`, lines `  key:  value`, lists indented by 4 spaces, and `=== [end]`. Section tags: `summary`, `os`, `firmware`, `cpu`, `memory`, `graphics`, `display` or `monitors`, `problems`, `history` or `crashes`, `whea`, `fwevents`, `storage`, `gpuerrors`, `dumps`, `mce`, `kernel`, `journal`, `taint`, `sensors`, `pci`, `usb`, `network`, `disks`, `efivars`. A failed step prints `failed / не удалось: reason`, a skipped one `skipped / пропущено: reason`; the script goes on either way.
- UEFI variables, the same on both systems: `  var NAME-GUID attr=0xAAAAAAAA size=N`, then `    OOOO: xx xx ... (16 bytes)  |ASCII|`; data only, without the 4 attribute bytes efivarfs puts first. Windows reads them only as administrator (`GetFirmwareEnvironmentVariableExW`, `SeSystemEnvironmentPrivilege` for this process only); variables without the runtime attribute are not visible to an OS at all.
- Linux test hook: `Z3REPORT_EFIVARS=/path/to/folder bash z3report.sh` reads files laid out like efivarfs (4 attribute bytes, then data) from that folder instead of `/sys/firmware/efi/efivars`.
- Linux never reads `/sys/class/thermal` or the `acpitz` hwmon (on the AM4P2MS board the ACPI thermal zone's `_TMP` method accesses the Super I/O chip); hwmon is read only for `k10temp`, `zenpower`, `amdgpu`, `radeon`, `nouveau`, `nvme`, `coretemp`, `fam15h_power`. Windows reads no temperatures at all for the same reason.
- `z3report.ps1` keeps its code ASCII; the Russian strings live in one here-string that is re-decoded at run time if the file lost its UTF-8 BOM. Keep the BOM when editing.
- SMBIOS strings of types 0 to 3 (BIOS, board, system, chassis; the kernel's `DMI:` line on Linux) go through one rule, the same in both scripts (`SmbSafe` / `smbsafe`): a run of 8+ digits, or a letters-and-digits run of 10+ characters, becomes `<serial>`, unless it is a Lenovo machine type and model (`10MCS02600`), part number (`SDK0J40697`) or notebook board model (`LNVNB161216`). Memory part numbers are model numbers and are not passed through it; serial numbers and asset tags are never read.
- The elevated restart on Windows starts the same script with `-ExecutionPolicy Bypass -Relaunched`; `-Relaunched` is internal (no question, wait for Enter at the end). On Linux the question is asked only with a terminal on both input and output, and `sudo bash z3report.sh --no-sudo` is what it runs.
