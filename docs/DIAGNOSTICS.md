# Отчёт о проблеме / Problem reports

Есть три инструмента, каждый ловит своё:

| Инструмент | Где запускается | Что показывает |
|---|---|---|
| **Отчёт из BIOS (F11)** — с версии T1 | в меню BIOS, даже если Windows не загружается | что было при включении: где остановился запуск, почему плата перезагрузилась, ошибки процессора и памяти |
| **Скрипт для Windows или Linux** | в работающей системе | что было в системе: синие экраны, внезапные выключения, устройства без драйверов, ошибки дисков и видео |
| **Тест-флешка** — готовится | загрузка с флешки, без Windows | сама гоняет тесты (нагрузка, память, сон, серия перезагрузок) и собирает всё сразу; для редких и непонятных сбоев |

**Что прикладывать:**
1. **Всегда** — отчёт из BIOS (F11).
2. **Если Windows или Linux запускаются** — ещё отчёт скрипта.
3. **Если сбой редкий и непонятный** — папку с результатами тест-флешки.

## Отчёт из BIOS (F11)

Появится в версии T1.

1. Вставьте флешку (FAT32, свободно хотя бы 2 МБ).
2. Включите компьютер и нажмите **Del** — откроется меню настроек.
3. Нажмите **F11**. То же самое — ссылка «Отчёт для диагностики» внизу главного экрана или первая строка на странице
   «Состояние».
4. Меню покажет, как идёт сбор, и имя файла. Файл появится на флешке: `\Z3NOVO\REPORT-<дата>-<время>.TXT`.

Что в отчёте: сводка (процессор, память по слотам, температура и вентилятор), журнал последних 16 включений — какое
дошло до системы, а какое остановилось и на каком шаге, причины последних перезагрузок, ошибки процессора и памяти,
которые сохраняются даже после перезагрузки; ниже — подробные данные для разбора. Отчёт только читает: ничего не меняет
ни в BIOS, ни в настройках.

**Если компьютер зависает при включении:** после зависания включите его снова, нажмите Del и F11 — в отчёте будет видно,
где остановился предыдущий запуск.

## Скрипт для Windows или Linux

Скрипт [`z3report.ps1`](../tools/report/z3report.ps1) для Windows или [`z3report.sh`](../tools/report/z3report.sh) для Linux
собирает журналы сбоев за 30 дней в один файл. Как запустить — [tools/report/README.md](../tools/report/README.md).
На время тестов прошивки выключите в Windows быстрый запуск (Панель управления → Электропитание → Действия кнопок питания
→ снять «Включить быстрый запуск»): иначе «Завершение работы» — не полное выключение, и часть проверок будет неверной.

## Перегрев или медленная работа в Windows

Скрипт температуры не читает, поэтому для таких проблем нужен журнал датчиков:

1. Скачайте бесплатную программу **HWiNFO64** с её официального сайта и запустите в режиме **Sensors-only** (только
   датчики).
2. Если в её настройках есть опрос **Super I/O / EC**, выключите его: на этой плате обращения к микросхеме Super I/O
   под нагрузкой могут мешать работе. Нужны только датчики процессора (CPU, Tctl/Tdie), видеокарты и дисков.
3. Внизу окна датчиков нажмите кнопку записи журнала (**Logging Start**) и сохраните файл.
4. Сделайте то, при чём проблема появляется (игра, нагрузка, простой), 10–15 минут, потом остановите запись.
5. Приложите файл журнала (CSV) к сообщению.

## Если компьютер не включается совсем

Отчёт тогда снять нечем, поэтому важно то, что вы видите. Запишите:
- горит ли лампочка питания, крутится ли вентилятор, пищит ли компьютер, есть ли что-то на экране;
- что меняли перед этим: настройки, частоту памяти, процессор, планки, видеокарту, обновляли ли BIOS.

Потом попробуйте по порядку:
1. Выключите, выньте шнур из розетки на минуту, включите снова.
2. Если меняли память или её частоту — подождите пару минут: после трёх неудачных попыток плата сама запускается на
   безопасных настройках.
3. Сбросьте настройки BIOS: выключите, выньте шнур и круглую батарейку на плате на 5 минут. Все настройки вернутся
   к заводским.

   ⚠️ Если после шага 1 или 2 компьютер включился — **сначала сделайте отчёт F11**, и только потом, если нужно,
   сбрасывайте настройки. Сброс батарейкой стирает журнал запусков, по которому видна причина.
4. Если не помогло — верните родной BIOS программатором (см. [FLASHING.md](FLASHING.md)).

## Что в отчёты не попадает

Серийные номера, UUID, MAC-адреса (только первые три байта), ключ Windows, пароли, имя компьютера и пользователей.
Перед отправкой всё равно откройте файлы и проверьте их.

## Что написать вместе с отчётами

Что делали, что ожидали, что произошло; процессор, планки памяти, видеокарта; версия Z3NOVO (видна в заголовке меню).

Куда отправлять: раздел **Issues** на странице проекта на GitHub → **New issue** → форма «Проблема». В ней уже есть все нужные вопросы и место для файлов отчётов.

Если у вас **всё работает** — тоже расскажите: **New issue** → форма «Всё работает». По таким сообщениям собирается список проверенных процессоров, памяти и видеокарт.

---

# Problem reports

There are three tools, and each catches something different:

| Tool | Where it runs | What it shows |
|---|---|---|
| **BIOS report (F11)** — from version T1 | in the BIOS menu, even if Windows does not start | what happened at power-on: where a start stopped, why the board restarted, processor and memory errors |
| **Windows or Linux script** | in the running system | what happened in the system: blue screens, unexpected shutdowns, devices without drivers, disk and video errors |
| **Test stick** — in preparation | boots from a USB stick, no Windows needed | runs tests by itself (load, memory, sleep, a series of restarts) and collects everything at once; for rare and puzzling failures |

**What to attach:**
1. **Always** — the BIOS report (F11).
2. **If Windows or Linux starts** — the script report as well.
3. **If the failure is rare and puzzling** — the test stick's results folder.

## BIOS report (F11)

Arrives in version T1.

1. Plug in a USB stick (FAT32, at least 2 MB free).
2. Power on and press **Del** — the settings menu opens.
3. Press **F11**. The same thing: the "Diagnostics report" link at the bottom of the home screen, or the first line of the
   "Status" page.
4. The menu shows the progress and the file name. The file appears on the stick: `\Z3NOVO\REPORT-<date>-<time>.TXT`.

What is in it: a summary (processor, memory by slot, temperature and fan), the log of the last 16 power-ons — which ones
reached the system and which stopped and at what step, the reasons for the last restarts, processor and memory errors
that survive a restart; below that, detailed data for analysis. The report only reads: it changes nothing in the BIOS or
the settings.

**If the computer hangs at power-on:** after the hang, power it on again, press Del and F11 — the report shows where the
previous start stopped.

## Windows or Linux script

The [`z3report.ps1`](../tools/report/z3report.ps1) script for Windows or [`z3report.sh`](../tools/report/z3report.sh) for
Linux gathers 30 days of crash logs into one file. How to run them: [tools/report/README.md](../tools/report/README.md).
While testing the firmware, turn off Windows Fast Startup (Control Panel → Power Options → Choose what the power buttons
do → untick "Turn on fast startup"): otherwise "Shut down" is not a full shutdown and some checks will be wrong.

## Overheating or slowness in Windows

The script does not read temperatures, so for these problems a sensor log is needed:

1. Download the free **HWiNFO64** from its official site and run it in **Sensors-only** mode.
2. If its settings have **Super I/O / EC** polling, turn it off: on this board, accessing the Super I/O chip under load can
   interfere with the computer. Only the processor (CPU, Tctl/Tdie), graphics card and drive sensors are needed.
3. At the bottom of the sensors window press the log button (**Logging Start**) and save the file.
4. Do whatever brings the problem on (a game, a load, idling) for 10–15 minutes, then stop the log.
5. Attach the log file (CSV) to your report.

## If the computer does not start at all

Then there is no way to make a report, so what you see matters. Write down:
- whether the power light is on, the fan spins, the computer beeps, anything is on the screen;
- what you changed before: settings, memory speed, processor, sticks, graphics card, whether you updated the BIOS.

Then try, in this order:
1. Shut it down, unplug the cord for a minute, power it on again.
2. If you changed the memory or its speed, wait a couple of minutes: after three failed attempts the board starts by
   itself on safe settings.
3. Reset the BIOS settings: shut down, unplug the cord and take out the round battery on the board for 5 minutes. All
   settings go back to factory values.

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

If **everything works** for you, tell us too: **New issue** → the "Works for me" form. These reports build the list of tested processors, memory and graphics cards.
