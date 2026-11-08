# Z3NOVO — новый BIOS для Lenovo ThinkCentre M715s

[Русский](#z3novo--новый-bios-для-lenovo-thinkcentre-m715s) · [English](#z3novo--a-new-bios-for-the-lenovo-thinkcentre-m715s)

> **Это публичный тест.** Первая тестовая версия — **T1**, она ещё готовится.
> Прошивку сделали энтузиасты, а не Lenovo. Ставите её на свой страх и риск.
> Перед установкой обязательно сохраните копию своего BIOS — как, написано в [инструкции](docs/FLASHING.md).

<p align="center">
  <img src="docs/img/ez_home_ru.png" alt="Главный экран меню Z3NOVO" width="900">
</p>
<p align="center"><sub>Главный экран нового меню: процессор и его температура, память по слотам, вентилятор, быстрые настройки.</sub></p>

## Что это и зачем

BIOS — это программа внутри компьютера, которая его включает и запускает Windows или Linux.
Родной BIOS Lenovo для M715s старый: новые процессоры с ним не работают, меню неудобное, вентилятор шумит.

Z3NOVO заменяет родной BIOS. С ним:

- **Можно поставить более новый процессор Ryzen**, вплоть до 5000-й серии.
  *Пока проверено только с Ryzen 3 2200G.* Процессорам без встроенной графики (например, Ryzen 7 2700 или
  Ryzen 5 5600) нужна отдельная видеокарта.
- **Удобное меню настроек** (клавиша Del): работает мышью, на русском и английском, есть поиск и простой режим.
- **Тихий вентилятор**: обороты меняются плавно, есть режимы «Тихо», «Авто», «Макс» и свой график.
- **Включение после пропадания света**, если включить это в настройках.
- **Исправлены зависания** при включении и перезагрузке, которые бывали на этой плате.
- **Загрузка по сети** и **удалённое управление DASH** (по умолчанию выключено).
- **Скоро, в T1:** обновление BIOS с флешки прямо из меню и кнопка «Отчёт для диагностики».

## Что работает, а что нет

Проверено на плате с Ryzen 3 2200G и двумя планками памяти по 8 ГБ.

✅ **Работает**
- включение и перезагрузки (100 из 100 подряд), сон;
- новое меню мышью и клавиатурой, меню загрузки (F9);
- изображение со встроенной графики через HDMI (1920×1080);
- USB 3.0 на полной скорости (5 Гбит/с), USB-клавиатура и мышь;
- сеть 1 Гбит/с (около 940 Мбит/с на деле);
- SSD SATA на 6 Гбит/с;
- память в двух каналах на DDR4-2667;
- тихий вентилятор, включение после пропадания света;
- Linux;
- DASH: текстовая консоль BIOS по сети.

⚠️ **Есть, но ещё не проверено**
- другие процессоры (Ryzen 2000, 3000, 5000), видеокарта, SSD M.2;
- четыре планки памяти, XMP;
- выходы DisplayPort и VGA;
- звук: звуковые устройства система видит, но звук ещё не включали;
- COM-порт: система его видит, передачу не проверяли;
- каждый USB-разъём по отдельности (передние и задние);
- Windows, загрузка по сети;
- настройки сети DASH в новом меню;
- обновление BIOS с флешки и «Отчёт для диагностики» — появятся в T1.

❌ **Не работает**
- изменение напряжения памяти — так устроена плата;
- процессоры A-серии;
- разгон — в T1 выключен;
- загрузка по сети в старом режиме (не UEFI).

## Что нужно знать заранее

- **Первый раз прошивку ставят программатором.** Это недорогое устройство, которое подключают прямо к микросхеме
  BIOS на плате. Потом обновлять можно будет с флешки. Подробно — в [инструкции по установке](docs/FLASHING.md).
- **Windows может попросить активацию заново.** Держите под рукой ключ или вход в учётную запись Microsoft.
  Подробно — в [известных проблемах](docs/KNOWN_ISSUES.md).
- **У самой платы есть ограничения,** их не исправит никакой BIOS: напряжение памяти всегда 1,2 В, а плата рассчитана
  на процессоры до 65 Вт. Что из этого следует — в [ограничениях платы](docs/LIMITS.md).

## Если что-то не так

Опишите, что случилось, в разделе **Issues** на GitHub и приложите отчёт. Как его собрать — в [этой инструкции](docs/DIAGNOSTICS.md).

## Документы

- [Установка, обновление и возврат к родному BIOS](docs/FLASHING.md)
- [Что плата может и чего не может](docs/LIMITS.md)
- [Известные проблемы](docs/KNOWN_ISSUES.md)
- [Как сообщить о проблеме](docs/DIAGNOSTICS.md)
- [История версий](CHANGELOG.md)

## Для тех, кому интересно

Плата AM4P2MS на чипсете AMD B350. Основа прошивки — AMI Aptio V с AGESA ComboAM4v2PI 1.2.0.F от платы Biostar на том
же чипсете. В неё перенесены настройки именно этой платы Lenovo: линии PCIe, питание, вентилятор, микросхема Super I/O.

---

# Z3NOVO — a new BIOS for the Lenovo ThinkCentre M715s

> **This is a public test.** The first test version is **T1**, still in preparation.
> The firmware is made by enthusiasts, not by Lenovo. Install it at your own risk.
> Save a copy of your own BIOS before you install anything — see the [guide](docs/FLASHING.md).

<p align="center">
  <img src="docs/img/ez_home_ru.png" alt="The Z3NOVO menu's home screen" width="900">
</p>
<p align="center"><sub>The new menu's home screen (shown in Russian; English is one click away): processor and its temperature, memory by slot, fan, quick settings.</sub></p>

## What it is and why

The BIOS is the program inside the computer that switches it on and starts Windows or Linux.
Lenovo's own BIOS for the M715s is old: newer processors do not work with it, its menu is awkward, and the fan is loud.

Z3NOVO replaces Lenovo's BIOS. With it:

- **You can fit a newer Ryzen processor**, up to the 5000 series.
  *So far only the Ryzen 3 2200G has been tested.* Processors without built-in graphics (for example the Ryzen 7 2700
  or Ryzen 5 5600) need a graphics card.
- **An easy settings menu** (the Del key): works with a mouse, in English and Russian, with search and a simple view.
- **A quiet fan**: its speed changes smoothly, with Quiet, Auto and Max modes and a curve of your own.
- **Power on after a power cut**, if you turn that on in the settings.
- **Fixes for hangs** at power-on and reboot that used to happen on this board.
- **Network boot** and **DASH remote management** (off by default).
- **Coming in T1:** updating the BIOS from a USB stick right from the menu, and a "Diagnostics report" button.

## What works and what does not

Tested on a board with a Ryzen 3 2200G and two 8 GB memory sticks.

✅ **Works**
- power-on and reboots (100 out of 100 in a row), sleep;
- the new menu with mouse and keyboard, the boot menu (F9);
- picture from the built-in graphics over HDMI (1920×1080);
- USB 3.0 at full speed (5 Gbit/s), USB keyboard and mouse;
- network at 1 Gbit/s (about 940 Mbit/s in practice);
- SATA SSD at 6 Gbit/s;
- dual-channel memory at DDR4-2667;
- the quiet fan, power on after a power cut;
- Linux;
- DASH: the text BIOS console over the network.

⚠️ **There, but not tested yet**
- other processors (Ryzen 2000, 3000, 5000), a graphics card, an M.2 SSD;
- four memory sticks, XMP;
- the DisplayPort and VGA outputs;
- sound: the system sees the sound devices, but sound has not been played yet;
- the serial (COM) port: the system sees it, data has not been sent through it yet;
- each USB socket on its own (front and back);
- Windows, network boot;
- DASH network settings in the new menu;
- updating the BIOS from a USB stick and the "Diagnostics report" — coming in T1.

❌ **Does not work**
- changing the memory voltage — that is how the board is built;
- A-series processors;
- overclocking — off in T1;
- network boot in the old (non-UEFI) mode.

## Know this first

- **The first install needs a programmer.** It is an inexpensive device that connects straight to the BIOS chip on the
  board. After that, updates will work from a USB stick. Details: the [install guide](docs/FLASHING.md).
- **Windows may ask to be activated again.** Keep your key or your Microsoft account login at hand.
  Details: [known issues](docs/KNOWN_ISSUES.md).
- **The board itself has limits** that no BIOS can fix: the memory voltage is always 1.2 V, and the board is built for
  processors up to 65 W. What that means: [board limits](docs/LIMITS.md).

## If something goes wrong

Describe what happened under **Issues** on GitHub and attach a report. How to make one: [this guide](docs/DIAGNOSTICS.md).

## Documents

- [Installing, updating and going back to Lenovo's BIOS](docs/FLASHING.md)
- [What the board can and cannot do](docs/LIMITS.md)
- [Known issues](docs/KNOWN_ISSUES.md)
- [How to report a problem](docs/DIAGNOSTICS.md)
- [Version history](CHANGELOG.md)

## For the curious

Board AM4P2MS with the AMD B350 chipset. The firmware is AMI Aptio V with AGESA ComboAM4v2PI 1.2.0.F from a Biostar
board with the same chipset, carrying this Lenovo board's own settings: PCIe lanes, power, fan, the Super I/O chip.
