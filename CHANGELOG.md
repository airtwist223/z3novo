# История версий / Changelog

Новые версии сверху. T1, T2 и так далее — тестовые версии; 1.0 будет первой стабильной.
Newest first. T1, T2 and so on are test versions; 1.0 will be the first stable one.

## T2.2 — видеокарты, деление слота и чистая загрузка

В T2.2 вошло всё из T2.1. Главное — видеокарты: на Ryzen без встроенной графики видеокарта больше не пропадает перед
запуском системы, а процессоры со встроенной графикой с видеокартой больше не остаются без изображения и не
перезапускаются по кругу. Слот x16 можно делить для нескольких SSD. Надписи родного BIOS при включении больше не
появляются.

### Что нового

**Видеокарты**
- **На Ryzen без встроенной графики видеокарта больше не пропадает перед запуском системы.** На Ryzen 1000, 2000, 3000 и
  5000 без буквы G (например, 1500X, 2600, 3100, 3300X, 5600X) прошивка прямо перед запуском загрузчика выключала
  тактовый сигнал слота x16: так велела таблица, оставшаяся от процессоров A-серии. Видеокарта пропадала с шины, и на
  мониторе застывала заставка BIOS, хотя Windows или Linux продолжали загружаться. Теперь сигнал слота включён всё время,
  как в родном BIOS Lenovo. Ошибка была во всех прежних версиях.
- **Встроенная графика рядом с видеокартой больше не ломает запуск** (Ryzen 2000G–5000G, Athlon). Если в слоте есть
  видеокарта, а «Две видеокарты сразу» выключены, прошивка AMD сама выключает встроенную графику: ставит отметку в CMOS,
  забирает у неё память и один раз перезапускает компьютер. T2.0 и T2.1 стирали эту отметку при каждом запуске, и части
  прошивки переставали понимать друг друга: изображения не было, Athlon перезапускался по кругу, а Ryzen 5 5600G
  переставал запускаться вовсе, даже без видеокарты, пока прошивку не записывали заново. Теперь отметку никто не стирает.
- **«Две видеокарты сразу» по умолчанию — «Авто»** (было «Выкл»). С видеокартой встроенная графика остаётся включённой: к
  ней можно подключить ещё один монитор. Цена — её память (512 МБ на Ryzen 4000G и 5000G, 2 ГБ на 2000G и 3000G при 8 ГБ
  памяти и больше) и немного энергии. «Выкл» выключает встроенную графику и возвращает её память системе. Без видеокарты
  и на процессорах без встроенной графики настройка ни на что не влияет.
- **Окно сохранения не даст молча остаться без изображения.** Если в слоте есть видеокарта, а выбраны «Основная
  видеокарта: Встроенная», «Встроенная графика: Авто» и «Две видеокарты сразу: Выкл», после перезапуска изображения не
  будет: встроенную графику выключит AMD. Теперь окно сохранения об этом предупреждает и просит подтвердить «Я понимаю
  риск».
- **«Поддержка старых систем» (CSM) по умолчанию выключена, со страховкой.** Изображение при включении выводят
  UEFI-драйверы видеокарт. Так работают Resizable BAR, память для встроенной графики больше 2 ГБ и встроенная графика
  рядом с видеокартой в Windows (со старым режимом видео у неё бывает код 43). Если CSM выключен, а видеокарта без
  UEFI-драйвера не даёт изображения (так бывает у старых карт), прошивка сама включает CSM со старым режимом видео и один
  раз перезапускает компьютер; меню потом объясняет, что случилось. Если в «Какие системы загружать» стояло «Только
  старые», там станет «UEFI и старые», чтобы Windows и Linux в режиме UEFI продолжали загружаться. Второго перезапуска
  подряд не бывает.
- **Где действуют новые заводские значения** («Две видеокарты сразу» — «Авто», CSM — выкл): F6 «Сбросить всё»,
  сброс CMOS и замена процессора (со следующего запуска) и первая установка программатором. **Обновление из меню ваши
  настройки не меняет.**
- **Windows или Linux, установленные в старом режиме (MBR), загружаются только с CSM.** Окна «Нет диска для загрузки» и
  «Система не загрузилась» теперь говорят об этом и где CSM включить: Классика → Загрузка → «Поддержка старых систем».

**Деление слота x16**
- **Новый пункт «Деление слота x16»** (Классика → Устройства, под «Скорость слотов PCIe»). Слот для видеокарты делится на
  независимые части — для переходника с несколькими SSD M.2 или видеокарты вместе с SSD:
  - Ryzen 4000G и 5000G — x8+x4+x4 (видеокарта x8 и два SSD по x4);
  - Ryzen 1000, 2000, 3000 и 5000 без встроенной графики — x4+x4+x4+x4;
  - Ryzen 2000G, 3000G и Athlon слот не делят: в слот выведено 8 линий (у Athlon — 4).

  x8+x8 нет ни для одного процессора. Чего ваш процессор не умеет, в меню закрыто и объяснено. Действует со следующего
  запуска, при сохранении меню просит подтвердить «Я понимаю риск». Вернуть — «x16», F6 или батарейка.
- **Части слота не теряют тактовый сигнал.** На Ryzen 4000G и 5000G при x8+x4+x4 первая часть (x8) может быть пустой:
  SSD в частях x4 остаются видны в системе. При x4+x4+x4+x4 сигнал включён всегда (см. первый пункт).

**Загрузка и заставка**
- **Надписи родного BIOS больше не появляются.** «No option to boot to», «System Configuration Changed» и «Memory OC
  fail» не мелькают перед нашими окнами, а 10 секунд ожидания после сброса CMOS и неудачной частоты памяти больше нет.
  Код в правом нижнем углу заставки больше не рисуется. Из прошивки убраны прошивальщик BIO-Flasher и экраны Biostar при
  включении. Наше меню загрузки (F9) сообщает прошивке о запуске системы так же, как родное меню, — этот сигнал теперь
  получают все её части.
- **Жёлтая строка под логотипом** вместо этих надписей: «Настройки BIOS сброшены на заводские (сброс CMOS)» или «Разгон
  памяти не прошёл — память работает на заводской частоте. Подробности — Del». Без пауз: загрузка идёт дальше, перед
  запуском системы строка стирается. Язык — как у меню.
- **Дата BIOS в Windows и Linux** (сведения о системе, `dmidecode`) — дата этой версии; раньше там всегда было
  08/31/2025.

**Меню**
- **F6 «Сбросить всё» — обычные несохранённые изменения.** После F6 заводские значения видны в строках и в счётчике
  изменений: их можно поправить и записать одним F10, а отменить — как любые правки (вернуть строку или «Выйти без
  сохранения»). Раньше после сброса сразу открывалось окно сохранения, и до записи ничего нельзя было поменять. Первое
  окно F6 говорит, какие заводские значения у Z3NOVO свои.
- **Окно сохранения без служебных строк.** После F6 и после возврата резервной копии в списке только пункты, которые есть
  в меню; скрытые настройки прошивки — одной фразой с их числом. F6 больше не трогает служебные поля, которые прошивка
  пишет сама при каждом запуске. Строки «Отметка о сбросе CMOS» больше нет: отметку снимает любое сохранение.
- **Окно «Обновить прошивку» на экране 800×600:** строки списка файлов больше не налезают друг на друга, длинный текст
  проверки прокручивается и не уходит под кнопки.
- Значения AMD «True/False» на вкладке «Другое» показываются как «Да/Нет»; длинные значения в окне сохранения не
  обрезаются; в «Резервных копиях» нет английских имён служебных данных.
- **Отчёт F11:** в строке «мощность ЦП» вместо «нет» печатались непонятные символы — исправлено.

**Вентиляторы**
- **Нет ложных «пинков» вентиляторам AUX.** Защита от остановки (с T2.1) принимала сбойное чтение оборотов за остановку
  вентилятора. У трёхпинового вентилятора на AUX2 такие чтения бывают пачками, поэтому выход FAN3 время от времени
  получал 2 секунды полных оборотов и каждый раз поднимался на 10 % до перезагрузки: за несколько часов вентиляторы
  AUX сами доходили с 25 % до полных оборотов. Теперь сбойное чтение просто пропускается; остановкой считается только настоящее
  «нет оборотов».
- **Кривые вентилятора процессора.** «Тихо» — 25 % до 40 °C и 30 % при 55 °C (было 25 % при 30 °C и 33 % при 50 °C):
  тише на Ryzen 4000G и 5000G, которые в простое теплее. «Авто» в простое тише: 36 % при 30 °C и 40 % при 50 °C (было 40
  и 48 %). С 60 °C обе кривые — как раньше.

**Как обновиться**
- С T2.1 — из меню с флешки, как обычно ([по шагам](docs/FLASHING.md#с-t21-на-t22)). С T2.0, T1.2 и T1.1r — тем же
  путём, но сначала уберите с флешки старые копии `Z3BACKUP` (как для T2.1). Настройки сохраняются.

### Ограничения
- Деление слота — только то, что описано выше; x8+x8 нет ни для одного процессора
  ([подробнее](docs/LIMITS.md#11-слот-x16-две-видеокарты-и-csm)).
- Встроенная графика рядом с видеокартой работает в Windows только с видео UEFI (CSM выключен, как по умолчанию в T2.2);
  со старым режимом видео у неё бывает код 43.
- После смены деления слота или процессора Windows может показать у встроенной графики код 43 — переустановите драйверы
  чипсета и видео AMD.
- Старая видеокарта без UEFI-драйвера вместе с процессором со встроенной графикой: страховка CSM не срабатывает
  (UEFI-драйвер есть у встроенной), и до загрузки системы на мониторе видеокарты пусто. Включите CSM сами или подключите
  монитор к плате.
- [Известные проблемы](docs/KNOWN_ISSUES.md).

## T2.2 — graphics cards, slot bifurcation and a clean start

T2.2 has everything from T2.1. The main thing is graphics cards: on Ryzen processors without built-in graphics the card no
longer drops off before the system starts, and processors with built-in graphics no longer end up with no picture or
restart in a loop when a card is in. The x16 slot can be split for several SSDs. The stock BIOS messages no longer show
at power-on.

### What is new

**Graphics cards**
- **On Ryzen processors without built-in graphics the card no longer drops off before the system starts.** On the Ryzen
  1000, 2000, 3000 and 5000 without the G (for example the 1500X, 2600, 3100, 3300X, 5600X) the firmware switched the x16
  slot's reference clock off right before starting the boot loader: a table left over from the A-series processors said
  so. The card dropped off the bus, and the BIOS splash froze on the monitor although Windows or Linux went on loading.
  Now the slot's clock stays on all the time, as in Lenovo's own BIOS. The bug was in every earlier version.
- **Built-in graphics next to a card no longer break the start** (Ryzen 2000G–5000G, Athlon). With a card in the slot and
  "Both graphics at once" off, AMD's firmware turns the built-in graphics off by itself: it puts a mark in CMOS, takes
  their memory away and restarts the computer once. T2.0 and T2.1 erased that mark at every start, and the parts of the
  firmware stopped agreeing with each other: there was no picture, an Athlon restarted in a loop, and a Ryzen 5 5600G
  stopped starting at all, even without the card, until the firmware was written again. Now nothing erases the mark.
- **"Both graphics at once" is Auto by default** (it was Off). With a card the built-in graphics stay on: you can plug
  one more monitor into them. The price is their memory (512 MB on the Ryzen 4000G and 5000G, 2 GB on the 2000G and 3000G
  with 8 GB of memory or more) and a little power. Off turns the built-in graphics off and gives their memory back to the
  system. Without a card, and on processors without built-in graphics, the setting changes nothing.
- **The save window will not let you end up with no picture without a word.** With a card in the slot and "Primary
  graphics: Integrated", "Integrated graphics: Auto" and "Both graphics at once: Off" chosen, there will be no picture
  after the restart: AMD turns the built-in graphics off. Now the save window warns about it and asks you to confirm
  "I understand the risk".
- **Legacy system support (CSM) is off by default, with a safety net.** The picture at power-on comes from the cards'
  UEFI drivers. That is what Resizable BAR, more than 2 GB of memory for the built-in graphics and the built-in graphics
  next to a card in Windows need (with the legacy video mode they may show code 43). If CSM is off and a card without a
  UEFI driver gives no picture (old cards do that), the firmware turns CSM on by itself with the legacy video mode and
  restarts the computer once; the menu then explains what happened. If "Which systems to boot" was Legacy only, it
  becomes UEFI and legacy, so Windows and Linux in UEFI mode keep starting. There is never a second restart in a row.
- **Where the new factory values apply** ("Both graphics at once" Auto, CSM off): F6 "Reset all", clearing CMOS and
  changing the processor (from the next start), and the first install with a programmer. **Updating from the menu does
  not change your settings.**
- **Windows or Linux installed the old way (MBR) start only with CSM.** The "No disk to start from" and "The system did not
  start" windows now say so and where to turn CSM on: Classic → Boot → "Legacy system support".

**x16 slot bifurcation**
- **The new item "x16 slot bifurcation"** (Classic → Devices, under "PCIe slot speed"). The graphics slot is split into
  independent parts, for an adapter with several M.2 SSDs or a graphics card together with SSDs:
  - the Ryzen 4000G and 5000G: x8+x4+x4 (the card x8 and two SSDs x4 each);
  - the Ryzen 1000, 2000, 3000 and 5000 without built-in graphics: x4+x4+x4+x4;
  - the Ryzen 2000G, 3000G and Athlon do not split the slot: it has 8 lanes on them (4 on the Athlon).

  No processor has x8+x8. What your processor cannot do is locked in the menu with the reason. It applies from the next
  start, and saving asks you to confirm "I understand the risk". To undo: x16, F6 or the battery.
- **The parts of the slot keep their reference clock.** On the Ryzen 4000G and 5000G at x8+x4+x4 the first part (x8)
  may be empty: the SSDs in the x4 parts stay visible in the system. At x4+x4+x4+x4 the clock is always on (see the first
  item).

**Boot and boot screen**
- **The stock BIOS messages no longer show.** "No option to boot to", "System Configuration Changed" and "Memory OC fail"
  no longer flash up before our windows, and the 10-second wait after clearing CMOS or a failed memory speed is gone. The
  code in the bottom right corner of the boot screen is no longer drawn. The BIO-Flasher and Biostar's power-on screens
  are taken out of the firmware. Our boot menu (F9) tells the firmware a system is starting the same way the stock menu
  does, so every part of the firmware that waits for that signal now gets it.
- **A yellow line under the logo** instead of those messages: "BIOS settings reset to factory defaults (CMOS reset)" or
  "Memory overclock failed — memory runs at the stock speed. Details — Del". No pauses: the start goes on, and the line is
  wiped before the system starts. In the menu's language.
- **The BIOS date in Windows and Linux** (System Information, `dmidecode`) is this version's date; before, it was always
  08/31/2025.

**Menu**
- **F6 "Reset all" gives ordinary unsaved changes.** After F6 the factory values show in the rows and in the change
  counter: you can adjust them and write everything with one F10, or undo them like any changes (put a row back or "Leave
  without saving"). Before, the save window opened right after the reset, and nothing could be changed before writing. The
  first F6 window says which factory values are Z3NOVO's own.
- **No service rows in the save window.** After F6 and after restoring a backup, the list holds only items that are in the
  menu; the firmware's hidden settings go into one sentence with their number. F6 no longer touches the service fields the
  firmware writes itself at every start. The "CMOS reset mark" row is gone: any save clears the mark.
- **The "Update firmware" window on an 800×600 screen:** the lines of the file list no longer overlap, and a long check
  text scrolls instead of going under the buttons.
- AMD's "True/False" values on the Other tab show as Yes/No; long values in the save window are no longer cut; "Backups"
  shows no English names of service data.
- **The F11 report:** the «мощность ЦП» (CPU power) line printed garbled characters instead of «нет» (none) — fixed.

**Fans**
- **No false "kicks" to the AUX fans.** The stall guard (from T2.1) took a failed speed reading for a stopped fan. A 3-pin
  fan on AUX2 gives such readings in bursts, so the FAN3 output now and then got 2 seconds at full speed and was raised by
  10 % until a restart each time: over a few hours the AUX fans crept up from 25 % to full speed by themselves. Now a failed
  reading is just skipped; only a real "no speed" counts as a stop.
- **The processor fan's curves.** Quiet is 25 % up to 40 °C and 30 % at 55 °C (it was 25 % at 30 °C and 33 % at 50 °C):
  quieter on the Ryzen 4000G and 5000G, which run warmer at idle. Auto is quieter at idle: 36 % at 30 °C and 40 % at
  50 °C (it was 40 and 48 %). From 60 °C both curves are as before.

**How to update**
- From T2.1: from the menu with a USB stick, as usual ([step by step](docs/FLASHING.md#from-t21-to-t22)). From T2.0, T1.2
  and T1.1r: the same way, but first clear the old `Z3BACKUP` copies off the stick (as for T2.1). Settings are kept.

### Limits
- Slot bifurcation is only what is described above; no processor has x8+x8
  ([details](docs/LIMITS.md#11-the-x16-slot-two-graphics-and-csm)).
- The built-in graphics next to a card work in Windows only with UEFI video (CSM off, the T2.2 default); with the legacy
  video mode they may show code 43.
- After changing the slot bifurcation or the processor, Windows may show code 43 on the built-in graphics: reinstall the
  AMD chipset and graphics drivers.
- An old card without a UEFI driver together with a processor with built-in graphics: the CSM safety net does not fire
  (the built-in graphics have a UEFI driver), and the card's monitor stays blank until the system starts. Turn CSM on
  yourself or plug the monitor into the board.
- [Known issues](docs/KNOWN_ISSUES.md#known-issues).

## T2.1 — вентиляторы после сна и тише

В T2.1 вошло всё из T2.0. Главное — вентиляторы: после сна они снова регулируются сами, в простое тише, и у каждого
теперь свои настройки.

### Что нового

**Вентиляторы после сна**
- **После сна вентиляторы снова идут по температуре.** В T2.0 после пробуждения прошивка их больше не регулировала: они
  оставались на средних оборотах (около 56–60 %) до перезагрузки. Теперь через несколько секунд после пробуждения обороты
  снова следуют за температурой процессора; до обычных оборотов вентиляторы опускаются плавно, за полминуты–пару
  минут, пока процессор остывает.
- **Прошивка следит за своим таймером после сна.** Вентиляторы регулирует таймер, который срабатывает дважды в секунду.
  После пробуждения что-то в системе сбрасывает его настройки, хотя сам таймер продолжает идти; если бы его после этого
  запустили заново, он срабатывал бы около 2000 раз в секунду. Теперь прошивка всегда запускает таймер с полными
  настройками, а если заметит, что он срабатывает слишком часто, сама перезапускает его правильно.
- **Режим «Микросхемой» после сна и при включении** (Классика → Питание → «Управление вентилятором»). В этом режиме
  обороты ведёт сама микросхема платы по температуре процессора, которую она опрашивает. Теперь прошивка после сна и при
  каждом включении проверяет, что опрос действительно запустился. Если это не подтвердилось, вентиляторы, которые ведёт
  микросхема, идут на полных оборотах: громче, но не по застывшей температуре. Раньше после сна микросхема в этом
  режиме вела вентиляторы по температуре, застывшей на значении до сна.
- **Аварийная защита в режиме «Микросхемой» даёт настоящие полные обороты.** Если температура, по которой работает
  микросхема, расходится с температурой процессора больше чем на 20 °C, прошивка ставит вентиляторам полные обороты.
  Раньше вентилятор процессора в этом случае вставал примерно на 36–40 %, а корпусные не трогались.

**Вентиляторы тише**
- **«Тихо» вентилятора процессора тише в простое:** 25 % при 30 °C и 33 % при 50 °C (было 36 и 40 %); с 60 °C — как
  раньше. Штатный кулер Lenovo в простое крутится около 900 об/мин вместо примерно 1300. «Авто» не менялось.
- **Корпусные вентиляторы в простое тише:** «Тихо» — 20 %, «Авто» — 25 % (было 30 и 35 %); 25 % — столько стояло на
  SYS_FAN в T1.2. С нагревом процессора обороты растут, с 75 °C — как раньше, с 85 °C — полные.

**Настройки вентиляторов**
- **У каждого вентилятора свой режим и своя кривая.** «Вентилятор корпуса (FAN2)» и «Вентиляторы AUX1+AUX2 (FAN3)»
  получили четвёртый вариант «Своя»: открывается тот же редактор кривой, что у вентилятора процессора. Своя кривая
  вентилятора процессора, сохранённая раньше, работает как прежде; если вы рисовали её по старому «Тихо», сама она не
  изменится — чтобы получить новое «Тихо», выберите его заново.
- **«Минимум» у каждого вентилятора** (Классика → Питание → «Минимум FAN1 (процессор)», «Минимум FAN2 (корпус)»,
  «Минимум FAN3 (AUX1 + AUX2)»): от 0 до 100 %, по умолчанию 20 %. Медленнее этого прошивка вентилятор не крутит, что бы
  ни говорили режим или своя кривая; точки своей кривой ниже минимума редактор поднимает до него. Ниже 20 % можно, но не
  всякий вентилятор держит низкие обороты: штатный кулер Lenovo, например, и при 5 % крутится около 870 об/мин, а при 0 %
  вентилятор может остановиться. Действует со следующего запуска.
- **Защита от остановки.** Если вентилятор, обороты которого видит плата, остановился, хотя должен крутиться, прошивка
  примерно через 15–25 секунд даёт ему 2 секунды полных оборотов и до перезагрузки держит этот выход на 10 % выше.
  Короткие остановки на несколько секунд защиту не включают. Вентилятор, обороты которого плата не видит, так не
  защищён.

**Разъёмы вентиляторов**
- **Четвёртый разъём AUX2 виден.** На плате четыре разъёма вентиляторов — CPU_FAN, SYS_FAN, AUX1_FAN и AUX2_FAN, — а
  выходов, которыми управляет прошивка, три: AUX1 и AUX2 работают от одного выхода, FAN3, и регулируются вместе. Обороты
  вентилятора на AUX2 раньше нигде не показывались; теперь они видны в окне «Состояние» (дорожка «AUX2 · с FAN3»), на
  карточке вентилятора на главном экране и в отчёте F11. Строка FAN3 в «Питании» теперь называется «Вентиляторы
  AUX1+AUX2 (FAN3)»: её режим, своя кривая и минимум действуют на оба разъёма, защита от остановки следит за обоими.
- **Трёхпиновые вентиляторы на этой плате не регулируются ни на одном разъёме.** На разъёмах всегда 12 В, а обороты
  меняются только по отдельному проводу ШИМ у четырёхпиновых вентиляторов. Трёхпиновый всегда крутится на полных — так
  устроена плата, прошивка этого не изменит ([подробнее](docs/LIMITS.md#10-вентиляторы)). Справка в меню теперь об этом
  предупреждает.

**Окно «Состояние» и отчёт F11**
- **Окно «Состояние» показывает настоящую скважность вентилятора.** Раньше оно не учитывало встроенный нижний предел
  микросхемы 20 % у FAN1 и FAN3, и, например, настоящие 37,5 % показывались как «22 %». Теперь в строке вентилятора —
  настоящая скважность и его минимум («ШИМ 37 % · мин. 20 %»), в подробностях (F3) — включён ли предел микросхемы.
- **Отчёт F11:** новые строки «Скважность / duty» (настоящая скважность каждого выхода и предел микросхемы) и «Минимум /
  minimum», обороты AUX2 — в строках «Вентиляторы» и «Тахометры».

**Меню**
- **Второй курсор мыши больше не появляется.** Когда наше меню открывалось само — система не загрузилась, нет диска для
  загрузки, — поверх него двигалась ещё и белая стрелка родного меню BIOS, а наш курсор мог двигаться рывками: обе
  программы читали одну мышь. Теперь прошивка перед запуском нашего меню выключает чужую стрелку. При Del и F9 второго
  курсора не было и раньше.
- **Меню прошивки находит новый файл, даже если на флешке много старых копий.** Окно «Обновить прошивку» вмещало только
  24 файла и читало папку `\Z3NOVO` раньше корня флешки; копии `Z3BACKUP-….BIN`, которые меню сохраняет при каждом
  обновлении, со временем занимали весь список, и новый файл не показывался. Теперь в списке до 64 файлов: сначала файлы
  из корня флешки, потом из `\Z3NOVO`, копии `Z3BACKUP` — в конце, самые новые первыми; копия никогда не вытесняет образ.
  Если файлов больше, окно пишет «Показаны не все файлы: N из M».
- **В окне ввода числа PgUp и PgDn меняют значение на 10 шагов** (раньше они там ничего не делали) — во всех числовых
  пунктах.

**Коды устройств**
- **Встроенные устройства представляются как Lenovo.** У графики, USB-контроллеров процессора и чипсета, SATA чипсета,
  SMBus и LPC код платы в PCI (Subsystem) теперь 17AA:36C7 — как в родном BIOS Lenovo M715s, а не код Biostar
  1565:170B / 1565:370B. GPU-Z и диспетчер устройств показывают производителя Lenovo; звук и сетевая карта были Lenovo и
  раньше. При первом запуске Windows может заново найти эти устройства: экран мигнёт, разрешение может сброситься, может встать стандартный видеодрайвер (тогда переустановите драйвер AMD). Это
  один раз. Мосты PCIe не менялись: иначе Windows сочла бы сетевую карту новой и сбросила бы её настройки.

**Как обновиться**
- С T2.0, T1.2 или T1.1r — из меню с флешки, как обычно ([по шагам](docs/FLASHING.md#с-t20-на-t21)). Настройки
  сохраняются. **Перед обновлением** уберите с флешки старые копии: если в папке `\Z3NOVO` 24 и больше файлов `.BIN`,
  меню T2.0 и T1.x не увидит новый файл. Перенесите копии `Z3BACKUP-….BIN` из `\Z3NOVO` на компьютер или возьмите
  флешку без них.

### Ограничения
- Трёхпиновые вентиляторы на этой плате не регулируются ни на одном разъёме: всегда полные обороты
  ([подробнее](docs/LIMITS.md#10-вентиляторы)).
- AUX1_FAN и AUX2_FAN — один выход FAN3: по отдельности их не настроить.
- Защита от остановки работает только у вентиляторов, обороты которых видит плата; поднятый ею минимум держится до
  перезагрузки. В отчёте F11 её срабатывание видно только по тому, что скважность выше кривой и минимума.
- «Минимум» и свои кривые действуют со следующего запуска и только когда «Управление вентилятором» стоит «Прошивкой».
- [Известные проблемы](docs/KNOWN_ISSUES.md).

### Что проверено
На плате автора (AM4P2MS ревизии 1.1, Ryzen 3 2200G, две планки по 8 ГБ DDR4-2666) проверено:
- **сон и вентилятор после пробуждения:** два сна подряд — после каждого прошивка снова регулирует вентиляторы дважды
  в секунду, обороты как до сна (около 900 об/мин в простое); под нагрузкой после сна обороты растут вместе с
  температурой (2616 об/мин при 69 °C) и снова снижаются, когда нагрузка кончилась;
- **защита от сбоя таймера после сна:** таймер, нарочно запущенный после пробуждения с неверной настройкой (так он
  срабатывал бы около 2000 раз в секунду), прошивка меньше чем за секунду перезапустила правильно;
- **«Тихо» вентилятора процессора:** штатный кулер Lenovo в простое (29 °C) — 894 об/мин при 26 %; с прежней кривой было
  1298 об/мин при 35 °C;
- **разъёмы:** четырёхпиновый вентилятор на SYS_FAN слушается FAN2 (965 → 1573 об/мин на полных), на AUX1_FAN и
  AUX2_FAN — FAN3 (954 → 1537 и 945 → 1510 об/мин); обороты AUX2 читаются отдельно;
- **трёхпиновые вентиляторы:** на CPU_FAN 1123–1147 об/мин при любой скважности FAN1 и при любой из 8 частот ШИМ, на
  SYS_FAN 1121–1146 при любой скважности FAN2, на AUX2_FAN 1117–1140 при любой FAN3 — не регулируются;
- **защита от остановки:** четырёхпиновый вентилятор на AUX1 остановили рукой — через 16 секунд прошивка дала ему
  2 секунды полных оборотов и подняла выход с 25 до 35 %, при повторной остановке — ещё раз, до 45 %; остановки на 3 и
  8 секунд защиту не включили; трёхпиновый вентилятор на AUX2 ложных срабатываний не дал;
- **коды устройств:** Linux (lspci) показывает 17AA:36C7 у графики, обоих USB-контроллеров процессора, звука, SMBus,
  LPC, USB и SATA чипсета.

Тестеры проверили на T2.0 сон: с Ryzen 5 PRO 4650G работают сон и гибернация (в журнале запусков — удачные выходы из
сна), с Ryzen 5 5600G компьютер засыпает и просыпается от кнопки питания и клавиатуры. Исправление сна из T2.0
подтверждено на Ryzen 4000G и 5000G. На T2.1 тестеры с теми же процессорами подтвердили: вентилятор после сна сам
возвращается к кривой, корпусные вентиляторы идут по кривой, GPU-Z показывает Lenovo. Что тестеры проверили раньше — в [списке проверенного](docs/TESTED.md).

### Что ещё не проверено
- Второй курсор мыши, когда меню открывается само (исправление проверено в эмуляторе).
- Режим «Микросхемой».

## T2.1 — fans after sleep, and quieter

T2.1 has everything from T2.0. The main thing is the fans: after sleep they are controlled again by themselves, they are
quieter at idle, and each now has settings of its own.

### What is new

**Fans after sleep**
- **After sleep the fans follow the temperature again.** In T2.0, after waking up, the firmware no longer controlled them:
  they stayed at a medium speed (about 56–60 %) until a restart. Now, a few seconds after waking, the speed follows the
  processor's temperature again; the fans come down to their usual speed smoothly, within half a minute to a couple
  of minutes, as the processor cools.
- **The firmware watches its timer after sleep.** The fans are driven by a timer that fires twice a second. After a wake
  something in the system resets its settings while the timer itself keeps running; had it been started again after
  that, it would fire about 2000 times a second. Now the firmware always starts the timer with its full settings, and if
  it sees the timer firing too often, it restarts it correctly by itself.
- **"By the chip" mode after sleep and at power-on** (Classic → Power → "Fan control"). In this mode the board's chip runs
  the fans itself by the processor's temperature, which it polls. Now, after sleep and at every power-on, the firmware
  checks that the polling really started. If that is not confirmed, the fans the chip runs go to full speed: louder, but
  not following a frozen temperature. Before, after sleep the chip in this mode ran the fans by a temperature frozen at
  its value from before the sleep.
- **The emergency guard in "By the chip" mode gives real full speed.** If the temperature the chip works by differs from
  the processor's by more than 20 °C, the firmware sets the fans to full speed. Before, the processor fan ended up at
  about 36–40 % in that case, and the case fans were not touched.

**Quieter fans**
- **The processor fan's Quiet is quieter at idle:** 25 % at 30 °C and 33 % at 50 °C (it was 36 and 40 %); from 60 °C as
  before. Lenovo's stock cooler turns at about 900 rpm at idle instead of about 1300. Auto has not changed.
- **The case fans are quieter at idle:** Quiet is 20 %, Auto 25 % (it was 30 and 35 %); 25 % is what SYS_FAN ran at in
  T1.2. The speed rises as the processor heats; from 75 °C as before, from 85 °C full.

**Fan settings**
- **Each fan has a mode and a curve of its own.** "Case fan (FAN2)" and "Fans AUX1 + AUX2 (FAN3)" got the fourth choice,
  Custom: it opens the same curve editor as the processor fan's. A custom processor fan curve saved earlier works as
  before; if you drew it after the old Quiet, it does not change by itself — to get the new Quiet, pick Quiet again.
- **A "minimum" for each fan** (Classic → Power → "FAN1 minimum (CPU)", "FAN2 minimum (case)", "FAN3 minimum (AUX1 +
  AUX2)"): from 0 to 100 %, 20 % by default. The firmware never runs the fan slower than this, whatever the mode or your
  own curve says; the editor raises a custom curve's points under the minimum up to it. Under 20 % is allowed, but not
  every fan holds a low speed: Lenovo's stock cooler, for example, still turns at about 870 rpm at 5 %, and at 0 % a fan
  may stop. It applies from the next start.
- **Stall guard.** If a fan whose speed the board can see stops although it should be turning, the firmware gives it
  2 seconds at full speed after about 15–25 seconds and keeps that output 10 % higher until a restart. Short stops of a
  few seconds do not trigger it. A fan whose speed the board cannot see has no such guard.

**Fan headers**
- **The fourth header, AUX2, is visible.** The board has four fan headers — CPU_FAN, SYS_FAN, AUX1_FAN and AUX2_FAN — but
  three outputs the firmware controls: AUX1 and AUX2 run on one output, FAN3, and are controlled together. A fan on AUX2
  was shown nowhere before; now its speed is in the Health window (the "AUX2 · with FAN3" lane), on the fan card of the
  home screen and in the F11 report. FAN3's row in Power is now called "Fans AUX1 + AUX2 (FAN3)": its mode, custom curve
  and minimum apply to both headers, and the stall guard watches both.
- **3-pin fans are not controlled on any header of this board.** The headers always carry 12 V, and the speed changes only
  through the separate PWM wire of 4-pin fans. A 3-pin fan always runs at full speed — that is how the board is built,
  and no firmware can change it ([details](docs/LIMITS.md#10-fans)). The menu's help now says so.

**The Health window and the F11 report**
- **The Health window shows the fan's real duty.** Before, it did not take the chip's built-in 20 % floor on FAN1 and FAN3
  into account, so a real 37.5 %, for example, showed as "22 %". Now the fan's line shows the real duty and its minimum
  ("PWM 37 % · min. 20 %"), and the details (F3) show whether the chip's floor is on.
- **The F11 report:** new lines «Скважность / duty» (each output's real duty and the chip's floor) and «Минимум /
  minimum»; AUX2's speed is in the «Вентиляторы / fans» and «Тахометры / tach» lines.

**Menu**
- **No more second mouse pointer.** When our menu opened by itself — the system did not start, there was no disk to boot —
  the stock BIOS menu's white arrow moved over it too, and our pointer could move in jerks: both programs read the same
  mouse. Now the firmware turns the other arrow off before starting our menu. With Del and F9 there was no second pointer
  before either.
- **The firmware menu finds a new file even when the stick holds many old copies.** The "Update firmware" window held
  only 24 files and read the `\Z3NOVO` folder before the stick's root; the `Z3BACKUP-….BIN` copies the menu saves at every
  update filled the whole list over time, and a new file did not show. Now the list holds up to 64 files: first the files
  in the stick's root, then those in `\Z3NOVO`, the `Z3BACKUP` copies last, newest first; a copy never pushes an image
  out. When there are more files, the window says "Not all files are shown: N of M".
- **In the number entry window PgUp and PgDn change the value by 10 steps** (before, they did nothing there), for every
  number item.

**Device IDs**
- **The built-in devices present themselves as Lenovo's.** The graphics, the processor's and the chipset's USB
  controllers, the chipset's SATA, SMBus and LPC now carry the board ID (PCI Subsystem) 17AA:36C7, as in Lenovo's own
  M715s BIOS, instead of Biostar's 1565:170B / 1565:370B. GPU-Z and Device Manager show Lenovo as the maker; the sound
  and the network card were Lenovo's before too. At the first start Windows may find these devices anew: the screen
  blinks, the resolution may reset, Windows may put in its standard display driver (then reinstall AMD's driver). That happens once. The PCIe bridges were left as they were: otherwise Windows would
  take the network card for a new one and drop its settings.

**How to update**
- From T2.0, T1.2 or T1.1r: from the menu with a USB stick, as usual ([step by step](docs/FLASHING.md#from-t20-to-t21)).
  Settings are kept. **Before updating**, clear the old copies off the stick: with 24 or more `.BIN` files in the
  `\Z3NOVO` folder, the T2.0 and T1.x menu does not see the new file. Move the `Z3BACKUP-….BIN` copies from `\Z3NOVO` to a
  computer, or use a stick without them.

### Limits
- 3-pin fans are not controlled on any header of this board: always full speed
  ([details](docs/LIMITS.md#10-fans)).
- AUX1_FAN and AUX2_FAN are one output, FAN3: they cannot be set apart.
- The stall guard works only for fans whose speed the board can see; the minimum it raises holds until a restart. In the
  F11 report it shows only as a duty above the curve and the minimum.
- The minimums and custom curves apply from the next start, and only while "Fan control" is "By firmware".
- [Known issues](docs/KNOWN_ISSUES.md#known-issues).

### Tested
On the author's board (AM4P2MS revision 1.1, Ryzen 3 2200G, two 8 GB sticks of DDR4-2666):
- **sleep and the fan after waking:** two sleeps in a row — after each, the firmware controls the fans twice a second
  again, at the same speed as before sleep (about 900 rpm at idle); under load after sleep the speed rises with the
  temperature (2616 rpm at 69 °C) and goes down again when the load is over;
- **the timer guard after sleep:** a timer started on purpose with a wrong setting after waking (it would have fired about
  2000 times a second) was restarted correctly by the firmware in under a second;
- **the processor fan's Quiet:** Lenovo's stock cooler at idle (29 °C) turns at 894 rpm at 26 %; with the previous curve
  it was 1298 rpm at 35 °C;
- **the headers:** a 4-pin fan on SYS_FAN follows FAN2 (965 → 1573 rpm at full), on AUX1_FAN and AUX2_FAN it follows FAN3
  (954 → 1537 and 945 → 1510 rpm); AUX2's speed is read on its own;
- **3-pin fans:** on CPU_FAN 1123–1147 rpm at any FAN1 duty and any of the 8 PWM frequencies, on SYS_FAN 1121–1146 at any
  FAN2 duty, on AUX2_FAN 1117–1140 at any FAN3 duty — not controlled;
- **the stall guard:** a 4-pin fan on AUX1 was stopped by hand — after 16 seconds the firmware gave it 2 seconds at full
  speed and raised the output from 25 to 35 %, and when stopped again, once more, to 45 %; stops of 3 and 8 seconds did not
  trigger it; a 3-pin fan on AUX2 gave no false alarms;
- **the device IDs:** Linux (lspci) shows 17AA:36C7 on the graphics, both of the processor's USB controllers, the sound,
  SMBus, LPC and the chipset's USB and SATA.

Testers tried sleep on T2.0: with a Ryzen 5 PRO 4650G sleep and hibernation work (the boot log shows successful wakes
from sleep), with a Ryzen 5 5600G the computer goes to sleep and wakes up with the power button and the keyboard. The
T2.0 sleep fix is confirmed on the Ryzen 4000G and 5000G. On T2.1 testers with the same processors confirmed that the fan goes back to
its curve by itself after sleep, the case fans follow their curve and GPU-Z shows Lenovo. What testers checked earlier is in
[the tested list](docs/TESTED.md#what-has-been-tested).

### Not tested yet
- The second mouse pointer when the menu opens by itself (the fix was tested in an emulator).
- "By the chip" mode.

## T2.0 — вторая тестовая версия

В T2.0 вошло всё, что исправлено в T1.1r и T1.2, и много нового.

### Что нового

**Загрузка и заставка**
- **Новая заставка.** Логотип Z3NOVO меньше и стоит выше середины экрана: кружок загрузки Windows его больше не задевает.
  Подсказки «[Del] Настройки  [F9] Меню загрузки» — отдельной строкой у нижнего края, на языке меню; перед запуском
  Windows или Linux они стираются.
- **F6 и F12 на заставке больше не открывают прошивальщик Biostar** (BIO-Flasher): нажатие просто пропускается. Del и F9
  работают как раньше.
- **F9 запускает диск сразу.** Windows Boot Manager и другие диски стартуют из меню загрузки без лишней перезагрузки, как
  флешки.
- **Родное меню Biostar больше не появляется само.** Если система не загрузилась (нет диска, загрузчик не запустился),
  открывается наше меню с окном «Система не загрузилась» и кнопкой «Меню загрузки»; страница Biostar и её жёлтые часы не
  мелькают. Если наше меню вдруг не запустится, на экране будет короткая подсказка, и компьютер перезагрузится. Окна
  пароля BIOS, Secure Boot и TPM — как раньше.
- **Родное меню BIOS — только в сервисном режиме:** флешка с файлом `\Z3NOVO\SERVICE.TXT` (содержимое любое), затем F1 в
  нашем меню и последняя строка окна «Клавиши». Файл ищется только на USB-флешке. Программы в Windows и Linux тоже больше
  не могут открыть родное меню в обход этого.
- **Включение быстрее** на Ryzen 2000, 2000G и 3000G: прошивка читает свою микросхему в быстром режиме и не ждёт лишнего.
  Меню хранится в прошивке в сжатом виде и по Del открывается быстрее; освободилось место для нового.
- **Меню не открывается раньше, чем прошивка загрузила свои настройки.** Раньше при очень раннем нажатии Del вкладка
  «Питание» могла оказаться пустой.
- **Ryzen без встроенной графики и без видеокарты:** если загрузиться не с чего, плата больше не перезагружается по кругу
  (раньше наше меню пыталось открыться без экрана и через 30 секунд перезапускало компьютер). 8 коротких сигналов при
  включении без видеокарты — обычное «нет изображения».

**Меню**
- **Строка F-клавиш внизу экрана.** В «Классике»: F1 Клавиши, F2 Язык, F6 Сбросить всё, F7 EZ, F9 Загрузка, F11 Отчёт,
  F12 Снимок и справа F10 Сохранить; на главном экране — свои. Кнопки нажимаются мышью и с клавиатуры.
- **F1 — окно «Клавиши»:** все клавиши меню в одном окне; строку можно нажать мышью или Enter — она сделает то же, что
  клавиша. Внизу окна — QR-коды Telegram-бота [@z3novo_bot](https://t.me/z3novo_bot) и страницы проекта на GitHub.
- **F6 — «Сбросить всё на заводские»** (то же — Классика → Безопасность). Сначала окно скажет, что изменится и что нет,
  «Показать изменения» откроет список, а записывается всё только по «Сохранить и перезагрузить». Не меняются пароли,
  безопасная загрузка и её ключи, модуль TPM, порядок загрузки, язык и настройки самих устройств (например, DASH в
  сетевой карте). Передумали — «Назад», Esc или правая кнопка мыши: всё остаётся как было до F6, вместе с вашими
  несохранёнными изменениями.
- **F12 — снимок экрана на флешку** (`\Z3NOVO\SCREEN-дата-время.PNG`) на любом экране меню, в том числе в меню загрузки.
- **Backspace (или Delete) сбрасывает пункт** — то же, что кнопка «Сбросить» справа.
- **Окно «Состояние»** вместо прежней страницы: Классика → Питание → «Датчики и обороты» или щелчок по температуре
  вверху. Процессор и каждый вентилятор, у которого есть сигнал, — своя дорожка с числом и графиком за минуту; ниже —
  воздух на входе, батарейка CMOS, частота, память, версия BIOS и какие разъёмы вентиляторов пусты. Под оборотами — ШИМ.
  F3 в этом окне показывает подробности: напряжения и регистры. Всё помещается без прокрутки от 800×600 до 1920×1080.
- **Вкладка «Другое»** (была «Все»): настройки AMD CBS/PBS и страницы устройств (NVMe, SATA, сетевая карта, платы
  расширения) в том же виде, что остальные вкладки. Сырые страницы родного меню Biostar оттуда убраны — всё нужное из них
  есть на других вкладках. У пунктов AMD CBS — описания простыми словами; 37 пунктов, которые на этой плате только вредят
  или ничего не делают (тестовые режимы PCIe, отладка, режим для жидкого азота и подобные), убраны.
- **Esc на главном экране** открывает окно «Выйти?» с кнопками «Остаться» и «Загрузить».
- **Главный экран после ручного разгона** пишет у частоты «вручную» и показывает заданное значение, а не заводской буст.
- **Меню открывается в том виде, который выбран последним** — главный экран или «Классика».
- **F3 работает только в окне «Состояние».** Общего режима с техническими названиями больше нет.
- **Окно ввода числа говорит единицами пункта:** напряжение — в вольтах (раньше «0x18, 0x28…»), и «+» его повышает;
  обороты — в процентах, «Авто» — словом. Значение можно набрать: «1,3» или «1300» — это 1,300 В.
- **У рискованных пунктов — своё предупреждение**, что будет, если компьютер не запустится: откат после трёх неудачных
  запусков, возврат памяти на обычную скорость или как сбросить CMOS.
- **Перезагрузка, когда она нужна.** После включения «Защиты от неудачного разгона» или смены ключей Secure Boot меню
  предлагает «Перезагрузить», а не уходит сразу в систему.
- **Флешки exFAT читаются** (файл обновления, загрузка с флешки, программы UEFI). Только чтение: отчёт F11, снимок экрана
  и копию прошивки на exFAT не записать — меню так и скажет; для записи нужна флешка FAT32.
- **Платы расширения** со своими настройками (RAID-контроллеры, сетевые карты): их страницы во вкладке «Другое» работают
  через драйвер самой платы.

**Процессор и питание**
- **Разгон процессора с защитой:** своя частота и напряжение ядер на Ryzen 2000G, 3000G и 4000G, а на 2000G и 3000G — ещё
  и встроенной графики (Классика → Процессор). Открывается только после включения **«Защиты от неудачного разгона»**:
  если после разгона компьютер 3 раза подряд не дойдёт до загрузки системы, прошивка сама вернёт заводские значения.
  Пределы для разных процессоров — в [ограничениях платы](docs/LIMITS.md#6-разгон-процессора).
- **Разгон встроенной графики на Ryzen 4000G и 5000G:** от заводской частоты модели до 2400 МГц, напряжение 1,10–1,25 В.
  **Athlon 200GE–3150G** — разгон графики, как у Ryzen 2000G/3000G. Только при «Защите от неудачного разгона». Частота
  графики задаётся постоянной, как на других платах; прибавка в играх небольшая.
- **Curve Optimizer на Ryzen 5000 (5000G и 5000 без G):** снижение напряжения всех ядер на 1–30 ступеней; буст и пределы
  мощности остаются заводскими. Только при «Защите от неудачного разгона» и только если сама AMD даёт его этому
  процессору.
- «Защита от неудачного разгона» возвращает теперь и настройки AMD Overclocking (Curve Optimizer, ручные частоты AMD) и
  включается раньше в запуске.
- **Процессоры на 95–105 Вт** (2700X, 3900X, 5800X, 5950X и подобные) по умолчанию ограничены классом 65 Вт (88 Вт): на
  это рассчитана плата. Полную мощность можно включить на свой риск: Классика → Процессор → «Свои пределы мощности (PBO)».
  Меню показывает ограничение пометкой в «Классике» и строкой на главном экране.
- **«Свои пределы мощности (PBO)»** (для всех Ryzen): свои PPT/TDC/EDC, множитель PBO и прибавка буста до +200 МГц (где их
  поддерживает прошивка AMD). Включается только вместе с «Защитой от неудачного разгона»; при сохранении — предупреждение
  и галочка «Я понимаю риск»; три неудачных запуска подряд вернут заводские значения.
- **Предел температуры на Ryzen 3000 и 5000 без графики:** Классика → Процессор → «Предел температуры» (Авто, 85°, 80°,
  75°).
- **«Режим мощности» на 65-ваттных Ryzen 4000G и 5000G:** «Эко» (до 60 Вт) и «Обычный». «Повышенного» у них нет: 88 Вт —
  уже их заводской предел и предел платы.
- **Пределы тока — этой платы, а не платы-донора:** прошивка сообщает процессору числа Lenovo для M715s. На Ryzen 2000G
  и 3000G ток графики и контроллера памяти ограничен 40 А, как у Lenovo.
- **Напряжение графики на Ryzen 2000G и 3000G — не ниже 1,10 В:** от этой же линии питается контроллер памяти.
- **Точное управление частотой (CPPC) на Ryzen 4000G и 5000G теперь по умолчанию включено:** Windows и Linux (драйвер
  amd-pstate) сами быстро выбирают частоту каждого ядра. Пункт Классика → Процессор → «Точное управление частотой».

**Память**
- **Ручная частота и XMP без лишней перезагрузки** перед каждым запуском системы. Компьютер перезапускается сам один раз
  только сразу после сохранения новых настроек памяти или после обновления прошивки.
- **«Авто» с двумя разными планками** ставит частоту по более медленной (раньше — по последней найденной).
- **Задержки памяти снова видны.** На настоящей плате меню не узнавало их названий, и с T1 в Классика → Память были
  только «Подача команд», «Gear Down» и ODT. Теперь там все главные задержки и новая свёрнутая группа «Тонкие задержки»:
  ещё 24 задержки и сопротивление ODT процессора, с понятными названиями и пределами AMD. Своё значение — это разгон
  памяти: подбирайте его только с долгой проверкой памяти.
- **Ryzen 3000 без G, 4000G, 5000 и 5000G:** пункты «Контроллер памяти 1:1» и «Частота Infinity Fabric» (открываются
  только при своей скорости памяти).
- **Ryzen 4000G и 5000G: две настройки памяти — как у других плат с этими процессорами.** После обновления прошивки (в
  том числе с T1.x) первый запуск один раз заново обучит память — это несколько секунд.
- **«Память для графики» — своё число в гигабайтах.** На Ryzen 4000G и 5000G — от 1 ГБ до «вся память минус 3 ГБ», шаг
  1 ГБ; если системе остаётся меньше 8 ГБ, меню предупредит. На Ryzen 2000G и 3000G — от 512 МБ до 16 ГБ, кроме 3, 6 и
  12 ГБ. Больше 2 ГБ — только с выключенным CSM. Сохранённые раньше значения остаются как были.
- «Авто» больше не оставляет в списке изменений спрятанное значение (например, частоту памяти при «Режиме памяти: Авто»).

**Экран**
- **Второй разъём DisplayPort можно переключить в «HDMI»** (Классика → Устройства → «Второй разъём DisplayPort») — для
  пассивного переходника DP→HDMI: с ним доступна частота кадров до 144 Гц. Монитор DisplayPort в этом разъёме тогда
  ничего не покажет. На Ryzen 4000G и 5000G после переключения компьютер один раз перезапустится сам.

**Вентиляторы и датчики**
- **Все три вентилятора управляются.** Кроме вентилятора процессора прошивка ведёт по температуре процессора и
  вентиляторы на разъёмах FAN2 и FAN3: раньше они крутились на постоянных средних оборотах. В Классика → Питание у
  каждого свой режим «Тихо / Авто / Макс».
- **Вентилятор на старте спокойнее:** больше не поднимается до половины оборотов после логотипа, а на Ryzen 2000G, 3000G
  и Athlon не уходит на несколько секунд на полные.
- **«Импульсов за оборот» 2 или 4** для вентилятора процессора — если меню показывает обороты вдвое больше настоящих.
- **Напряжения в окне «Состояние» и в отчёте F11:** питание +3,3 В, дежурное +3,3 В и батарейка CMOS (ниже 2,7 В меню
  подскажет её заменить). +12 В и +5 В на этой плате не измеряются вовсе: эти входы микросхемы датчиков не подключены,
  поэтому AIDA64, HWiNFO и родной BIOS показывали там бессмыслицу — блок питания ни при чём
  ([подробнее](docs/DIAGNOSTICS.md#напряжения-aida64-и-hwinfo)).

**Имя компьютера**
- **Компьютер называется своим именем.** Windows, AIDA64 и другие программы видят его как Z3NOVO Labs ThinkCentre M715s
  Reborn (плата AM4P2MS Unlocked), а не Biostar X470GTA; в строке версии BIOS — Z3NOVO и номер версии. Серийный номер и
  модель конкретной машины прошивка не выдумывает: эти поля пустые. Программы Lenovo (Vantage, System Update) эту машину не
  узнают и ничего для неё не предлагают. Windows может один раз попросить подтвердить активацию
  ([что делать](docs/KNOWN_ISSUES.md)).

**Безопасность**
- **Пароль BIOS задаётся в нашем меню:** Классика → Безопасность → «Пароль на настройки» и «Пароль на включение», от 3 до
  20 знаков. Пароль спрашивается один раз. Забытый пароль снимает только сброс CMOS, а с ним сбрасываются все настройки.
- **«Очистить TPM»** (сначала сохраните ключ восстановления BitLocker) и под ним строка «Платформенная иерархия TPM» —
  обычно включена, трогать её не нужно.
- **«Ключи Secure Boot»:** записать ключи по умолчанию, включить и выключить безопасную загрузку, удалить все ключи.
  Включённая безопасная загрузка теперь сохраняется (раньше было окно «Сохранено не всё»). Как включать по шагам — в
  [DIAGNOSTICS.md](docs/DIAGNOSTICS.md#secure-boot-по-шагам).

**DASH**
- **Наше меню в консоли DASH:** Del или F9, нажатые в текстовой консоли DASH, открывают наше меню текстом (пункт «Консоль
  BIOS через DASH»). По-русски — если терминал в UTF-8, иначе по-английски. F5–F12 доходят и из обычных терминалов
  (telnet, xterm, PuTTY). Окна, которые есть только на экране (кривая вентилятора, обновление прошивки и подобные), в
  консоли не открываются.
- **DASH включает компьютер и после выдёргивания шнура.** Раньше после пропадания питания команда «включить» не доходила.
  Теперь, если DASH включён и «Автовключение» стоит «Не включаться», после возвращения питания компьютер сам включается
  на несколько секунд, готовит DASH и выключается; дальше «включить» по DASH работает. С «Включиться» он просто
  загружается, и DASH тоже готов.
- **DASH больше не замолкает до выдёргивания шнура:** если управляющий процессор сетевой карты перестал отвечать (бывало
  после удалённого сброса или зависания), прошивка при следующем включении перезапускает его.
- **Удалённое питание в Linux без параметра ядра:** когда DASH включён, прошивка сама прячет от Linux шину, по которой
  карта передаёт команды питания.

**Отчёт F11**
- **Куда отправить отчёт:** после F11 окно показывает QR-коды Telegram-бота @z3novo_bot и GitHub; адреса — и в начале
  файла отчёта.
- Новые строки: планка стоит, но не используется (на главном экране меню тогда тоже есть такая строка); память
  восстановлена из сохранённого или обучена заново; за сколько открылось меню; напряжения; обороты и выходы всех
  вентиляторов, сырые счёты тахометров и версия программы в микросхеме вентиляторов; что умеет защита от неудачного
  разгона. Выход из сна больше не отмечается как незавершённый запуск. Про флешку только для чтения отчёт пишет прямо, а
  не «флешка не найдена».

**Исправления**
- **Сон на Ryzen 4000G и 5000G.** Компьютер засыпал, но не просыпался: экран чёрный, лампочка горит, помогало только
  выдернуть шнур. При пробуждении процессор проверяет, что копия прошивки в памяти не изменилась, а прошивка писала в эту
  копию свои заметки. Теперь перед запуском системы и перед выходом из сна копия возвращается в исходный вид. **На таких
  процессорах это ещё не проверено** — просьба к тем, у кого такой процессор, — в [известных проблемах](docs/KNOWN_ISSUES.md).
- **Ryzen 2000G, 3000G и Athlon: обмен с микросхемой, которая ведёт вентиляторы, датчики и сторожевой таймер, больше не
  теряет данные.** Раньше терялось около 10 % обращений, теперь — ни одного из 20 000.
- **Встроенная графика больше не может выключиться сама после зависания при старте.** Журнал запусков мог записать в CMOS
  значение, которое прошивка AMD читает как «выключить встроенную графику»: на Ryzen с графикой и без видеокарты тогда не
  было изображения до 15 запусков подряд. Теперь журнал этот байт не трогает, а если такое значение там уже есть, прошивка
  его стирает.
- **Linux больше не пишет «irq 7: nobody cared»:** неиспользуемый контроллер GPIO снова скрыт, как у Lenovo.
- **Слот M.2:** тактовый сигнал накопителя NVMe теперь всегда включён, как в родном BIOS Lenovo.
- **Сохранение настроек:** если прошивка отказывается записать один пункт (например, «Безопасную загрузку»), остальные
  изменения всё равно записываются, а следующее сохранение не натыкается на ту же ошибку. Раньше после такого отказа
  каждое сохранение заканчивалось окном «Сохранено не всё», и часть изменений (вентиляторы, DASH) не записывалась.
- При экране 800×600 всплывающее сообщение в «Классике» больше не ложится на строки списка.
- Исправлена скрытая ошибка меню: при каждом запуске оно писало за пределы отведённой памяти. Проявлений не видели.

**Как обновиться**
- С T1.2 или T1.1r — из меню с флешки, как обычно ([по шагам](docs/FLASHING.md#с-t12-или-t11r-на-t20)). Настройки
  сохраняются. Первый запуск после обновления на несколько секунд дольше: прошивка заново обучает память. С T1.1 и T1 путь
  тот же, но его мы не проверяли.

### Ограничения
- Напряжение памяти всегда 1,2 В — так устроена плата ([подробнее](docs/LIMITS.md)).
- Своя частота ядер закрыта на Ryzen без встроенной графики, на Ryzen 5000 (вместо неё — Curve Optimizer) и на Athlon,
  кроме 3000G. Напряжение ядер задаётся как постоянное, без смещения: схема питания на плате смещений не умеет. Curve
  Optimizer — только общий для всех ядер и только в минус ([подробнее](docs/LIMITS.md#6-разгон-процессора)).
- «Защита от неудачного разгона» ловит только запуски, которые не дошли до системы, и возвращает заводские значения, а не
  последние удачные. Если после разгона сбоит уже Windows (например, в играх), нажмите Del при включении и верните «Авто».
- Разгон встроенной графики делает её частоту постоянной, и драйвер об этом не знает. На Ryzen 3 2200G автора уже при
  1200 МГц (1,200 В) компьютер зависал под нагрузкой на графику, а в Linux драйвер amdgpu после такого разгона сбоит.
  Такие сбои защита не ловит.
- «Подача команд» (Cmd2T) и «Gear Down» можно менять и при скорости памяти «Авто», но тогда встроенная защита AMD («Memory
  OC fail») их не прикрывает: если память с ними не заведётся, поможет только сброс CMOS.
- Когда DASH выключен, по сети компьютер не включить и не перезапустить. С DASH и «Автовключение: Как было» компьютер,
  который был выключен, когда пропало питание, по DASH не включится, пока его хоть раз не включат кнопкой или по сети
  (Wake-on-LAN).
- С включённой безопасной загрузкой не запускаются неподписанные флешки, в том числе тест-флешка.
- [Известные проблемы](docs/KNOWN_ISSUES.md).

### Что проверено
На плате автора (AM4P2MS ревизии 1.1, Ryzen 3 2200G, две планки по 8 ГБ DDR4-2666), на двух последних пробных сборках
(последняя отличается от T2.0 только номером версии):
- обновление из меню с предыдущей пробной сборки, возврат на неё из меню и снова вперёд;
- запуск, Windows и Linux, сон и пробуждение, вход в наше меню из Windows («Параметры встроенного ПО UEFI»);
- заставка: логотип, подсказки Del/F9 по-русски и по-английски, кружок загрузки Windows их не задевает, перед системой
  подсказки стираются; F6 и F12 на заставке ничего не открывают;
- F6 «Сбросить всё на заводские»: список изменений без настроек устройств, сброс с перезагрузкой (настройки DASH в
  сетевой карте целы), отмена кнопкой «Назад», Esc и правой кнопкой мыши;
- вкладка «Другое» и поиск, «Платформенная иерархия TPM», строка F-клавиш, окно F1 «Клавиши» и QR-коды (открывают бота и
  GitHub), сервисный режим (родное меню через `SERVICE.TXT`), снимки экрана F12, запоминание вида, Esc на главном экране,
  Backspace на пункте;
- окно «Состояние» (дорожки, ШИМ, подробности по F3) и отчёт F11 с QR-кодами;
- DASH: включение по сети после выключения и после выдёргивания шнура.

На плате автора, на более ранних пробных сборках T2 (на последних не повторяли):
- обновление из меню с T1.2;
- разгон ядер: 3900 МГц при 1,375 В — 10 минут под нагрузкой без ошибок (4000 МГц этот экземпляр не держит при любом
  напряжении); откат после трёх неудачных запусков сработал. С тех пор защиту доработали (Curve Optimizer, более ранний
  запуск) — в нынешнем виде на плате её ещё не проверяли;
- разгон графики 1200 МГц / 1,200 В применяется, но под нагрузкой на графику компьютер зависал;
- обмен с микросхемой IT8738: 0 ошибок на 20 000 обращений; ускоренное чтение микросхемы BIOS;
- новое имя компьютера (в Linux), нет строки «irq 7: nobody cared»;
- наше меню в консоли DASH: Del, F9, переходы по меню и изменение пунктов (сохранение из консоли не проверяли);
- «Память для графики» 11 ГБ при 16 ГБ памяти: Linux видит 11 ГБ видеопамяти.

Тестеры T2.0 ещё не проверяли; их проверки T1.2 — в [списке проверенного](docs/TESTED.md).

### Что ещё не проверено
- **Сон на Ryzen 4000G и 5000G с исправлением** — ждём от владельцев таких процессоров
  ([как помочь](docs/KNOWN_ISSUES.md)).
- Всё, что на Ryzen 3 2200G не проверить: разгон графики Ryzen 4000G/5000G и Athlon, разгон ядер Ryzen 4000G, Curve
  Optimizer, ограничение процессоров на 95–105 Вт и «Свои пределы мощности (PBO)», предел температуры, «Режим мощности» и
  CPPC на 4000G/5000G, «Контроллер памяти 1:1» и «Частота Infinity Fabric», настройки памяти 4000G/5000G, «Память для
  графики» больше 16 ГБ.
- Защита от неудачного разгона в нынешнем виде.
- Обновление с T1.2 и T1.1r на сам T2.0 и возврат с T2.0 на T1.2 — на плате (проверены только расчётом на компьютере);
  обновление с T1.1 и T1.
- F9 → запуск диска без перезагрузки, окно «Система не загрузилась», пароль BIOS, Secure Boot, очистка TPM.
- Вентиляторы FAN2 и FAN3 (на плате автора они не подключены), «Импульсов за оборот», вентилятор на старте.
- Задержки памяти в «Классике» и «Тонкие задержки», ручная частота и XMP без лишней перезагрузки, «Авто» с двумя разными
  планками.
- Второй DisplayPort в режиме HDMI, такт M.2 с накопителем NVMe, страницы плат расширения, флешки exFAT.
- Напряжения в «Состоянии» против мультиметра; активация Windows после смены имени компьютера.
- DASH: удалённое выключение и перезагрузка в Linux без параметра ядра, перезапуск замолчавшего DASH, сохранение
  настроек из консоли.
- Ryzen без встроенной графики без видеокарты (после исправления).

## T2.0 — second test version

T2.0 has everything fixed in T1.1r and T1.2, and a lot that is new.

### What is new

**Start-up and the boot screen**
- **A new boot screen.** The Z3NOVO logo is smaller and sits above the middle of the screen, so the Windows loading
  circle no longer touches it. The "[Del] Setup  [F9] Boot menu" hints are a line of their own near the bottom edge, in
  the menu's language; they are wiped before Windows or Linux starts.
- **F6 and F12 at the boot screen no longer open Biostar's flasher** (BIO-Flasher): the key is simply skipped. Del and F9
  work as before.
- **F9 starts a disk at once.** Windows Boot Manager and other disks start from the boot menu without an extra restart,
  just like USB sticks.
- **The stock Biostar menu no longer shows up by itself.** If the system did not start (no disk, or the boot loader did
  not run), our menu opens with a "The system did not start" window and a "Boot menu" button; the Biostar page and its
  yellow clock do not flash up. Should our menu ever fail to start, a short note appears and the computer restarts. The
  BIOS password, Secure Boot and TPM windows show as before.
- **The stock BIOS menu only in service mode:** a USB stick with the file `\Z3NOVO\SERVICE.TXT` (any content), then F1 in
  our menu and the last line of the Keys window. The file is looked for on USB sticks only. Programs in Windows and Linux
  can no longer open the stock menu around this either.
- **Faster power-on** on the Ryzen 2000, 2000G and 3000G: the firmware reads its chip in fast mode and no longer waits for
  nothing. The menu is stored compressed in the firmware and opens faster on Del; this freed room for new things.
- **The menu does not open before the firmware has loaded its settings.** Before, a very early Del could leave the Power
  tab empty.
- **A Ryzen without built-in graphics and no graphics card:** when there is nothing to boot, the board no longer restarts
  in a loop (before, our menu tried to open without a screen and restarted the computer after 30 seconds). Eight short
  beeps at power-on without a graphics card are the usual "no picture".

**Menu**
- **A line of F keys at the bottom.** In Classic: F1 Keys, F2 Language, F6 Reset all, F7 EZ, F9 Boot, F11 Report,
  F12 Screenshot and, on the right, F10 Save; the home screen has its own. The buttons work with the mouse and the
  keyboard.
- **F1 opens the Keys window:** every key of the menu in one window; a line clicked or Enter does what the key does. At
  the bottom of the window: QR codes for the Telegram bot [@z3novo_bot](https://t.me/z3novo_bot) and the project's GitHub
  page.
- **F6: "Reset all to factory"** (also Classic → Security). A window first says what changes and what stays, "Show the
  changes" opens the list, and nothing is written until "Save and restart". The passwords, Secure Boot and its keys, the
  TPM, the boot order, the language and the devices' own settings (DASH in the network card, for example) stay as they
  are. Changed your mind? "Back", Esc or a right click leaves everything as it was before F6, your own unsaved changes
  included.
- **F12 saves a screenshot to a USB stick** (`\Z3NOVO\SCREEN-date-time.PNG`) on any screen of the menu, the boot menu
  included.
- **Backspace (or Delete) resets an item**, the same as the "Reset" button on the right.
- **The Health window** replaces the old page: Classic → Power → "Sensors and fan speeds", or a click on the temperature
  at the top. The processor and every fan that gives a signal get a lane of their own with the number and a one-minute
  graph; below are the inlet air, the CMOS battery, the clock, the memory, the BIOS version and which fan headers are
  empty. Under the fan speed is the PWM. F3 in this window shows the details: voltages and registers. It all fits without
  scrolling from 800×600 to 1920×1080.
- **The "Other" tab** ("All" before): the AMD CBS/PBS settings and the devices' pages (NVMe, SATA, the network card,
  add-in cards) look the same as the other tabs. The raw pages of Biostar's stock menu are gone from it; everything needed
  from them is on the other tabs. AMD CBS items have plain-word descriptions; 37 items that only do harm or nothing on this
  board (PCIe test modes, debugging, a liquid-nitrogen mode and the like) are gone.
- **Esc on the home screen** opens a "Leave?" window with "Stay" and "Boot".
- **The home screen after a manual overclock** shows "manual" next to the clock and the value you set, not the factory
  boost.
- **The menu opens in the view chosen last**, the home screen or Classic.
- **F3 works only in the Health window.** The general mode with technical names is gone.
- **The number box speaks the item's units:** voltage in volts (it used to show "0x18, 0x28…"), and + raises it; fan
  speed in per cent, Auto as a word. You can type a value: "1.3" or "1300" means 1.300 V.
- **Risky items have a warning of their own** about what happens if the computer does not start: the rollback after three
  failed starts, memory going back to the normal speed, or how to clear CMOS.
- **A restart when one is needed.** After you turn on "Failed overclock protection" or change the Secure Boot keys, the
  menu offers "Restart" instead of going straight on to the system.
- **exFAT USB sticks can be read** (an update file, booting from a stick, UEFI programs). Read only: the F11 report, a
  screenshot and a firmware copy cannot be written to exFAT, and the menu says so; writing needs a FAT32 stick.
- **Add-in cards** with their own settings (RAID controllers, network cards): their pages on the "Other" tab work through
  the card's own driver.

**Processor and power**
- **Processor overclocking with protection:** your own core clock and voltage on the Ryzen 2000G, 3000G and 4000G, and on
  the 2000G and 3000G the built-in graphics too (Classic → Processor). It opens only after you turn on **"Failed overclock
  protection"**: if after an overclock the computer fails to reach the system 3 times in a row, the firmware puts the
  factory values back by itself. Limits for each processor: [board limits](docs/LIMITS.md#6-processor-overclocking).
- **Built-in graphics overclocking on the Ryzen 4000G and 5000G:** from the model's own clock up to 2400 MHz, at
  1.10–1.25 V. **Athlon 200GE–3150G:** graphics overclocking as on the Ryzen 2000G/3000G. Only with Failed overclock
  protection on. The graphics clock is fixed, as on other boards; the gain in games is small.
- **Curve Optimizer on the Ryzen 5000 (5000G and 5000 without G):** lowers every core's voltage by 1–30 steps; the boost
  and the power limits stay as made. Only with Failed overclock protection on, and only where AMD itself offers it for the
  processor.
- Failed overclock protection now also puts AMD Overclocking settings back (Curve Optimizer, AMD's manual clocks) and
  starts earlier in the boot.
- **95–105 W processors** (2700X, 3900X, 5800X, 5950X and the like) are limited to the 65 W class (88 W) by default: that
  is what the board is built for. Full power can be turned on at your own risk: Classic → Processor → "Own power limits
  (PBO)". The menu shows the limit with a note in Classic and a line on the home screen.
- **"Own power limits (PBO)"** (every Ryzen): your own PPT/TDC/EDC, the PBO scalar and a boost override up to +200 MHz
  (where AMD's firmware supports them). It goes on only together with Failed overclock protection; saving warns and asks
  you to tick "I understand the risk"; three failed starts in a row bring the factory values back.
- **Temperature limit on the Ryzen 3000 and 5000 without graphics:** Classic → Processor → "Temperature limit" (Auto, 85°,
  80°, 75°).
- **Power mode on the 65 W Ryzen 4000G and 5000G:** Eco (up to 60 W) and Normal. They have no Boosted: 88 W is already
  their own limit and the board's.
- **Current limits of this board, not the donor's:** the firmware gives the processor Lenovo's numbers for the M715s. On
  the Ryzen 2000G and 3000G the current of the graphics and the memory controller is capped at 40 A, as Lenovo does.
- **Graphics voltage on the Ryzen 2000G and 3000G is now 1.10 V at the lowest:** the memory controller runs off the same
  line.
- **Fine clock control (CPPC) on the Ryzen 4000G and 5000G is now on by default:** Windows and Linux (the amd-pstate
  driver) pick each core's clock quickly themselves. The item: Classic → Processor → "Fine clock control".

**Memory**
- **Manual speed and XMP without the extra restart** before every start of the system. The computer restarts by itself
  once only right after you save new memory settings or after a firmware update.
- **Auto with two different sticks** sets the speed by the slower one (before, by the last one found).
- **The memory delays show again.** On the real board the menu did not recognise their names, and since T1 Classic →
  Memory had only the command rate, Gear Down and ODT. Now it has all the main delays and a new folded group, Fine delays:
  24 more delays and the processor's ODT resistance, with plain names and AMD's limits. A value of your own is a memory
  overclock: tune it only with a long memory test.
- **Ryzen 3000 without G, 4000G, 5000 and 5000G:** "Memory controller 1:1" and "Infinity Fabric clock" (they open only
  with a memory speed of your own).
- **Ryzen 4000G and 5000G: two memory settings as on other boards with these processors.** After the firmware update
  (from T1.x as well) the first start trains the memory once more; it takes a few seconds.
- **"Memory for graphics" is a number of your own, in gigabytes.** On the Ryzen 4000G and 5000G it goes from 1 GB up to
  all the memory less 3 GB, in steps of 1 GB; if the system is left with less than 8 GB, the menu warns you. On the Ryzen
  2000G and 3000G it is 512 MB to 16 GB, except 3, 6 and 12 GB. Over 2 GB needs CSM off. Values saved before stay as they
  were.
- Auto no longer leaves a hidden value in the list of changes (for example the memory speed with "Memory mode: Auto").

**Screen**
- **The second DisplayPort socket can be switched to "HDMI"** (Classic → Devices → "Second DisplayPort socket") for a
  passive DP→HDMI adapter: with it a refresh rate of up to 144 Hz is available. A DisplayPort monitor on that socket then
  shows nothing. On the Ryzen 4000G and 5000G the computer restarts once by itself after the switch.

**Fans and sensors**
- **All three fans are controlled.** Besides the processor fan, the firmware now drives the fans on the FAN2 and FAN3
  headers by the processor's temperature: before, they ran at a fixed medium speed. In Classic → Power each has its own
  Quiet / Auto / Max mode.
- **A calmer fan at start-up:** it no longer runs at half speed after the logo, and on the Ryzen 2000G, 3000G and Athlon it
  no longer goes to full speed for a few seconds.
- **"Pulses per revolution" 2 or 4** for the processor fan, if the menu shows twice the real speed.
- **Voltages in the Health window and in the F11 report:** the +3.3 V supply, the +3.3 V standby and the CMOS battery
  (below 2.7 V the menu suggests replacing it). +12 V and +5 V are not measured on this board at all: those inputs of the
  sensor chip are not connected, which is why AIDA64, HWiNFO and the stock BIOS showed nonsense there — the power supply
  is fine ([details](docs/DIAGNOSTICS.md#voltages-aida64-and-hwinfo)).

**Computer name**
- **The computer goes by its own name.** Windows, AIDA64 and other programs see it as a Z3NOVO Labs ThinkCentre M715s
  Reborn (board AM4P2MS Unlocked) instead of a Biostar X470GTA; the BIOS version line reads Z3NOVO and the version. The
  firmware does not make up a machine's serial number or model: those fields are blank. Lenovo's tools (Vantage, System
  Update) do not recognise the machine and offer nothing for it. Windows may ask once to confirm activation
  ([what to do](docs/KNOWN_ISSUES.md#known-issues)).

**Security**
- **The BIOS password is set in our menu:** Classic → Security → "Settings password" and "Power-on password", 3 to 20
  characters. The password is asked once. A forgotten password can only be removed by clearing CMOS, which resets all
  settings too.
- **"Clear the TPM"** (save your BitLocker recovery key first), with the "TPM platform hierarchy" line under it: it is
  normally on and needs no touching.
- **"Secure Boot keys":** install the default keys, turn Secure Boot on and off, delete all keys. Secure Boot turned on is
  now saved (before, a "Not everything was saved" window came up). Step by step:
  [DIAGNOSTICS.md](docs/DIAGNOSTICS.md#secure-boot-step-by-step).

**DASH**
- **Our menu in the DASH console:** Del or F9 pressed in the DASH text console opens our menu as text (the "BIOS console
  over DASH" item). It writes Russian when the terminal is set to UTF-8 and English otherwise. F5–F12 now get through from
  ordinary terminals too (telnet, xterm, PuTTY). Windows that only the screen has (the fan curve, the firmware update and
  the like) do not open in the console.
- **DASH turns the computer on after the power cord was out, too.** Before, after a power loss the "power on" command went
  nowhere. Now, with DASH on and Auto power-on at Stay off, the computer turns on by itself for a few seconds when power
  comes back, gets DASH ready and turns off again; after that "power on" over DASH works. With Turn on it simply boots, and
  DASH is ready as well.
- **DASH no longer goes silent until the power cord is pulled:** if the network card's management processor stops
  answering (seen after a remote reset or a hang), the firmware restarts it at the next power-on.
- **Remote power on Linux without the kernel parameter:** while DASH is on, the firmware hides from Linux the bus the card
  sends its power commands over.

**F11 report**
- **Where to send the report:** after F11 the window shows QR codes for the Telegram bot @z3novo_bot and GitHub; the
  addresses are at the top of the report file too.
- New lines: a stick in place but not in use (the menu's home screen then has such a line too); memory restored from the
  saved setup or trained anew; how long the menu took to open; voltages; the speeds and outputs of all fans, the raw
  tachometer counts and the version of the program in the fan chip; what the overclock protection covers. Waking from
  sleep is no longer marked as an unfinished start. A read-only stick is named as such instead of "no stick".

**Fixes**
- **Sleep on the Ryzen 4000G and 5000G.** The computer went to sleep but did not wake up: black screen, power light on,
  only pulling the plug helped. On waking the processor checks that the firmware's copy in memory has not changed, and the
  firmware wrote its notes into that copy. Now the copy is put back as it was before the system starts and before
  returning from sleep. **Not yet tested on these processors**; a request to their owners is in the
  [known issues](docs/KNOWN_ISSUES.md#known-issues).
- **Ryzen 2000G, 3000G and Athlon: talking to the chip that runs the fans, the sensors and the watchdog no longer loses
  data.** Before, about 10 % of the exchanges were lost; now none in 20,000.
- **The built-in graphics can no longer switch itself off after a start that hung.** The boot log could write into CMOS a
  value that AMD's firmware reads as "turn the built-in graphics off": on a Ryzen with graphics and no graphics card there
  was then no picture for up to 15 starts in a row. Now the log leaves that byte alone, and if that value is already
  there, the firmware clears it.
- **Linux no longer reports "irq 7: nobody cared":** the unused GPIO controller is hidden again, as Lenovo has it.
- **M.2 slot:** the NVMe drive's reference clock now stays on all the time, as in Lenovo's own BIOS.
- **Saving settings:** when the firmware refuses to write one item (Secure Boot, for example), the other changes are still
  written, and the next save does not run into the same error. Before, after such a refusal every save ended with "Not
  everything was saved", and some changes (fans, DASH) were never written.
- On an 800×600 screen a pop-up message in Classic no longer lands on the rows of the list.
- Fixed a hidden menu bug: every time the menu started it wrote past the memory set aside for it. No effects were seen.

**How to update**
- From T1.2 or T1.1r: from the menu with a USB stick, as usual ([step by step](docs/FLASHING.md#from-t12-or-t11r-to-t20)).
  Settings are kept. The first start after the update takes a few seconds longer: the firmware trains the memory anew.
  From T1.1 and T1 the way is the same, but we have not tested it.

### Limits
- The memory voltage is always 1.2 V, that is how the board is built ([details](docs/LIMITS.md)).
- A core clock of your own is locked on Ryzen without built-in graphics, on the Ryzen 5000 (they get Curve Optimizer
  instead) and on the Athlon except the 3000G. The core voltage is set as a fixed value with no offset: the board's power
  circuit cannot do offsets. Curve Optimizer is one value for all cores, and negative only
  ([details](docs/LIMITS.md#6-processor-overclocking)).
- Failed overclock protection only catches starts that did not reach the system, and it puts back the factory values, not
  the last good ones. If Windows itself fails after an overclock (in games, for example), press Del at power-on and set
  Auto again.
- A graphics overclock fixes the graphics clock, and the driver does not know it. On the author's Ryzen 3 2200G, already at
  1200 MHz (1.200 V) the computer froze under graphics load, and on Linux the amdgpu driver misbehaves after such an
  overclock. The protection does not catch such failures.
- Command rate (Cmd2T) and Gear Down can be changed with the memory speed on Auto too, but then AMD's built-in protection
  ("Memory OC fail") does not cover them: if the memory does not start with them, only clearing CMOS helps.
- With DASH off, the computer cannot be turned on or restarted over the network. With DASH on and Auto power-on at As it
  was, a computer that was off when the power went cannot be turned on over DASH until it has been turned on once with the
  button or over the network (Wake-on-LAN).
- With Secure Boot on, unsigned USB sticks do not start, the test stick among them.
- [Known issues](docs/KNOWN_ISSUES.md#known-issues).

### Tested
On the author's board (AM4P2MS revision 1.1, Ryzen 3 2200G, two 8 GB sticks of DDR4-2666), on the last two test builds
(the last one differs from T2.0 only in its version number):
- updating from the menu from the previous test build, going back to it from the menu and forward again;
- start-up, Windows and Linux, sleep and wake, opening our menu from Windows ("UEFI Firmware Settings");
- the boot screen: the logo, the Del/F9 hints in Russian and English, the Windows loading circle does not touch them, the
  hints are wiped before the system; F6 and F12 at the boot screen open nothing;
- F6 "Reset all to factory": the list of changes without the devices' settings, the reset with a restart (the DASH
  settings in the network card intact), cancelling with "Back", Esc and a right click;
- the "Other" tab and search, "TPM platform hierarchy", the F-key line, the F1 Keys window and the QR codes (they open the
  bot and GitHub), service mode (the stock menu through `SERVICE.TXT`), F12 screenshots, the remembered view, Esc on the
  home screen, Backspace on an item;
- the Health window (lanes, PWM, details on F3) and the F11 report with QR codes;
- DASH: power-on over the network after a shutdown and after the power cord was out.

On the author's board, on earlier T2 test builds (not repeated on the last ones):
- updating from the menu from T1.2;
- core overclocking: 3900 MHz at 1.375 V for 10 minutes under load without errors (this sample does not hold 4000 MHz at
  any voltage); the rollback after three failed starts worked. The protection has been reworked since (Curve Optimizer, an
  earlier start), and in its current form it has not been tested on the board yet;
- a graphics overclock of 1200 MHz / 1.200 V is applied, but the computer froze under graphics load;
- talking to the IT8738 chip: 0 errors in 20,000 exchanges; faster reading of the BIOS chip;
- the new computer name (on Linux), no "irq 7: nobody cared" line;
- our menu in the DASH console: Del, F9, moving through the menu and changing items (saving from the console not tested);
- "Memory for graphics" at 11 GB with 16 GB of memory: Linux sees 11 GB of video memory.

Testers have not tried T2.0 yet; what they checked on T1.2 is in [the tested list](docs/TESTED.md#what-has-been-tested).

### Not tested yet
- **Sleep on the Ryzen 4000G and 5000G with the fix**: we are waiting for owners of these processors
  ([how to help](docs/KNOWN_ISSUES.md#known-issues)).
- Everything that cannot be tried on a Ryzen 3 2200G: graphics overclocking on the Ryzen 4000G/5000G and Athlon, core
  overclocking on the Ryzen 4000G, Curve Optimizer, the limit on 95–105 W processors and "Own power limits (PBO)", the
  temperature limit, power mode and CPPC on the 4000G/5000G, "Memory controller 1:1" and "Infinity Fabric clock", the
  memory settings of the 4000G/5000G, "Memory for graphics" over 16 GB.
- Failed overclock protection in its current form.
- Updating from T1.2 and T1.1r to T2.0 itself and going back from T2.0 to T1.2, on the board (checked only by calculation
  on a computer); updating from T1.1 and T1.
- F9 → starting a disk without a restart, the "The system did not start" window, the BIOS password, Secure Boot, clearing
  the TPM.
- The FAN2 and FAN3 fans (not connected on the author's board), "Pulses per revolution", the fan at start-up.
- The memory delays in Classic and Fine delays, manual speed and XMP without the extra restart, Auto with two different
  sticks.
- The second DisplayPort socket in HDMI mode, the M.2 clock with an NVMe drive, add-in card pages, exFAT sticks.
- The Health window's voltages against a multimeter; Windows activation after the name change.
- DASH: remote power-off and restart on Linux without the kernel parameter, restarting a DASH that went silent, saving
  settings from the console.
- A Ryzen without built-in graphics and no graphics card (after the fix).

## T1.2 — служебные байты CMOS

- **Прошивка больше не верит мусору в памяти CMOS.** Память CMOS (та, что держится на батарейке) хранит и служебные
  байты нашей прошивки: журнал запусков, отметки для отчёта F11 и несколько тестовых команд для разработки. Если плата
  пришла с остатками другой прошивки, случайное значение могло совпасть с такой командой. На одной плате из-за этого
  при каждом включении было три перезапуска подряд, а передние USB и два задних под сетевым разъёмом не работали.
  Теперь прошивка помечает свои байты подписью и при первом запуске, если подписи нет, один раз их стирает.
- После установки журнал запусков в отчёте F11 начнётся заново — это нормально, один раз.
- Больше ничего не менялось: всё остальное как в T1.1r.
- Обновление с T1.1r, T1.1 или T1: из меню с флешки, как обычно ([как обновить](docs/FLASHING.md#обновление)).
  Настройки сохраняются.

## T1.2 — CMOS service bytes

- **The firmware no longer trusts leftovers in CMOS memory.** The battery-backed CMOS memory also holds our firmware's
  service bytes: the boot log, marks for the F11 report and a few test commands for development. When a board came with
  another firmware's leftovers, a random value could match such a command. On one board that meant three restarts in a
  row at every power-on, and the front USB sockets and the two rear ones under the network socket did not work. Now the
  firmware marks its bytes with a signature and, at the first start without one, clears them once.
- After installing, the boot log in the F11 report starts over — that is normal, once.
- Nothing else changed: everything else is as in T1.1r.
- Updating from T1.1r, T1.1 or T1: from the menu with a USB stick, as usual ([how to update](docs/FLASHING.md#updating)).
  Settings are kept.

## T1.1r — перезагрузка на Ryzen 4000G и 5000G

- **Перезагрузка теперь полная на всех процессорах, кроме Ryzen 2000G/3000G и Athlon 200GE/3000G.** В T1.1 она была
  «мягкой», как у Lenovo: процессор сбрасывался не полностью. Ryzen 4000G и 5000G к такому не готовы: на 5000G
  перезагрузка из Windows зависала, а на 4600G после неё Windows тормозила и показывала «Время работы» около 10675199
  дней. Теперь перезагрузка на них полная, как в BIOS Biostar. Для Ryzen 2000G/3000G и Athlon всё осталось как в T1.1.
- Больше ничего не менялось.
- Обновление с T1.1 или T1: из меню с флешки, как обычно ([как обновить](docs/FLASHING.md#обновление)). Настройки
  сохраняются.

## T1.1r — restarts on Ryzen 4000G and 5000G

- **A restart is now a full one on every processor except the Ryzen 2000G/3000G and Athlon 200GE/3000G.** In T1.1 it
  was a "soft" one, as Lenovo has it: the processor was not reset all the way. The Ryzen 4000G and 5000G are not made for
  that: on a 5000G a restart from Windows hung, and on a 4600G Windows slowed down after it and showed an uptime of about
  10675199 days. Now these processors get a full restart, as in Biostar's BIOS. On the Ryzen 2000G/3000G and Athlon
  nothing changed from T1.1.
- Nothing else changed.
- Updating from T1.1 or T1: from the menu with a USB stick, as usual ([how to update](docs/FLASHING.md#updating)).
  Settings are kept.

## T1.1 — исправления к T1

- **Windows снова загружается.** На T1 Windows падала при загрузке с синим экраном ACPI_BIOS_ERROR, а следующий старт
  зависал до выключения кнопкой. Причина — наша правка термозоны ACPI: прошивка превращала её в устройство без
  названия, а Windows такое не принимает. Теперь термозона остаётся термозоной, но не обращается к микросхеме датчиков и
  всегда показывает 0 °C (это заглушка, температуру процессора смотрите по датчику процессора).
- **Контроллер GPIO снова виден системе** (в T1 он был скрыт). В Linux при загрузке снова появляется безвредная строка
  `irq 7: nobody cared`.
- **Меню загрузки F9 запускает флешку сразу**, без перезагрузки, даже если у прошивки ещё нет для неё записи загрузки.
- **«Параметры встроенного ПО UEFI» в Windows** (и `systemctl reboot --firmware-setup` в Linux) открывают наше меню, а не
  родное меню BIOS.
- Обновление с T1: из меню с флешки, как обычно ([как обновить](docs/FLASHING.md#обновление)). Настройки сохраняются.

## T1.1 — fixes for T1

- **Windows boots again.** On T1 Windows stopped at boot with the blue screen ACPI_BIOS_ERROR, and the next start hung
  until the power button was held. The cause was our change to the ACPI thermal zone: the firmware turned it into a
  device with no name, which Windows does not accept. Now the thermal zone stays a thermal zone, but it no longer touches
  the sensor chip and always reads 0 °C (a placeholder; read the processor temperature from the processor's own sensor).
- **The GPIO controller is visible to the system again** (T1 hid it). Linux shows the harmless line
  `irq 7: nobody cared` at boot again.
- **The F9 boot menu starts a USB stick right away**, without a restart, even when the firmware has no boot entry for it
  yet.
- **"UEFI Firmware Settings" in Windows** (and `systemctl reboot --firmware-setup` on Linux) open our menu, not the stock
  BIOS menu.
- Updating from T1: from the menu with a USB stick, as usual ([how to update](docs/FLASHING.md#updating)). Settings are
  kept.

## T1 — первая тестовая версия

### Что нового по сравнению с родным BIOS Lenovo
- Можно ставить процессоры Ryzen вплоть до 5000-й серии (AMD AGESA 1.2.0.F).
- Новое меню настроек (клавиша Del): мышь, русский и английский, поиск, простой режим. Меню выбора загрузки (F9).
- **Обновление BIOS с флешки прямо из меню** (Классика → Безопасность → «Прошивка BIOS»). Ваши настройки, ключ Windows
  и данные TPM сохраняются; перед записью можно сохранить копию всей микросхемы на флешку.
  [Как обновить](docs/FLASHING.md#обновление).
- **Отчёт для диагностики** по клавише F11 — файл на флешке, который прикладывают к сообщению о проблеме.
- **Резервные копии настроек:** видно, на какой версии прошивки снята копия и что именно вернётся.
- Тихий вентилятор с плавными оборотами и своим графиком.
- **Разгон памяти:** частота до DDR4-3200 (Ryzen 1000, 2000, 2000G, 3000G) или до DDR4-3600 (Ryzen 3000, 4000G, 5000,
  5000G), основные задержки, XMP при одинаковых планках с профилем. Если память не заработает, компьютер сам запустится
  на обычной скорости, а меню предложит вернуть «Авто».
- **Режим мощности** для Ryzen 2200G, 2400G, 3200G и 3400G: «Эко» (35 Вт), «Обычный», «Повышенный» (до 88 Вт).
- **Resizable BAR** — один переключатель в меню.
- Включение после пропадания света, сон, включение по будильнику и по сети.
- Видеовыходы настроены как у Lenovo: оба разъёма DisplayPort работают как DisplayPort.
- Исправлены зависания при включении и перезагрузке с Ryzen 3 2200G.
- Загрузка по сети (UEFI).
- **DASH** — удалённое управление (по умолчанию выключено): веб-страница карты, текстовая консоль по сети, настройки сети
  DASH прямо в меню, удалённое включение, выключение и перезагрузка. В Linux для удалённого питания нужен параметр ядра
  `module_blacklist=i2c_piix4` ([подробнее](docs/KNOWN_ISSUES.md)).
- Скрипты для Windows и Linux, которые собирают отчёт о сбоях ([как пользоваться](tools/report/README.md)).

### Ограничения
- Напряжение памяти всегда 1,2 В — так устроена плата ([подробнее](docs/LIMITS.md)).
- Разгон процессора и графики (своя частота и напряжение) закрыт.
- Пароль BIOS пока задаётся только в родном меню (в нашем меню F1 → Security); установка из нашего меню — в следующей
  версии.
- [Известные проблемы](docs/KNOWN_ISSUES.md).

### Что проверено
На плате автора: AM4P2MS ревизии 1.1, Ryzen 3 2200G, две планки по 8 ГБ DDR4-2666.
- Первая установка программатором; обновление из меню туда и обратно с сохранением настроек; копия микросхемы перед
  записью.
- Серии перезагрузок без зависаний, сон и пробуждение по будильнику, включение по будильнику и по сети.
- Оба разъёма DisplayPort (кабель DP→HDMI), заставка и система.
- Отчёт F11, вентилятор под нагрузкой, сеть 1 Гбит/с, USB 3.0.
- DASH: веб-страница, консоль в обе стороны, адрес из меню, удалённые перезагрузка, выключение и включение.

### Что ещё не проверено
- Другие процессоры, четыре планки памяти, XMP, разгон памяти, режимы мощности под нагрузкой, Resizable BAR, видеокарта,
  M.2, Windows.

## T1 — first test version

### What is new compared with Lenovo's BIOS
- Ryzen processors up to the 5000 series can be fitted (AMD AGESA 1.2.0.F).
- A new settings menu (the Del key): mouse, English and Russian, search, a simple view. A boot menu (F9).
- **BIOS updates from a USB stick right from the menu** (Classic → Security → BIOS firmware). Your settings, Windows key
  and TPM data are kept; before writing, a copy of the whole chip can be saved to the stick.
  [How to update](docs/FLASHING.md#updating).
- **Diagnostics report** with the F11 key: a file on a USB stick to attach to a problem report.
- **Settings backups:** shows which firmware version a backup was taken on and exactly what will come back.
- A quiet fan with smooth speed changes and a curve of your own.
- **Memory overclocking:** speed up to DDR4-3200 (Ryzen 1000, 2000, 2000G, 3000G) or DDR4-3600 (Ryzen 3000, 4000G, 5000,
  5000G), the main timings, XMP when all sticks are identical and have a profile. If the memory does not start, the
  computer comes up at the normal speed by itself and the menu offers to go back to Auto.
- **Power mode** for the Ryzen 2200G, 2400G, 3200G and 3400G: Eco (35 W), Normal, Boosted (up to 88 W).
- **Resizable BAR** as a single switch in the menu.
- Power on after a power cut, sleep, power on by alarm and over the network.
- Video outputs set up as Lenovo has them: both DisplayPort sockets work as DisplayPort.
- Fixes for hangs at power-on and reboot with the Ryzen 3 2200G.
- Network boot (UEFI).
- **DASH** remote management (off by default): the card's web page, a text console over the network, DASH network
  settings right in the menu, remote power on, power off and restart. On Linux, remote power needs the kernel parameter
  `module_blacklist=i2c_piix4` ([details](docs/KNOWN_ISSUES.md)).
- Scripts for Windows and Linux that collect a crash report ([how to use them](tools/report/README.md)).

### Limits
- The memory voltage is always 1.2 V, that is how the board is built ([details](docs/LIMITS.md)).
- Processor and graphics overclocking (your own clock and voltage) is closed.
- The BIOS password can so far be set only in the stock menu (F1 → Security from our menu); setting it from our menu comes
  in the next version.
- [Known issues](docs/KNOWN_ISSUES.md).

### Tested
On the author's board: AM4P2MS revision 1.1, Ryzen 3 2200G, two 8 GB DDR4-2666 sticks.
- First install with a programmer; updating from the menu both ways with settings kept; a copy of the chip before writing.
- Series of reboots without hangs, sleep and wake by alarm, power on by alarm and over the network.
- Both DisplayPort sockets (DP→HDMI cable), the boot logo and the system.
- The F11 report, the fan under load, 1 Gbit/s network, USB 3.0.
- DASH: web page, console both ways, address from the menu, remote restart, power off and power on.

### Not tested yet
- Other processors, four memory sticks, XMP, memory overclocking, power modes under load, Resizable BAR, a graphics card,
  M.2, Windows.
