# История версий / Changelog

Новые версии сверху. T1, T2… — публичные тестовые версии; 1.0 будет первой стабильной.
Newest first. T1, T2… are public test versions; 1.0 will be the first stable one.

## T1 — первая публичная тестовая / first public test (готовится / in preparation)

### Есть в версии
- Основа: AMI Aptio V, AGESA ComboAM4v2PI 1.2.0.F, таблицы платы Lenovo M715s (AM4P2MS).
- Приложение настроек Z3NOVO (Del): мышь и клавиатура, RU/EN, поиск, простой режим и все настройки, страница
  состояния, меню загрузки (F9), разрешение по монитору, экранная клавиатура.
- Вентилятор под управлением прошивки: плавная кривая, режимы «Тихо/Авто/Макс», редактор кривой.
- Исправления зависаний при включении и перезагрузке с Ryzen 3 2200G.
- Включение после пропадания питания.
- Загрузка по сети UEFI (PXE).
- DASH: по умолчанию выключено; настройки сети DASH в приложении.
- Скрипты сбора журналов для Windows и Linux ([tools/report](tools/report/README.md)); скрипт для Windows ещё проходит первую проверку.
- В работе: обновление прошивки с флешки, «Отчёт для диагностики» в приложении.

### Ограничения
- Напряжение памяти всегда 1,2 В (так устроена плата), см. [docs/LIMITS.md](docs/LIMITS.md).
- XMP — только при одинаковых планках с профилем.
- Разгон процессора и графики закрыт.
- Известные проблемы: [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md).

### Проверено
- Ryzen 3 2200G, 2 × 8 ГБ DDR4-2666: запуск, 100 перезагрузок подряд, вентилятор, сеть, DASH.

### Не проверено
- Другие процессоры, четыре планки, XMP, память графики больше 2 ГБ.

### In this version
- Base: AMI Aptio V, AGESA ComboAM4v2PI 1.2.0.F, the Lenovo M715s (AM4P2MS) board tables.
- The Z3NOVO settings app (Del): mouse and keyboard, RU/EN, search, a simple view and all settings, a status page,
  a boot menu (F9), resolution from the monitor, an on-screen keyboard.
- Firmware fan control: a smooth curve, Quiet/Auto/Max presets, a curve editor.
- Fixes for hangs at power-on and reboot with the Ryzen 3 2200G.
- Power on after a power loss.
- UEFI network boot (PXE).
- DASH: off by default; DASH network settings in the app.
- Log collection scripts for Windows and Linux ([tools/report](tools/report/README.md)); the Windows script is still getting its first test.
- In progress: firmware updates from a USB stick, the diagnostics report in the app.

### Limits
- The memory voltage is always 1.2 V (that is how the board is built), see [docs/LIMITS.md](docs/LIMITS.md).
- XMP only with identical sticks that have a profile.
- Processor and graphics overclocking is locked.
- Known issues: [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md).

### Tested
- Ryzen 3 2200G, 2 × 8 GB DDR4-2666: start, 100 reboots in a row, fan, network, DASH.

### Not tested
- Other processors, four sticks, XMP, graphics memory above 2 GB.
