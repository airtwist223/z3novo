# Отчёт о проблеме / Problem reports

> Скрипты для Windows и Linux уже здесь. Отчёт из прошивки появится в T1.

## Что понадобится

1. **Отчёт из прошивки.** В приложении настроек (Del) — кнопка «Отчёт для диагностики». На USB-флешку запишется
   текстовый файл: сводка о системе, журнал последних запусков (на каком шаге остановился неудачный старт), причины
   перезагрузок, ошибки процессора, память и настройки. Если компьютер зависает при запуске, после зависания включите
   его снова, откройте приложение и сделайте отчёт: в нём будет видно, где остановился предыдущий старт.
2. **Отчёт из системы** (если Windows или Linux запускаются): скрипт [`z3report.ps1`](../tools/report/z3report.ps1) для
   Windows или [`z3report.sh`](../tools/report/z3report.sh) для Linux соберёт журналы сбоев (синие экраны, внезапные
   выключения, аппаратные ошибки) в один файл. Как запустить — [tools/report/README.md](../tools/report/README.md).
   Скрипт для Linux проверен; скрипт для Windows ещё проходит первую проверку на настоящей Windows.

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
4. Если не помогло — верните родной BIOS программатором (см. [FLASHING.md](FLASHING.md)).

## Что в отчёты не попадает

Серийные номера, UUID, MAC-адреса (только первые три байта), ключ Windows, пароли, имя компьютера и пользователей.
Перед отправкой всё равно откройте файлы и проверьте их.

## Что написать вместе с отчётами

Что делали, что ожидали, что произошло; процессор, планки памяти, видеокарта; версия Z3NOVO (видна в заголовке меню).

Куда отправлять: раздел **Issues** на странице проекта на GitHub → **New issue** → форма «Проблема». В ней уже есть все нужные вопросы и место для файлов отчётов.

---

# Problem reports

> The Windows and Linux scripts are already here. The firmware report arrives in T1.

## What you will need

1. **A report from the firmware.** In the settings app (Del), the "Diagnostics report" button writes a text file to a
   USB stick: a system summary, the log of recent starts (where a failed start stopped), the reasons for restarts,
   processor errors, memory and settings. If the computer hangs while starting, power it on again after the hang, open
   the app and make a report: it shows where the previous start stopped.
2. **A report from the operating system** (if Windows or Linux starts): the [`z3report.ps1`](../tools/report/z3report.ps1)
   script for Windows or [`z3report.sh`](../tools/report/z3report.sh) for Linux gathers the crash logs (blue screens,
   unexpected shutdowns, hardware errors) into one file. How to run them: [tools/report/README.md](../tools/report/README.md).
   The Linux script has been tested; the Windows script is still getting its first run on a real Windows machine.

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
4. If that does not help, go back to Lenovo's BIOS with a programmer (see [FLASHING.md](FLASHING.md)).

## What the reports leave out

Serial numbers, UUIDs, MAC addresses (only the first three bytes), the Windows key, passwords, computer and user names.
Open the files and check them before you send them anyway.

## What to write along with the reports

What you did, what you expected, what happened; your processor, memory sticks and graphics card; the Z3NOVO version
(shown in the menu's header).

Where to send them: **Issues** on the project's GitHub page → **New issue** → the "Problem" form. It already asks everything we need and has room for the report files.
