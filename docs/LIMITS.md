# Что плата может и чего не может / What the board can and cannot do

Здесь то, что зависит от самой платы Lenovo M715s, а не от BIOS. Это не изменит ни Z3NOVO, ни любая другая прошивка.
С раздела 6 — что из этого следует для разгона, датчиков, DASH и безопасной загрузки.

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
- **Задержки** (с T2.0 видны в Классика → Память, ещё 24 — в свёрнутой группе «Тонкие задержки»): «Авто» берёт их из
  планки. Своё значение — это разгон памяти: подбирайте его только с долгой проверкой памяти. Сопротивление ODT задаётся
  только вместе со своей скоростью памяти.
- **«Подача команд» (Cmd2T) и «Gear Down»** можно менять и при скорости памяти «Авто», но тогда встроенная защита AMD
  («Memory OC fail») их не прикрывает: если память с ними не заведётся, поможет только сброс CMOS (батарейка или
  перемычка). Меняйте их вместе со своей скоростью памяти («Вручную» или XMP) — тогда защита работает.
- На Ryzen 3000 без G, 4000G, 5000 и 5000G в Классика → Память есть ещё «Контроллер памяти 1:1» и «Частота Infinity
  Fabric» (с T2.0). Они открываются только при своей скорости памяти, а когда память возвращается на «Авто», тоже
  возвращаются на «Авто».

## 3. Питание процессора и охлаждение

Lenovo выпускала эту плату под процессоры с TDP до 65 Вт. Что на самом деле ограничивает и что можно изменить:

| Что | Можно ли улучшить | Что это значит |
|---|---|---|
| **Кулер** (штатный — на 65 Вт) | да, но с переделкой | Крепление у Lenovo своё: по чертежу отверстия на тех же местах, что у AM4 (54×90 мм), но пластиковых упоров AM4 нет, винты и задняя пластина свои. Обычный кулер AM4 может потребовать переделки крепления; это не проверено. В корпус SFF помещается кулер высотой примерно до 65–70 мм. Мощнее кулер — процессор дольше держит высокую частоту. |
| **Схема питания процессора на плате** (4+2 фазы, без радиаторов) | частично | Сами фазы не поменять, но охлаждение улучшить можно: наклеить небольшие радиаторы на силовые транзисторы (через термопрокладку и так, чтобы не замкнуть соседние детали) и дать обдув — например, кулер, который дует вниз на плату. Без этого под долгой нагрузкой выше ~90–100 Вт она сильно греется. |
| **Блок питания** (штатный — 180 или 210 Вт на весь компьютер) | да | Можно поставить мощнее. У платы свой разъём питания Lenovo, поэтому для обычного блока нужен переходник. Со штатным блоком и видеокартой запаса почти нет. |

Что из этого следует:

- **Процессоры до 65 Вт** (2200G, 2700, 3600, 5600, 5600G, 5700G и подобные) — работают без оговорок.
- **Процессоры на 95–105 Вт** (2700X, 3800X, 5800X, 5900X и подобные) с T2.0 по умолчанию работают в классе 65 Вт:
  прошивка ограничивает их до 88 Вт, 60 А и 90 А — на это рассчитана плата. Полную мощность можно включить: Классика →
  Процессор → «Свои пределы мощности (PBO)» (только вместе с «Защитой от неудачного разгона»). Это на ваш страх и риск:
  главный предел тут — схема питания на плате, без радиаторов и без датчика температуры; кулер и блок питания можно
  поменять, а её — только лучше охлаждать. Если включаете: мощный блок питания, радиаторы на транзисторы схемы питания,
  обдув платы вокруг сокета и предел температуры (например 75–80°). На Ryzen 1000 прошивка ограничивает только мощность
  (88 Вт), токи — нет. На этой плате такие процессоры не проверены.
- **«Свои пределы мощности (PBO)»** (тот же пункт, для всех Ryzen): свои PPT/TDC/EDC, множитель PBO и прибавка буста до
  +200 МГц (где их поддерживает прошивка AMD). При сохранении — предупреждение и галочка «Я понимаю риск». Три неудачных
  запуска подряд возвращают заводские значения и выключают пункт.
- **Предел температуры:** у Ryzen 3000 и 5000 без графики — Классика → Процессор → «Предел температуры» (Авто, 85°, 80°,
  75°); у Ryzen 2000G/3000G — пара пунктов AMD CBS. У Ryzen 1000/2000 без графики и 4000G/5000G его пока нет.
- **Режим мощности** (Классика → Процессор): для Ryzen 2200G, 2400G, 3200G и 3400G — «Эко» (35 Вт — тише и холоднее),
  «Обычный» и «Повышенный» (до 88 Вт); на 2200G и 3200G «Повышенный» почти ничего не даёт: этим процессорам столько
  обычно не нужно. С T2.0 и для 65-ваттных Ryzen 4000G и 5000G — «Эко» (до 60 Вт) и «Обычный». У моделей GE (35 Вт) и
  на других процессорах пункт закрыт и объясняет почему.
- **Пределы тока** с T2.0 — этой платы, а не платы-донора: прошивка сообщает процессору числа Lenovo для M715s. На
  Ryzen 2000G и 3000G ток встроенной графики и контроллера памяти ограничен 40 А, как у Lenovo.
- Программы в Windows и Linux, которые сами меняют пределы процессора (Ryzen Master и подобные), работают мимо прошивки.
- Разгон процессора и графики (своя частота и напряжение) — с T2.0, см. [раздел 6](#6-разгон-процессора).

## 4. Память для встроенной графики

Процессор со встроенной графикой отдаёт ей часть оперативной памяти.

- В режиме «Авто» это 2 ГБ на Ryzen 2000G/3000G (если памяти 8 ГБ и больше) и 512 МБ на Ryzen 4000G/5000G.
- С T2.0 размер задаётся своим числом («Память для графики»). На Ryzen 4000G и 5000G — от 1 ГБ до «вся память минус
  3 ГБ», шаг 1 ГБ (при 32 ГБ — до 29 ГБ); если системе остаётся меньше 8 ГБ, меню предупредит, что Windows будет
  тормозить. На Ryzen 2000G и 3000G — от 512 МБ до 16 ГБ, кроме 3, 6 и 12 ГБ.
- **Больше 2 ГБ получится, только если выключен режим совместимости со старыми системами (CSM).**
- На плате автора (Ryzen 3 2200G, 16 ГБ памяти) 11 ГБ работают: Linux видит 11 ГБ видеопамяти. Больше 16 ГБ и драйвер
  Windows с таким объёмом ещё никто не проверял.
- **Не выбирайте «3G», если CSM включён:** компьютер может перестать запускаться, и сброс настроек это не исправит.
  Наше меню такого не даст, а в старом меню BIOS этот вариант остался.
- Обычно ставить много не нужно: Windows и Linux сами дают встроенной графике до половины памяти, когда ей это нужно.
  Большое значение помогает только программам, которые смотрят на «объём видеопамяти».

## 5. Процессоры

- Процессоры A-серии (A6, A8, A10, A12, Athlon X4 9xx) с этой прошивкой не работают.
- Процессорам без встроенной графики нужна видеокарта. Без неё изображения нет (8 коротких сигналов при включении —
  обычное «нет изображения»); с T2.0 плата в этом случае хотя бы не перезагружается по кругу.

## 6. Разгон процессора

С версии T2.0 можно задать свою частоту и напряжение ядер, своё напряжение и частоту встроенной графики и Curve
Optimizer — что именно, зависит от процессора (таблица ниже). Всё это — Классика → Процессор.

**Сначала включите «Защиту от неудачного разгона»:** без неё эти строки закрыты. Защита включается сразу, а работает со
следующего запуска — меню само предложит перезагрузиться; потом снова нажмите Del и задайте разгон. Если после разгона
компьютер 3 раза подряд не дойдёт до загрузки системы, прошивка сама вернёт заводские значения разгона процессора и
графики (а также Curve Optimizer и «Своих пределов мощности»); другие настройки она не трогает. Каждый такой запуск
плата сама перезапускает через минуту, весь откат занимает около 4 минут. На плате автора откат проверен на ранней
пробной сборке T2; в нынешнем виде (с Curve Optimizer и более ранним запуском) — ещё нет.

**Чего защита не ловит.** Если система запускается, но падает или зависает под нагрузкой (например, в играх) или в
простое, откат не сработает. Тогда нажмите Del при включении и верните «Авто». Откат возвращает заводские значения, а не
последние удачные: удачный разгон после отката придётся задать заново.

**Напряжение ядер** задаётся как постоянное, а не как смещение: схема питания процессора на плате смещений не умеет.
С заданной частотой буст выключается: ядра работают на ней.

| Процессоры | Частота и напряжение ядер | Встроенная графика | Curve Optimizer |
|---|---|---|---|
| Ryzen 2000G (2200G, 2400G, их GE и PRO) | до 4000 МГц, до 1,40 В | 800–1600 МГц, 1,10–1,20 В | — |
| Ryzen 3000G (3200G, 3400G, их GE и PRO), Athlon 3000G | до 4200 МГц, до 1,40 В | 800–1600 МГц, 1,10–1,20 В | — |
| Athlon 200GE, 220GE, 240GE, 300GE, 320GE, 3050GE, 3150G | закрыто (множитель заблокирован AMD) | 800–1600 МГц, 1,10–1,20 В | — |
| Ryzen 4000G (4300G, 4600G, 4650G и подобные) | 3000–4200 МГц, до 1,20 В | от заводской частоты модели до 2400 МГц, 1,10–1,25 В | — |
| Ryzen 5000G (5600G, 5700G и подобные) | закрыто | от заводской частоты модели до 2400 МГц, 1,10–1,25 В | все ядра, −1…−30 |
| Ryzen 5000 без графики | закрыто | — | все ядра, −1…−30 |
| Ryzen 1000, 2000 и 3000 без графики | закрыто | — | — |

- Это пределы меню, а не обещание: каждый экземпляр процессора свой. Нижний предел частоты у каждой модели свой, меню
  само показывает пределы для вашего процессора. На плате автора Ryzen 3 2200G стабильно работал на 3900 МГц при
  1,375 В (10 минут под нагрузкой без ошибок), а на 4000 МГц зависал при любом напряжении.
- **Разгон встроенной графики** делает её частоту постоянной, и драйвер об этом не знает. На Ryzen 3 2200G автора частота
  1200 МГц (1,200 В) применилась, но под нагрузкой на графику компьютер зависал; возможно, сама графика этого экземпляра
  на такой частоте не тянет. В Linux драйвер amdgpu после такого разгона перестаёт договариваться с процессором (ошибки
  «Failed to send Message»); не включайте в Linux ручные режимы частот amdgpu. Поднимайте частоту по шагу и проверяйте
  под нагрузкой; если зависает — Del при включении и «Авто». То же предупреждение — в подсказке у этих пунктов в меню.
- Встроенная графика Ryzen 2000G/3000G и контроллер памяти питаются от одной линии. Прошивка держит её ток в пределе
  Lenovo для этой платы, 40 А, поэтому напряжение графики — от 1,10 до 1,20 В.
- **Curve Optimizer** (Ryzen 5000) — снижение напряжения всех ядер на 1–30 ступеней, только общий для всех ядер и только в
  минус; буст и пределы мощности остаются заводскими. Есть, только если сама AMD даёт его этому процессору. Слишком
  большой Curve Optimizer обычно даёт сбои уже в системе — в простое и при лёгкой работе; их защита не ловит: Del при
  включении и ближе к нулю.
- **Почему закрыто.** У Ryzen 5000 своя частота выключила бы буст и при допустимом на плате напряжении была бы медленнее
  заводской — поэтому у них Curve Optimizer. У Athlon, кроме 3000G, множитель заблокирован в самом процессоре. Ryzen без
  графики работают только с видеокартой, а штатный блок питания — 180–210 Вт, и схема питания рассчитана на 65 Вт.
- На этой плате проверен только разгон Ryzen 3 2200G. Разгон Ryzen 4000G и 5000G, Athlon и Curve Optimizer ещё никто не
  проверял.

## 7. Датчики напряжения

- **+12 В и +5 В на этой плате не измеряются вовсе.** Входы микросхемы датчиков (ITE IT8738), которые на других платах
  меряют +12 В, +5 В и напряжение процессора, здесь никуда не подключены. Поэтому AIDA64, HWiNFO, родной BIOS и другие
  программы показывают в этих строках случайные числа (например, «+12 В» = 7 или 17 В). Так было и с родным BIOS Lenovo.
  Блок питания здесь ни при чём, а исправить эти строки нельзя никаким множителем.
- Плата меряет три напряжения, все около 3 В: питание +3,3 В, дежурное +3,3 В и батарейку CMOS. С T2.0 они видны в окне
  «Состояние» (F3 — подробности) и в отчёте F11. Батарейка замеряется только при включении компьютера; если она ниже
  2,7 В, меню подскажет её заменить (CR2032).
- Пока компьютер включён в розетку, «Батарейка CMOS», возможно, показывает не саму батарейку, а дежурное питание за ней;
  это ещё не проверено. Сверить эти три напряжения с мультиметром тоже ещё не успели.
- Что скрыть в AIDA64 и HWiNFO — в [DIAGNOSTICS.md](DIAGNOSTICS.md#напряжения-aida64-и-hwinfo).

## 8. DASH

- **Когда DASH выключен** (так по умолчанию), по сети компьютер не включить и не перезапустить, даже если сетевая карта
  выключенного компьютера отвечает по сети: её прошивка запускает DASH сама, но команды питания не выполняются.
- **После пропадания питания** часть чипсета, которая принимает команду «включить» от сетевой карты, ждёт, пока её
  настроит прошивка, а прошивка работает только при включении. Поэтому с T2.0, если DASH включён, а «Автовключение»
  (Классика → Питание) стоит «Не включаться», компьютер после возвращения питания сам включается на несколько секунд,
  готовит DASH и выключается; дальше «включить» по DASH работает. С «Включиться» он просто загружается, и DASH тоже готов.
  С «Как было» компьютер, который был выключен, когда пропало питание, по DASH не включится, пока его хоть раз не включат
  кнопкой или по сети (Wake-on-LAN).

## 9. Безопасная загрузка (Secure Boot)

- С включённой безопасной загрузкой запускаются только подписанные загрузчики: Windows и большинство Linux (через shim)
  — да; неподписанные флешки — нет. Среди них и наша [тест-флешка](https://github.com/airtwist223/z3novo/releases/tag/TestStick-1.4):
  чтобы загрузиться с неё, сначала выключите безопасную загрузку.
- Без записанных ключей безопасная загрузка не действует, даже если переключатель стоит на «Вкл».
- Включение и выключение безопасной загрузки меняют измерения TPM: если в Windows включён BitLocker или «Шифрование
  устройства», заранее сохраните ключ восстановления. Порядок по шагам — в
  [DIAGNOSTICS.md](DIAGNOSTICS.md#secure-boot-по-шагам); на плате автора безопасная загрузка с T2.0 ещё не проверялась.

---

# What the board can and cannot do

These depend on the Lenovo M715s board itself, not on the BIOS. Neither Z3NOVO nor any other firmware can change them.
From section 6 on: what follows from them for overclocking, sensors, DASH and Secure Boot.

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
- **Delays** (from T2.0 shown in Classic → Memory, 24 more in the folded Fine delays group): Auto takes them from the
  stick. A value of your own is a memory overclock: tune it only with a long memory test. The ODT resistance can only be
  set together with a memory speed of your own.
- **Command rate (Cmd2T) and Gear Down** can be changed with the memory speed on Auto too, but then AMD's built-in
  protection ("Memory OC fail") does not cover them: if the memory does not start with them, only clearing CMOS (battery
  or jumper) helps. Change them together with a memory speed of your own (Manual or XMP): then the protection works.
- On the Ryzen 3000 without G, 4000G, 5000 and 5000G, Classic → Memory also has "Memory controller 1:1" and "Infinity
  Fabric clock" (from T2.0). They open only with a memory speed of your own, and when the memory goes back to Auto, they
  go back to Auto too.

## 3. Processor power and cooling

Lenovo made this board for processors with a TDP of up to 65 W. What actually sets the limit, and what can be changed:

| What | Can it be improved | What it means |
|---|---|---|
| **Cooler** (the stock one is for 65 W) | yes, with some rework | Lenovo uses its own mount: on the drawing the holes sit where AM4 has them (54×90 mm), but there are no AM4 plastic brackets, and the screws and backplate are Lenovo's. An ordinary AM4 cooler may need its mount reworked; this has not been tried. The SFF case fits a cooler only about 65–70 mm tall. A stronger cooler lets the processor hold a high speed for longer. |
| **Processor power circuit on the board** (4+2 phases, no heatsinks) | partly | The phases themselves cannot be changed, but their cooling can: stick small heatsinks on the power transistors (with a thermal pad, without shorting nearby parts) and add airflow, for example a cooler that blows down onto the board. Without that, long loads above about 90–100 W make it run very hot. |
| **Power supply** (the stock one is 180 or 210 W for the whole computer) | yes | A stronger one can be fitted. The board has Lenovo's own power socket, so an ordinary unit needs an adapter. With the stock unit and a graphics card there is almost no headroom. |

What follows from that:

- **Processors up to 65 W** (2200G, 2700, 3600, 5600, 5600G, 5700G and the like) work without caveats.
- **95–105 W processors** (2700X, 3800X, 5800X, 5900X and the like) run in the 65 W class by default from T2.0: the
  firmware limits them to 88 W, 60 A and 90 A, which the board is built for. Full power can be turned on: Classic →
  Processor → "Own power limits (PBO)" (only together with "Failed overclock protection"). It is at your own risk: the
  main limit here is the board's power circuit, with no heatsinks and no temperature sensor; the cooler and the power
  supply can be replaced, the circuit can only be cooled better. If you turn it on: a strong power supply, heatsinks on
  the power circuit's transistors, airflow over the board around the socket and a temperature limit (for example
  75–80°). On the Ryzen 1000 the firmware limits only the power (88 W), not the currents. Such processors have not been
  tested on this board.
- **"Own power limits (PBO)"** (the same item, every Ryzen): your own PPT/TDC/EDC, the PBO scalar and a boost override up
  to +200 MHz (where AMD's firmware supports them). Saving warns and asks you to tick "I understand the risk". Three
  failed starts in a row put the factory values back and turn the item off.
- **Temperature limit:** on the Ryzen 3000 and 5000 without graphics, Classic → Processor → "Temperature limit" (Auto, 85°,
  80°, 75°); on the Ryzen 2000G/3000G, a pair of AMD CBS items. The Ryzen 1000/2000 without graphics and the 4000G/5000G
  do not have it yet.
- **Power mode** (Classic → Processor): for the Ryzen 2200G, 2400G, 3200G and 3400G, Eco (35 W, quieter and cooler),
  Normal and Boosted (up to 88 W); on the 2200G and 3200G Boosted makes little difference, these processors rarely need
  that much. From T2.0 also for the 65 W Ryzen 4000G and 5000G: Eco (up to 60 W) and Normal. On the GE models (35 W) and
  other processors the item is closed and says why.
- **Current limits** from T2.0 are this board's, not the donor's: the firmware gives the processor Lenovo's numbers for
  the M715s. On the Ryzen 2000G and 3000G the current of the built-in graphics and the memory controller is capped at
  40 A, as Lenovo does.
- Programs in Windows and Linux that change the processor's limits themselves (Ryzen Master and the like) work around the
  firmware.
- Processor and graphics overclocking (your own clock and voltage): from T2.0, see [section 6](#6-processor-overclocking).

## 4. Memory for built-in graphics

A processor with built-in graphics gives part of the main memory to it.

- On Auto that is 2 GB on Ryzen 2000G/3000G (with 8 GB of memory or more) and 512 MB on Ryzen 4000G/5000G.
- From T2.0 the size is a number of your own ("Memory for graphics"). On the Ryzen 4000G and 5000G it goes from 1 GB up
  to all the memory less 3 GB, in steps of 1 GB (up to 29 GB with 32 GB); if the system is left with less than 8 GB, the
  menu warns that Windows will be slow. On the Ryzen 2000G and 3000G it is 512 MB to 16 GB, except 3, 6 and 12 GB.
- **More than 2 GB works only with the legacy compatibility mode (CSM) turned off.**
- On the author's board (Ryzen 3 2200G, 16 GB of memory) 11 GB works: Linux sees 11 GB of video memory. Nobody has tried
  more than 16 GB, or the Windows driver with that much, yet.
- **Do not choose "3G" with CSM on:** the computer may stop starting, and resetting the settings will not fix it. Our menu
  does not offer it; the old BIOS menu still does.
- Usually you do not need much: Windows and Linux give built-in graphics up to half of the memory when it needs it.
  A large value only helps programs that look at "video memory size".

## 5. Processors

- A-series processors (A6, A8, A10, A12, Athlon X4 9xx) do not work with this firmware.
- Processors without built-in graphics need a graphics card. Without one there is no picture (eight short beeps at
  power-on are the usual "no picture"); from T2.0 the board at least no longer restarts in a loop then.

## 6. Processor overclocking

From T2.0 you can set your own core clock and voltage, your own built-in graphics clock and voltage, and Curve
Optimizer; which of them depends on the processor (table below). All of it is in Classic → Processor.

**First turn on "Failed overclock protection":** without it these items are locked. The protection is on at once and
works from the next start; the menu offers a restart by itself, then press Del again and set the overclock. If after an
overclock the computer fails to reach the system 3 times in a row, the firmware puts the processor and graphics
overclock back to the factory values by itself (Curve Optimizer and "Own power limits" too); other settings stay. The
board restarts each such start after a minute; the whole rollback takes about 4 minutes. On the author's board the
rollback was tested on an early T2 test build; in its current form (with Curve Optimizer and an earlier start) it has
not been tested yet.

**What the protection does not catch.** If the system starts but crashes or freezes under load (in games, for example)
or at idle, the rollback does not kick in. Then press Del at power-on and set Auto again. The rollback puts back the
factory values, not the last good ones: after a rollback a good overclock has to be set again.

**The core voltage** is set as a fixed value, not as an offset: the board's processor power circuit cannot do offsets.
With a clock of your own the boost is off: the cores run at that clock.

| Processors | Core clock and voltage | Built-in graphics | Curve Optimizer |
|---|---|---|---|
| Ryzen 2000G (2200G, 2400G, their GE and PRO) | up to 4000 MHz, up to 1.40 V | 800–1600 MHz, 1.10–1.20 V | — |
| Ryzen 3000G (3200G, 3400G, their GE and PRO), Athlon 3000G | up to 4200 MHz, up to 1.40 V | 800–1600 MHz, 1.10–1.20 V | — |
| Athlon 200GE, 220GE, 240GE, 300GE, 320GE, 3050GE, 3150G | locked (AMD locks the multiplier) | 800–1600 MHz, 1.10–1.20 V | — |
| Ryzen 4000G (4300G, 4600G, 4650G and the like) | 3000–4200 MHz, up to 1.20 V | from the model's own clock up to 2400 MHz, 1.10–1.25 V | — |
| Ryzen 5000G (5600G, 5700G and the like) | locked | from the model's own clock up to 2400 MHz, 1.10–1.25 V | all cores, −1…−30 |
| Ryzen 5000 without graphics | locked | — | all cores, −1…−30 |
| Ryzen 1000, 2000 and 3000 without graphics | locked | — | — |

- These are the menu's limits, not a promise: every processor sample is different. The lowest clock differs by model;
  the menu shows the limits for your processor itself. On the author's board the Ryzen 3 2200G ran stable at 3900 MHz
  and 1.375 V (10 minutes under load without errors) and froze at 4000 MHz at any voltage.
- **A built-in graphics overclock** fixes the graphics clock, and the driver does not know it. On the author's Ryzen 3
  2200G, 1200 MHz (1.200 V) was applied, but the computer froze under graphics load; maybe this sample's graphics simply
  cannot run at that clock. On Linux the amdgpu driver stops talking to the processor after such an overclock ("Failed
  to send Message" errors); do not switch amdgpu to manual clock modes on Linux. Raise the clock one step at a time and
  test under load; if it freezes, Del at power-on and Auto. The same warning is in these items' help in the menu.
- The built-in graphics of the Ryzen 2000G/3000G and the memory controller run off one power line. The firmware keeps
  its current within Lenovo's limit for this board, 40 A, so the graphics voltage is 1.10 to 1.20 V.
- **Curve Optimizer** (Ryzen 5000) lowers every core's voltage by 1–30 steps; one value for all cores, and negative only;
  the boost and the power limits stay as made. It is there only where AMD itself offers it for the processor. Too much
  Curve Optimizer usually fails once the system runs, at idle and in light work; the protection does not catch that: Del
  at power-on and closer to zero.
- **Why locked.** On the Ryzen 5000 a fixed clock would turn the boost off and be slower than stock at the voltage this
  board allows, so they get Curve Optimizer instead. On the Athlon, except the 3000G, the multiplier is locked in the
  processor itself. Ryzen without graphics only work with a graphics card, while the stock power supply is 180–210 W and
  the power circuit is built for 65 W.
- On this board only the Ryzen 3 2200G overclock has been tested. Overclocking the Ryzen 4000G and 5000G and the Athlon,
  and Curve Optimizer, nobody has tried yet.

## 7. Voltage sensors

- **+12 V and +5 V are not measured on this board at all.** The sensor chip's inputs (ITE IT8738) that measure +12 V, +5 V
  and the processor voltage on other boards are not connected to anything here. So AIDA64, HWiNFO, the stock BIOS and
  other programs show random numbers in those lines (for example "+12 V" = 7 or 17 V). It was the same with Lenovo's own
  BIOS. The power supply is fine, and no multiplier can fix those lines.
- The board measures three voltages, all around 3 V: the +3.3 V supply, the +3.3 V standby and the CMOS battery. From
  T2.0 they are shown in the Health window (F3 for details) and in the F11 report. The battery is measured only at
  power-on; below 2.7 V the menu suggests replacing it (CR2032).
- While the computer is plugged in, "CMOS battery" may show the standby power behind the battery rather than the battery
  itself; this has not been checked yet. Checking the three voltages against a multimeter has not been done yet either.
- What to hide in AIDA64 and HWiNFO: [DIAGNOSTICS.md](DIAGNOSTICS.md#voltages-aida64-and-hwinfo).

## 8. DASH

- **With DASH off** (the default), the computer cannot be turned on or restarted over the network, even when the network
  card of the switched-off computer answers on the network: its own firmware starts DASH, but power commands are not
  carried out.
- **After a power cut** the part of the chipset that takes the network card's "power on" command waits to be set up by
  the firmware, and the firmware only runs when the computer is on. So from T2.0, with DASH on and Auto power-on (Classic
  → Power) at Stay off, the computer turns on by itself for a few seconds when power comes back, gets DASH ready and
  turns off again; after that "power on" over DASH works. With Turn on it simply boots, and DASH is ready as well. With As
  it was, a computer that was off when the power went cannot be turned on over DASH until it has been turned on once with
  the button or over the network (Wake-on-LAN).

## 9. Secure Boot

- With Secure Boot on, only signed boot loaders start: Windows and most Linux distributions (through shim) do; unsigned
  USB sticks do not. Our [test stick](https://github.com/airtwist223/z3novo/releases/tag/TestStick-1.4) is one of them: to
  boot from it, turn Secure Boot off first.
- Without keys installed, Secure Boot does nothing, even with its switch on.
- Turning Secure Boot on or off changes the TPM measurements: if BitLocker or "Device encryption" is on in Windows, save
  the recovery key first. Step by step: [DIAGNOSTICS.md](DIAGNOSTICS.md#secure-boot-step-by-step); Secure Boot on T2.0 has
  not been tested on the author's board yet.
