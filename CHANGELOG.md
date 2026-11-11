# История версий / Changelog

Новые версии сверху. T1, T2 и так далее — тестовые версии; 1.0 будет первой стабильной.
Newest first. T1, T2 and so on are test versions; 1.0 will be the first stable one.

## T1.2 — служебные байты CMOS

- **Прошивка больше не верит мусору в памяти CMOS.** Память CMOS (та, что держится на батарейке) хранит и служебные
  байты нашей прошивки: журнал запусков, отметки для отчёта F11 и несколько тестовых команд для разработки. Если плата
  пришла с остатками другой прошивки, случайное значение могло совпасть с такой командой. На одной плате из-за этого
  при каждом включении было три перезапуска подряд, а передние USB и два задних под сетевым разъёмом не работали.
  Теперь прошивка помечает свои байты подписью и при первом запуске, если подписи нет, один раз их стирает.
- После установки журнал запусков в отчёте F11 начнётся заново — это нормально, один раз.
- Больше ничего не менялось: всё остальное как в T1.1r.
- Обновление с T1.1r, T1.1 или T1: из меню с флешки, как обычно ([как обновить](docs/FLASHING.md#обновление)).
  Настройки сохраняются.

## T1.2 — CMOS service bytes

- **The firmware no longer trusts leftovers in CMOS memory.** The battery-backed CMOS memory also holds our firmware's
  service bytes: the boot log, marks for the F11 report and a few test commands for development. When a board came with
  another firmware's leftovers, a random value could match such a command. On one board that meant three restarts in a
  row at every power-on, and the front USB sockets and the two rear ones under the network socket did not work. Now the
  firmware marks its bytes with a signature and, at the first start without one, clears them once.
- After installing, the boot log in the F11 report starts over — that is normal, once.
- Nothing else changed: everything else is as in T1.1r.
- Updating from T1.1r, T1.1 or T1: from the menu with a USB stick, as usual ([how to update](docs/FLASHING.md#updating)).
  Settings are kept.

## T1.1r — перезагрузка на Ryzen 4000G и 5000G

- **Перезагрузка теперь полная на всех процессорах, кроме Ryzen 2000G/3000G и Athlon 200GE/3000G.** В T1.1 она была
  «мягкой», как у Lenovo: процессор сбрасывался не полностью. Ryzen 4000G и 5000G к такому не готовы: на 5000G
  перезагрузка из Windows зависала, а на 4600G после неё Windows тормозила и показывала «Время работы» около 10675199
  дней. Теперь перезагрузка на них полная, как в BIOS Biostar. Для Ryzen 2000G/3000G и Athlon всё осталось как в T1.1.
- Больше ничего не менялось.
- Обновление с T1.1 или T1: из меню с флешки, как обычно ([как обновить](docs/FLASHING.md#обновление)). Настройки
  сохраняются.

## T1.1r — restarts on Ryzen 4000G and 5000G

- **A restart is now a full one on every processor except the Ryzen 2000G/3000G and Athlon 200GE/3000G.** In T1.1 it
  was a "soft" one, as Lenovo has it: the processor was not reset all the way. The Ryzen 4000G and 5000G are not made for
  that: on a 5000G a restart from Windows hung, and on a 4600G Windows slowed down after it and showed an uptime of about
  10675199 days. Now these processors get a full restart, as in Biostar's BIOS. On the Ryzen 2000G/3000G and Athlon
  nothing changed from T1.1.
- Nothing else changed.
- Updating from T1.1 or T1: from the menu with a USB stick, as usual ([how to update](docs/FLASHING.md#updating)).
  Settings are kept.

## T1.1 — исправления к T1

- **Windows снова загружается.** На T1 Windows падала при загрузке с синим экраном ACPI_BIOS_ERROR, а следующий старт
  зависал до выключения кнопкой. Причина — наша правка термозоны ACPI: прошивка превращала её в устройство без
  названия, а Windows такое не принимает. Теперь термозона остаётся термозоной, но не обращается к микросхеме датчиков и
  всегда показывает 0 °C (это заглушка, температуру процессора смотрите по датчику процессора).
- **Контроллер GPIO снова виден системе** (в T1 он был скрыт). В Linux при загрузке снова появляется безвредная строка
  `irq 7: nobody cared`.
- **Меню загрузки F9 запускает флешку сразу**, без перезагрузки, даже если у прошивки ещё нет для неё записи загрузки.
- **«Параметры встроенного ПО UEFI» в Windows** (и `systemctl reboot --firmware-setup` в Linux) открывают наше меню, а не
  родное меню BIOS.
- Обновление с T1: из меню с флешки, как обычно ([как обновить](docs/FLASHING.md#обновление)). Настройки сохраняются.

## T1.1 — fixes for T1

- **Windows boots again.** On T1 Windows stopped at boot with the blue screen ACPI_BIOS_ERROR, and the next start hung
  until the power button was held. The cause was our change to the ACPI thermal zone: the firmware turned it into a
  device with no name, which Windows does not accept. Now the thermal zone stays a thermal zone, but it no longer touches
  the sensor chip and always reads 0 °C (a placeholder; read the processor temperature from the processor's own sensor).
- **The GPIO controller is visible to the system again** (T1 hid it). Linux shows the harmless line
  `irq 7: nobody cared` at boot again.
- **The F9 boot menu starts a USB stick right away**, without a restart, even when the firmware has no boot entry for it
  yet.
- **"UEFI Firmware Settings" in Windows** (and `systemctl reboot --firmware-setup` on Linux) open our menu, not the stock
  BIOS menu.
- Updating from T1: from the menu with a USB stick, as usual ([how to update](docs/FLASHING.md#updating)). Settings are
  kept.

## T1 — первая тестовая версия

### Что нового по сравнению с родным BIOS Lenovo
- Можно ставить процессоры Ryzen вплоть до 5000-й серии (AMD AGESA 1.2.0.F).
- Новое меню настроек (клавиша Del): мышь, русский и английский, поиск, простой режим. Меню выбора загрузки (F9).
- **Обновление BIOS с флешки прямо из меню** (Классика → Безопасность → «Прошивка BIOS»). Ваши настройки, ключ Windows
  и данные TPM сохраняются; перед записью можно сохранить копию всей микросхемы на флешку.
  [Как обновить](docs/FLASHING.md#обновление).
- **Отчёт для диагностики** по клавише F11 — файл на флешке, который прикладывают к сообщению о проблеме.
- **Резервные копии настроек:** видно, на какой версии прошивки снята копия и что именно вернётся.
- Тихий вентилятор с плавными оборотами и своим графиком.
- **Разгон памяти:** частота до DDR4-3200 (Ryzen 1000, 2000, 2000G, 3000G) или до DDR4-3600 (Ryzen 3000, 4000G, 5000,
  5000G), основные задержки, XMP при одинаковых планках с профилем. Если память не заработает, компьютер сам запустится
  на обычной скорости, а меню предложит вернуть «Авто».
- **Режим мощности** для Ryzen 2200G, 2400G, 3200G и 3400G: «Эко» (35 Вт), «Обычный», «Повышенный» (до 88 Вт).
- **Resizable BAR** — один переключатель в меню.
- Включение после пропадания света, сон, включение по будильнику и по сети.
- Видеовыходы настроены как у Lenovo: оба разъёма DisplayPort работают как DisplayPort.
- Исправлены зависания при включении и перезагрузке с Ryzen 3 2200G.
- Загрузка по сети (UEFI).
- **DASH** — удалённое управление (по умолчанию выключено): веб-страница карты, текстовая консоль по сети, настройки сети
  DASH прямо в меню, удалённое включение, выключение и перезагрузка. В Linux для удалённого питания нужен параметр ядра
  `module_blacklist=i2c_piix4` ([подробнее](docs/KNOWN_ISSUES.md)).
- Скрипты для Windows и Linux, которые собирают отчёт о сбоях ([как пользоваться](tools/report/README.md)).

### Ограничения
- Напряжение памяти всегда 1,2 В — так устроена плата ([подробнее](docs/LIMITS.md)).
- Разгон процессора и графики (своя частота и напряжение) закрыт.
- Пароль BIOS пока задаётся только в родном меню (в нашем меню F1 → Security); установка из нашего меню — в следующей
  версии.
- [Известные проблемы](docs/KNOWN_ISSUES.md).

### Что проверено
На плате автора: AM4P2MS ревизии 1.1, Ryzen 3 2200G, две планки по 8 ГБ DDR4-2666.
- Первая установка программатором; обновление из меню туда и обратно с сохранением настроек; копия микросхемы перед
  записью.
- Серии перезагрузок без зависаний, сон и пробуждение по будильнику, включение по будильнику и по сети.
- Оба разъёма DisplayPort (кабель DP→HDMI), заставка и система.
- Отчёт F11, вентилятор под нагрузкой, сеть 1 Гбит/с, USB 3.0.
- DASH: веб-страница, консоль в обе стороны, адрес из меню, удалённые перезагрузка, выключение и включение.

### Что ещё не проверено
- Другие процессоры, четыре планки памяти, XMP, разгон памяти, режимы мощности под нагрузкой, Resizable BAR, видеокарта,
  M.2, Windows.

## T1 — first test version

### What is new compared with Lenovo's BIOS
- Ryzen processors up to the 5000 series can be fitted (AMD AGESA 1.2.0.F).
- A new settings menu (the Del key): mouse, English and Russian, search, a simple view. A boot menu (F9).
- **BIOS updates from a USB stick right from the menu** (Classic → Security → BIOS firmware). Your settings, Windows key
  and TPM data are kept; before writing, a copy of the whole chip can be saved to the stick.
  [How to update](docs/FLASHING.md#updating).
- **Diagnostics report** with the F11 key: a file on a USB stick to attach to a problem report.
- **Settings backups:** shows which firmware version a backup was taken on and exactly what will come back.
- A quiet fan with smooth speed changes and a curve of your own.
- **Memory overclocking:** speed up to DDR4-3200 (Ryzen 1000, 2000, 2000G, 3000G) or DDR4-3600 (Ryzen 3000, 4000G, 5000,
  5000G), the main timings, XMP when all sticks are identical and have a profile. If the memory does not start, the
  computer comes up at the normal speed by itself and the menu offers to go back to Auto.
- **Power mode** for the Ryzen 2200G, 2400G, 3200G and 3400G: Eco (35 W), Normal, Boosted (up to 88 W).
- **Resizable BAR** as a single switch in the menu.
- Power on after a power cut, sleep, power on by alarm and over the network.
- Video outputs set up as Lenovo has them: both DisplayPort sockets work as DisplayPort.
- Fixes for hangs at power-on and reboot with the Ryzen 3 2200G.
- Network boot (UEFI).
- **DASH** remote management (off by default): the card's web page, a text console over the network, DASH network
  settings right in the menu, remote power on, power off and restart. On Linux, remote power needs the kernel parameter
  `module_blacklist=i2c_piix4` ([details](docs/KNOWN_ISSUES.md)).
- Scripts for Windows and Linux that collect a crash report ([how to use them](tools/report/README.md)).

### Limits
- The memory voltage is always 1.2 V, that is how the board is built ([details](docs/LIMITS.md)).
- Processor and graphics overclocking (your own clock and voltage) is closed.
- The BIOS password can so far be set only in the stock menu (F1 → Security from our menu); setting it from our menu comes
  in the next version.
- [Known issues](docs/KNOWN_ISSUES.md).

### Tested
On the author's board: AM4P2MS revision 1.1, Ryzen 3 2200G, two 8 GB DDR4-2666 sticks.
- First install with a programmer; updating from the menu both ways with settings kept; a copy of the chip before writing.
- Series of reboots without hangs, sleep and wake by alarm, power on by alarm and over the network.
- Both DisplayPort sockets (DP→HDMI cable), the boot logo and the system.
- The F11 report, the fan under load, 1 Gbit/s network, USB 3.0.
- DASH: web page, console both ways, address from the menu, remote restart, power off and power on.

### Not tested yet
- Other processors, four memory sticks, XMP, memory overclocking, power modes under load, Resizable BAR, a graphics card,
  M.2, Windows.
