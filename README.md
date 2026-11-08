# Z3NOVO — прошивка BIOS для Lenovo ThinkCentre M715s

[Русский](#z3novo--прошивка-bios-для-lenovo-thinkcentre-m715s) · [English](#z3novo--bios-firmware-for-lenovo-thinkcentre-m715s)

> **Статус: публичный тест.** Первая тестовая версия — **T1** (готовится, ещё не выпущена).
> Это неофициальная прошивка: не от Lenovo и не от AMD. Ставите на свой страх и риск.
> Перед установкой обязательно сохраните копию своей микросхемы BIOS (см. [docs/FLASHING.md](docs/FLASHING.md)).

<p align="center">
  <img src="docs/img/ez_home_ru.png" alt="Главный экран меню Z3NOVO" width="900">
</p>
<p align="center"><sub>Главный экран нового меню: процессор и его температура, память по слотам, вентилятор, быстрые настройки.</sub></p>

## Отказ от ответственности

- Прошивка распространяется **«как есть», без каких-либо гарантий**. Вы устанавливаете её сами, по своему решению и на
  свой риск.
- Автор **не несёт ответственности** за любые последствия установки и использования: неработающий или повреждённый
  компьютер, вышедшие из строя детали, потерю данных, потерю гарантии, расходы на ремонт и любой другой ущерб.
- Каждая версия перед выпуском проверяется на **собственном компьютере автора** (Lenovo ThinkCentre M715s, Ryzen 3 2200G,
  2 × 8 ГБ DDR4-2666). Что проверено — отмечено в таблице «Что работает, а что нет» и в [истории версий](CHANGELOG.md).
  Всё, что не отмечено как проверенное, **не проверялось** и может не работать.
- Это неофициальная прошивка. Lenovo, AMD, AMI, Biostar и Realtek к ней отношения не имеют и её не поддерживают.
  Установка неофициального BIOS может лишить вас гарантии производителя.
- Перед установкой сохраните копию своего BIOS: это единственный способ вернуть всё как было.

Устанавливая прошивку, вы соглашаетесь с этими условиями.

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

Проверено на плате с Ryzen 3 2200G и двумя планками по 8 ГБ.

| | ✅ Работает | ⚠️ Не проверено | ❌ Не работает |
|---|---|---|---|
| **Процессор** | Ryzen 3 2200G | другие Ryzen 1000–5000 | A-серия (A6–A12), разгон |
| **Память** | 2 планки в двухканале, DDR4-2667 | 4 планки, профиль XMP | напряжение выше 1,2 В |
| **Монитор** | DisplayPort (кабель DP→HDMI) | DP→DP, VGA | |
| **Видеокарта** | | в слоте PCIe x16 | |
| **USB** | USB 3.0, клавиатура, мышь | каждый разъём по отдельности | |
| **Диски** | SATA (SSD, HDD) | M.2 SSD | |
| **Сеть** | интернет 1 Гбит/с, включение по сети (Wake-on-LAN) | загрузка системы с сервера по сети (PXE) | |
| **DASH** (удалённое управление) | текстовое меню BIOS с другого компьютера (консоль по сети) | правка настроек DASH в новом меню | |
| **Питание** | 100 перезагрузок без зависаний, сон, включение по таймеру и после отключения света | | |
| **Меню BIOS** | новое меню (Del), выбор загрузки (F9) | обновление с флешки, отчёт (будут в T1) | |
| **Системы** | Linux | Windows | |
| **Звук** | | на плате и через DisplayPort | |
| **Прочее** | TPM 2.0, вентилятор процессора | COM-порт | |

## Ограничения железа

Коротко: **напряжение памяти на этой плате всегда 1,2 В** — его не меняет никакая прошивка; питание процессора на плате рассчитано на
процессоры до 65 Вт (кулер и блок питания можно поставить мощнее, а схему питания на плате — только лучше охлаждать). Подробно, с последствиями для XMP, разгона и памяти встроенной графики: [docs/LIMITS.md](docs/LIMITS.md).

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

## Disclaimer

- The firmware is provided **"as is", without any warranty**. You install it yourself, by your own decision and at your
  own risk.
- The author **accepts no liability** for any consequences of installing or using it: a computer that does not work or
  is damaged, failed parts, lost data, a voided warranty, repair costs or any other damage.
- Every version is tested before release on **the author's own computer** (Lenovo ThinkCentre M715s, Ryzen 3 2200G,
  2 × 8 GB DDR4-2666). What was tested is marked in the "What works and what does not" table and in the
  [version history](CHANGELOG.md). Anything not marked as tested **has not been tested** and may not work.
- This is unofficial firmware. Lenovo, AMD, AMI, Biostar and Realtek have nothing to do with it and do not support it.
  Installing an unofficial BIOS may void the manufacturer's warranty.
- Save a copy of your BIOS before installing: it is the only way to put everything back as it was.

By installing the firmware you accept these terms.

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

Tested on a board with a Ryzen 3 2200G and two 8 GB sticks.

| | ✅ Works | ⚠️ Not tested | ❌ Does not work |
|---|---|---|---|
| **Processor** | Ryzen 3 2200G | other Ryzen 1000–5000 | A-series (A6–A12), overclocking |
| **Memory** | 2 sticks in dual channel, DDR4-2667 | 4 sticks, XMP profile | voltage above 1.2 V |
| **Monitor** | DisplayPort (DP→HDMI cable) | DP→DP, VGA | |
| **Graphics card** | | in the PCIe x16 slot | |
| **USB** | USB 3.0, keyboard, mouse | each socket on its own | |
| **Drives** | SATA (SSD, HDD) | M.2 SSD | |
| **Network** | 1 Gbit/s internet, power-on over the network (Wake-on-LAN) | starting a system from a server over the network (PXE) | |
| **DASH** (remote management) | the text BIOS menu from another computer (network console) | editing DASH settings in the new menu | |
| **Power** | 100 restarts without a hang, sleep, power-on by timer and after a power cut | | |
| **BIOS menu** | new menu (Del), boot choice (F9) | USB-stick update, report (coming in T1) | |
| **Systems** | Linux | Windows | |
| **Sound** | | onboard and over DisplayPort | |
| **Other** | TPM 2.0, processor fan | COM port | |

## Hardware limits

In short: **the memory voltage on this board is always 1.2 V**, no firmware can change it, and the board's processor power circuit is built
for processors up to 65 W (the cooler and the power supply can be upgraded; the board's power circuit can only be cooled better). Details, including what this means for XMP, overclocking and integrated graphics memory:
[docs/LIMITS.md](docs/LIMITS.md).

## Documents

- [docs/FLASHING.md](docs/FLASHING.md) — installing, updating, going back.
- [docs/LIMITS.md](docs/LIMITS.md) — what the board can and cannot do.
- [docs/DIAGNOSTICS.md](docs/DIAGNOSTICS.md) — how to collect a problem report.
- [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) — known problems.
- [CHANGELOG.md](CHANGELOG.md) — version history.
