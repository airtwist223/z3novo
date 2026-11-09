# История версий / Changelog

Новые версии сверху. T1, T2 и так далее — тестовые версии; 1.0 будет первой стабильной.
Newest first. T1, T2 and so on are test versions; 1.0 will be the first stable one.

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
