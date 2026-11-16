# Отчёт о проблеме / Problem reports

Есть три инструмента, каждый ловит своё:

| Инструмент | Где запускается | Что показывает |
|---|---|---|
| **Отчёт из BIOS (F11)** | в меню BIOS, даже если Windows не загружается | что было при включении: где остановился запуск, почему плата перезагрузилась, ошибки процессора и памяти |
| **Скрипт для Windows или Linux** | в работающей системе | что было в системе: синие экраны, внезапные выключения, устройства без драйверов, ошибки дисков и видео |
| **[Тест-флешка](https://github.com/airtwist223/z3novo/releases/tag/TestStick-1.4)** | загрузка с флешки, без Windows | сама гоняет тесты (нагрузка, память, сон, серия перезагрузок) и собирает всё сразу; для редких и непонятных сбоев |

**Что прикладывать:**
1. **Всегда** — отчёт из BIOS (F11).
2. **Если Windows или Linux запускаются** — ещё отчёт скрипта.
3. **Если сбой редкий и непонятный** — папку с результатами [тест-флешки](#тест-флешка).

## Отчёт из BIOS (F11)

1. Вставьте флешку (FAT32, свободно хотя бы 2 МБ). Флешка exFAT не подойдёт: на неё прошивка не пишет.
2. Включите компьютер и нажмите **Del** — откроется меню настроек.
3. Нажмите **F11**. То же самое — с T2.0 кнопка «F11 Отчёт» в строке внизу экрана или «Отчёт для диагностики» в окне
   «Состояние»; в T1.x — ссылка внизу главного экрана или первая строка на странице «Состояние».
4. Меню покажет, как идёт сбор, и имя файла. Файл появится на флешке: `\Z3NOVO\REPORT-<дата>-<время>.TXT`. С T2.0 в
   том же окне — QR-коды, куда отправить отчёт: Telegram-бот [@z3novo_bot](https://t.me/z3novo_bot) и GitHub.

Что в отчёте: сводка (процессор, память по слотам, температура и вентилятор), журнал последних 16 включений — какое
дошло до системы, а какое остановилось и на каком шаге, причины последних перезагрузок, ошибки процессора и памяти,
которые сохраняются даже после перезагрузки; ниже — подробные данные для разбора. Отчёт только читает: ничего не меняет
ни в BIOS, ни в настройках.

С T2.0 в отчёте есть ещё: каналы памяти (если планка стоит, но не используется, — прямо так), восстановлена ли память из
сохранённого или обучена заново, за сколько открылось меню; строки «Напряжения / voltages»
([что они значат](#напряжения-aida64-и-hwinfo)), «Вентиляторы / fans» и «Выходы вентиляторов / fan outputs» (обороты
FAN1–FAN3 и кто ведёт каждый выход); строка «меню загружено как файл тома прошивки (FvFile, нужно для Secure Boot)» — её
смотрят перед включением безопасной загрузки ([по шагам](#secure-boot-по-шагам)).

**Если компьютер зависает при включении:** после зависания включите его снова, нажмите Del и F11 — в отчёте будет видно,
где остановился предыдущий запуск.

## Скрипт для Windows или Linux

Скрипт [`z3report.ps1`](../tools/report/z3report.ps1) для Windows или [`z3report.sh`](../tools/report/z3report.sh) для Linux
собирает журналы сбоев за 30 дней в один файл. Как запустить — [tools/report/README.md](../tools/report/README.md).
На время тестов прошивки выключите в Windows быстрый запуск (Панель управления → Электропитание → Действия кнопок питания
→ снять «Включить быстрый запуск»): иначе «Завершение работы» — не полное выключение, и часть проверок будет неверной.

## Тест-флешка

[Скачать тест-флешку](https://github.com/airtwist223/z3novo/releases/tag/TestStick-1.4) — маленький Linux, который
загружается с флешки, сам собирает сведения и гоняет проверки, а результаты пишет на ту же флешку. Windows и ваши диски
он не трогает, в прошивку и настройки BIOS ничего не пишет.

1. **Записать флешку** — любой из трёх способов:
   - **Ventoy:** положите файл `Z3NOVO-TestStick-1.4.iso` на флешку Ventoy (имя должно начинаться с `Z3NOVO`);
   - **архив:** распакуйте `Z3NOVO-TestStick-1.4.zip` на флешку FAT32, чтобы в её корне были папки `EFI` и `Z3NOVO`;
   - **образ:** запишите `Z3NOVO-TestStick-1.4.img` программой Rufus или balenaEtcher (сотрёт флешку).
2. **Загрузиться с неё:** F9 (прошивка Z3NOVO) или F12 (родной BIOS Lenovo) и выберите флешку.
3. **Выбрать проверку** (клавиши 1–5) или ничего не нажимать: через 10 секунд начнётся «Только сведения» — 1–2 минуты,
   без нагрузки и без сна; потом компьютер выключится сам. Клавиатура для этого не нужна.
4. **Прислать** папку `Z3NOVO\TEST-…` с флешки целиком (можно в zip). Главный файл — `SUMMARY.TXT`, итог простыми словами;
   там же карта разъёмов: какие USB, SATA, гнёзда звука и видеовыходы работают.

Подробно о каждой проверке — в `README.md` рядом с файлами флешки.

Тест-флешка не подписана, поэтому с включённой безопасной загрузкой (Secure Boot) она не запустится: на время проверки
выключите безопасную загрузку.

## Перегрев или медленная работа в Windows

Скрипт температуры не читает, поэтому для таких проблем нужен журнал датчиков:

1. Скачайте бесплатную программу **HWiNFO64** с её официального сайта и запустите в режиме **Sensors-only** (только
   датчики).
2. Если в её настройках есть опрос **Super I/O / EC**, выключите его: на этой плате обращения к микросхеме Super I/O
   под нагрузкой могут мешать работе. Нужны только датчики процессора (CPU, Tctl/Tdie), видеокарты и дисков.
3. Внизу окна датчиков нажмите кнопку записи журнала (**Logging Start**) и сохраните файл.
4. Сделайте то, при чём проблема появляется (игра, нагрузка, простой), 10–15 минут, потом остановите запись.
5. Приложите файл журнала (CSV) к сообщению.

## Напряжения, AIDA64 и HWiNFO

**+12 В и +5 В на этой плате не измеряются вовсе.** Микросхема датчиков (ITE IT8738) не подключена к +12 В, +5 В и
напряжению процессора. Строки, которые программы подписывают «+12V», «+5V», «Vcore» или «CPU Core», показывают случайные
числа (например, 7–17 В «на +12»). С родным BIOS Lenovo было так же. Блок питания в порядке, а исправить эти строки
нельзя никаким множителем — их нужно просто скрыть.

Настоящих измерений на этой плате три, и все около 3 вольт: питание +3,3 В, дежурное +3,3 В и батарейка CMOS. С T2.0 их
верные значения видны в окне **«Состояние»** нашего меню (F3 — подробности) и в отчёте F11. Если батарейка ниже 2,7 В,
её (CR2032) пора менять: иначе после отключения от розетки могут сбрасываться настройки и часы.

Лучше смотреть напряжения в нашем меню и не включать датчики этой микросхемы в программах
([известные проблемы](KNOWN_ISSUES.md)). Если всё же включили:
- **HWiNFO** (окно «Sensors»): строки +12V, +5V и Vcore от «ITE IT8738» — правой кнопкой → «Hide» (скрыть).
- **AIDA64** («Компьютер» → «Датчики»): строки +12 В, +5 В и «ЦП» от IT8738 не исправляются — не обращайте на них
  внимания и не выводите их на панель датчиков.
- **Linux** (`sensors`, драйвер it87): строки in0–in5 — те же неподключённые входы.

Какая строка программы какому входу соответствует, мы знаем пока только по устройству микросхемы. Если пришлёте снимок
окна HWiNFO или AIDA64 и снимок «Состояния» Z3NOVO, сделанные один за другим, — допишем сюда точное соответствие.

## Вентиляторы FAN2 и FAN3

С T2.0 прошивка ведёт по температуре процессора не только вентилятор процессора (FAN1), но и вентиляторы на двух других
разъёмах платы: FAN2 (у Lenovo — System fan) и FAN3 (Aux fan). Раньше они крутились на постоянных средних оборотах.

- **Где настроить:** Классика → Питание → «Вентилятор корпуса (FAN2)» и «Доп. вентилятор (FAN3)», у каждого «Тихо /
  Авто / Макс» (по умолчанию «Авто»). Они тише процессорного: в простое около 30–35 %, с нагревом процессора обороты
  растут, с 85 °C — полные. Эти строки действуют, когда «Управление вентилятором» стоит «Прошивкой»; при «Микросхемой» эти
  вентиляторы ведёт сама микросхема по температуре процессора.
- **Где видно:** в окне «Состояние» — дорожки FAN2 и FAN3 (появляются, когда на разъёме есть вентилятор), в отчёте F11 —
  строки «Вентиляторы» и «Выходы вентиляторов».
- **Какой разъём — FAN2, а какой — FAN3,** мы вывели из прошивки Lenovo; на плате автора к ним ничего не подключено, так
  что это ещё не проверено. Чтобы узнать у себя: поставьте одному вентилятору «Макс», а другому «Тихо» и посмотрите в
  «Состоянии», какая дорожка выросла.
- **Если вентилятор не слушается своей строки** (стоит, всё время на полных или на средних), пришлите отчёт F11, снятый
  при работающем вентиляторе, и напишите, в какой разъём он включён.

## Secure Boot по шагам

С T2.0 безопасная загрузка включается в нашем меню: Классика → Безопасность → «Ключи Secure Boot». **На плате автора
этот порядок ещё не проверялся** — если решите включать, сначала сделайте копию микросхемы и будьте готовы вернуть её
программатором.

**0. Подготовка.**
- **Копия микросхемы BIOS.** Меню сохраняет её на флешку при обновлении прошивки; или прочитайте микросхему
  программатором ([как](FLASHING.md)).
- **BitLocker.** Если в Windows включён BitLocker или «Шифрование устройства», заранее сохраните ключ восстановления:
  включение и выключение безопасной загрузки меняют измерения TPM, и Windows может его попросить.

**1. Проверка.** Нажмите F11 и откройте отчёт: там должна быть строка «меню загружено как файл тома прошивки (FvFile,
нужно для Secure Boot): **да**». Если «нет» — безопасную загрузку не включайте, а пришлите этот отчёт: иначе наше меню
при ней может не открыться.

**2. Ключи.** «Ключи Secure Boot» → «Записать ключи по умолчанию…» и подтвердите. Без ключей безопасная загрузка не
действует.

**3. Включение.** Там же «Включить безопасную загрузку», затем F10 → «Сохранить и перезагрузить». Окна «Сохранено не
всё» быть не должно.

**4. После перезагрузки.** Del открывает наше меню; в «Ключах Secure Boot» безопасная загрузка действует. Windows
грузится как обычно; проверить: «Сведения о системе» (`msinfo32`) → «Состояние безопасной загрузки: Вкл». Неподписанные
флешки (например, тест-флешка) теперь не запускаются — так и должно быть.

**Выключить:** «Ключи Secure Boot» → «Выключить безопасную загрузку» → F10. Или «Удалить все ключи…»: без ключей
безопасная загрузка не действует.

**Если по Del вместо меню появился текст «The on-screen menu could not start»** и компьютер перезагружается — прошивка не
пропустила наше меню проверкой подписи. Пришлите отчёт (или фото) и верните копию микросхемы программатором. Сброс
настроек батарейкой, скорее всего, тоже выключит безопасную загрузку, но этот путь мы ещё не проверяли.

## Если компьютер не включается совсем

Отчёт тогда снять нечем, поэтому важно то, что вы видите. Запишите:
- горит ли лампочка питания, крутится ли вентилятор, пищит ли компьютер, есть ли что-то на экране;
- что меняли перед этим: настройки, частоту памяти, процессор, планки, видеокарту, обновляли ли BIOS.

Потом попробуйте по порядку:
1. Выключите, выньте шнур из розетки на минуту, включите снова.
2. Если меняли память или её частоту — подождите пару минут: после трёх неудачных попыток плата сама запускается на
   безопасных настройках.
3. Сбросьте настройки BIOS: выключите, выньте шнур и круглую батарейку на плате на 5 минут. Все настройки вернутся
   к заводским, а записи Windows и Linux в меню загрузки пропадут.

   ⚠️ Если после шага 1 или 2 компьютер включился — **сначала сделайте отчёт F11**, и только потом, если нужно,
   сбрасывайте настройки. Сброс батарейкой стирает журнал запусков, по которому видна причина.
4. Если не помогло — верните родной BIOS программатором (см. [FLASHING.md](FLASHING.md)).

## Что в отчёты не попадает

Серийные номера, UUID, MAC-адреса (только первые три байта), ключ Windows, пароли, имя компьютера и пользователей.
Перед отправкой всё равно откройте файлы и проверьте их.

## Что написать вместе с отчётами

Что делали, что ожидали, что произошло; процессор, планки памяти, видеокарта; версия Z3NOVO (видна в заголовке меню).

Куда отправлять: раздел **Issues** на странице проекта на GitHub → **New issue** → форма «Проблема». В ней уже есть все нужные вопросы и место для файлов отчётов.
Можно и через Telegram-бот [@z3novo_bot](https://t.me/z3novo_bot): он примет описание и файлы отчётов.

Если у вас **всё работает** — тоже расскажите: **New issue** → форма «Всё работает». По таким сообщениям собирается список проверенных процессоров, памяти и видеокарт.

---

# Problem reports

There are three tools, and each catches something different:

| Tool | Where it runs | What it shows |
|---|---|---|
| **BIOS report (F11)** | in the BIOS menu, even if Windows does not start | what happened at power-on: where a start stopped, why the board restarted, processor and memory errors |
| **Windows or Linux script** | in the running system | what happened in the system: blue screens, unexpected shutdowns, devices without drivers, disk and video errors |
| **[Test stick](https://github.com/airtwist223/z3novo/releases/tag/TestStick-1.4)** | boots from a USB stick, no Windows needed | runs tests by itself (load, memory, sleep, a series of restarts) and collects everything at once; for rare and puzzling failures |

**What to attach:**
1. **Always** — the BIOS report (F11).
2. **If Windows or Linux starts** — the script report as well.
3. **If the failure is rare and puzzling** — the [test stick](#test-stick)'s results folder.

## BIOS report (F11)

1. Plug in a USB stick (FAT32, at least 2 MB free). An exFAT stick will not do: the firmware does not write to it.
2. Power on and press **Del** — the settings menu opens.
3. Press **F11**. The same thing: from T2.0 the "F11 Report" button in the line at the bottom of the screen, or "Diagnostics
   report" in the Health window; on T1.x the link at the bottom of the home screen, or the first line of the Health page.
4. The menu shows the progress and the file name. The file appears on the stick: `\Z3NOVO\REPORT-<date>-<time>.TXT`.
   From T2.0 the same window shows QR codes for where to send the report: the Telegram bot
   [@z3novo_bot](https://t.me/z3novo_bot) and GitHub.

What is in it: a summary (processor, memory by slot, temperature and fan), the log of the last 16 power-ons — which ones
reached the system and which stopped and at what step, the reasons for the last restarts, processor and memory errors
that survive a restart; below that, detailed data for analysis. The report only reads: it changes nothing in the BIOS or
the settings.

From T2.0 the report also has (it is mostly in Russian; line names as they appear): the memory channels (a stick that is
in place but not in use is named as such), whether the memory was restored from the saved setup or trained anew, how
long the menu took to open; the "Напряжения / voltages" line ([what it means](#voltages-aida64-and-hwinfo)), the
"Вентиляторы / fans" and "Выходы вентиляторов / fan outputs" lines (the FAN1–FAN3 speeds and what drives each output);
the line «меню загружено как файл тома прошивки (FvFile, нужно для Secure Boot)» ("the menu was loaded as a firmware
volume file"), to check before turning Secure Boot on ([step by step](#secure-boot-step-by-step)).

**If the computer hangs at power-on:** after the hang, power it on again, press Del and F11 — the report shows where the
previous start stopped.

## Windows or Linux script

The [`z3report.ps1`](../tools/report/z3report.ps1) script for Windows or [`z3report.sh`](../tools/report/z3report.sh) for
Linux gathers 30 days of crash logs into one file. How to run them: [tools/report/README.md](../tools/report/README.md).
While testing the firmware, turn off Windows Fast Startup (Control Panel → Power Options → Choose what the power buttons
do → untick "Turn on fast startup"): otherwise "Shut down" is not a full shutdown and some checks will be wrong.

## Test stick

[Download the test stick](https://github.com/airtwist223/z3novo/releases/tag/TestStick-1.4): a small Linux that starts
from a USB stick, collects the details and runs checks by itself, and writes the results to the same stick. It does not
touch Windows or your disks and writes nothing to the firmware or the BIOS settings.

1. **Make the stick**, any of three ways:
   - **Ventoy:** copy `Z3NOVO-TestStick-1.4.iso` onto the Ventoy stick (the name must start with `Z3NOVO`);
   - **archive:** unpack `Z3NOVO-TestStick-1.4.zip` onto a FAT32 stick so that `EFI` and `Z3NOVO` sit at its top level;
   - **image:** write `Z3NOVO-TestStick-1.4.img` with Rufus or balenaEtcher (this erases the stick).
2. **Start from it:** F9 (Z3NOVO firmware) or F12 (stock Lenovo BIOS) and pick the stick.
3. **Pick a check** (keys 1–5) or press nothing: after 10 seconds "Information only" starts — 1–2 minutes, no load and
   no sleep; then the computer switches itself off. No keyboard needed for that.
4. **Send** the `Z3NOVO\TEST-…` folder from the stick, whole (zipped is fine). The main file is `SUMMARY.TXT`, the result
   in plain words; it also has the port map: which USB, SATA, sound jacks and video outputs work.

Each check is described in `README.md` next to the stick files.

The test stick is not signed, so it does not start with Secure Boot on: turn Secure Boot off for the test.

## Overheating or slowness in Windows

The script does not read temperatures, so for these problems a sensor log is needed:

1. Download the free **HWiNFO64** from its official site and run it in **Sensors-only** mode.
2. If its settings have **Super I/O / EC** polling, turn it off: on this board, accessing the Super I/O chip under load can
   interfere with the computer. Only the processor (CPU, Tctl/Tdie), graphics card and drive sensors are needed.
3. At the bottom of the sensors window press the log button (**Logging Start**) and save the file.
4. Do whatever brings the problem on (a game, a load, idling) for 10–15 minutes, then stop the log.
5. Attach the log file (CSV) to your report.

## Voltages, AIDA64 and HWiNFO

**+12 V and +5 V are not measured on this board at all.** The sensor chip (ITE IT8738) is not connected to +12 V, +5 V
or the processor voltage. The lines the programs label "+12V", "+5V", "Vcore" or "CPU Core" show random numbers (for
example 7–17 V "on +12"). It was the same with Lenovo's own BIOS. The power supply is fine, and no multiplier can fix
those lines: just hide them.

This board measures three things, all around 3 volts: the +3.3 V supply, the +3.3 V standby and the CMOS battery. From
T2.0 their right values are shown in our menu's **Health** window (F3 for details) and in the F11 report. If the battery
is below 2.7 V, it is time to replace it (CR2032): otherwise the settings and the clock may reset once the computer is
unplugged.

It is better to read the voltages in our menu and not to turn on this chip's sensors in programs
([known issues](KNOWN_ISSUES.md#known-issues)). If you did turn them on:
- **HWiNFO** (the Sensors window): the +12V, +5V and Vcore lines of "ITE IT8738": right click → Hide.
- **AIDA64** (Computer → Sensor): the +12 V, +5 V and CPU Core lines of the IT8738 cannot be fixed; ignore them and keep
  them off the sensor panel.
- **Linux** (`sensors`, the it87 driver): in0–in5 are the same unconnected inputs.

Which program line matches which input we know so far only from how the chip is built. If you send a screenshot of
HWiNFO or AIDA64 and one of Z3NOVO's Health window, taken one after the other, we will add the exact match here.

## FAN2 and FAN3 fans

From T2.0 the firmware drives by the processor's temperature not only the processor fan (FAN1) but also the fans on the
board's two other headers: FAN2 (Lenovo's System fan) and FAN3 (Aux fan). Before, they ran at a fixed medium speed.

- **Where to set them:** Classic → Power → "Case fan (FAN2)" and "Auxiliary fan (FAN3)", each with Quiet / Auto / Max
  (Auto by default). They are quieter than the processor fan: about 30–35 % at idle, the speed rises as the processor
  heats, full from 85 °C. These items apply while Fan control is "By firmware"; with "By the chip" the chip runs these
  fans itself by the processor's temperature.
- **Where to see them:** in the Health window, the FAN2 and FAN3 lanes (they appear once a fan is on the header); in the
  F11 report, the "fans" and "fan outputs" lines.
- **Which header is FAN2 and which is FAN3** we worked out from Lenovo's firmware; nothing is connected to them on the
  author's board, so it has not been tested yet. To find out on yours: set one fan to Max and the other to Quiet and see
  which lane in the Health window goes up.
- **If a fan does not follow its item** (stands still, or runs at full or medium speed all the time), send an F11 report
  taken with the fan running and say which header it is on.

## Secure Boot step by step

From T2.0 Secure Boot is turned on in our menu: Classic → Security → "Secure Boot keys". **This procedure has not been
tested on the author's board yet**: if you decide to turn it on, make a copy of the chip first and be ready to write it
back with a programmer.

**0. Preparation.**
- **A copy of the BIOS chip.** The menu saves one to the stick when it updates the firmware; or read the chip with a
  programmer ([how](FLASHING.md#first-install)).
- **BitLocker.** If BitLocker or "Device encryption" is on in Windows, save the recovery key first: turning Secure Boot
  on or off changes the TPM measurements, and Windows may ask for it.

**1. Check.** Press F11 and open the report: it must have the line «меню загружено как файл тома прошивки (FvFile,
нужно для Secure Boot): **да**» ("yes"). If it says «нет» ("no"), do not turn Secure Boot on; send that report instead,
because otherwise our menu may not open with it.

**2. Keys.** "Secure Boot keys" → "Install default keys…" and confirm. Without keys Secure Boot does nothing.

**3. Turning it on.** In the same place, "Turn Secure Boot on", then F10 → "Save and restart". There should be no "Not
everything was saved" window.

**4. After the restart.** Del opens our menu; "Secure Boot keys" shows Secure Boot in effect. Windows starts as usual;
to check: System Information (`msinfo32`) → "Secure Boot State: On". Unsigned USB sticks (the test stick, for example)
no longer start, as expected.

**To turn it off:** "Secure Boot keys" → "Turn Secure Boot off" → F10. Or "Delete all keys…": without keys Secure Boot
does nothing.

**If Del brings the text "The on-screen menu could not start" instead of the menu** and the computer restarts, the
firmware's signature check did not let our menu through. Send a report (or a photo) and write the chip copy back with a
programmer. Resetting the settings with the battery will most likely turn Secure Boot off too, but we have not tested
that way yet.

## If the computer does not start at all

Then there is no way to make a report, so what you see matters. Write down:
- whether the power light is on, the fan spins, the computer beeps, anything is on the screen;
- what you changed before: settings, memory speed, processor, sticks, graphics card, whether you updated the BIOS.

Then try, in this order:
1. Shut it down, unplug the cord for a minute, power it on again.
2. If you changed the memory or its speed, wait a couple of minutes: after three failed attempts the board starts by
   itself on safe settings.
3. Reset the BIOS settings: shut down, unplug the cord and take out the round battery on the board for 5 minutes. All
   settings go back to factory values, and the Windows and Linux entries in the boot menu disappear.

   ⚠️ If the computer starts after step 1 or 2, **make the F11 report first**, and only then reset the settings if needed.
   The battery reset erases the boot log that shows the cause.
4. If that does not help, go back to Lenovo's BIOS with a programmer (see [FLASHING.md](FLASHING.md)).

## What the reports leave out

Serial numbers, UUIDs, MAC addresses (only the first three bytes), the Windows key, passwords, computer and user names.
Open the files and check them before you send them anyway.

## What to write along with the reports

What you did, what you expected, what happened; your processor, memory sticks and graphics card; the Z3NOVO version
(shown in the menu's header).

Where to send them: **Issues** on the project's GitHub page → **New issue** → the "Problem" form. It already asks everything we need and has room for the report files.
The Telegram bot [@z3novo_bot](https://t.me/z3novo_bot) works too: it takes a description and the report files.

If **everything works** for you, tell us too: **New issue** → the "Works for me" form. These reports build the list of tested processors, memory and graphics cards.
