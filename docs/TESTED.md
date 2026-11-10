# Что проверено / What has been tested

Дополняется по мере проверок: наши собственные и отчёты тестеров (форма «Всё работает» в Issues).
Updated as reports come in: our own checks and testers' reports (the "Everything works" form in Issues).

## Что работает, а что нет

Проверено на плате AM4P2MS ревизии 1.1 с Ryzen 3 2200G и двумя планками по 8 ГБ, а также у тестеров с Ryzen 3 4300GE.

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

## What works and what does not

Tested on an AM4P2MS revision 1.1 board with a Ryzen 3 2200G and two 8 GB sticks, and by testers with a Ryzen 3 4300GE.

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
