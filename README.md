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

Проверено на плате с Ryzen 3 2200G и двумя планками памяти по 8 ГБ.

✅ **Работает**
- включение и перезагрузки (100 из 100 подряд), сон;
- новое меню мышью и клавиатурой, меню загрузки (F9);
- изображение со встроенной графики через DisplayPort, USB-клавиатура и мышь, SSD SATA, сеть;
- память в двух каналах на DDR4-2667;
- тихий вентилятор, включение после пропадания света;
- Linux;
- DASH: текстовая консоль BIOS по сети.

⚠️ **Есть, но ещё не проверено**
- другие процессоры (Ryzen 2000, 3000, 5000), видеокарта, SSD M.2;
- четыре планки памяти, XMP;
- Windows, звук, COM-порт, загрузка по сети;
- настройки сети DASH в новом меню;
- обновление BIOS с флешки и «Отчёт для диагностики» — появятся в T1.

❌ **Не работает**
- изменение напряжения памяти — так устроена плата;
- процессоры A-серии;
- разгон — в T1 выключен;
- загрузка по сети в старом режиме (не UEFI).

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

Tested on a board with a Ryzen 3 2200G and two 8 GB memory sticks.

✅ **Works**
- power-on and reboots (100 out of 100 in a row), sleep;
- the new menu with mouse and keyboard, the boot menu (F9);
- picture from the built-in graphics over DisplayPort, USB keyboard and mouse, SATA SSD, network;
- dual-channel memory at DDR4-2667;
- the quiet fan, power on after a power cut;
- Linux;
- DASH: the text BIOS console over the network.

⚠️ **There, but not tested yet**
- other processors (Ryzen 2000, 3000, 5000), a graphics card, an M.2 SSD;
- four memory sticks, XMP;
- Windows, sound, the serial (COM) port, network boot;
- DASH network settings in the new menu;
- updating the BIOS from a USB stick and the "Diagnostics report" — coming in T1.

❌ **Does not work**
- changing the memory voltage — that is how the board is built;
- A-series processors;
- overclocking — off in T1;
- network boot in the old (non-UEFI) mode.

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
