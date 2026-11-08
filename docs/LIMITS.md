# Ограничения железа / Hardware limits

Здесь собрано то, что задаёт сама плата Lenovo M715s, а не прошивка. Ни Z3NOVO, ни любая другая прошивка этого не изменит.

## 1. Напряжение памяти — всегда 1,2 В

Питание планок памяти делает отдельный регулятор возле слотов. На этой плате его напряжение задано резисторами ровно
на 1,2 В (стандарт DDR4), и провода, по которому BIOS мог бы им управлять, нет. В заводской прошивке Lenovo нет кода
для этого; пункты «DRAM Voltage» из прошивки-донора в приложении спрятаны, потому что на этой плате им нечем управлять.

Что из этого следует:

- **Профили XMP на 1,35 В** (почти все комплекты DDR4-3200 CL16 и все DDR4-3600) на своей частоте, скорее всего,
  не запустятся. Ставьте частоту вручную на шаг-два ниже профиля, задержки — «Авто».
- **Лучше всего подходят планки на 1,2 В:** стандартные JEDEC (например, DDR4-3200 CL22) или комплекты, у которых
  профиль XMP рассчитан на 1,2 В (обычно DDR4-2666 и часть DDR4-2933/3200).
- Напряжение контроллера памяти в самом процессоре (SoC) прошивка менять может, но питание планок оно не заменяет.

## 2. Частота памяти и XMP

- «Авто» на Ryzen 2000 и процессорах с графикой не поднимает частоту выше DDR4-2667. Выше — только вручную.
- XMP берёт из профиля **первой** планки только частоту и четыре основные задержки (tCL, tRCD, tRP, tRAS), остальное
  прошивка считает сама. Частота XMP — не выше DDR4-3200 на Ryzen 2000 и процессорах с графикой.
- Поэтому в приложении XMP можно выбрать, только если все планки одинаковые и профиль у них есть. Если профилю нужно
  больше 1,2 В, приложение предупредит.
- После замены планок сначала один запуск на «Авто», потом XMP: прошивка видит новый профиль со второго запуска.
- Если память с выбранной частотой не запустится, после трёх неудачных попыток плата стартует на запасных настройках
  и покажет «Memory OC fail». Выбор при этом остаётся — верните «Авто». Если плата зависла без сообщения, поможет
  только сброс CMOS (он сотрёт все настройки).
- Четыре планки (по две на канал) работают медленнее: обычно DDR4-1866–2133.

## 3. Питание и охлаждение — плата на 65 Вт

Питание процессора 4+2 фазы без радиаторов, блок питания 180–210 Вт, штатный кулер на 65 Вт.

- Разгон процессора в T1 закрыт.
- Ryzen 7 2700 и подобные не разгоняйте и не включайте PBO: первым кончится блок питания, особенно с видеокартой.
- Ryzen 5 5600: можно уменьшать напряжение (Curve Optimizer), не поднимая пределов мощности.

## 4. Память встроенной графики

- «Авто»: 2 ГБ на Ryzen 2000G/3000G при 8 ГБ памяти и больше; 512 МБ на Ryzen 4000G/5000G.
- В меню — до 16 ГБ. **Больше 2 ГБ получится только при загрузке UEFI с выключенным CSM.** С включённым CSM
  прошивка кладёт видеопамять ниже 4 ГБ, а там помещается максимум 2 ГБ.
- **Не выбирайте «3G» при включённом CSM**: по разбору кода плата может перестать запускаться, и сброс CMOS это
  не исправит (настройка хранится во флеше). Приложение этот вариант при CSM не даёт; в родном меню BIOS он есть.
- Windows и Linux сами дают встроенной графике до половины памяти как «общую», когда она нужна. Выделенную память
  система теряет совсем, поэтому большое значение нужно только программам, которые смотрят на «объём видеопамяти».

## 5. Процессоры

- AGESA этой прошивки не поддерживает процессоры A-серии (A6/A8/A10/A12, Athlon X4 9xx).
- Процессорам без встроенной графики нужна видеокарта.

---

# Hardware limits

These are set by the Lenovo M715s board itself, not by the firmware. Neither Z3NOVO nor any other firmware can change them.

## 1. Memory voltage is always 1.2 V

The memory sticks are powered by a separate regulator next to the slots. On this board its voltage is set by resistors to
exactly 1.2 V (the DDR4 standard), and there is no line the BIOS could use to control it. Lenovo's own firmware has no
code for it; the donor firmware's "DRAM Voltage" items are hidden in the app because on this board they control nothing.

What follows from that:

- **XMP profiles that need 1.35 V** (nearly all DDR4-3200 CL16 kits and all DDR4-3600) will most likely not start at
  their speed. Set the speed by hand one or two steps below the profile, with timings on Auto.
- **1.2 V sticks suit this board best:** standard JEDEC ones (for example DDR4-3200 CL22) or kits whose XMP profile is
  rated for 1.2 V (usually DDR4-2666 and some DDR4-2933/3200).
- The firmware can change the voltage of the memory controller inside the processor (SoC), but that does not replace
  the sticks' own supply.

## 2. Memory speed and XMP

- Auto does not go above DDR4-2667 on Ryzen 2000 and processors with graphics. Higher speeds are manual only.
- XMP takes only the speed and the four main timings (tCL, tRCD, tRP, tRAS) from the profile of the **first** stick;
  the firmware works out the rest. XMP speed is capped at DDR4-3200 on Ryzen 2000 and processors with graphics.
- So the app lets you choose XMP only when all sticks are identical and have a profile, and warns you when the profile
  needs more than 1.2 V.
- After changing sticks, start once on Auto, then choose XMP: the firmware sees a new profile from the second start.
- If memory does not start at the chosen speed, after three failed attempts the board starts on fallback settings and
  shows "Memory OC fail". The choice stays as it was, so set it back to Auto. If the board hangs with no message, only
  a CMOS clear helps (it erases all settings).
- Four sticks (two per channel) run slower, usually DDR4-1866–2133.

## 3. Power and cooling: a 65 W board

The processor power stage has 4+2 phases without heatsinks, the power supply is rated 180–210 W, and the stock cooler is
built for 65 W.

- Processor overclocking is locked in T1.
- Do not overclock a Ryzen 7 2700 or similar, and do not turn on PBO: the power supply runs out first, especially with a
  graphics card.
- Ryzen 5 5600: lowering voltage (Curve Optimizer) is fine without raising the power limits.

## 4. Integrated graphics memory

- Auto: 2 GB on Ryzen 2000G/3000G with 8 GB of memory or more; 512 MB on Ryzen 4000G/5000G.
- The menu goes up to 16 GB. **More than 2 GB works only when booting UEFI with CSM off.** With CSM on, the firmware
  puts graphics memory below 4 GB, where at most 2 GB fits.
- **Do not choose "3G" with CSM on**: by our reading of the code the board may stop starting, and a CMOS clear will not
  fix it (the setting is kept in flash). The app does not offer this with CSM on; the stock BIOS menu still does.
- Windows and Linux already give integrated graphics up to half of the memory as "shared" when it needs it. Dedicated
  memory is lost to the system entirely, so a large value only matters to programs that look at "video memory size".

## 5. Processors

- This firmware's AGESA does not support A-series processors (A6/A8/A10/A12, Athlon X4 9xx).
- Processors without integrated graphics need a graphics card.
