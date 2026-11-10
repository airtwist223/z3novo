# Что проверено / What has been tested

Дополняется по мере проверок: наши собственные и отчёты тестеров (форма «Всё работает» в Issues).
Updated as reports come in: our own checks and testers' reports (the "Everything works" form in Issues).

## По процессорам

### Ryzen 3 2200G (Raven Ridge)

**Плата автора** — 2 × 8 ГБ DDR4-2666 (Crucial + Kingston), версии T1 и T1.1, Windows 11 и Linux:
- всё из общей таблицы ниже: перезагрузки (серии по 10–100), сон, включение по таймеру, по сети и после пропадания
  света, оба DisplayPort, USB 3.0, сеть 1 Гбит/с, SATA, TPM, вентилятор;
- Windows 11: загрузка, драйверы чипсета AMD, часы ядер после перезагрузки в порядке;
- DASH: консоль, веб-страница, удалённое включение, выключение и перезагрузка, ISO по сети.

**Тестер** — 2 × 4 ГБ (2666 + Samsung 2400, вместе работают на 2400), T1.1, Windows 11 Pro:
- перезагрузки, сон, USB, сеть, звук, DisplayPort, SATA, обновление BIOS из меню.

### Ryzen 3 4300GE (Renoir)

**Тестер** — 2 × 8 ГБ Crucial (2666 + 2400), тестовая сборка T1.1r, Windows:
- память на 3000 и 3200 с задержками «Авто»: AIDA64 (FPU, кэш, память) 15 минут, TestMem5 3 цикла — без ошибок;
- перезагрузки без тормозов, все USB, сеть, оба DisplayPort и VGA, звук и микрофон спереди и сзади,
  M.2 NVMe Samsung 970 EVO.

### Ryzen 5 4600G (Renoir)

**Тестер**, T1.1, Windows:
- после «Перезагрузки» Windows тормозит (см. [известные проблемы](KNOWN_ISSUES.md)); исправление (T1.1r) проверяется.

## Общая таблица

| | ✅ Работает | ⚠️ Не проверено | ❌ Не работает |
|---|---|---|---|
| **Процессор** | Ryzen 3 2200G, Ryzen 3 4300GE | другие Ryzen 1000–5000 | A-серия (A6–A12), разгон |
| **Память** | 2 планки в двухканале, DDR4-2667; разные планки вместе (2666 + 2400 работают на 2400); разгон из меню до DDR4-3200 (Crucial 2400 и 2666 на 4300GE, задержки «Авто», проверено AIDA64 и TestMem5) | 4 планки, профиль XMP | напряжение выше 1,2 В |
| **Монитор** | оба разъёма DisplayPort (кабель DP→HDMI), VGA | кабель DP→DP | |
| **Видеокарта** | | в слоте PCIe x16; Resizable BAR — новый переключатель в меню (нужны видеокарта и процессор с его поддержкой) | |
| **USB** | все разъёмы, USB 3.0, клавиатура, мышь | | |
| **Диски** | SATA (SSD, HDD), M.2 NVMe (Samsung 970 EVO) | | |
| **Сеть** | интернет 1 Гбит/с, включение по сети (Wake-on-LAN) | загрузка системы с сервера по сети (PXE) | |
| **DASH** (удалённое управление) | текстовая консоль по сети, настройка адреса DASH в новом меню, веб-страница DASH, удалённые включение, выключение и перезагрузка (в Linux — с параметром `module_blacklist=i2c_piix4`; перезагрузка проверена и при работающей Windows); подключение ISO по сети (в Windows 11 появляется USB-привод; нужен HTTP-сервер, который отдаёт начало ответа одним пакетом) | экран BIOS в консоли DASH | |
| **Питание** | 100 перезагрузок без зависаний, сон, включение по таймеру и после отключения света | | |
| **Меню BIOS** | новое меню (Del), выбор загрузки (F9, флешка запускается сразу), отчёт для диагностики (F11), обновление прошивки с флешки, вход в меню из Windows («Параметры встроенного ПО UEFI») | | |
| **Системы** | Linux; Windows 11 (с T1.1: загрузка, сон, драйверы чипсета AMD, TPM, сеть) | | |
| **Звук** | выход и микрофон спереди и сзади | через DisplayPort | |
| **Прочее** | TPM 2.0, вентилятор процессора | COM-порт | |

---

# What has been tested

## By processor

### Ryzen 3 2200G (Raven Ridge)

**The author's board** — 2 × 8 GB DDR4-2666 (Crucial + Kingston), versions T1 and T1.1, Windows 11 and Linux:
- everything in the table below: restarts (series of 10–100), sleep, power-on by timer, over the network and after a
  power cut, both DisplayPort sockets, USB 3.0, 1 Gbit/s network, SATA, TPM, fan;
- Windows 11: boot, AMD chipset drivers, the cores' clocks fine after a restart;
- DASH: console, web page, remote power on, power off and restart, ISO over the network.

**A tester** — 2 × 4 GB (2666 + Samsung 2400, running together at 2400), T1.1, Windows 11 Pro:
- restarts, sleep, USB, network, sound, DisplayPort, SATA, BIOS update from the menu.

### Ryzen 3 4300GE (Renoir)

**A tester** — 2 × 8 GB Crucial (2666 + 2400), test build T1.1r, Windows:
- memory at 3000 and 3200 with timings on Auto: AIDA64 (FPU, cache, memory) 15 minutes, TestMem5 3 cycles, no errors;
- restarts without slowdowns, every USB socket, network, both DisplayPort sockets and VGA, sound and microphone front and
  back, M.2 NVMe Samsung 970 EVO.

### Ryzen 5 4600G (Renoir)

**A tester**, T1.1, Windows:
- after Restart, Windows slows down (see [known issues](KNOWN_ISSUES.md)); a fix (T1.1r) is being tested.

## Overall table

| | ✅ Works | ⚠️ Not tested | ❌ Does not work |
|---|---|---|---|
| **Processor** | Ryzen 3 2200G, Ryzen 3 4300GE | other Ryzen 1000–5000 | A-series (A6–A12), overclocking |
| **Memory** | 2 sticks in dual channel, DDR4-2667; different sticks together (2666 + 2400 run at 2400); overclocking from the menu up to DDR4-3200 (Crucial 2400 and 2666 on a 4300GE, timings on Auto, checked with AIDA64 and TestMem5) | 4 sticks, XMP profile | voltage above 1.2 V |
| **Monitor** | both DisplayPort sockets (DP→HDMI cable), VGA | DP→DP cable | |
| **Graphics card** | | in the PCIe x16 slot; Resizable BAR, a new switch in the menu (needs a graphics card and processor that support it) | |
| **USB** | every socket, USB 3.0, keyboard, mouse | | |
| **Drives** | SATA (SSD, HDD), M.2 NVMe (Samsung 970 EVO) | | |
| **Network** | 1 Gbit/s internet, power-on over the network (Wake-on-LAN) | starting a system from a server over the network (PXE) | |
| **DASH** (remote management) | the text console over the network, setting the DASH address in the new menu, the DASH web page, remote power on, off and restart (on Linux with `module_blacklist=i2c_piix4`; restart also checked with Windows running); attaching an ISO over the network (Windows 11 sees a USB drive; needs an HTTP server that sends the start of each reply in one packet) | the BIOS screen in the DASH console | |
| **Power** | 100 restarts without a hang, sleep, power-on by timer and after a power cut | | |
| **BIOS menu** | new menu (Del), boot choice (F9, a USB stick starts at once), diagnostics report (F11), firmware update from a USB stick, opening the menu from Windows ("UEFI Firmware Settings") | | |
| **Systems** | Linux; Windows 11 (from T1.1: boot, sleep, AMD chipset drivers, TPM, network) | | |
| **Sound** | output and microphone, front and back | over DisplayPort | |
| **Other** | TPM 2.0, processor fan | COM port | |
