# Z3NOVO — прошивка BIOS для Lenovo ThinkCentre M715s

[Русский](#z3novo--прошивка-bios-для-lenovo-thinkcentre-m715s) · [English](#z3novo--bios-firmware-for-lenovo-thinkcentre-m715s)

> **Статус: публичный тест.** Первая тестовая версия — **T1** (готовится, ещё не выпущена).
> Это неофициальная прошивка: не от Lenovo и не от AMD. Ставите на свой страх и риск.
> Перед установкой обязательно сохраните копию своей микросхемы BIOS (см. [docs/FLASHING.md](docs/FLASHING.md)).

<p align="center">
  <img src="docs/img/ez_home_ru.png" alt="Главный экран меню Z3NOVO" width="900">
</p>
<p align="center"><sub>Главный экран нового меню: процессор и его температура, память по слотам, вентилятор, быстрые настройки.</sub></p>

## Что это

Z3NOVO — прошивка для Lenovo ThinkCentre M715s (корпус SFF, плата AM4P2MS, чипсет AMD B350).
Основа — AMI Aptio V с AGESA ComboAM4v2PI 1.2.0.F (от платы Biostar на том же чипсете), в которую перенесены таблицы
именно этой платы Lenovo: линии PCIe, выводы, питание, вентилятор, Super I/O. Вместо старого текстового меню —
своё графическое приложение настроек с мышью, на русском и английском.

## Что умеет

- **Процессоры:** Ryzen 1000–5000 для AM4 по возможностям AGESA. На этой плате проверен только Ryzen 3 2200G.
  Процессоры без встроенной графики (например, Ryzen 7 2700, Ryzen 5 5600) работают только с видеокартой.
- **Приложение настроек (Del):** мышь и клавиатура, RU/EN, поиск по настройкам, простой режим и все настройки,
  страница состояния (температура процессора, вентилятор), меню загрузки (F9), разрешение экрана по монитору,
  экранная клавиатура.
- **Вентилятор:** плавную кривую ведёт прошивка; режимы «Тихо», «Авто», «Макс» и свой редактор кривой.
- **Стабильный старт:** исправлены зависания при включении и перезагрузке, найденные на этой плате с Ryzen 3 2200G
  (в проверке 100 перезагрузок из 100).
- **Включение после пропадания питания** (настройка «Restore on AC Power Loss»).
- **Загрузка по сети UEFI (PXE).**
- **DASH** — удалённое управление по сети через встроенную сетевую карту. По умолчанию выключено. Настройки сети
  DASH (адрес, маска, шлюз, имя) меняются прямо в приложении.
- **В T1 (в работе):** обновление прошивки с флешки без программатора и «Отчёт для диагностики» одной кнопкой.

## Что работает, а что нет

Проверено на плате с Ryzen 3 2200G и двумя планками памяти по 8 ГБ. ✅ работает · ⚠️ есть, но не проверено · ❌ не работает

| Что | | Подробности |
|---|:-:|---|
| Ryzen 3 2200G | ✅ | на нём проверено всё, что ниже |
| Другие Ryzen 1000–5000 | ⚠️ | прошивка их поддерживает, на плате не проверены; без встроенной графики нужна видеокарта |
| Процессоры A-серии (A6–A12, Athlon X4 9xx) | ❌ | эта прошивка их не поддерживает |
| Включение и перезагрузка | ✅ | 100 из 100 подряд без зависаний |
| Сон (S3) и пробуждение по таймеру | ✅ | |
| Включение после пропадания питания | ✅ | настройка «Restore on AC Power Loss» |
| Wake-on-LAN (включение по сети) | ⚠️ | не проверено |
| Меню настроек Z3NOVO (Del) | ✅ | мышь и клавиатура, RU/EN, поиск |
| Меню загрузки (F9) и родное меню BIOS | ✅ | |
| Память, 2 планки, два канала, DDR4-2667 | ✅ | memtest86+ без ошибок |
| Память, 4 планки | ⚠️ | не проверено; частота будет ниже (1866–2133) |
| XMP | ⚠️ | только одинаковые планки с профилем; напряжение не поднимается |
| Напряжение памяти | ❌ | всегда 1,2 В — так устроена плата |
| Встроенная графика, DisplayPort с кабелем DP→HDMI | ✅ | 1920×1080 |
| Монитор DisplayPort на кабеле DP–DP | ⚠️ | похоже, разъём настроен как HDMI — исправим до T1 |
| Второй DisplayPort, VGA | ⚠️ | не проверено |
| Видеокарта в слоте PCIe x16 | ⚠️ | не проверено |
| USB 3.0 | ✅ | флешки на 5 Гбит/с, клавиатура, мышь |
| Каждый USB-разъём отдельно (передние, задние) | ⚠️ | не проверено по отдельности |
| SATA | ✅ | SSD на 6 Гбит/с, проверены три разъёма |
| M.2: SSD и Wi-Fi | ⚠️ | не проверено |
| Сеть | ✅ | 1 Гбит/с, на деле около 940 Мбит/с |
| Загрузка по сети (PXE) | ⚠️ | только UEFI; не проверено |
| DASH (удалённое управление) | ✅ | по умолчанию выключено; консоль BIOS по сети работает, настройки в меню ещё проверяются |
| Звук: на плате и через DP | ⚠️ | система видит, звук не включали |
| COM-порт | ⚠️ | система видит, обмен данными не проверяли |
| Вентилятор процессора | ✅ | плавная кривая, режимы «Тихо/Авто/Макс» |
| Температура процессора | ✅ | в меню и в системе |
| TPM 2.0 (в процессоре) | ✅ | Linux видит; с Windows 11 не проверено |
| Linux | ✅ | |
| Windows | ⚠️ | не проверено; может попросить активацию заново |
| Разгон | ❌ | в T1 выключен |
| Обновление BIOS с флешки, отчёт для диагностики | ⚠️ | появятся в T1 |

## Ограничения железа

Коротко: **напряжение памяти на этой плате всегда 1,2 В** — его не меняет никакая прошивка; плата рассчитана на
процессоры 65 Вт. Подробно, с последствиями для XMP, разгона и памяти встроенной графики: [docs/LIMITS.md](docs/LIMITS.md).

## Документы

- [docs/FLASHING.md](docs/FLASHING.md) — установка, обновление, откат.
- [docs/LIMITS.md](docs/LIMITS.md) — что плата может и чего не может.
- [docs/DIAGNOSTICS.md](docs/DIAGNOSTICS.md) — как собрать отчёт о проблеме.
- [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) — известные проблемы.
- [CHANGELOG.md](CHANGELOG.md) — история версий.

---

# Z3NOVO — BIOS firmware for Lenovo ThinkCentre M715s

> **Status: public test.** The first test version is **T1** (in preparation, not released yet).
> This is unofficial firmware, made neither by Lenovo nor by AMD. Install it at your own risk.
> Save a copy of your own BIOS chip before you install anything (see [docs/FLASHING.md](docs/FLASHING.md)).

<p align="center">
  <img src="docs/img/ez_home_ru.png" alt="The Z3NOVO menu's home screen" width="900">
</p>
<p align="center"><sub>The new menu's home screen (shown in Russian; English is one click away): processor and its temperature, memory by slot, fan, quick settings.</sub></p>

## What it is

Z3NOVO is firmware for the Lenovo ThinkCentre M715s (SFF case, board AM4P2MS, AMD B350 chipset). It is AMI Aptio V with
AGESA ComboAM4v2PI 1.2.0.F (from a Biostar board with the same chipset), carrying this Lenovo board's own tables:
PCIe lanes, pins, power, fan, Super I/O. Instead of the old text menu it has its own graphical settings app with mouse
support, in Russian and English.

## What it does

- **Processors:** AM4 Ryzen 1000–5000 as far as AGESA supports them. Only the Ryzen 3 2200G has been tested on this board.
  Processors without integrated graphics (for example the Ryzen 7 2700 or Ryzen 5 5600) need a graphics card.
- **Settings app (Del):** mouse and keyboard, RU/EN, settings search, a simple view and all settings, a status page (CPU
  temperature, fan), a boot menu (F9), screen resolution from the monitor, an on-screen keyboard.
- **Fan:** the firmware drives a smooth curve; Quiet, Auto and Max presets and a curve editor of your own.
- **Reliable start:** fixes for hangs at power-on and reboot found on this board with the Ryzen 3 2200G (100 out of 100
  reboots in testing).
- **Power on after a power loss** (the "Restore on AC Power Loss" setting).
- **UEFI network boot (PXE).**
- **DASH** remote management over the onboard network card. Off by default. Its network settings (address, mask,
  gateway, name) are edited right in the app.
- **Coming in T1 (in progress):** firmware updates from a USB stick without a programmer, and a one-button diagnostics report.

## What works and what does not

Tested on a board with a Ryzen 3 2200G and two 8 GB memory sticks. ✅ works · ⚠️ there, not tested · ❌ does not work

| What | | Details |
|---|:-:|---|
| Ryzen 3 2200G | ✅ | everything below was tested with it |
| Other Ryzen 1000–5000 | ⚠️ | supported by the firmware, not tested on a board; without built-in graphics you need a graphics card |
| A-series processors (A6–A12, Athlon X4 9xx) | ❌ | this firmware does not support them |
| Power-on and restart | ✅ | 100 out of 100 in a row without a hang |
| Sleep (S3) and waking on a timer | ✅ | |
| Power on after a power cut | ✅ | the "Restore on AC Power Loss" setting |
| Wake-on-LAN (power on over the network) | ⚠️ | not tested |
| Z3NOVO settings menu (Del) | ✅ | mouse and keyboard, RU/EN, search |
| Boot menu (F9) and the stock BIOS menu | ✅ | |
| Memory, 2 sticks, dual channel, DDR4-2667 | ✅ | memtest86+ without errors |
| Memory, 4 sticks | ⚠️ | not tested; the speed will be lower (1866–2133) |
| XMP | ⚠️ | identical sticks with a profile only; the voltage cannot be raised |
| Memory voltage | ❌ | always 1.2 V — that is how the board is built |
| Built-in graphics, DisplayPort with a DP→HDMI cable | ✅ | 1920×1080 |
| A DisplayPort monitor on a DP–DP cable | ⚠️ | the socket seems to be set up as HDMI — to be fixed before T1 |
| Second DisplayPort, VGA | ⚠️ | not tested |
| Graphics card in the PCIe x16 slot | ⚠️ | not tested |
| USB 3.0 | ✅ | USB sticks at 5 Gbit/s, keyboard, mouse |
| Each USB socket on its own (front, back) | ⚠️ | not tested one by one |
| SATA | ✅ | SSD at 6 Gbit/s, three sockets tested |
| M.2: SSD and Wi-Fi | ⚠️ | not tested |
| Network | ✅ | 1 Gbit/s, about 940 Mbit/s in practice |
| Network boot (PXE) | ⚠️ | UEFI only; not tested |
| DASH (remote management) | ✅ | off by default; the BIOS console over the network works, the settings in the menu are still being tested |
| Sound: onboard and over DP | ⚠️ | the system sees it, no sound played yet |
| Serial (COM) port | ⚠️ | the system sees it, no data sent yet |
| Processor fan | ✅ | smooth curve, Quiet/Auto/Max modes |
| Processor temperature | ✅ | in the menu and in the system |
| TPM 2.0 (in the processor) | ✅ | Linux sees it; not tested with Windows 11 |
| Linux | ✅ | |
| Windows | ⚠️ | not tested; may ask to be activated again |
| Overclocking | ❌ | off in T1 |
| BIOS update from a USB stick, diagnostics report | ⚠️ | coming in T1 |

## Hardware limits

In short: **the memory voltage on this board is always 1.2 V**, no firmware can change it, and the board is built for
65 W processors. Details, including what this means for XMP, overclocking and integrated graphics memory:
[docs/LIMITS.md](docs/LIMITS.md).

## Documents

- [docs/FLASHING.md](docs/FLASHING.md) — installing, updating, going back.
- [docs/LIMITS.md](docs/LIMITS.md) — what the board can and cannot do.
- [docs/DIAGNOSTICS.md](docs/DIAGNOSTICS.md) — how to collect a problem report.
- [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) — known problems.
- [CHANGELOG.md](CHANGELOG.md) — version history.
