# Что плата может и чего не может / What the board can and cannot do

Здесь то, что зависит от самой платы Lenovo M715s, а не от BIOS. Это не изменит ни Z3NOVO, ни любая другая прошивка.

## 1. Напряжение памяти всегда 1,2 В

Питание для планок памяти на этой плате сделано на одно напряжение — 1,2 В, стандартное для DDR4. Поменять его
программой нельзя: на плате просто нет такой возможности. Поэтому пункта «напряжение памяти» в меню нет.

Что это значит на практике:

- Многие «игровые» планки памяти рассчитаны на свою высокую частоту только при 1,35 В. На этой плате они на такой
  частоте, скорее всего, не заработают. Выход — поставить частоту вручную на ступень-две ниже, а задержки оставить
  на «Авто».
- Лучше всего подходят обычные планки без разгона, например DDR4-3200, которым хватает 1,2 В.

## 2. Как выставить частоту памяти

**XMP** — заводской «быстрый режим», записанный в самой планке. У обычных планок его нет, у «игровых» есть.

| Планки | Процессор | Что выставить |
|---|---|---|
| Обычные DDR4-2400 или 2666 | любой | «Авто» |
| Обычные DDR4-2933 или 3200 на 1,2 В | Ryzen 1000, 2000, 2000G, 3000G (например 2200G, 2700, 3200G) | **вручную 2933** — «Авто» даст только 2667 |
| Обычные DDR4-2933 или 3200 на 1,2 В | Ryzen 3000, 4000G, 5000, 5000G | «Авто» — даст до 3200 |
| «Игровые» с XMP на 1,2 В (обычно 2666, бывает 2933–3200) | любой | XMP |
| «Игровые» с XMP на 1,35 В (почти все 3000 и выше) | любой | вручную на ступень-две ниже профиля, задержки «Авто» |

- «Вручную» — в меню «Режим памяти» → «Вручную» и нужная частота; задержки оставить «Авто». Верхний предел в меню:
  DDR4-3200 для Ryzen 1000, 2000, 2000G и 3000G, DDR4-3600 для Ryzen 3000, 4000G, 5000 и 5000G. Основные задержки
  тоже можно задать вручную. При сохранении меню предупредит и попросит отметить «Я понимаю риск».
- У «игровых» планок обычная частота без XMP — часто 2133 или 2400. В режиме «Авто» они на ней и работают.
- XMP можно выбрать, только если все планки одинаковые и у них есть профиль. Если профилю нужно больше 1,2 В,
  меню предупредит.
- После замены планок сначала один раз включите компьютер с «Авто», и только потом выбирайте XMP или ручную частоту.
- Если с новой частотой память не заработала, компьютер после трёх неудачных попыток запустится сам на безопасных
  настройках и покажет надпись «Memory OC fail». Так он и будет работать на обычной скорости, пока вы не откроете
  меню (Del): оно само предложит вернуть «Авто» и объяснит, что случилось. Если компьютер завис и ничего не пишет,
  поможет только сброс настроек BIOS перемычкой или батарейкой (сбросятся все настройки).
- Четыре планки работают медленнее, чем две: обычно DDR4-1866–2133.

## 3. Питание процессора и охлаждение

Lenovo выпускала эту плату под процессоры с TDP до 65 Вт. Что на самом деле ограничивает и что можно изменить:

| Что | Можно ли улучшить | Что это значит |
|---|---|---|
| **Кулер** (штатный — на 65 Вт) | да, но с переделкой | Крепление у Lenovo своё: по чертежу отверстия на тех же местах, что у AM4 (54×90 мм), но пластиковых упоров AM4 нет, винты и задняя пластина свои. Обычный кулер AM4 может потребовать переделки крепления; это не проверено. В корпус SFF помещается кулер высотой примерно до 65–70 мм. Мощнее кулер — процессор дольше держит высокую частоту. |
| **Схема питания процессора на плате** (4+2 фазы, без радиаторов) | частично | Сами фазы не поменять, но охлаждение улучшить можно: наклеить небольшие радиаторы на силовые транзисторы (через термопрокладку и так, чтобы не замкнуть соседние детали) и дать обдув — например, кулер, который дует вниз на плату. Без этого под долгой нагрузкой выше ~90–100 Вт она сильно греется. |
| **Блок питания** (штатный — 180 или 210 Вт на весь компьютер) | да | Можно поставить мощнее. У платы свой разъём питания Lenovo, поэтому для обычного блока нужен переходник. Со штатным блоком и видеокартой запаса почти нет. |

Что из этого следует:

- **Процессоры до 65 Вт** (2200G, 2700, 3600, 5600, 5600G, 5700G и подобные) — работают без оговорок.
- **Процессоры на 95–105 Вт** (2700X, 3800X, 5800X, 5900X и подобные) — главный предел тут схема питания на плате:
  кулер и блок питания можно поменять, а её — только лучше охлаждать. Если ставите такой процессор: мощный блок питания,
  радиаторы на транзисторы схемы питания, обдув платы вокруг сокета, и следите за нагревом. Ограничить мощность
  процессора в меню T1 пока нельзя.
- **Режим мощности** (Классика → Процессор): «Эко» (35 Вт — тише и холоднее), «Обычный» и «Повышенный» (до 88 Вт).
  Есть только для Ryzen 2200G, 2400G, 3200G и 3400G; на других процессорах пункт закрыт и объясняет почему.
  На 2200G и 3200G «Повышенный» почти ничего не даёт: этим процессорам столько обычно не нужно.
- Разгон процессора и графики (своя частота и напряжение) в T1 закрыт.

## 4. Память для встроенной графики

Процессор со встроенной графикой отдаёт ей часть оперативной памяти.

- В режиме «Авто» это 2 ГБ на Ryzen 2000G/3000G (если памяти 8 ГБ и больше) и 512 МБ на Ryzen 4000G/5000G.
- В меню можно выбрать до 16 ГБ, но **больше 2 ГБ получится, только если выключен режим совместимости со старыми
  системами (CSM)**.
- **Не выбирайте «3G», если CSM включён:** компьютер может перестать запускаться, и сброс настроек это не исправит.
  Наше меню такого не даст, а в старом меню BIOS этот вариант остался.
- Обычно ставить много не нужно: Windows и Linux сами дают встроенной графике до половины памяти, когда ей это нужно.
  Большое значение помогает только программам, которые смотрят на «объём видеопамяти».

## 5. Процессоры

- Процессоры A-серии (A6, A8, A10, A12, Athlon X4 9xx) с этой прошивкой не работают.
- Процессорам без встроенной графики нужна видеокарта.

---

# What the board can and cannot do

These depend on the Lenovo M715s board itself, not on the BIOS. Neither Z3NOVO nor any other firmware can change them.

## 1. The memory voltage is always 1.2 V

The board powers the memory sticks at a single voltage, 1.2 V, the DDR4 standard. Software cannot change it: the board
simply has no way to. That is why there is no "memory voltage" item in the menu.

What this means in practice:

- Many "gaming" memory sticks reach their high speed only at 1.35 V. On this board they will most likely not run at that
  speed. Set the speed by hand one or two steps lower and leave the timings on Auto.
- Ordinary sticks without overclocking, such as DDR4-3200 ones that are happy at 1.2 V, suit this board best.

## 2. How to set the memory speed

**XMP** is a factory "fast mode" stored in the memory stick itself. Ordinary sticks do not have it; "gaming" sticks do.

| Sticks | Processor | What to set |
|---|---|---|
| Ordinary DDR4-2400 or 2666 | any | Auto |
| Ordinary DDR4-2933 or 3200 at 1.2 V | Ryzen 1000, 2000, 2000G, 3000G (for example 2200G, 2700, 3200G) | **2933 by hand** — Auto gives only 2667 |
| Ordinary DDR4-2933 or 3200 at 1.2 V | Ryzen 3000, 4000G, 5000, 5000G | Auto — gives up to 3200 |
| "Gaming" with XMP at 1.2 V (usually 2666, sometimes 2933–3200) | any | XMP |
| "Gaming" with XMP at 1.35 V (nearly all 3000 and up) | any | by hand, one or two steps below the profile, timings on Auto |

- "By hand" means: in the menu, Memory mode → Manual and the speed you want; leave the timings on Auto. The menu goes
  up to DDR4-3200 for Ryzen 1000, 2000, 2000G and 3000G and DDR4-3600 for Ryzen 3000, 4000G, 5000 and 5000G. The main
  timings can be set by hand too. When you save, the menu warns you and asks you to tick "I understand the risk".
- Without XMP, "gaming" sticks often run at an ordinary 2133 or 2400, and that is what they do on Auto.
- XMP can be chosen only when all sticks are identical and have a profile. If the profile needs more than 1.2 V, the menu
  warns you.
- After changing sticks, start the computer once on Auto before choosing XMP or a manual speed.
- If memory does not work at the new speed, after three failed attempts the computer starts by itself on safe settings
  and shows "Memory OC fail". It keeps running at the normal speed until you open the menu (Del), which then offers Auto
  by itself and explains what happened. If the computer hangs with nothing on screen, only resetting the BIOS
  settings with the jumper or the battery helps (it resets all settings).
- Four sticks run slower than two, usually DDR4-1866–2133.

## 3. Processor power and cooling

Lenovo made this board for processors with a TDP of up to 65 W. What actually sets the limit, and what can be changed:

| What | Can it be improved | What it means |
|---|---|---|
| **Cooler** (the stock one is for 65 W) | yes, with some rework | Lenovo uses its own mount: on the drawing the holes sit where AM4 has them (54×90 mm), but there are no AM4 plastic brackets, and the screws and backplate are Lenovo's. An ordinary AM4 cooler may need its mount reworked; this has not been tried. The SFF case fits a cooler only about 65–70 mm tall. A stronger cooler lets the processor hold a high speed for longer. |
| **Processor power circuit on the board** (4+2 phases, no heatsinks) | partly | The phases themselves cannot be changed, but their cooling can: stick small heatsinks on the power transistors (with a thermal pad, without shorting nearby parts) and add airflow, for example a cooler that blows down onto the board. Without that, long loads above about 90–100 W make it run very hot. |
| **Power supply** (the stock one is 180 or 210 W for the whole computer) | yes | A stronger one can be fitted. The board has Lenovo's own power socket, so an ordinary unit needs an adapter. With the stock unit and a graphics card there is almost no headroom. |

What follows from that:

- **Processors up to 65 W** (2200G, 2700, 3600, 5600, 5600G, 5700G and the like) work without caveats.
- **95–105 W processors** (2700X, 3800X, 5800X, 5900X and the like): the main limit here is the board's power circuit —
  the cooler and the power supply can be replaced, the circuit can only be cooled better. If you fit one: a strong power
  supply, heatsinks on the power circuit's transistors, airflow over the board around the socket, and watch the
  temperatures. The T1 menu cannot cap the processor's power yet.
- **Power mode** (Classic → Processor): Eco (35 W, quieter and cooler), Normal and Boosted (up to 88 W). Only for the
  Ryzen 2200G, 2400G, 3200G and 3400G; on other processors the item is closed and says why. On the 2200G and 3200G
  Boosted makes little difference: these processors rarely need that much.
- Processor and graphics overclocking (your own clock and voltage) is closed in T1.

## 4. Memory for built-in graphics

A processor with built-in graphics gives part of the main memory to it.

- On Auto that is 2 GB on Ryzen 2000G/3000G (with 8 GB of memory or more) and 512 MB on Ryzen 4000G/5000G.
- The menu goes up to 16 GB, but **more than 2 GB works only with the legacy compatibility mode (CSM) turned off**.
- **Do not choose "3G" with CSM on:** the computer may stop starting, and resetting the settings will not fix it. Our menu
  does not offer it; the old BIOS menu still does.
- Usually you do not need much: Windows and Linux give built-in graphics up to half of the memory when it needs it.
  A large value only helps programs that look at "video memory size".

## 5. Processors

- A-series processors (A6, A8, A10, A12, Athlon X4 9xx) do not work with this firmware.
- Processors without built-in graphics need a graphics card.
