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

## Что в отчёты не попадает

Серийные номера, UUID, MAC-адреса (только первые три байта), ключ Windows, пароли, имя компьютера и пользователей.
Перед отправкой всё равно откройте файлы и проверьте их.

## Что написать вместе с отчётами

Что делали, что ожидали, что произошло; процессор, планки памяти, видеокарта; версия Z3NOVO (видна в заголовке меню).

Куда отправлять: раздел **Issues** на странице проекта на GitHub — новое обращение, описание и файлы отчётов.

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

## What the reports leave out

Serial numbers, UUIDs, MAC addresses (only the first three bytes), the Windows key, passwords, computer and user names.
Open the files and check them before you send them anyway.

## What to write along with the reports

What you did, what you expected, what happened; your processor, memory sticks and graphics card; the Z3NOVO version
(shown in the menu's header).

Where to send them: **Issues** on the project's GitHub page — open a new issue with the description and the report files.
