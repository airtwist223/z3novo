# Известные проблемы / Known issues

## Открытые

- **Ryzen 4000G и 5000G: выход из сна — исправлено в T2.0, но ещё не подтверждено.** До T2.0 компьютер с такими
  процессорами засыпал, но не просыпался: экран чёрный, вентиляторы крутятся, помогало только выдернуть шнур. Причину
  нашли в коде и в T2.0 исправили, но проверить исправление на таком процессоре пока не на чем: у автора Ryzen 3 2200G (на
  нём сон работает). **Если у вас Ryzen 4000G или 5000G, проверьте, пожалуйста, сон на T2.0** (Windows: «Пуск» →
  кнопка питания → «Спящий режим», потом разбудите кнопкой питания, клавиатурой или мышью) и напишите, проснулся ли
  компьютер: в Telegram-бот [@z3novo_bot](https://t.me/z3novo_bot) или в Issues на GitHub (форма «Проблема» или «Всё
  работает»). Если не проснулся — выдерните шнур из розетки на 30 секунд, включите, нажмите Del и F11 и приложите этот
  отчёт. Пока сон не подтверждён, можно поставить в Windows «Сон: никогда» или пользоваться гибернацией.
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
- **Перед нашим окном может мелькнуть текст родного BIOS** — «No option to boot to», «System Configuration Changed» или
  «Memory OC fail». Так бывает в редких случаях: нет ни одного пункта загрузки, после сброса CMOS или после неудачной
  частоты памяти. Это на доли секунды; дальше открывается наше окно.
- **Батарейка стирает больше, чем кажется.** Если вынуть батарейку (или заменить процессор), прошивка сбрасывает все
  настройки BIOS, а записи Windows и Linux в меню загрузки пропадают. Зависший компьютер выключайте кнопкой (держать 5
  секунд) или вынимайте шнур на 30 секунд; батарейку — только если компьютер совсем не включается
  ([что делать](DIAGNOSTICS.md#если-компьютер-не-включается-совсем)).
- **PCIe 4.0 на Ryzen 3000 и 5000 без графики не проверен.** Если накопитель или видеокарта PCIe 4.0 работают со сбоями,
  поставьте Классика → Устройства → «Скорость слотов PCIe» → Gen 3 и напишите нам.
- **Автор проверяет каждую версию только на своей плате AM4P2MS ревизии 1.1 с Ryzen 3 2200G.** Что тестеры проверили
  на других процессорах — в [списке проверенного](TESTED.md). Другие ревизии платы ещё никто не проверял.
- **Не всякая память заводится на этой плате.** Одноранговый модуль 16 ГБ на чипах 16 Гбит (AMD R7 16G DDR4-2666, чипы
  Nanya) не стартует на ней ни с одной прошивкой, включая родную Lenovo: писки и перезагрузка по кругу. Не помогает и
  пониженная частота (2133, 2T). На платах Intel тот же модуль работает. Обычные модули (на чипах 8 Гбит) работают.
  В паре с другой планкой компьютер запускается, но этот модуль не используется: Windows показывает всю память как
  установленную, а доступна только память второй планки, и работает один канал. В отчёте F11 это видно по строке
  «видно в карте памяти» (с T2.0 — прямо: «планка стоит, но не используется»).
- **«3G» памяти для графики при включённом CSM** опасен — см. [ограничения платы](LIMITS.md), раздел 4. Наше меню на
  Ryzen 2000G/3000G не предлагает 3, 6 и 12 ГБ.

## Исправлено в T2.0

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

- **Ryzen 4000G and 5000G: waking from sleep — fixed in T2.0, but not yet confirmed.** Before T2.0 a computer with these
  processors went to sleep but did not wake up: black screen, fans spinning, only pulling the cord helped. The cause was
  found in the code and fixed in T2.0, but there is nothing to test the fix on yet: the author has a Ryzen 3 2200G (sleep
  works on it). **If you have a Ryzen 4000G or 5000G, please try sleep on T2.0** (Windows: Start → Power → Sleep, then
  wake it with the power button, the keyboard or the mouse) and tell us whether the computer woke up: in the Telegram bot
  [@z3novo_bot](https://t.me/z3novo_bot) or under Issues on GitHub (the "Problem" or "Works for me" form). If it did not
  wake up, pull the cord out of the wall socket for 30 seconds, power on, press Del and F11, and attach that report. Until
  sleep is confirmed, you can set Windows to "Sleep: Never" or use hibernation.
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
- **Text from the stock BIOS may flash up before our window**: "No option to boot to", "System Configuration Changed" or
  "Memory OC fail". It happens in rare cases: no boot entry at all, after clearing CMOS or after a failed memory speed. It
  lasts a fraction of a second; then our window opens.
- **The battery clears more than it seems.** Taking the battery out (or changing the processor) makes the firmware reset
  every BIOS setting, and the Windows and Linux entries in the boot menu disappear. Turn a frozen computer off with the
  power button (hold it for 5 seconds) or unplug it for 30 seconds; take the battery out only if the computer does not
  start at all ([what to do](DIAGNOSTICS.md#if-the-computer-does-not-start-at-all)).
- **PCIe 4.0 on the Ryzen 3000 and 5000 without graphics has not been tested.** If a PCIe 4.0 drive or graphics card
  misbehaves, set Classic → Devices → "PCIe slot speed" → Gen 3 and let us know.
- **The author tests every version only on the author's own AM4P2MS revision 1.1 board with a Ryzen 3 2200G.** What
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

## Fixed in T2.0

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
