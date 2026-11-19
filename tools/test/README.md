# Проверка в системе для тестеров Z3NOVO / Z3NOVO in-system test

[Русский](#русский) · [English](#english)

---

## Русский

Прошивка Z3NOVO (ThinkCentre M715s, плата AM4P2MS) проходит открытый тест. Этот скрипт проверяет её в **вашей** системе — Windows 10 или 11, или Linux — без вашего участия. Прошейте BIOS, загрузите систему, запустите скрипт и займитесь своими делами: он сам соберёт сведения о компьютере, несколько раз усыпит и разбудит компьютер, нагрузит процессор и память с проверкой, оставит компьютер в простое, несколько раз перезагрузит его, соберёт журналы ошибок и сложит всё в **один архив**. В архиве главный файл — `SUMMARY.txt`: итог простыми словами, «ВСЁ В ПОРЯДКЕ», «ЕСТЬ ЗАМЕЧАНИЯ» или «ЕСТЬ ОШИБКИ», и что именно.

Скрипт [z3report](../report/README.md) только собирает сведения за 1–2 минуты; [тест-флешка](https://github.com/airtwist223/z3novo/releases/tag/TestStick-1.5) проверяет железо из своего Linux. Этот скрипт проверяет то, что видно только из вашей системы: сон и пробуждение в ней, перезагрузки, ошибки драйверов, дисков, видео и USB.

### Сколько идёт

| | Короткий (по умолчанию) | Долгий (`-Long` / `--long`) |
|---|---|---|
| Снимок системы (как z3report, и ещё память, линки PCIe, NVMe, Secure Boot, TPM, активация Windows) | 1–3 мин | 1–3 мин |
| Сон с пробуждением по таймеру | 3 раза по 60 с | 8 раз по 90 с |
| Нагрузка на все ядра и память с проверкой по шаблонам | 10 мин | 20 мин |
| Простой (часть зависаний Ryzen бывает именно в простое) | 3 мин | 18 мин |
| Перезагрузки подряд | 3 | 8 |
| **Всего** | **около 35 мин в Windows, 30 мин в Linux** | **около 1,5 ч в Windows, 1 ч 20 мин в Linux** |

Если часть шагов пропустить (`-Skip` / `--skip`) или поменять их длину, проверка короче или длиннее: перед началом скрипт показывает расчёт для выбранных шагов, а итог — и расчёт, и сколько шло на самом деле.

### Перед запуском

1. **Сохраните работу и закройте программы**: компьютер будет сам засыпать и перезагружаться.
2. **Нужны права администратора** (Windows) или **root** (Linux): скрипт сам предложит их получить.
3. **Быстрый запуск Windows** на время тестов прошивки лучше выключить: Панель управления → Электропитание → Действия кнопок питания → снять «Включить быстрый запуск» ([подробнее](../../docs/DIAGNOSTICS.md#скрипт-для-windows-или-linux)). Скрипт покажет, включён ли он.
4. **BitLocker с PIN** (или диск Linux, который при включении спрашивает пароль) не даст пройти перезагрузкам без человека. В Windows скрипт сам это увидит и пропустит перезагрузки; в Linux добавьте `--skip reboot`.
5. Во время сна **не трогайте мышь и клавиатуру**: движение разбудит компьютер раньше таймера, и это попадёт в замечания.
6. Лучше заранее **установить обновления Windows**: обновление при перезагрузке удлиняет её.

### Windows 10 и 11

1. Скачайте файл `z3test.ps1` целиком (не копируйте его текст в Блокнот).
2. Щёлкните по файлу правой кнопкой → «Выполнить с помощью PowerShell». Скрипт попросит права администратора (Enter или «Д»), Windows покажет окно подтверждения. В новом окне скрипт покажет план и предупреждения: **Enter — начать**.
   Или сразу: PowerShell от имени администратора, перейдите в папку со скриптом (`cd $HOME\Downloads`) и запустите `powershell -ExecutionPolicy Bypass -File .\z3test.ps1` (долгий — добавьте `-Long`).
3. Дальше ничего делать не нужно. Компьютер будет засыпать и сам просыпаться через минуту-полторы, а потом перезагружаться. **После перезагрузок входить в Windows не нужно**: проверка продолжится сама (её продолжает задача планировщика от имени системы).
4. В конце на рабочем столе появится **`Z3TEST-win-<дата>-<время>.zip`**. Если в этот момент в Windows никто не вошёл, при следующем входе откроется окно с итогом.

`-ExecutionPolicy Bypass` разрешает запустить этот скрипт один раз и ничего не меняет в настройках Windows.

### Linux

1. Скачайте файл `z3test.sh`.
2. Откройте терминал в папке со скриптом и запустите `sudo bash z3test.sh` (долгий — `sudo bash z3test.sh --long`). Без sudo скрипт сам предложит перезапуститься через него. Появятся план и предупреждения: **Enter — начать**.
3. Окно терминала можно закрыть — проверка пойдёт дальше. После перезагрузок её продолжает служба systemd; входить в систему не нужно.
4. В конце в домашней папке появится **`Z3TEST-linux-<дата>-<время>.zip`** (если в системе нет ни одной программы для zip — `.tar.gz`).

Если ваша система хранит журнал только в памяти, после зависания прошлый запуск не виден, и итог будет беднее. По желанию включите постоянный журнал (это делаете вы, не скрипт): `sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald`.

### Ключи

| Windows | Linux | Что |
|---|---|---|
| `-Long` | `--long` | долгий режим |
| `-Skip sleep,load,idle,reboot` | `--skip sleep,load,idle,reboot` | пропустить шаги (любые из списка) |
| `-SleepCycles N`, `-SleepSeconds S` | `--sleep-cycles N`, `--sleep-seconds S` | сколько раз и на сколько секунд засыпать |
| `-LoadMinutes M`, `-IdleMinutes M`, `-Reboots N` | `--load-minutes M`, `--idle-minutes M`, `--reboots N` | длительность нагрузки и простоя, число перезагрузок |
| `-Yes` | `--yes` | начать без вопроса |
| `-Stop` | `--stop` | остановить идущую проверку (или доделать оборванную) |
| — | `--deep` | ещё и вентилятор после сна (см. ниже) |

### Если что-то пошло не так

- **Компьютер уснул и не проснулся за 5 минут** (лампа мигает или экран тёмный): коротко нажмите кнопку питания. Не реагирует — держите кнопку 5 секунд и включите снова. Скрипт сам поймёт, что случилось (Windows запишет «внезапное выключение», Kernel-Power 41), и **прямо напишет в итоге**: «компьютер не проснулся из сна N». Итог соберётся после старта системы, входить для этого не обязательно.
- **Завис во время нагрузки или простоя** — то же самое: держите кнопку 5 секунд, включите. В итоге будет, на каком шаге и в какое время это случилось (скрипт каждые 10 секунд отмечает, что жив).
- **Остановить проверку**: Ctrl+C в окне скрипта; или создайте на рабочем столе файл `Z3TEST-STOP` (в Linux — `~/Z3TEST-STOP`); или запустите скрипт с `-Stop` (Windows) / `--stop` (Linux). Скрипт откатит свои изменения и сделает архив из того, что успел.
- **Окно закрыли или компьютер выключили посреди проверки**: при следующем старте системы скрипт сам откатит изменения и сделает архив; то же при следующем запуске скрипта.

### Что проверяется

| Шаг | Windows | Linux |
|---|---|---|
| Снимок | весь отчёт z3report; память: сколько стоит и сколько видно, частота по паспорту планки и заданная прошивкой; скорость и ширина линков PCIe; модель и прошивка NVMe, их состояние; Secure Boot (и SetupMode), TPM; статус активации Windows (без ключа) | весь отчёт z3report; то же про память, PCIe, NVMe, Secure Boot и TPM |
| Сон | задача планировщика с «пробуждать компьютер» и переход в сон; проснулся ли, от чего (таймер или кнопка), сколько занял, сколько времени ушло на прошивку; события Kernel-Power и Power-Troubleshooter; не пропали ли устройства | `rtcwake`; проснулся ли, за сколько, время прошивки (FPDT), журнал ядра сна; не пропали ли устройства |
| Нагрузка | все логические процессоры: память по 7 шаблонам с проверкой каждого слова и повторяемый расчёт, который должен совпадать до бита (помощник на C#, его собирает сама Windows) | то же средствами coreutils: шаблоны через файловую систему в памяти (`/dev/shm`, а если его нет — свой tmpfs на время нагрузки) и `cmp` (в урезанной системе без `cmp` — по хешу), повторяемый расчёт через `gzip` и `awk`; температура Tctl. Если места в памяти нет совсем, итог прямо скажет, что память не проверялась |
| Простой | 18 мин в долгом режиме, отметки «жив» и паузы, когда система не отвечала | то же |
| Перезагрузки | N подряд, считаются завершённые; чистое ли выключение, нет ли лишних запусков, сколько длилась каждая; разрывы во времени ловят зависания | то же через службу systemd и журнал |
| Итог | события за время проверки: WHEA, синие экраны и мини-дампы (список), внезапные выключения, сбросы видеодрайвера (TDR), ошибки дисков (storahci, stornvme), USB, ACPI | журнал ядра за время проверки: MCE, паники, подвисания, ошибки PCIe, видео, дисков (SATA, NVMe), USB, ACPI; pstore; EDAC |

**Вентилятор после сна** (на T2.0 с Ryzen 5600G после пробуждения обороты перестают регулироваться): в Windows **не проверяется** — для этого нужен доступ к железу, а на этой плате обращения из Windows к микросхеме датчиков могут её подвесить. В Linux — с ключом `--deep`, см. ниже. Без него просто послушайте: меняются ли обороты под нагрузкой после сна.

### Что скрипт меняет на время проверки и как возвращает

Всё, что скрипт меняет, он сначала записывает в журнал изменений и возвращает в конце, при остановке, при Ctrl+C, а если проверка оборвалась — при следующем старте системы или следующем запуске скрипта. В архиве этот журнал — `changes-undone.txt`.

- **Windows:** задачи планировщика `\Z3NOVO\Z3TEST-resume` (при старте Windows, от имени системы: продолжает проверку после перезагрузки) и `\Z3NOVO\Z3TEST-wake` (будит компьютер из сна; убирается после каждого сна); пункт «Разрешить таймеры пробуждения» активной схемы питания (от сети) — на время шага сна; папка `C:\ProgramData\Z3TEST`, доступная только администраторам и системе. Если проверка закончилась, когда в Windows никто не вошёл, остаётся разовая задача `\Z3NOVO\Z3TEST-show`: при входе она один раз показывает итог, через 3 дня удаляется сама, а следующий запуск скрипта или `-Stop` убирает её сразу.
- **Linux:** служба `/etc/systemd/system/z3test-resume.service` (продолжает проверку после перезагрузки); `/sys/power/mem_sleep` — только если там был не `deep`, до следующей загрузки; будильник часов (RTC); свой tmpfs под `/var/lib/z3test` на время нагрузки — только если в системе нет `/dev/shm`; папка `/var/lib/z3test`. Блокировка сна от рабочего стола (`systemd-inhibit`) живёт, только пока работает скрипт. В журнал ядра пишется одна строка «z3test: run … started» — по ней в итоге читается журнал только за время проверки.

### Чего скрипт не делает

- Не пишет в переменные прошивки и не меняет настройки BIOS; переменные Z3NOVO и Secure Boot только читает.
- Не обращается к железу напрямую: порты, SMBus, микросхема Super I/O IT8738, EC, термозоны ACPI. На Ryzen 3 2200G от таких обращений из ОС виснет микросхема датчиков. Единственное исключение — `--deep` в Linux (ниже).
- Не ходит в сеть, не ставит программы и драйверы, не читает ключ Windows (только статус активации и канал лицензии).
- В архиве замазано то же, что в отчёте z3report: имя компьютера, имена пользователей, серийные номера, UUID, MAC-адреса (кроме первых трёх байт), IP-адреса, имена сетей Wi-Fi, пути в домашних папках.

### Вентилятор после сна: `--deep` (только Linux)

`sudo bash z3test.sh --deep` — к обычной проверке добавляется проверка вентилятора после сна. Быстрее всего — только сон с ней, минут за 5: `sudo bash z3test.sh --deep --skip load,idle,reboot`.

Как это устроено. Процессорным вентилятором в Z3NOVO управляет драйвер Z3Fan внутри прошивки (SMM), дважды в секунду. Его состояние видно в байте `DEh` расширенной памяти CMOS (порты `72h`/`73h`): бит 6 — «Z3Fan включён в этой загрузке», бит 7 — «Z3Fan подтвердил, что работает»; каждый свой такт Z3Fan снова ставит бит 7, если тот сброшен. Скрипт:

1. до первого сна читает `DEh` и **один раз сбрасывает бит 7**: если через 3 секунды бит вернулся, Z3Fan работает и проверка годится;
2. после первого и после последнего сна делает то же самое. Не вернулся бит после сна — Z3Fan после пробуждения не работает: это и есть ошибка T2.0, и итог так и скажет.

Это **запись** в CMOS, поэтому только с `--deep`, только от root и только когда всё сходится: процессор AMD, плата AM4P2MS (ThinkCentre M715s), работает прошивка Z3NOVO (есть её переменная Z3Chip), ядро разрешает `/dev/port` (при включённом Secure Boot блокировка ядра его запрещает — тогда `--deep` пропускается). Меняется только бит 7 байта `DEh`: младшая половина байта (другой счётчик) и остальные биты не трогаются, индексный порт после каждого обращения возвращается как был (так же делает сам Z3Fan). Если бит не вернулся сам, скрипт тут же ставит его обратно, так что байт остаётся таким, каким был. На работу компьютера этот бит не влияет: прошивка читает его только при включении, а при каждом включении выставляет заново. Подробности для разбора — в `fan.txt` архива.

### Что отправить

Архив целиком (`Z3TEST-win-….zip` или `Z3TEST-linux-….zip`) — в Telegram-бот [@z3novo_bot](https://t.me/z3novo_bot) («Проблема» или «Всё работает») или на GitHub: **Issues → New issue**. Напишите версию Z3NOVO (видна в заголовке меню BIOS) и что было необычного. Если в итоге есть ошибки — приложите и отчёт из BIOS: Del → F11 ([как](../../docs/DIAGNOSTICS.md#отчёт-из-bios-f11)). Перед отправкой файлы можно просмотреть: замазанные места выглядят как `<host>`, `<user>`, `<serial>`, `~` и так далее.

---

## English

The Z3NOVO firmware (ThinkCentre M715s, board AM4P2MS) is in public testing. This script tests it in **your own** system, Windows 10 or 11 or Linux, with nobody at the keyboard. Flash the BIOS, start your system, run the script and go about your day: it collects the computer's details, puts the computer to sleep and wakes it several times, loads the CPU and memory with checks, leaves it idle, restarts it several times, collects the error logs and puts everything into **one archive**. The main file in it is `SUMMARY.txt`: the result in plain words, "ALL GOOD", "SOME NOTES" or "ERRORS FOUND", and what exactly.

The [z3report](../report/README.md) script only collects details in a minute or two; the [test stick](https://github.com/airtwist223/z3novo/releases/tag/TestStick-1.5) tests the hardware from its own Linux. This script tests what only your own system shows: sleep and waking in it, restarts, driver, disk, display and USB errors.

### How long it takes

| | Short (default) | Long (`-Long` / `--long`) |
|---|---|---|
| Snapshot (as z3report, plus memory, PCIe links, NVMe, Secure Boot, TPM, Windows activation) | 1–3 min | 1–3 min |
| Sleep, woken by a timer | 3 times, 60 s each | 8 times, 90 s each |
| Load on all cores and the memory with pattern checks | 10 min | 20 min |
| Idling (some Ryzen hangs happen only at idle) | 3 min | 18 min |
| Restarts in a row | 3 | 8 |
| **Total** | **about 35 min on Windows, 30 min on Linux** | **about 1.5 h on Windows, 1 h 20 min on Linux** |

Leave steps out (`-Skip` / `--skip`) or change their length and the test is shorter or longer: before it starts the script shows the reckoning for the chosen steps, and the result shows both the reckoning and the time it really took.

### Before you start

1. **Save your work and close programs**: the computer goes to sleep and restarts by itself.
2. **Administrator rights** (Windows) or **root** (Linux) are needed: the script offers to get them.
3. Better turn **Windows Fast Startup** off while testing the firmware: Control Panel → Power Options → Choose what the power buttons do → untick "Turn on fast startup" ([more](../../docs/DIAGNOSTICS.md#windows-or-linux-script)). The script shows whether it is on.
4. **BitLocker with a PIN** (or a Linux disk that asks for a password at power-on) stops the restarts without a person. On Windows the script notices it and skips the restarts; on Linux add `--skip reboot`.
5. While the computer sleeps, **do not touch the mouse or the keyboard**: a move wakes it before the timer, and that becomes a note.
6. Better **install Windows updates** first: an update during a restart makes it longer.

### Windows 10 and 11

1. Download the file `z3test.ps1` itself (do not copy its text into Notepad).
2. Right-click the file → "Run with PowerShell". The script asks for administrator rights (Enter or "Y"), Windows shows a confirmation. In the new window the script shows the plan and the warnings: **Enter to start**.
   Or straight away: PowerShell as administrator, go to the script's folder (`cd $HOME\Downloads`) and run `powershell -ExecutionPolicy Bypass -File .\z3test.ps1` (add `-Long` for the long run).
3. Nothing more to do. The computer goes to sleep and wakes by itself after a minute or so, then restarts. **You do not need to log on after the restarts**: the test goes on by itself (a scheduled task running as the system carries it on).
4. At the end **`Z3TEST-win-<date>-<time>.zip`** appears on the Desktop. If nobody was logged on at that moment, a window with the result opens at the next logon.

`-ExecutionPolicy Bypass` lets this one script run once and changes no Windows settings.

### Linux

1. Download the file `z3test.sh`.
2. Open a terminal in its folder and run `sudo bash z3test.sh` (long run: `sudo bash z3test.sh --long`). Without sudo the script offers to run again through it. The plan and the warnings appear: **Enter to start**.
3. You may close the terminal: the test goes on. After the restarts a systemd unit carries it on; you do not need to log in.
4. At the end **`Z3TEST-linux-<date>-<time>.zip`** appears in your home folder (`.tar.gz` if the system has no program that makes zips).

If your system keeps its journal in RAM only, a hang hides the previous boot and the result says less. If you like, turn on the persistent journal (you do this, not the script): `sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald`.

### Options

| Windows | Linux | What |
|---|---|---|
| `-Long` | `--long` | the long run |
| `-Skip sleep,load,idle,reboot` | `--skip sleep,load,idle,reboot` | leave steps out (any of the list) |
| `-SleepCycles N`, `-SleepSeconds S` | `--sleep-cycles N`, `--sleep-seconds S` | how many sleeps and how long each |
| `-LoadMinutes M`, `-IdleMinutes M`, `-Reboots N` | `--load-minutes M`, `--idle-minutes M`, `--reboots N` | load and idle length, number of restarts |
| `-Yes` | `--yes` | start without the question |
| `-Stop` | `--stop` | stop a running test (or finish one that broke off) |
| — | `--deep` | the fan after sleep as well (see below) |

### If something goes wrong

- **The computer went to sleep and has not woken within 5 minutes** (the light blinks, or the screen stays dark): press the power button briefly. No response: hold it for 5 seconds and power on again. The script finds out what happened (Windows logs an "unexpected shutdown", Kernel-Power 41) and **says it plainly in the result**: "the computer did not wake from sleep N". The result is made once the system has started; you need not log on for that.
- **A hang during the load or idling**: the same, hold the button for 5 seconds and power on. The result says at which step and when it happened (every 10 seconds the script notes that it is alive).
- **To stop the test**: Ctrl+C in the script's window; or create a file `Z3TEST-STOP` on the Desktop (Linux: `~/Z3TEST-STOP`); or run the script with `-Stop` (Windows) / `--stop` (Linux). The script undoes its changes and makes an archive of what it has.
- **The window was closed or the computer switched off in the middle**: at the next start of the system the script undoes its changes and makes the archive by itself; the same at the next run of the script.

### What is tested

| Step | Windows | Linux |
|---|---|---|
| Snapshot | the whole z3report report; memory: how much is installed and how much is seen, the speed the module is rated for and the speed the firmware set; PCIe link speed and width; NVMe model, firmware and health; Secure Boot (and SetupMode), TPM; the Windows activation status (never the key) | the whole z3report report; the same about memory, PCIe, NVMe, Secure Boot and TPM |
| Sleep | a scheduled task with "wake the computer to run this task", then sleep; whether it woke, by what (the timer or a button), how long it took and how much of it was the firmware; Kernel-Power and Power-Troubleshooter events; devices gone | `rtcwake`; whether it woke, how long it took, the firmware's part (FPDT), the kernel log of the sleep; devices gone |
| Load | every logical CPU: memory in 7 patterns with every word checked, and a fixed calculation that must come out the same to the bit (a C# helper that Windows compiles itself) | the same with coreutils: patterns through a file system in RAM (`/dev/shm`, or a tmpfs of its own for the load when there is none) and `cmp` (by a hash on a cut-down system without `cmp`), the fixed calculation with `gzip` and `awk`; the Tctl temperature. With no room in RAM at all, the result says plainly that memory was not checked |
| Idling | 18 min in the long run, signs of life and pauses when the system did not answer | the same |
| Restarts | N in a row, the finished ones counted; a clean shutdown, no extra starts, how long each took; gaps in time catch hangs | the same through a systemd unit and the journal |
| Result | the events of the test: WHEA, blue screens and minidumps (a list), unexpected shutdowns, display driver resets (TDR), disk errors (storahci, stornvme), USB, ACPI | the kernel log of the test: MCE, panics, stalls, PCIe errors, graphics, disks (SATA, NVMe), USB, ACPI; pstore; EDAC |

**The fan after sleep** (on T2.0 with a Ryzen 5600G the fan stops following the temperature after a wake): **not checked on Windows**, since that needs hardware access, and on this board accesses to the sensor chip from Windows can hang it. On Linux, with `--deep`, see below. Without it, just listen: does the fan speed change under load after a sleep.

### What the script changes for the test and how it undoes it

The script first writes every change into a journal and undoes it at the end, on a stop, on Ctrl+C, or, if the test broke off, at the next start of the system or the next run of the script. In the archive the journal is `changes-undone.txt`.

- **Windows:** the scheduled tasks `\Z3NOVO\Z3TEST-resume` (at Windows start, as the system: carries the test on after a restart) and `\Z3NOVO\Z3TEST-wake` (wakes the computer from sleep; removed after each sleep); "Allow wake timers" of the active power plan (plugged in) for the sleep step; the folder `C:\ProgramData\Z3TEST`, open to administrators and the system only. If the test finished while nobody was logged on, a one-time task `\Z3NOVO\Z3TEST-show` stays: it shows the result once at logon, removes itself after 3 days, and the next run of the script or `-Stop` removes it at once.
- **Linux:** the unit `/etc/systemd/system/z3test-resume.service` (carries the test on after a restart); `/sys/power/mem_sleep`, only if it was not `deep`, until the next boot; the RTC wake alarm; a tmpfs of its own under `/var/lib/z3test` for the load, only if the system has no `/dev/shm`; the folder `/var/lib/z3test`. The sleep inhibitor against the desktop (`systemd-inhibit`) lives only as long as the script. One line "z3test: run … started" goes into the kernel log: the result reads the kernel log from there on only.

### What the script never does

- It writes no firmware variables and changes no BIOS settings; the Z3NOVO and Secure Boot variables are only read.
- It does not touch hardware directly: I/O ports, SMBus, the Super I/O chip IT8738, the EC, ACPI thermal zones. With a Ryzen 3 2200G such accesses from the OS hang the sensor chip. The one exception is `--deep` on Linux (below).
- It does not use the network, installs no programs or drivers, never reads the Windows key (only the activation status and the licence channel).
- The archive masks what the z3report report masks: computer name, user names, serial numbers, UUIDs, MAC addresses (all but the first three bytes), IP addresses, Wi-Fi names, home folder paths.

### The fan after sleep: `--deep` (Linux only)

`sudo bash z3test.sh --deep` adds the fan check after sleep to the usual test. The quickest is sleep only with it, about 5 minutes: `sudo bash z3test.sh --deep --skip load,idle,reboot`.

How it works. In Z3NOVO the CPU fan is driven by the Z3Fan driver inside the firmware (SMM), twice a second. Its state shows in byte `DEh` of the extended CMOS memory (ports `72h`/`73h`): bit 6 "Z3Fan is on this boot", bit 7 "Z3Fan confirmed that it runs"; on every tick Z3Fan sets bit 7 again if it is clear. The script:

1. before the first sleep reads `DEh` and **clears bit 7 once**: if the bit is back 3 seconds later, Z3Fan runs and the check is valid;
2. after the first and after the last sleep does the same. A bit that does not come back after a sleep means Z3Fan does not run after waking: that is the T2.0 bug, and the result says so.

This is a **write** to CMOS, so only with `--deep`, only as root and only when everything fits: an AMD processor, the AM4P2MS board (ThinkCentre M715s), the Z3NOVO firmware running (its Z3Chip variable is there), and a kernel that allows `/dev/port` (with Secure Boot on, the kernel lockdown forbids it, and `--deep` is skipped). Only bit 7 of `DEh` changes: the low half of the byte (another counter) and the other bits are left alone, and the index port is put back as it was after every access (as Z3Fan itself does). If the bit did not come back by itself, the script sets it back at once, so the byte ends as it was. The bit has no effect on how the computer works: the firmware reads it only at power-on and sets it anew at every power-on. The details are in `fan.txt` in the archive.

### What to send

The whole archive (`Z3TEST-win-….zip` or `Z3TEST-linux-….zip`) to the Telegram bot [@z3novo_bot](https://t.me/z3novo_bot) ("Problem" or "Everything works") or on GitHub: **Issues → New issue**. Say which Z3NOVO version (in the BIOS menu title) and anything unusual. If the result has errors, attach the BIOS report as well: Del, then F11 ([how](../../docs/DIAGNOSTICS.md#bios-report-f11)). You may look through the files before sending: masked values look like `<host>`, `<user>`, `<serial>`, `~` and so on.

---

## For developers / Для разработчиков

- `z3test.ps1` and `z3test.sh` carry the code of `../report/z3report.ps1` and `../report/z3report.sh` unchanged, between two marker lines (`==== z3report.ps1 1.0 (sha256 …), its lines … copied unchanged`): the snapshot is z3report's own steps and summary, and every file of the archive goes through z3report's masking (plus one rule: a line starting with the byte 02h is fixed text and is not masked). A fix to the report or the masking goes into z3report first; the two test scripts are then made again from it.
- Windows: everything lives in `C:\ProgramData\Z3TEST` (administrators and SYSTEM only, the startup task runs a copy of the script from there as SYSTEM): `current.txt` points at the run folder `run-<stamp>` with `state.txt` (key=value), `changes.txt` (the journal: `task|NAME`, `power|SCHEME|SUB|SETTING|ac|OLD`, `taskfolder`), `heartbeat.txt` (`epoch|step|detail`, every 10 s), `verdicts.txt` (`LEVEL|ru|en`), the raw logs, and `STOP` (the stop flag). A file opened without sharing (`lock`) keeps a second copy out. The run folder is removed once the zip is written.
- Linux: the same in `/var/lib/z3test` (journal kinds `unit`, `memsleep`, `wakealarm`, `cmosde`, `shm`, `mount`); the lock is `flock` on `lock`. Every `awk` here keeps to what mawk and busybox awk do too: numbers that can pass 2^31 (memory sizes) are counted in MiB and printed with `%.0f`, never `%d` (`tests/awkcheck.sh`).
- Steps in `state.txt` (`phase`): `snapshot`, `sleep`, `load`, `idle`, `reboot`, `final`, `done`. A start with a run on and `phase=reboot` with a restart asked for is a restart of the test; any other start is "unexpected": the script reads Kernel-Power 41 (Windows) or the end of the previous boot in the journal (Linux) and the last heartbeat, writes what happened and finishes.
- Linux test hooks (used by the QEMU and awk checks): `Z3TEST_ROOT`, `Z3TEST_UNIT_DIR`, `Z3TEST_FAKE_SYSTEMD=1`, `Z3TEST_REBOOT_CMD`, `Z3TEST_FAKE_CMOS=DIR` (files `index` and `cmos` in place of ports 72h/73h), `Z3TEST_MEMINFO`, `Z3TEST_DMI_TABLE`, `Z3TEST_SYSPCI`, `Z3TEST_LOAD_PLACES`, and z3report's `Z3REPORT_EFIVARS`.
- `z3test.ps1` keeps its code ASCII; the Russian strings live in the `$TextData` and `$TestTextData` blocks, re-decoded at run time if the file lost its UTF-8 BOM. Keep the BOM when editing.
