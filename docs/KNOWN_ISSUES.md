# Известные проблемы / Known issues

- **Windows может попросить активацию заново.** Новый BIOS называет плату по-другому, и в нём нет ключа Windows,
  который Lenovo записала в родной BIOS. Введите свой ключ или войдите в учётную запись Microsoft, к которой привязана
  лицензия. Ваш ключ остаётся в сохранённой копии родного BIOS.
- **Плата называется по-другому.** В сведениях о системе она видна под именем платы Biostar, с которой взята основа
  прошивки. На работу это не влияет.
- **Программы, показывающие температуры и обороты.** С процессором Ryzen 3 2200G связь с микросхемой датчиков на плате
  (ITE IT8738) иногда сбоит — это особенность процессора, прошивка её обходит. Не включайте в таких программах датчики
  этой микросхемы (раздел ITE в HWiNFO и AIDA64, драйвер it87 в Linux): они покажут ерунду и могут мешать вентилятору.
  Температуру процессора смотрите по датчику самого процессора («CPU» в HWiNFO, k10temp в Linux).
- **DASH** (удалённое управление). Встроенная программа сетевой карты 2016 года, в ней есть известные дыры.
  Не включайте DASH без надобности. Если нужен — только на прямом кабеле к своему компьютеру или в отдельной сети без
  выхода в интернет. Вход в DASH защищён заводским паролем, одинаковым у всех таких карт, а сменить его в нашем меню
  пока нельзя: любой, кто подключён к той же сети, может управлять компьютером.
- **Разгон** процессора и графики в T1 выключен: защита от неудачного разгона ещё не проверена.
- **DASH: удалённое включение, выключение и перезагрузка в Linux.** Драйвер SMBus в Linux (`i2c_piix4`) при загрузке
  трогает ту же шину, по которой карта DASH передаёт команды питания, и они перестают доходить. Обход: параметр ядра
  `module_blacklist=i2c_piix4` (при этом в Linux не будут видны данные модулей памяти по SMBus). В Windows без программ,
  которые опрашивают SMBus (HWiNFO, AIDA64 и подобные), это не мешает. В следующей версии прошивка спрячет эту шину
  от системы сама. Экран BIOS в текстовой консоли DASH и подключение ISO по сети пока не работают.
- **Проверено только на плате AM4P2MS ревизии 1.1 и только с Ryzen 3 2200G.** Другие ревизии платы, другие процессоры
  и четыре планки памяти ещё никто не проверял.
- **Ручная частота памяти** может давать лишнюю перезагрузку при каждом втором включении. Проверяется.
- **«3G» памяти для графики при включённом CSM** опасен — см. [ограничения платы](LIMITS.md), раздел 4.

---

# Known issues

- **Windows may ask to be activated again.** The new BIOS gives the board a different name and does not carry the
  Windows key Lenovo put in its BIOS. Enter your key or sign in to the Microsoft account your licence is linked to.
  Your key stays in the saved copy of Lenovo's BIOS.
- **The board has a different name.** System information shows it under the name of the Biostar board the firmware is
  based on. It does not affect how anything works.
- **Programs that show temperatures and fan speeds.** With the Ryzen 3 2200G, talking to the board's sensor chip
  (ITE IT8738) sometimes fails. That is a quirk of the processor, and the firmware works around it. Do not turn on that
  chip's sensors in such programs (the ITE section in HWiNFO and AIDA64, the it87 driver on Linux): they will show
  nonsense and can get in the fan's way. Read the processor temperature from the processor's own sensor ("CPU" in
  HWiNFO, k10temp on Linux).
- **DASH** (remote management). The network card's built-in program is from 2016 and has known holes. Do not turn DASH
  on unless you need it. If you do, use it only on a direct cable to your own computer or on a separate network with no
  internet access. DASH sign-in uses the factory password that every such card shares, and our menu cannot change it
  yet: anyone on the same network can control the computer.
- **Overclocking** of the processor and graphics is off in T1: the protection against a failed overclock has not been
  tested yet.
- **DASH remote power on, power off and restart on Linux.** Linux's SMBus driver (`i2c_piix4`) touches, at boot, the same
  bus the DASH card sends its power commands over, and they stop getting through. Workaround: the kernel parameter
  `module_blacklist=i2c_piix4` (Linux then cannot read the memory sticks' data over SMBus). On Windows it does no harm
  as long as no program polls the SMBus (HWiNFO, AIDA64 and the like). The next version will hide this bus from the
  system by itself. The BIOS screen in the DASH text console and attaching an ISO over the network do not work yet.
- **Tested only on an AM4P2MS revision 1.1 board and only with the Ryzen 3 2200G.** Nobody has tried other board revisions,
  other processors or four memory sticks yet.
- **Manual memory speed** may cause an extra restart on every second power-on. Being checked.
- **"3G" of graphics memory with CSM on** is dangerous, see [board limits](LIMITS.md), section 4.
