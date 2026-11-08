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
- Компьютер включается и перезагружается без зависаний (проверили 100 раз подряд), засыпает и просыпается.
- Новое меню настроек — и мышью, и с клавиатуры. Меню «с чего загрузиться» по клавише F9.
- Монитор через HDMI, в том числе Full HD (1920×1080).
- USB: быстрые флешки и диски, клавиатура, мышь.
- Интернет по проводу.
- Обычные диски SSD и HDD (разъём SATA).
- Две планки памяти работают вместе, в быстром двухканальном режиме.
- Тихий вентилятор и автовключение, когда дали свет.
- Linux.

⚠️ **Есть, но ещё не проверили**
- Другие процессоры — всё, кроме Ryzen 3 2200G.
- Отдельная видеокарта и SSD в маленьком разъёме M.2.
- Четыре планки памяти и быстрый режим памяти XMP.
- Мониторы через DisplayPort и VGA.
- Звук: звуковую карту компьютер видит, но звук ещё не включали.
- Каждый USB-разъём по отдельности, спереди и сзади.
- Windows.
- Обновление BIOS с флешки и «Отчёт для диагностики» — появятся в T1.

❌ **Не работает**
- Поднять напряжение памяти — так устроена плата ([подробнее](docs/LIMITS.md)).
- Старые процессоры AMD A-серии (A6, A8, A10, A12).
- Разгон — в T1 выключен.

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

- Плата AM4P2MS на чипсете AMD B350. Основа прошивки — AMI Aptio V с AGESA ComboAM4v2PI 1.2.0.F от платы Biostar на том
  же чипсете. В неё перенесены настройки именно этой платы Lenovo: линии PCIe, питание, вентилятор, микросхема Super I/O.
- Проверенные скорости: USB 3.0 — 5 Гбит/с, сеть — 1 Гбит/с (около 940 Мбит/с на деле), SATA — 6 Гбит/с, память —
  DDR4-2667 в двух каналах.
- Загрузка по сети (PXE) есть только в режиме UEFI, на плате ещё не проверялась.
- DASH (удалённое управление через встроенную сетевую карту): по умолчанию выключено; проверена текстовая консоль BIOS
  по сети, настройки сети DASH в новом меню ещё проверяются.
- COM-порт система видит, обмен данными через него не проверялся.

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
- The computer powers on and restarts without hanging (tested 100 times in a row), sleeps and wakes up.
- The new settings menu, with a mouse or a keyboard. The "what to start from" menu on the F9 key.
- A monitor over HDMI, including Full HD (1920×1080).
- USB: fast USB sticks and drives, keyboard, mouse.
- Wired internet.
- Ordinary SSDs and hard drives (SATA).
- Two memory sticks working together in fast dual-channel mode.
- The quiet fan, and switching on when power comes back.
- Linux.

⚠️ **There, but not tested yet**
- Other processors — anything but the Ryzen 3 2200G.
- A graphics card, and SSDs in the small M.2 slot.
- Four memory sticks, and the XMP fast memory mode.
- Monitors over DisplayPort and VGA.
- Sound: the computer sees the sound card, but no sound has been played yet.
- Each USB socket on its own, front and back.
- Windows.
- Updating the BIOS from a USB stick and the "Diagnostics report" — coming in T1.

❌ **Does not work**
- Raising the memory voltage — that is how the board is built ([details](docs/LIMITS.md)).
- Old AMD A-series processors (A6, A8, A10, A12).
- Overclocking — off in T1.

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

- Board AM4P2MS with the AMD B350 chipset. The firmware is AMI Aptio V with AGESA ComboAM4v2PI 1.2.0.F from a Biostar
  board with the same chipset, carrying this Lenovo board's own settings: PCIe lanes, power, fan, the Super I/O chip.
- Measured speeds: USB 3.0 at 5 Gbit/s, network at 1 Gbit/s (about 940 Mbit/s in practice), SATA at 6 Gbit/s, memory
  at DDR4-2667 in dual channel.
- Network boot (PXE) is available in UEFI mode only and has not been tried on a board yet.
- DASH (remote management through the onboard network card): off by default; the text BIOS console over the network
  works, and the DASH network settings in the new menu are still being tested.
- The serial (COM) port is detected; sending data through it has not been tried.
