# Известные проблемы / Known issues

- **T1 и Windows: синий экран ACPI_BIOS_ERROR — исправлено в T1.1.** Если у вас T1, обновитесь до T1.1 из меню с флешки.
  Если после синего экрана компьютер завис на заставке, держите кнопку питания 5 секунд, включите снова, нажмите Del и
  обновитесь.
- **Ryzen 4000G и 5000G: перезагрузка из Windows — исправлено в T1.1r.** В T1.1 после «Перезагрузки» Windows на
  Ryzen 4000G грузила процессор впустую, а «Время работы» в Диспетчере задач показывало около 10675199 дней; на 5000G
  перезагрузка зависала. Обновитесь до T1.1r. Пока стоит T1.1, вместо «Перезагрузки» выключайте компьютер и включайте
  снова.
- **Ryzen 5000G: выход из сна может зависнуть** (сообщение тестера с Ryzen 5 5600G и четырьмя разными планками памяти).
  Компьютер засыпает нормально, но при пробуждении зависает: вентиляторы крутятся, экран чёрный. Похоже, дело в памяти,
  которая работает выше своей паспортной скорости (см. следующий пункт); проверяем. Пока поставьте в Windows
  «Сон: никогда». Если компьютер завис — выдерните шнур из розетки на 30 секунд и включите снова.
- **Режим памяти «Авто» и планки разной скорости.** Если стоят планки на разную скорость (например, 2400 и 2666),
  «Авто» может выставить скорость быстрой планки: медленная тогда работает выше своей паспортной скорости, а при
  перезагрузке бывает лишний перезапуск. Пока выставьте вручную («Режим памяти» → «Вручную») частоту самой медленной
  планки. Исправление — в T2.
- **При включении три перезапуска подряд, потом не работают передние USB и два задних под сетевым разъёмом** — если
  в памяти CMOS платы остался мусор от прежней прошивки (такое было на одной плате). Наша прошивка принимает один из этих
  байтов за свою тестовую команду. Батарейка и шнур этот мусор не стирают. **Исправлено в T1.2:** при первом запуске
  прошивка сама стирает свои служебные байты, если их записала не она. Обновитесь.
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
- **Автор проверяет каждую версию только на своей плате AM4P2MS ревизии 1.1 с Ryzen 3 2200G.** Что тестеры проверили
  на других процессорах — в [списке проверенного](TESTED.md). Другие ревизии платы ещё никто не проверял.
- **Не всякая память заводится на этой плате.** Одноранговый модуль 16 ГБ на чипах 16 Гбит (AMD R7 16G DDR4-2666, чипы
  Nanya) не стартует на ней ни с одной прошивкой, включая родную Lenovo: писки и перезагрузка по кругу. Не помогает и
  пониженная частота (2133, 2T). На платах Intel тот же модуль работает. Обычные модули (на чипах 8 Гбит) работают.
  В паре с другой планкой компьютер запускается, но этот модуль не используется: Windows показывает всю память как
  установленную, а доступна только память второй планки, и работает один канал. В отчёте F11 это видно по строке
  «видно в карте памяти» (с T2 — прямо: «планка стоит, но не используется»).
- **Ручная частота памяти:** перед каждым запуском системы одна лишняя перезагрузка (несколько секунд, система потом
  работает нормально). Причина найдена — модуль AMD каждый раз пересобирает настройки памяти; исправление — в T2.
- **«3G» памяти для графики при включённом CSM** опасен — см. [ограничения платы](LIMITS.md), раздел 4.

---

# Known issues

- **T1 and Windows: blue screen ACPI_BIOS_ERROR — fixed in T1.1.** If you have T1, update to T1.1 from the menu with a USB
  stick. If the computer hangs on the logo after the blue screen, hold the power button for 5 seconds, turn it on again,
  press Del and update.
- **Ryzen 4000G and 5000G: restart from Windows — fixed in T1.1r.** On T1.1, after Restart, Windows on a Ryzen 4000G
  kept the processor busy for nothing and Task Manager showed an uptime of about 10675199 days; on a 5000G the restart
  hung. Update to T1.1r. While you are on T1.1, shut the computer down and turn it on again instead of Restart.
- **Ryzen 5000G: waking from sleep may hang** (reported by a tester with a Ryzen 5 5600G and four different memory
  sticks). The computer goes to sleep normally but hangs when it wakes: the fans spin, the screen stays black. It looks
  like memory running above its rated speed (see the next item); we are checking. For now set Windows to "Sleep: Never".
  If the computer hangs, pull the cord out of the wall socket for 30 seconds and turn it on again.
- **Memory mode "Auto" with sticks of different speeds.** With sticks rated for different speeds (2400 and 2666, for
  example), "Auto" may set the faster stick's speed: the slower one then runs above its rated speed, and a restart may
  bring an extra reset. For now set the slowest stick's speed by hand ("Memory mode" → "Manual"). The fix comes in T2.
- **Three restarts in a row at power-on, then the front USB sockets and the two rear ones under the network socket do
  not work** — when the board's CMOS memory still holds leftovers from a previous firmware (seen on one board). Our
  firmware takes one of those bytes for its own test command. The battery and the cord do not clear it. **Fixed in
  T1.2:** at its first start the firmware clears its own service bytes if it did not write them itself. Update.
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
- **The author tests every version only on the author's own AM4P2MS revision 1.1 board with a Ryzen 3 2200G.** What testers have
  checked on other processors is in [the tested list](TESTED.md). Nobody has tried other board revisions yet.
- **Not every memory stick starts on this board.** A single-rank 16 GB stick built on 16 Gbit chips (AMD R7 16G
  DDR4-2666, Nanya chips) does not start on it with any firmware, Lenovo's own included: beeps and a restart in a loop.
  A lower speed (2133, 2T) does not help either. The same stick works on Intel boards. Ordinary sticks (on 8 Gbit chips)
  work. Paired with another stick the computer starts, but this stick is not used: Windows lists all the memory as
  installed, only the other stick's memory is available, and one channel works. The F11 report shows it in the
  "visible in the memory map" line (from T2 directly: "stick present, not in use").
- **Manual memory speed:** one extra restart before every start of the system (a few seconds; the system then runs
  normally). The cause is found: an AMD module rebuilds the memory settings every time; the fix comes in T2.
- **"3G" of graphics memory with CSM on** is dangerous, see [board limits](LIMITS.md), section 4.
