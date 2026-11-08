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

## 2. Частота памяти и XMP

**XMP** — это заводской «быстрый режим», записанный в самой планке памяти.

- В режиме «Авто» память на Ryzen 2000 и процессорах со встроенной графикой работает не быстрее DDR4-2667 — даже если
  планка рассчитана на 3000 или 3200. Быстрее — только вручную или через XMP. С Ryzen 5000 «Авто» поднимается до 3200.
- У «игровых» планок (например, «DDR4-3000») высокая частота обычно записана только в профиле XMP, а их обычная частота —
  2133 или 2400. В режиме «Авто» они работают именно на ней.
- Вручную с Ryzen 3 2200G можно пробовать 2800 или 2933 с задержками «Авто».
- XMP в меню можно выбрать, только если все планки одинаковые и у них есть такой режим. Если режиму нужно больше
  1,2 В, меню предупредит.
- После замены планок сначала один раз включите компьютер с «Авто», и только потом выбирайте XMP.
- Если с новой частотой память не заработает, компьютер после трёх неудачных попыток запустится сам на безопасных
  настройках и покажет надпись «Memory OC fail». Тогда верните частоту на «Авто». Если компьютер завис и ничего не
  пишет — поможет только сброс настроек BIOS перемычкой или батарейкой (сбросятся все настройки).
- Четыре планки работают медленнее, чем две: обычно DDR4-1866–2133.

## 3. Плата рассчитана на процессоры до 65 Вт

Схема питания процессора без радиаторов, блок питания на 180–210 Вт, штатный кулер на 65 Вт.

- Разгон процессора в T1 выключен.
- Ryzen 7 2700 и похожие не разгоняйте и не включайте автоматический разгон (PBO): блок питания может не справиться,
  особенно вместе с видеокартой.
- Ryzen 5 5600: понижать напряжение (Curve Optimizer) можно, повышать пределы мощности — нет.

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

## 2. Memory speed and XMP

**XMP** is a factory "fast mode" stored in the memory stick itself.

- On Auto, memory on Ryzen 2000 and processors with built-in graphics runs no faster than DDR4-2667, even if the stick is
  rated for 3000 or 3200. Faster is manual or XMP only. With a Ryzen 5000, Auto goes up to 3200.
- "Gaming" sticks (for example "DDR4-3000") usually keep their high speed only in the XMP profile; their ordinary speed is
  2133 or 2400, and that is what they run at on Auto.
- By hand, a Ryzen 3 2200G can try 2800 or 2933 with timings on Auto.
- The menu lets you choose XMP only when all sticks are identical and have this mode. If the mode needs more than 1.2 V,
  the menu warns you.
- After changing sticks, start the computer once on Auto before choosing XMP.
- If memory does not work at the new speed, after three failed attempts the computer starts by itself on safe settings
  and shows "Memory OC fail". Then set the speed back to Auto. If the computer hangs with nothing on screen, only
  resetting the BIOS settings with the jumper or the battery helps (it resets all settings).
- Four sticks run slower than two, usually DDR4-1866–2133.

## 3. The board is built for processors up to 65 W

The processor power circuit has no heatsinks, the power supply is rated 180–210 W, and the stock cooler is built for 65 W.

- Processor overclocking is turned off in T1.
- Do not overclock a Ryzen 7 2700 or similar, and do not turn on automatic overclocking (PBO): the power supply may not
  cope, especially with a graphics card.
- Ryzen 5 5600: lowering the voltage (Curve Optimizer) is fine, raising the power limits is not.

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
