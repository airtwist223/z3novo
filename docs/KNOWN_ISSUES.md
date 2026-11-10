# Известные проблемы / Known issues

- **T1 и Windows: синий экран ACPI_BIOS_ERROR — исправлено в T1.1.** Если у вас T1, обновитесь до T1.1 из меню с флешки.
  Если после синего экрана компьютер завис на заставке, держите кнопку питания 5 секунд, включите снова, нажмите Del и
  обновитесь.
- **Ryzen 4000G и Windows: тормоза после перезагрузки** (сообщение тестера с Ryzen 5 4600G). После «Перезагрузки» Windows
  грузит процессор впустую, а «Время работы» в Диспетчере задач показывает около 10675199 дней. Пока обойти так: вместо
  «Перезагрузки» выключите компьютер и включите снова. Исправление проверяется.
- **Пассивный переходник DisplayPort → HDMI: нет высокой частоты кадров.** Оба разъёма платы работают как настоящие
  DisplayPort (как у Lenovo), и с пассивным переходником драйвер AMD ограничивает частоту его паспортным пределом: для
  1440p обычно 60–75 Гц. Для 144 Гц возьмите кабель DP→DP (если у монитора есть вход DisplayPort) или активный
  переходник DP 1.4 → HDMI 2.0. В T2 в меню появится выбор «HDMI через переходник» для второго разъёма.
- **Windows может попросить активацию заново.** Новый BIOS называет плату по-другому, и в нём нет ключа Windows,
  который Lenovo записала в родной BIOS. Введите свой ключ или войдите в учётную запись Microsoft, к которой привязана
  лицензия. Ваш ключ остаётся в сохранённой копии родного BIOS.
- **Плата называется по-другому.** В сведениях о системе она видна под именем платы Biostar, с которой взята основа
  прошивки. На работу это не влияет.
- **Программы, показывающие температуры и обороты.** С процессором Ryzen 3 2200G связь с микросхемой датчиков на плате
  (ITE IT8738) иногда сбоит — это особенность процессора, прошивка её обходит. Не включайте в таких программах датчики
  этой микросхемы (раздел ITE в HWiNFO и AIDA64, драйвер it87 в Linux): они покажут ерунду и могут мешать вентилятору.
  Температуру процессора смотрите по датчику самого процессора («CPU» в HWiNFO, k10temp в Linux). Термозона ACPI
  («ACPI Thermal Zone» в Windows, acpitz в Linux) всегда показывает 0 °C: это заглушка, настоящих показаний в ней нет.
- **Linux пишет при загрузке `irq 7: nobody cared`.** Безвредно: Linux отключает это прерывание, всё остальное работает.
  В Windows такого нет.
- **DASH** (удалённое управление). Встроенная программа сетевой карты 2016 года, в ней есть известные дыры.
  Не включайте DASH без надобности. Если нужен — только на прямом кабеле к своему компьютеру или в отдельной сети без
  выхода в интернет. Вход в DASH защищён заводским паролем, одинаковым у всех таких карт, а сменить его в нашем меню
  пока нельзя: любой, кто подключён к той же сети, может управлять компьютером.
- **Разгон** процессора и графики пока выключен: защита от неудачного разгона ещё не проверена.
- **Меню загрузки F9: диск (например, Windows Boot Manager) запускается через одну перезагрузку.** Компьютер
  перезапускается и грузится с выбранного диска. Флешки запускаются сразу. Запуск дисков без перезагрузки — в T2.
- **DASH: удалённое включение, выключение и перезагрузка в Linux.** Драйвер SMBus в Linux (`i2c_piix4`) при загрузке
  трогает ту же шину, по которой карта DASH передаёт команды питания, и они перестают доходить. Обход: параметр ядра
  `module_blacklist=i2c_piix4` (при этом в Linux не будут видны данные модулей памяти по SMBus). В Windows без программ,
  которые опрашивают SMBus (HWiNFO, AIDA64 и подобные), это не мешает. В следующей версии прошивка спрячет эту шину
  от системы сама. Экран BIOS в текстовой консоли DASH пока не работает. Подключение ISO по сети работает, но не со всяким
  HTTP-сервером: карта ждёт, что заголовок ответа и начало файла придут одним пакетом (простой `python3 -m http.server` так
  не делает, и карта бросает подключение). Готовый скрипт: [tools/dash](../tools/dash/README.md).
- **Проверено только на плате AM4P2MS ревизии 1.1 и только с Ryzen 3 2200G.** Другие ревизии платы, другие процессоры
  и четыре планки памяти ещё никто не проверял.
- **Не всякая память заводится на этой плате.** Одноранговый модуль 16 ГБ на чипах 16 Гбит (AMD R7 16G DDR4-2666, чипы
  Nanya) не стартует на ней ни с одной прошивкой, включая родную Lenovo: писки и перезагрузка по кругу. Не помогает и
  пониженная частота (2133, 2T). На платах Intel тот же модуль работает. Обычные модули (на чипах 8 Гбит) работают.
- **Ручная частота памяти:** перед каждым запуском системы одна лишняя перезагрузка (несколько секунд, система потом
  работает нормально). Причина найдена — модуль AMD каждый раз пересобирает настройки памяти; исправление — в T2.
- **«3G» памяти для графики при включённом CSM** опасен — см. [ограничения платы](LIMITS.md), раздел 4.

---

# Known issues

- **T1 and Windows: blue screen ACPI_BIOS_ERROR — fixed in T1.1.** If you have T1, update to T1.1 from the menu with a USB
  stick. If the computer hangs on the logo after the blue screen, hold the power button for 5 seconds, turn it on again,
  press Del and update.
- **Ryzen 4000G and Windows: slowdowns after a restart** (reported by a tester with a Ryzen 5 4600G). After Restart, Windows
  keeps the processor busy for nothing and Task Manager shows an uptime of about 10675199 days. Workaround for now: instead
  of Restart, shut the computer down and turn it on again. A fix is being tested.
- **Passive DisplayPort → HDMI adapter: no high refresh rate.** Both of the board's sockets work as real DisplayPort (as
  Lenovo has them), and with a passive adapter the AMD driver caps the refresh rate at the adapter's rated limit: for
  1440p usually 60–75 Hz. For 144 Hz use a DP→DP cable (if the monitor has a DisplayPort input) or an active DP 1.4 →
  HDMI 2.0 adapter. T2 adds a menu choice, "HDMI through an adapter", for the second socket.
- **Windows may ask to be activated again.** The new BIOS gives the board a different name and does not carry the
  Windows key Lenovo put in its BIOS. Enter your key or sign in to the Microsoft account your licence is linked to.
  Your key stays in the saved copy of Lenovo's BIOS.
- **The board has a different name.** System information shows it under the name of the Biostar board the firmware is
  based on. It does not affect how anything works.
- **Programs that show temperatures and fan speeds.** With the Ryzen 3 2200G, talking to the board's sensor chip
  (ITE IT8738) sometimes fails. That is a quirk of the processor, and the firmware works around it. Do not turn on that
  chip's sensors in such programs (the ITE section in HWiNFO and AIDA64, the it87 driver on Linux): they will show
  nonsense and can get in the fan's way. Read the processor temperature from the processor's own sensor ("CPU" in
  HWiNFO, k10temp on Linux). The ACPI thermal zone ("ACPI Thermal Zone" in Windows, acpitz on Linux) always reads 0 °C:
  it is a placeholder with no real reading behind it.
- **Linux prints `irq 7: nobody cared` at boot.** Harmless: Linux turns that interrupt off and everything else works.
  Windows does not have this.
- **DASH** (remote management). The network card's built-in program is from 2016 and has known holes. Do not turn DASH
  on unless you need it. If you do, use it only on a direct cable to your own computer or on a separate network with no
  internet access. DASH sign-in uses the factory password that every such card shares, and our menu cannot change it
  yet: anyone on the same network can control the computer.
- **Overclocking** of the processor and graphics is off for now: the protection against a failed overclock has not been
  tested yet.
- **F9 boot menu: a disk (Windows Boot Manager, for example) starts through one restart.** The computer restarts and
  boots from the chosen disk. USB sticks start at once. Starting disks without a restart comes in T2.
- **DASH remote power on, power off and restart on Linux.** Linux's SMBus driver (`i2c_piix4`) touches, at boot, the same
  bus the DASH card sends its power commands over, and they stop getting through. Workaround: the kernel parameter
  `module_blacklist=i2c_piix4` (Linux then cannot read the memory sticks' data over SMBus). On Windows it does no harm
  as long as no program polls the SMBus (HWiNFO, AIDA64 and the like). The next version will hide this bus from the
  system by itself. The BIOS screen in the DASH text console does not work yet. Attaching an ISO over the network works, but
  not with every HTTP server: the card expects a reply's headers and the start of the file in one packet (a plain
  `python3 -m http.server` does not do that, and the card gives up). A ready script: [tools/dash](../tools/dash/README.md).
- **Tested only on an AM4P2MS revision 1.1 board and only with the Ryzen 3 2200G.** Nobody has tried other board revisions,
  other processors or four memory sticks yet.
- **Not every memory stick starts on this board.** A single-rank 16 GB stick built on 16 Gbit chips (AMD R7 16G
  DDR4-2666, Nanya chips) does not start on it with any firmware, Lenovo's own included: beeps and a restart in a loop.
  A lower speed (2133, 2T) does not help either. The same stick works on Intel boards. Ordinary sticks (on 8 Gbit chips)
  work.
- **Manual memory speed:** one extra restart before every start of the system (a few seconds; the system then runs
  normally). The cause is found: an AMD module rebuilds the memory settings every time; the fix comes in T2.
- **"3G" of graphics memory with CSM on** is dangerous, see [board limits](LIMITS.md), section 4.
