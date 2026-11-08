# История версий / Changelog

Новые версии сверху. T1, T2 и так далее — тестовые версии; 1.0 будет первой стабильной.
Newest first. T1, T2 and so on are test versions; 1.0 will be the first stable one.

## T1 — первая тестовая версия (готовится)

### Что нового по сравнению с родным BIOS Lenovo
- Можно ставить процессоры Ryzen вплоть до 5000-й серии.
- Новое меню настроек (клавиша Del): мышь, русский и английский, поиск, простой режим.
- Меню выбора, с чего загружаться (клавиша F9).
- Тихий вентилятор с плавными оборотами и своим графиком.
- Включение после пропадания света.
- Исправлены зависания при включении и перезагрузке с Ryzen 3 2200G.
- Видеовыходы настроены как у Lenovo: оба разъёма DisplayPort теперь работают как DisplayPort (раньше два выхода были
  настроены как HDMI, и монитор на кабеле DP–DP мог не показывать); должен заработать VGA. Кабели DP→HDMI работают как раньше.
- Загрузка по сети.
- Удалённое управление DASH (по умолчанию выключено), его настройки сети меняются прямо в меню.
- Скрипты для Windows и Linux, которые собирают отчёт о сбоях ([как пользоваться](tools/report/README.md)).
  Скрипт для Windows ещё проходит первую проверку.
- Ещё делается: обновление BIOS с флешки прямо из меню и кнопка «Отчёт для диагностики».

### Ограничения
- Напряжение памяти всегда 1,2 В — так устроена плата ([подробнее](docs/LIMITS.md)).
- Быстрый режим памяти XMP — только если все планки одинаковые.
- Разгон процессора и графики выключен.
- [Известные проблемы](docs/KNOWN_ISSUES.md).

### Что проверено
- Ryzen 3 2200G, две планки по 8 ГБ DDR4-2666: включение, 100 перезагрузок подряд, вентилятор, сеть, DASH.

### Что ещё не проверено
- Другие процессоры, четыре планки памяти, XMP, больше 2 ГБ памяти для встроенной графики.

## T1 — first test version (in preparation)

### What is new compared with Lenovo's BIOS
- Ryzen processors up to the 5000 series can be fitted.
- A new settings menu (the Del key): mouse, English and Russian, search, a simple view.
- A menu to choose what to boot from (the F9 key).
- A quiet fan with smooth speed changes and a curve of your own.
- Power on after a power cut.
- Fixes for hangs at power-on and reboot with the Ryzen 3 2200G.
- Video outputs set up as Lenovo has them: both DisplayPort sockets now work as DisplayPort (two outputs used to be set
  up as HDMI, so a monitor on a DP–DP cable might show nothing); VGA should start working. DP→HDMI cables work as before.
- Network boot.
- DASH remote management (off by default), with its network settings in the menu.
- Scripts for Windows and Linux that collect a crash report ([how to use them](tools/report/README.md)).
  The Windows script is still getting its first test.
- Still in progress: updating the BIOS from a USB stick right from the menu, and a "Diagnostics report" button.

### Limits
- The memory voltage is always 1.2 V, that is how the board is built ([details](docs/LIMITS.md)).
- The XMP fast memory mode only when all sticks are identical.
- Processor and graphics overclocking is off.
- [Known issues](docs/KNOWN_ISSUES.md).

### Tested
- Ryzen 3 2200G, two 8 GB DDR4-2666 sticks: power-on, 100 reboots in a row, fan, network, DASH.

### Not tested yet
- Other processors, four memory sticks, XMP, more than 2 GB of memory for built-in graphics.
