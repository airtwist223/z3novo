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
  *Пока проверено только с Ryzen 3 2200G.* Если у процессора нет встроенной графики (например, Ryzen 7 2700 или
  Ryzen 5 5600), понадобится отдельная видеокарта.
- **Удобное меню настроек** (клавиша Del): работает мышью, на русском и английском, есть поиск и простой режим.
- **Тихий вентилятор**: обороты меняются плавно, есть режимы «Тихо», «Авто», «Макс» и свой график.
- **Компьютер сам включается, когда дали свет**, если включить это в настройках.
- **Исправлены зависания** при включении и перезагрузке, которые бывали на этой плате.
- **Скоро, в T1:** обновление BIOS с флешки прямо из меню и кнопка «Отчёт для диагностики».

## Что работает, а что нет

Проверяли на плате с процессором Ryzen 3 2200G и двумя планками памяти по 8 ГБ.

✅ **Работает**
- **Включение и перезагрузка** — без зависаний, проверили 100 раз подряд.
- **Сон (S3)** — компьютер засыпает и просыпается; **пробуждение по таймеру (RTC)** тоже работает.
- **Новое меню настроек** — мышью и с клавиатуры. **Меню загрузки (F9)** — выбрать, с чего запуститься.
- **HDMI** — монитор, в том числе Full HD (1920×1080).
- **USB 3.0** — флешки и диски на полной скорости (5 Гбит/с); USB-клавиатура и мышь.
- **Сеть 1 Гбит/с** — интернет по проводу, на деле около 940 Мбит/с.
- **SATA 6 Гбит/с** — обычные SSD и жёсткие диски.
- **Память DDR4-2667 в двух каналах** — две планки работают вместе, так быстрее.
- **Вентилятор** — тихий, обороты меняются плавно.
- **Restore on AC Power Loss** — компьютер сам включается, когда дали свет.
- **TPM 2.0** — модуль безопасности, встроенный в процессор (нужен для Windows 11): Linux его видит.
- **DASH** — удалённое управление по сети, как Intel AMT: работает текстовый экран BIOS по сети.
- **Linux**.

⚠️ **Есть, но ещё не проверили**
- **Другие процессоры** — всё, кроме Ryzen 3 2200G.
- **Видеокарта в слоте PCIe x16** и **SSD M.2** — маленький SSD-модуль на плате.
- **Четыре планки памяти** и **XMP** — заводской быстрый режим памяти.
- **DisplayPort и VGA** — другие разъёмы для монитора.
- **Звук** — звуковую карту система видит, но звук ещё не включали.
- **COM-порт** — старый разъём для модемов, станков и подобного: система его видит, обмен данными не проверяли.
- **Каждый USB-разъём по отдельности** — передние и задние.
- **Wake-on-LAN** — включение компьютера по сети с другого компьютера.
- **Загрузка по сети (PXE)** — запуск системы с сервера по сети, только в режиме UEFI.
- **Настройки сети DASH в новом меню.**
- **Windows.**
- **Обновление BIOS с флешки** и **«Отчёт для диагностики»** — появятся в T1.

❌ **Не работает**
- **Изменение напряжения памяти** — всегда 1,2 В, так устроена плата ([подробнее](docs/LIMITS.md)).
- **Процессоры AMD A-серии** (A6, A8, A10, A12, Athlon X4 9xx) — эта прошивка их не поддерживает.
- **Разгон** — в T1 выключен.
- **Загрузка по сети в старом режиме (Legacy PXE)** — только в режиме UEFI.

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
  *So far only the Ryzen 3 2200G has been tested.* If the processor has no built-in graphics (for example the Ryzen 7
  2700 or Ryzen 5 5600), you will need a graphics card.
- **An easy settings menu** (the Del key): works with a mouse, in English and Russian, with search and a simple view.
- **A quiet fan**: its speed changes smoothly, with Quiet, Auto and Max modes and a curve of your own.
- **The computer switches itself on when power comes back**, if you turn that on in the settings.
- **Fixes for hangs** at power-on and reboot that used to happen on this board.
- **Coming in T1:** updating the BIOS from a USB stick right from the menu, and a "Diagnostics report" button.

## What works and what does not

Tested on a board with a Ryzen 3 2200G processor and two 8 GB memory sticks.

✅ **Works**
- **Power-on and restart** — no hangs, tested 100 times in a row.
- **Sleep (S3)** — the computer sleeps and wakes up; **waking on a timer (RTC)** works too.
- **The new settings menu** — with a mouse or a keyboard. **Boot menu (F9)** — choose what to start from.
- **HDMI** — a monitor, including Full HD (1920×1080).
- **USB 3.0** — USB sticks and drives at full speed (5 Gbit/s); USB keyboard and mouse.
- **1 Gbit/s network** — wired internet, about 940 Mbit/s in practice.
- **SATA 6 Gbit/s** — ordinary SSDs and hard drives.
- **Dual-channel DDR4-2667 memory** — two sticks working together, which is faster.
- **Fan** — quiet, its speed changes smoothly.
- **Restore on AC Power Loss** — the computer switches itself on when power comes back.
- **TPM 2.0** — the security module built into the processor (Windows 11 needs it): Linux sees it.
- **DASH** — remote management over the network, like Intel AMT: the text BIOS screen over the network works.
- **Linux.**

⚠️ **There, but not tested yet**
- **Other processors** — anything but the Ryzen 3 2200G.
- **A graphics card in the PCIe x16 slot** and **M.2 SSDs** — the small SSD modules that fit on the board.
- **Four memory sticks** and **XMP** — the factory fast mode of memory sticks.
- **DisplayPort and VGA** — the other monitor sockets.
- **Sound** — the system sees the sound card, but no sound has been played yet.
- **Serial (COM) port** — the old socket for modems, machines and the like: the system sees it, data has not been sent yet.
- **Each USB socket on its own** — front and back.
- **Wake-on-LAN** — switching the computer on over the network from another computer.
- **Network boot (PXE)** — starting a system from a server over the network, UEFI mode only.
- **DASH network settings in the new menu.**
- **Windows.**
- **Updating the BIOS from a USB stick** and the **"Diagnostics report"** — coming in T1.

❌ **Does not work**
- **Changing the memory voltage** — always 1.2 V, that is how the board is built ([details](docs/LIMITS.md)).
- **AMD A-series processors** (A6, A8, A10, A12, Athlon X4 9xx) — this firmware does not support them.
- **Overclocking** — off in T1.
- **Network boot in the old mode (Legacy PXE)** — UEFI mode only.

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

Board AM4P2MS with the AMD B350 chipset. The firmware is AMI Aptio V with AGESA ComboAM4v2PI 1.2.0.F from a Biostar board
with the same chipset, carrying this Lenovo board's own settings: PCIe lanes, power, fan, the Super I/O chip.
