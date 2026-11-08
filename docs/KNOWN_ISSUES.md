# Известные проблемы / Known issues

## Для всех версий

- **Активация Windows.** После установки прошивка сообщает другое имя платы и не содержит ключа Windows, вшитого
  Lenovo. Windows может попросить активацию заново: введите свой ключ или войдите в учётную запись Microsoft, к
  которой привязана цифровая лицензия. Ваш ключ остаётся в сохранённой копии заводской прошивки.
- **Имя платы.** В сведениях о системе плата видна под именем платы-донора прошивки (Biostar). На работу это не влияет.
- **Программы мониторинга.** С Ryzen 3 2200G обмен процессора с микросхемой Super I/O (ITE IT8738) сбоит в 8–12 %
  обращений — это свойство процессора, прошивка его обходит. Не используйте датчики Super I/O в программах
  мониторинга (драйвер it87 в Linux, раздел ITE в HWiNFO/AIDA64): они будут показывать мусор и могут мешать
  вентилятору. Температуру процессора берите из датчиков самого процессора (k10temp, «CPU» в HWiNFO).
- **DASH.** Прошивка сетевой карты 2016 года, в ней есть известные уязвимости. Держите DASH выключенным или
  включайте только на прямом кабеле к доверенному компьютеру или в отдельной сети без выхода в интернет.
- **Разгон** процессора и графики в T1 закрыт: механизм отката неудачного разгона ещё не проверен на плате.
- **Проверено только с Ryzen 3 2200G.** Остальные процессоры и четыре планки памяти — не проверены.
- **Ручная частота памяти:** по разбору кода прошивки-донора может давать один лишний перезапуск при каждом втором
  включении. Проверяется.
- **«3G» видеопамяти при включённом CSM** опасен, см. [LIMITS.md](LIMITS.md), раздел 4.

---

# Known issues

## All versions

- **Windows activation.** After installation the firmware reports a different board name and does not carry the Windows
  key Lenovo put in its firmware. Windows may ask to be activated again: enter your key or sign in to the Microsoft
  account your digital licence is linked to. Your key stays in the saved copy of the factory firmware.
- **Board name.** System information shows the board under the name of the firmware donor's board (Biostar). It does
  not affect how anything works.
- **Monitoring programs.** With the Ryzen 3 2200G, 8–12 % of the processor's accesses to the Super I/O chip (ITE IT8738)
  fail. That is a property of the processor, and the firmware works around it. Do not use the Super I/O sensors in
  monitoring programs (the it87 driver on Linux, the ITE section in HWiNFO/AIDA64): they will show garbage and can get in
  the fan's way. Read the CPU temperature from the processor's own sensors (k10temp, "CPU" in HWiNFO).
- **DASH.** The network card's firmware is from 2016 and has known vulnerabilities. Keep DASH off, or use it only on a
  direct cable to a trusted computer or on a separate network with no internet access.
- **Overclocking** of the processor and graphics is locked in T1: the way back from a failed overclock has not been
  tested on a board yet.
- **Tested only with the Ryzen 3 2200G.** Other processors and four memory sticks are untested.
- **Manual memory speed:** by our reading of the donor firmware's code it may cause one extra restart on every second
  power-on. Being checked.
- **"3G" of graphics memory with CSM on** is dangerous, see [LIMITS.md](LIMITS.md), section 4.
