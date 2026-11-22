# Известные проблемы / Known issues

## Открытые

- **Трёхпиновые вентиляторы не регулируются.** На всех четырёх разъёмах вентиляторов этой платы всегда 12 В, а обороты
  меняются только по проводу ШИМ четырёхпиновых вентиляторов. Трёхпиновый вентилятор на любом разъёме крутится на полных
  оборотах — так устроена плата, прошивка этого не изменит. Разъёмы AUX1_FAN и AUX2_FAN работают от одного выхода (FAN3)
  и настраиваются только вместе ([подробнее](LIMITS.md#10-вентиляторы)).
- **«Минимум» ниже 20 %.** Не всякий вентилятор держит низкие обороты, а при 0 % вентилятор может остановиться.
  Вентилятор, обороты которого видит плата, защита от остановки раскрутит и до перезагрузки поднимет ему минимум;
  вентилятор, обороты которого плата не видит (в окне «Состояние» его нет или там 0), может так и стоять — поставьте ему
  минимум повыше ([подробнее](DIAGNOSTICS.md#вентиляторы)).
- **С некоторыми накопителями NVMe в слоте M.2 Windows зависает** (одно сообщение: Ryzen 5 PRO 4650G, T1.2, накопитель
  Western Digital; с диском SATA зависаний нет). В T2.0 тактовый сигнал слота M.2 сделан как в родном BIOS Lenovo, но
  помогает ли это, ещё не проверено. Если у вас так — пришлите отчёт F11 и модель накопителя.
- **Пассивный переходник DisplayPort → HDMI: нет высокой частоты кадров.** Оба разъёма платы работают как настоящие
  DisplayPort (как у Lenovo), и с пассивным переходником драйвер AMD ограничивает частоту его паспортным пределом: для
  1440p обычно 60–75 Гц. Для 144 Гц возьмите кабель DP→DP (если у монитора есть вход DisplayPort) или активный
  переходник DP 1.4 → HDMI 2.0. В T2.0 второй разъём можно переключить в «HDMI» (Классика → Устройства → «Второй разъём
  DisplayPort»); на плате автора это ещё не проверено. Первый разъём остаётся DisplayPort.
- **Windows может попросить активацию заново.** Новый BIOS называет компьютер по-другому, и в нём нет ключа Windows,
  который Lenovo записала в родной BIOS. С T2.0 имя меняется ещё раз (см. следующий пункт), поэтому Windows может
  попросить подтвердить активацию и после обновления с T1.x. Windows 11: Параметры → Система → Активация → «Устранение
  неполадок» → «Я недавно изменил оборудование на этом устройстве» (нужна учётная запись Microsoft, к которой привязана
  лицензия); в Windows 10 тот же пункт — в «Обновление и безопасность» → «Активация». Или введите свой ключ. Ваш ключ
  остаётся в сохранённой копии родного BIOS.
- **Компьютер называется по-другому.** С T2.0 сведения о системе показывают Z3NOVO Labs ThinkCentre M715s Reborn, плату —
  AM4P2MS Unlocked, версию BIOS — Z3NOVO и номер версии (на T1.x — имя платы Biostar, с которой взята основа прошивки).
  Серийный номер и модель машины пустые. Программы Lenovo (Vantage, System Update) эту машину не узнают и ничего для неё
  не предлагают: драйверы берите у AMD и производителей устройств. На работу это не влияет.
- **Программы, показывающие температуры и обороты.** С процессором Ryzen 3 2200G связь с микросхемой датчиков на плате
  (ITE IT8738) иногда сбоит — это особенность процессора, прошивка её обходит. Не включайте в таких программах датчики
  этой микросхемы (раздел ITE в HWiNFO и AIDA64, драйвер it87 в Linux): они покажут ерунду и могут мешать вентилятору.
  Температуру процессора смотрите по датчику самого процессора («CPU» в HWiNFO, k10temp в Linux). Термозона ACPI
  («ACPI Thermal Zone» в Windows, acpitz в Linux) всегда показывает 0 °C: это заглушка, настоящих показаний в ней нет.
  +12 В и +5 В эти программы на этой плате показывают неверно всегда: такие входы не подключены
  ([подробнее](DIAGNOSTICS.md#напряжения-aida64-и-hwinfo)).
- **DASH** (удалённое управление). Встроенная программа сетевой карты 2016 года, в ней есть известные дыры.
  Не включайте DASH без надобности. Если нужен — только на прямом кабеле к своему компьютеру или в отдельной сети без
  выхода в интернет. Вход в DASH защищён заводским паролем, одинаковым у всех таких карт, а сменить его в нашем меню
  пока нельзя: любой, кто подключён к той же сети, может управлять компьютером.
- **DASH: ISO по сети и удалённое питание в Linux.** Подключение ISO по сети работает, но не со всяким HTTP-сервером:
  карта ждёт, что заголовок ответа и начало файла придут одним пакетом (простой `python3 -m http.server` так не делает, и
  карта бросает подключение). Готовый скрипт: [tools/dash](../tools/dash/README.md). Драйвер SMBus в Linux (`i2c_piix4`)
  трогает ту же шину, по которой карта DASH передаёт команды питания; с T2.0 прошивка, когда DASH включён, прячет эту шину
  от Linux сама, и параметр ядра `module_blacklist=i2c_piix4` больше не должен быть нужен (на плате автора удалённые
  выключение и перезагрузка в Linux без него ещё не проверены). На T1.x этот параметр нужен.
- **DASH после пропадания питания.** С T2.0, если DASH включён, а «Автовключение» — «Не включаться», компьютер после
  возвращения питания сам включается на несколько секунд, готовит DASH и выключается — так и задумано. Если в эти секунды нажать кнопку питания,
  компьютер может выключиться сам — нажмите кнопку ещё раз. При «Автовключение: Как было» компьютер, который был выключен,
  когда пропало питание, по DASH не включится, пока его хоть раз не включат кнопкой или по сети (Wake-on-LAN).
- **Батарейка стирает больше, чем кажется.** Если вынуть батарейку (или заменить процессор), прошивка сбрасывает все
  настройки BIOS, а записи Windows и Linux в меню загрузки пропадают. С T2.2 со следующего запуска встают заводские
  значения Z3NOVO: CSM выключен, «Две видеокарты сразу» — «Авто»; Windows или Linux, установленные в режиме MBR, тогда
  не загрузятся, пока не включите CSM (Классика → Загрузка → «Поддержка старых систем»). Зависший компьютер выключайте
  кнопкой (держать 5 секунд) или вынимайте шнур на 30 секунд; батарейку — только если компьютер совсем не включается
  ([что делать](DIAGNOSTICS.md#если-компьютер-не-включается-совсем)).
- **Код 43 у встроенной графики рядом с видеокартой.** После смены деления слота x16 или процессора Windows может
  показать у встроенной графики AMD жёлтый значок (код 43): устройства получили новые номера. Переустановите драйверы
  чипсета и видео AMD. Встроенная графика рядом с видеокартой работает только с видео UEFI (CSM выключен, как по
  умолчанию в T2.2); со старым режимом видео у неё бывает код 43.
- **Старая видеокарта без UEFI-драйвера и процессор со встроенной графикой.** Если CSM выключен, изображение при
  включении выводит встроенная графика, а на мониторе видеокарты до загрузки Windows пусто: страховка CSM не
  срабатывает, потому что UEFI-драйвер у встроенной графики есть. Включите CSM (Классика → Загрузка → «Поддержка старых
  систем») или подключите монитор к разъёму на плате.
- **`shutdown /r /fw` в первый раз — ошибка 203.** Команда Windows «перезагрузиться в настройки BIOS» в первый раз может
  закончиться ошибкой 203. Компьютер всё равно откроет наше меню при следующей перезагрузке, а дальше команда работает
  сразу. Исправление — в следующей версии.
- **«Какие системы загружать» однажды само сменилось на «Только старые»** (одно сообщение): после сохранения «Только
  UEFI» и перезагрузки пункт показал «Только старые», со второго раза значение сохранилось. Ни прошивка, ни меню этот
  пункт сами не меняют, причина пока не найдена. Если у вас так — сразу сделайте отчёт F11 и пришлите его.
- **PCIe 4.0 на Ryzen 3000 и 5000 без графики не включается:** слоты работают как PCIe 3.0 (8 ГТ/с), даже если видеокарта
  или накопитель умеют 4.0. Так AMD ограничивает эти процессоры на платах этого класса; проверено на Ryzen 3 3300X.
- **Автор проверяет Z3NOVO только на своей плате AM4P2MS ревизии 1.1 с Ryzen 3 2200G.** Что тестеры проверили
  на других процессорах — в [списке проверенного](TESTED.md). Другие ревизии платы ещё никто не проверял.
- **Не всякая память заводится на этой плате.** Одноранговый модуль 16 ГБ на чипах 16 Гбит (AMD R7 16G DDR4-2666, чипы
  Nanya) не стартует на ней ни с одной прошивкой, включая родную Lenovo: писки и перезагрузка по кругу. Не помогает и
  пониженная частота (2133, 2T). На платах Intel тот же модуль работает. Обычные модули (на чипах 8 Гбит) работают.
  В паре с другой планкой компьютер запускается, но этот модуль не используется: Windows показывает всю память как
  установленную, а доступна только память второй планки, и работает один канал. В отчёте F11 это видно по строке
  «видно в карте памяти» (с T2.0 — прямо: «планка стоит, но не используется»).
- **«3G» памяти для графики при включённом CSM** опасен — см. [ограничения платы](LIMITS.md), раздел 4. Наше меню на
  Ryzen 2000G/3000G не предлагает 3, 6 и 12 ГБ.

## Исправлено в T2.2

- **Ryzen без встроенной графики: видеокарта пропадала перед запуском системы** (Ryzen 1000, 2000, 3000 и 5000 без
  буквы G; все версии до T2.1 включительно). На мониторе застывала заставка BIOS, хотя Windows или Linux загружались:
  прошивка перед загрузчиком выключала тактовый сигнал слота x16. Лекарство — обновиться на T2.2; меню BIOS (Del) с
  видеокартой при этом работает, обновиться можно из него.
- **Процессоры со встроенной графикой с видеокартой** (Ryzen 2000G–5000G, Athlon; T2.0 и T2.1). При «Две видеокарты
  сразу: Выкл» не было изображения, Athlon перезапускался по кругу, а Ryzen 4000G и 5000G могли перестать запускаться
  вовсе, даже без видеокарты. Прошивка стирала отметку, которой AMD выключает встроенную графику. Лекарство — обновиться
  на T2.2. Пока стоит T2.0 или T2.1, до установки видеокарты поставьте «Две видеокарты сразу» = «Авто». Если плата с
  Ryzen 4000G или 5000G уже не запускается и без видеокарты, обновитесь на T2.2 с другим процессором, с которым она
  запускается: при обновлении меню запишет блок настроек памяти процессора из файла. Другого процессора нет — запишите
  T2.2 программатором ([как](FLASHING.md#первая-установка)).
- **Вентиляторы AUX сами разгонялись** (T2.1). Защита от остановки принимала сбойное чтение оборотов (у трёхпинового
  вентилятора на AUX2 их бывает много) за остановку: выход FAN3 время от времени получал 2 секунды полных оборотов и до
  перезагрузки поднимался на 10 % — за несколько часов с 25 % до полных оборотов. Лекарство — обновиться на T2.2.
- **Перед нашим окном мелькал текст родного BIOS** — «No option to boot to», «System Configuration Changed» или «Memory
  OC fail», после сброса CMOS и неудачной частоты памяти ещё и с ожиданием 10 секунд. В T2.2 этих надписей нет; о сбросе
  CMOS и неудачном разгоне памяти говорит жёлтая строка под логотипом.
- **Windows и Linux показывали дату BIOS 08/31/2025.** В T2.2 — дата версии.

## Исправлено в T2.1

- **Вентиляторы после сна не регулировались.** В T2.0 после пробуждения они оставались на средних оборотах (около
  56–60 %) до перезагрузки. В T2.1 через несколько секунд после пробуждения прошивка снова ведёт их по температуре, до обычных оборотов они опускаются плавно — от полуминуты до пары минут, пока процессор остывает (подтверждено на Ryzen 3 2200G, Ryzen 5 PRO 4650G и Ryzen 5 5600G); в режиме
  «Микросхемой» прошивка проверяет, что микросхема опрашивает температуру, иначе ставит полные обороты.
- **Корпусные вентиляторы на T2.0 громче, чем на T1.2.** В T2.1 в простое «Тихо» — 20 %, «Авто» — 25 % (было 30 и 35 %);
  «Тихо» вентилятора процессора тоже тише.
- **Окно «Состояние» показывало скважность вентилятора неверно** — например, «22 %» вместо настоящих 37,5 %.
- **Вентилятор на разъёме AUX2_FAN нигде не показывался.** В T2.1 его обороты видны в «Состоянии», на главном экране и в
  отчёте F11.
- **Второй курсор мыши поверх нашего меню,** когда меню открывалось само (система не загрузилась, нет диска для
  загрузки). Исправлено в T2.1 (проверено в эмуляторе).
- **GPU-Z и диспетчер устройств показывали производителя Biostar** (код 1565:170B / 1565:370B). В T2.1 — Lenovo
  (17AA:36C7), как в родном BIOS.
- **Меню прошивки не показывало новый файл,** если в папке `\Z3NOVO` на флешке скопилось много копий `Z3BACKUP-….BIN`.
  Исправлено в T2.1: в списке до 64 файлов, файлы из корня флешки — первыми. Чтобы обновиться с T2.0 или T1.x, сначала
  перенесите старые копии на компьютер ([подробнее](FLASHING.md#обновление)).

## Исправлено в T2.0

- **Ryzen 4000G и 5000G: компьютер засыпал, но не просыпался** (экран чёрный, вентиляторы крутятся, помогало только
  выдернуть шнур). Исправлено в T2.0 и подтверждено тестерами: с Ryzen 5 PRO 4650G работают сон и гибернация, с Ryzen 5
  5600G компьютер засыпает и просыпается от кнопки питания и клавиатуры. Если сон у вас всё же не работает — выдерните
  шнур из розетки на 30 секунд, включите, нажмите Del и F11 и пришлите этот отчёт в бот
  [@z3novo_bot](https://t.me/z3novo_bot) или в Issues.
- **Режим памяти «Авто» и планки разной скорости.** «Авто» могло выставить скорость быстрой планки, и медленная работала
  выше своей паспортной скорости. В T2.0 частота — по более медленной планке (на плате автора ещё не проверено).
- **Ручная частота памяти: лишняя перезагрузка перед каждым запуском системы.** В T2.0 компьютер перезапускается сам
  только один раз — сразу после сохранения новых настроек памяти или после обновления прошивки (на плате автора ещё не
  проверено).
- **Меню загрузки F9: диск (например, Windows Boot Manager) запускался через перезагрузку.** В T2.0 — сразу (на плате автора ещё не проверено).
- **Linux писал при загрузке `irq 7: nobody cared`** (безвредно). В T2.0 неиспользуемый контроллер GPIO снова скрыт.
- **Разгон процессора и графики был закрыт.** В T2.0 он открыт вместе с защитой от неудачного разгона
  ([пределы](LIMITS.md#6-разгон-процессора)).
- **Настройки иногда переставали сохраняться** (окно «Сохранено не всё» при каждом сохранении, часть изменений не
  записывалась), а включённая безопасная загрузка не сохранялась вовсе. Исправлено в T2.0 (на плате автора ещё не
  проверено).
- **Пустая вкладка «Питание»** при очень раннем нажатии Del. Исправлено в T2.0 (на плате автора не воспроизводится,
  поэтому не проверено).
- **Ryzen без встроенной графики без видеокарты перезагружался по кругу**, если загрузиться было не с чего. Исправлено в
  T2.0 (на плате автора ещё не проверено).
- **Экран BIOS в текстовой консоли DASH не работал.** В T2.0 Del и F9 в консоли открывают наше меню текстом.
- **DASH после выдёргивания шнура не включал компьютер** и иногда замолкал до выдёргивания шнура. Исправлено в T2.0
  (оговорки — в пункте «DASH после пропадания питания» выше).

## Исправлено раньше

- **T1 и Windows: синий экран ACPI_BIOS_ERROR — исправлено в T1.1.** Если у вас T1, обновитесь из меню с флешки.
  Если после синего экрана компьютер завис на заставке, держите кнопку питания 5 секунд, включите снова, нажмите Del и
  обновитесь.
- **Ryzen 4000G и 5000G: перезагрузка из Windows — исправлено в T1.1r.** В T1.1 после «Перезагрузки» Windows на
  Ryzen 4000G грузила процессор впустую, а «Время работы» в Диспетчере задач показывало около 10675199 дней; на 5000G
  перезагрузка зависала. Пока стоит T1.1, вместо «Перезагрузки» выключайте компьютер и включайте снова.
- **При включении три перезапуска подряд, потом не работают передние USB и два задних под сетевым разъёмом** — если
  в памяти CMOS платы остался мусор от прежней прошивки (такое было на одной плате). Наша прошивка принимала один из этих
  байтов за свою тестовую команду. Батарейка и шнур этот мусор не стирают. **Исправлено в T1.2:** при первом запуске
  прошивка сама стирает свои служебные байты, если их записала не она.

---

# Known issues

## Open

- **3-pin fans are not controlled.** All four fan headers of this board always carry 12 V, and the speed changes only
  through the PWM wire of 4-pin fans. A 3-pin fan on any header runs at full speed: that is how the board is built, and no
  firmware can change it. The AUX1_FAN and AUX2_FAN headers run on one output (FAN3) and can only be set together
  ([details](LIMITS.md#10-fans)).
- **A minimum under 20 %.** Not every fan holds a low speed, and at 0 % a fan may stop. A fan whose speed the board can see
  is spun up by the stall guard, which also raises its minimum until a restart; a fan whose speed the board cannot see
  (it is missing from the Health window or shows 0 there) may just stay stopped — give it a higher minimum
  ([details](DIAGNOSTICS.md#fans)).
- **With some NVMe drives in the M.2 slot Windows hangs** (one report: Ryzen 5 PRO 4650G, T1.2, a Western Digital drive;
  no hangs with a SATA disk). In T2.0 the M.2 slot's reference clock works as in Lenovo's own BIOS, but whether this helps
  has not been tested yet. If you see this, send the F11 report and the drive's model.
- **Passive DisplayPort → HDMI adapter: no high refresh rate.** Both of the board's sockets work as real DisplayPort (as
  Lenovo has them), and with a passive adapter the AMD driver caps the refresh rate at the adapter's rated limit: for
  1440p usually 60–75 Hz. For 144 Hz use a DP→DP cable (if the monitor has a DisplayPort input) or an active DP 1.4 →
  HDMI 2.0 adapter. In T2.0 the second socket can be switched to "HDMI" (Classic → Devices → "Second DisplayPort
  socket"); this has not been tested on the author's board yet. The first socket stays DisplayPort.
- **Windows may ask to be activated again.** The new BIOS gives the computer a different name and does not carry the
  Windows key Lenovo put in its BIOS. From T2.0 the name changes once more (see the next item), so Windows may ask to
  confirm activation after updating from T1.x too. Windows 11: Settings → System → Activation → Troubleshoot → "I changed
  hardware on this device recently" (you need the Microsoft account the licence is linked to); on Windows 10 the same is
  under Update & Security → Activation. Or enter your key. Your key stays in the saved copy of Lenovo's BIOS.
- **The computer has a different name.** From T2.0 system information shows a Z3NOVO Labs ThinkCentre M715s Reborn, the
  board as AM4P2MS Unlocked and the BIOS version as Z3NOVO and the version number (on T1.x: the name of the Biostar board
  the firmware is based on). The machine's serial number and model are blank. Lenovo's tools (Vantage, System Update) do
  not recognise the machine and offer nothing for it: get drivers from AMD and the device makers. It does not affect how
  anything works.
- **Programs that show temperatures and fan speeds.** With the Ryzen 3 2200G, talking to the board's sensor chip
  (ITE IT8738) sometimes fails. That is a quirk of the processor, and the firmware works around it. Do not turn on that
  chip's sensors in such programs (the ITE section in HWiNFO and AIDA64, the it87 driver on Linux): they will show
  nonsense and can get in the fan's way. Read the processor temperature from the processor's own sensor ("CPU" in
  HWiNFO, k10temp on Linux). The ACPI thermal zone ("ACPI Thermal Zone" in Windows, acpitz on Linux) always reads 0 °C:
  it is a placeholder with no real reading behind it. +12 V and +5 V are always wrong in these programs on this board:
  those inputs are not connected ([details](DIAGNOSTICS.md#voltages-aida64-and-hwinfo)).
- **DASH** (remote management). The network card's built-in program is from 2016 and has known holes. Do not turn DASH
  on unless you need it. If you do, use it only on a direct cable to your own computer or on a separate network with no
  internet access. DASH sign-in uses the factory password that every such card shares, and our menu cannot change it
  yet: anyone on the same network can control the computer.
- **DASH: ISO over the network and remote power on Linux.** Attaching an ISO over the network works, but not with every
  HTTP server: the card expects a reply's headers and the start of the file in one packet (a plain
  `python3 -m http.server` does not do that, and the card gives up). A ready script: [tools/dash](../tools/dash/README.md).
  Linux's SMBus driver (`i2c_piix4`) touches the same bus the DASH card sends its power commands over; from T2.0 the
  firmware hides that bus from Linux by itself while DASH is on, and the kernel parameter `module_blacklist=i2c_piix4`
  should no longer be needed (remote power-off and restart on Linux without it have not been tested on the author's board
  yet). On T1.x the parameter is needed.
- **DASH after a power cut.** From T2.0, with DASH on and Auto power-on at Stay off, the computer turns on by itself for a
  few seconds when power comes back, gets DASH ready and turns off again — that is intended. If you press the power button during
  those seconds, the computer may turn itself off: press the button again. With Auto power-on at As it was, a computer
  that was off when the power went cannot be turned on over DASH until it has been turned on once with the button or over
  the network (Wake-on-LAN).
- **The battery clears more than it seems.** Taking the battery out (or changing the processor) makes the firmware reset
  every BIOS setting, and the Windows and Linux entries in the boot menu disappear. From T2.2 Z3NOVO's factory values
  come in from the next start: CSM off, "Both graphics at once" Auto; Windows or Linux installed in MBR mode then do not
  start until you turn CSM on (Classic → Boot → "Legacy system support"). Turn a frozen computer off with the power
  button (hold it for 5 seconds) or unplug it for 30 seconds; take the battery out only if the computer does not start
  at all ([what to do](DIAGNOSTICS.md#if-the-computer-does-not-start-at-all)).
- **Code 43 on the built-in graphics next to a card.** After changing the x16 slot bifurcation or the processor, Windows
  may show a yellow mark (code 43) on AMD's built-in graphics: the devices got new numbers. Reinstall the AMD chipset and
  graphics drivers. The built-in graphics next to a card work only with UEFI video (CSM off, the T2.2 default); with the
  legacy video mode they may show code 43.
- **An old card without a UEFI driver and a processor with built-in graphics.** With CSM off the built-in graphics give
  the picture at power-on, and the card's monitor stays blank until Windows starts: the CSM safety net does not fire,
  because the built-in graphics have a UEFI driver. Turn CSM on (Classic → Boot → "Legacy system support") or plug the
  monitor into a socket on the board.
- **`shutdown /r /fw` fails with error 203 the first time.** The Windows command "restart into the BIOS settings" may
  end with error 203 the first time. The computer still opens our menu at the next restart, and from then on the command
  works at once. The fix is in the next version.
- **"Which systems to boot" once changed to Legacy only by itself** (one report): after saving UEFI only and restarting,
  the item showed Legacy only; the second time the value stayed. Neither the firmware nor the menu changes this item by
  itself, and the cause has not been found yet. If it happens to you, make an F11 report right away and send it.
- **PCIe 4.0 does not turn on with the Ryzen 3000 and 5000 without graphics:** the slots run as PCIe 3.0 (8 GT/s) even
  when the graphics card or drive supports 4.0. AMD limits these processors this way on boards of this class; checked on a Ryzen 3 3300X.
- **The author tests Z3NOVO only on the author's own AM4P2MS revision 1.1 board with a Ryzen 3 2200G.** What
  testers have checked on other processors is in [the tested list](TESTED.md). Nobody has tried other board revisions
  yet.
- **Not every memory stick starts on this board.** A single-rank 16 GB stick built on 16 Gbit chips (AMD R7 16G
  DDR4-2666, Nanya chips) does not start on it with any firmware, Lenovo's own included: beeps and a restart in a loop.
  A lower speed (2133, 2T) does not help either. The same stick works on Intel boards. Ordinary sticks (on 8 Gbit chips)
  work. Paired with another stick the computer starts, but this stick is not used: Windows lists all the memory as
  installed, only the other stick's memory is available, and one channel works. The F11 report shows it in the
  "visible in the memory map" line (from T2.0 directly: "stick present, not in use").
- **"3G" of graphics memory with CSM on** is dangerous, see [board limits](LIMITS.md), section 4. On the Ryzen 2000G/3000G
  our menu does not offer 3, 6 or 12 GB.

## Fixed in T2.2

- **Ryzen without built-in graphics: the card dropped off before the system started** (the Ryzen 1000, 2000, 3000 and 5000
  without the G; every version up to T2.1). The BIOS splash froze on the monitor although Windows or Linux went on
  loading: the firmware switched the x16 slot's reference clock off before the boot loader. The cure is updating to T2.2;
  the BIOS menu (Del) works with the card meanwhile, so you can update from it.
- **Processors with built-in graphics and a card** (Ryzen 2000G–5000G, Athlon; T2.0 and T2.1). With "Both graphics at
  once: Off" there was no picture, an Athlon restarted in a loop, and a Ryzen 4000G or 5000G could stop starting at all,
  even without the card. The firmware erased the mark AMD turns the built-in graphics off with. The cure is updating to
  T2.2. While T2.0 or T2.1 is on, set "Both graphics at once" to Auto before putting the card in. If a board with a Ryzen
  4000G or 5000G no longer starts even without the card, update to T2.2 with another processor the board starts with:
  the update writes the processor's memory settings block from the file. No other processor at hand — write T2.2 with a
  programmer ([how](FLASHING.md#first-install)).
- **The AUX fans sped up by themselves** (T2.1). The stall guard took a failed speed reading (a 3-pin fan on AUX2 gives
  many) for a stop: the FAN3 output now and then got 2 seconds at full speed and was raised by 10 % until a restart —
  from 25 % to full speed within a few hours. The cure is updating to T2.2.
- **Stock BIOS text flashed up before our window**: "No option to boot to", "System Configuration Changed" or "Memory OC
  fail", after clearing CMOS and a failed memory speed with a 10-second wait as well. T2.2 shows none of it; a yellow line
  under the logo tells about a CMOS reset and a failed memory overclock.
- **Windows and Linux showed the BIOS date 08/31/2025.** In T2.2 it is the version's date.

## Fixed in T2.1

- **The fans were not controlled after sleep.** In T2.0, after waking up, they stayed at a medium speed (about 56–60 %)
  until a restart. In T2.1 the firmware drives them by the temperature again a few seconds after waking; they come down to their usual speed smoothly, within half a minute to a couple of minutes as the processor cools (confirmed on the Ryzen 3 2200G, Ryzen 5 PRO 4650G and Ryzen 5 5600G); in "By the chip" mode the
  firmware checks that the chip polls the temperature and sets full speed otherwise.
- **The case fans were louder on T2.0 than on T1.2.** In T2.1 at idle Quiet is 20 % and Auto 25 % (it was 30 and 35 %);
  the processor fan's Quiet is quieter too.
- **The Health window showed the fan's duty wrongly**, for example "22 %" for a real 37.5 %.
- **A fan on the AUX2_FAN header was shown nowhere.** In T2.1 its speed is in the Health window, on the home screen and in
  the F11 report.
- **A second mouse pointer over our menu** when the menu opened by itself (the system did not start, no disk to boot).
  Fixed in T2.1 (tested in an emulator).
- **GPU-Z and Device Manager showed Biostar as the maker** (ID 1565:170B / 1565:370B). In T2.1 it is Lenovo (17AA:36C7),
  as in Lenovo's own BIOS.
- **The firmware menu did not show a new file** when many `Z3BACKUP-….BIN` copies had piled up in the stick's `\Z3NOVO`
  folder. Fixed in T2.1: up to 64 files in the list, the files in the stick's root first. To update from T2.0 or T1.x,
  move the old copies to a computer first ([details](FLASHING.md#updating)).

## Fixed in T2.0

- **Ryzen 4000G and 5000G: the computer went to sleep but did not wake up** (black screen, fans spinning, only pulling the
  cord helped). Fixed in T2.0 and confirmed by testers: with a Ryzen 5 PRO 4650G sleep and hibernation work, with a
  Ryzen 5 5600G the computer goes to sleep and wakes up with the power button and the keyboard. If sleep still does not
  work for you, pull the cord out of the wall socket for 30 seconds, power on, press Del and F11, and send that report to
  the bot [@z3novo_bot](https://t.me/z3novo_bot) or under Issues.
- **Memory mode Auto with sticks of different speeds.** Auto could set the faster stick's speed, and the slower one then
  ran above its rated speed. In T2.0 the speed follows the slower stick (not yet tested on the author's board).
- **Manual memory speed: an extra restart before every start of the system.** In T2.0 the computer restarts by itself
  only once, right after you save new memory settings or after a firmware update (not yet tested on the author's board).
- **F9 boot menu: a disk (Windows Boot Manager, for example) started through a restart.** In T2.0 it starts at once (not yet tested on the author's
  board).
- **Linux printed `irq 7: nobody cared` at boot** (harmless). In T2.0 the unused GPIO controller is hidden again.
- **Processor and graphics overclocking was closed.** In T2.0 it is open together with the protection against a failed
  overclock ([limits](LIMITS.md#6-processor-overclocking)).
- **Settings sometimes stopped being saved** ("Not everything was saved" at every save, some changes never written), and
  Secure Boot turned on was not saved at all. Fixed in T2.0 (not yet tested on the author's board).
- **An empty Power tab** after a very early Del. Fixed in T2.0 (it does not happen on the author's board, so it has not
  been tested).
- **A Ryzen without built-in graphics and no graphics card restarted in a loop** when there was nothing to boot. Fixed in
  T2.0 (not yet tested on the author's board).
- **The BIOS screen in the DASH text console did not work.** In T2.0 Del and F9 in the console open our menu as text.
- **DASH did not turn the computer on after the power cord was out**, and sometimes went silent until the cord was
  pulled. Fixed in T2.0 (caveats: the "DASH after a power cut" item above).

## Fixed earlier

- **T1 and Windows: blue screen ACPI_BIOS_ERROR — fixed in T1.1.** If you have T1, update from the menu with a USB stick.
  If the computer hangs on the logo after the blue screen, hold the power button for 5 seconds, turn it on again, press
  Del and update.
- **Ryzen 4000G and 5000G: restart from Windows — fixed in T1.1r.** On T1.1, after Restart, Windows on a Ryzen 4000G
  kept the processor busy for nothing and Task Manager showed an uptime of about 10675199 days; on a 5000G the restart
  hung. While you are on T1.1, shut the computer down and turn it on again instead of Restart.
- **Three restarts in a row at power-on, then the front USB sockets and the two rear ones under the network socket do
  not work** — when the board's CMOS memory still holds leftovers from a previous firmware (seen on one board). Our
  firmware took one of those bytes for its own test command. The battery and the cord do not clear it. **Fixed in
  T1.2:** at its first start the firmware clears its own service bytes if it did not write them itself.
