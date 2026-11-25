# Что проверено / What has been tested

Дополняется по мере проверок автора и тестеров (форма «Всё работает» в Issues).
Updated as the author's checks and testers' reports (the "Everything works" form in Issues) come in.

| Процессор | Поколение | Версии | Итог |
|---|---|---|---|
| [Ryzen 5 1500X](#ryzen-5-1500x) | Summit Ridge | T2.1, T2.2 | ✅ работает с видеокартой GT 710 на T2.2 |
| [Ryzen 3 2200G](#ryzen-3-2200g) | Raven Ridge | T1, T1.1, T1.2, T2.0, T2.1 | ✅ работает; разгон ядер до 3900 МГц |
| [Ryzen 5 2400G](#ryzen-5-2400g) | Raven Ridge | T1.1 | ✅ работает, 2 × 16 ГБ до 3200 |
| [Ryzen 5 2600](#ryzen-5-2600) | Pinnacle Ridge | T2.1, T2.2 | ✅ работает, деление слота x16 на четыре x4 |
| [Ryzen 3 3200G](#ryzen-3-3200g) | Picasso | T1.1 | ✅ работает, память до 2933 |
| [Ryzen 5 3400G](#ryzen-5-3400g) | Picasso | T1.1 | ✅ работает, сон и включения |
| [Athlon PRO 300GE](#athlon-pro-300ge) | Picasso | T2.1, T2.2 | ✅ работает, на T2.2 вместе с видеокартой RX 6400 |
| [Ryzen 3 3100](#ryzen-3-3100) | Matisse | T1.1, T1.2, T2.1, T2.2 | ✅ работает с видеокартой GTX 470 на T2.2 |
| [Ryzen 3 3300X](#ryzen-3-3300x) | Matisse | T2.1, T2.2 | ✅ работает с видеокартой RX 6400 на T2.2; ⚠️ слот x16 только PCIe 3.0 |
| [Ryzen 3 4300GE](#ryzen-3-4300ge) | Renoir | T1.1r | ✅ работает, память до 3200 |
| [Ryzen 3 PRO 4350G](#ryzen-3-pro-4350g) | Renoir | T1.2, T2.0, T2.2 | ✅ работает: сон, четыре планки памяти, Resizable BAR, встроенная графика вместе с видеокартой; ⚠️ не работает PS/2 |
| [Ryzen 5 4600G](#ryzen-5-4600g) | Renoir | T1.1, T1.2 | ✅ работает: перезагрузки, USB, четыре планки памяти на 3600 |
| [Ryzen 5 PRO 4650G](#ryzen-5-pro-4650g) | Renoir | T1.2, T2.0, T2.1, T2.2 | ✅ работает: Windows и Linux, сон, 2 × 16 ГБ на 3200, видеокарта вместе со встроенной графикой; ⚠️ в Linux частотой процессора управляет старый драйвер |
| [Ryzen 5 5600G](#ryzen-5-5600g) | Cezanne | T1.1, T1.1r, T1.2, T2.0, T2.1, T2.2 | ✅ работает: сон, четыре планки памяти, видеокарта вместе со встроенной графикой, деление слота x16 |

[English version](#what-has-been-tested)

## Ryzen 5 1500X

> Summit Ridge · 4 ядра / 8 потоков · без встроенной графики

| | |
|---|---|
| **Версии** | T2.1, T2.2 |
| **Системы** | Windows, Linux (тест-флешка) |
| **Память** | 1 × 4 ГБ Micron 2400 |
| ✅ **Работает** | на T2.2 видеокарта GeForce GT 710 в слоте x16 даёт изображение · тест-флешка на T2.1: 15 стартов подряд дошли до системы или меню, сбоев нет · звук (кодек Realtek) · USB, 16 портов из 16 |
| ⚠️ **Особенности** | на T2.1 видеокарта пропадала перед запуском системы и застывала заставка (исправлено в T2.2, подтверждено) |

## Ryzen 3 2200G

> Raven Ridge · 4 ядра / 4 потока · встроенная Vega 8

| | |
|---|---|
| **Версии** | T1, T1.1, T1.2, T2.0, T2.1 |
| **Системы** | Windows 11, Windows 11 Pro, Linux |
| **Память** | 2 × 8 ГБ DDR4-2666 (Crucial + Kingston) · 2 × 4 ГБ разные (2666 + 2400) — вместе работают на 2400 |
| ✅ **Работает** | перезагрузки, сон, включение по таймеру, по сети и после пропадания света · оба DisplayPort · USB 3.0 · сеть 1 Гбит/с · SATA · звук · TPM 2.0 · вентиляторы · обновление BIOS из меню · DASH: консоль, веб-страница, удалённое питание, ISO по сети |
| ✅ **Новое в T2.0** | обновление из меню и возврат на предыдущую версию · заставка с подсказками Del/F9 · F6 «Сбросить всё на заводские» и его отмена · F12 снимок экрана · строка F-клавиш и окно F1 с QR-кодами · окно «Состояние» · вкладка «Другое» · сервисный режим · сон и пробуждение в Windows и Linux · DASH: включение после выдёргивания шнура, меню BIOS в консоли · разгон ядер 3900 МГц при 1,375 В · откат разгона после трёх неудачных запусков (проверен до последней доработки защиты) · «Память для графики» 11 ГБ · новое имя компьютера · нет «irq 7: nobody cared» в Linux |
| ✅ **Новое в T2.1** | вентилятор после сна: два сна подряд, после каждого снова по кривой (около 900 об/мин в простое), под нагрузкой 2616 об/мин при 69 °C · защита от сбоя таймера после сна · «Тихо»: штатный кулер Lenovo 894 об/мин в простое вместо 1298 · четырёхпиновые вентиляторы на SYS_FAN, AUX1_FAN и AUX2_FAN, обороты AUX2 · трёхпиновые на CPU_FAN, SYS_FAN и AUX2_FAN не регулируются (так устроена плата) · защита от остановки: пинок полными оборотами и выход на 10 % выше · в Linux у устройств коды Lenovo (17AA:36C7) |
| ⚠️ **Особенности** | COM-порт в Windows иногда не определяется · на 4000 МГц ядра зависают при любом напряжении · разгон графики 1200 МГц / 1,200 В под нагрузкой зависал · что ещё не проверено — в [истории версий](../CHANGELOG.md) |

**Опыты**
- Серии перезагрузок: 25, 10 и 100 подряд без зависаний.
- Windows 11: после перезагрузки часы всех ядер совпадают (расхождение меньше 1 мкс).
- Шторма прерываний от контроллера GPIO в Windows нет (0 % времени на прерывания).

## Ryzen 5 2400G

> Raven Ridge · 4 ядра / 8 потоков · встроенная Vega 11

| | |
|---|---|
| **Версии** | T1.1 |
| **Системы** | Windows 10 |
| **Память** | 2 × 16 ГБ Apacer NOX (комплект DDR4-3600), проверено на 2133 и 3200 |
| ✅ **Работает** | включение и перезагрузки · двухканальная память · DisplayPort · USB · сеть · звук · M.2 · частота памяти вручную · вентилятор · вычислительная видеокарта P106-100 вместе со встроенной графикой |
| ⚠️ **Особенности** | на T1.1 разгон процессора был закрыт (открыт с T2.0, на этом процессоре не проверялся) |

## Ryzen 5 2600

> Pinnacle Ridge · 6 ядер / 12 потоков · без встроенной графики

| | |
|---|---|
| **Версии** | T2.1, T2.2 |
| **Системы** | Windows |
| **Память** | 1 × 8 ГБ Crucial 2400 |
| ✅ **Работает** | деление слота x16 на x4+x4+x4+x4 через переходник: меню BIOS видит сразу видеокарту Radeon RX 6400 (x4), NVMe Micron (x4) и Intel Optane (x2) · запуск с видеокартой GeForce GT 1030 |
| ⚠️ **Особенности** | на T2.1 при запуске Windows застывала картинка: видеокарта пропадала перед запуском системы (исправлено в T2.2; на этом процессоре после исправления ещё не проверяли) |

## Ryzen 3 3200G

> Picasso · 4 ядра / 4 потока · встроенная Vega 8

| | |
|---|---|
| **Версии** | T1.1 |
| **Системы** | Windows 10 |
| **Память** | 2 × 8 ГБ Crucial Ballistix DDR4-3200, работают на 2933 |
| ✅ **Работает** | включение и перезагрузки, холодный старт с первого раза · включение после пропадания света · USB · сеть · DisplayPort · SATA · M.2 · обновление BIOS из меню · частота памяти вручную: **2933** — штатный предел этого процессора по AMD · три дня без зависаний |
| ⚠️ **Особенности** | на 3200 при 1,2 В память не работает (напряжение памяти на этой плате не поднять) · планка AMD 16 ГБ на чипах Nanya не заводится ([известные проблемы](KNOWN_ISSUES.md)) · через пассивный переходник DP→HDMI нет 144 Гц ([известные проблемы](KNOWN_ISSUES.md)) |

## Ryzen 5 3400G

> Picasso · 4 ядра / 8 потоков · встроенная Vega 11

| | |
|---|---|
| **Версии** | T1.1 |
| **Системы** | Windows 11 |
| **Память** | 2 × 8 ГБ Crucial DDR4-2400, разгон до 2866 |
| ✅ **Работает** | перезагрузки · сон · включение после пропадания света · USB · сеть · звук · DisplayPort · SATA · M.2 · частота памяти вручную; включения стабильнее, чем на прошивках Acer и AFOX |
| ⚠️ **Особенности** | на T1.1 с ручной частотой памяти перед запуском Windows бывает одна лишняя перезагрузка (в T2.0 исправлено, на этом процессоре не проверяли) |

## Athlon PRO 300GE

> Picasso · 2 ядра / 4 потока · встроенная Vega 3

| | |
|---|---|
| **Версии** | T2.1, T2.2 |
| **Системы** | Windows 10 |
| **Память** | 1 × 8 ГБ Crucial 2400 |
| ✅ **Работает** | встроенная графика · звук (кодек Realtek и HDMI) · USB, 17 портов из 17 · на T2.2 с видеокартой Radeon RX 6400: запуск без перезапусков; «Две видеокарты сразу» = «Авто» — работают обе, «Выкл» — встроенная графика выключается чисто |
| ⚠️ **Особенности** | на T2.1 с видеокартой перезапускался по кругу (исправлено в T2.2, подтверждено) · после установки видеокарты у встроенной графики был код 43 — ушёл после переустановки драйверов чипсета и видео AMD |

## Ryzen 3 3100

> Matisse · 4 ядра / 8 потоков · без встроенной графики

| | |
|---|---|
| **Версии** | T1.1, T1.2, T2.1, T2.2 |
| **Системы** | Windows |
| **Память** | 2 × 16 ГБ Apacer, 2133 |
| ✅ **Работает** | на T2.2 с видеокартой GeForce GTX 470 запускается Windows |
| ⚠️ **Особенности** | до T2.2 при запуске Windows застывала заставка: видеокарта пропадала перед запуском системы (исправлено в T2.2, подтверждено) |

## Ryzen 3 3300X

> Matisse · 4 ядра / 8 потоков · без встроенной графики

| | |
|---|---|
| **Версии** | T2.1, T2.2 |
| **Системы** | Windows, Linux (тест-флешка) |
| **Память** | 2 × 16 ГБ Kingston: HyperX Fury KHX3200C16D4/16GX и FURY Beast KF3200C16D4/16GX, работают на 2400 |
| ✅ **Работает** | на T2.2 с видеокартой Radeon RX 6400: изображение с самого включения (UEFI) и в системе · 15 стартов подряд дошли до системы или меню, сбоев нет · звук: система видит кодек Realtek и звук HDMI видеокарты · USB |
| ⚠️ **Особенности** | на T2.1 видеокарта пропадала перед запуском системы и застывала заставка (исправлено в T2.2, подтверждено) · слот x16 работает на PCIe 3.0 (8 ГТ/с), PCIe 4.0 нет: так AMD ограничивает процессоры на платах этого класса (чипсет B350) · XMP нельзя выбрать: меню разрешает его только для одинаковых планок, а у этих разные названия, хотя обе — Kingston DDR4-3200 CL16 на 16 ГБ |

## Ryzen 3 4300GE

> Renoir · 4 ядра / 8 потоков · встроенная Vega 5

| | |
|---|---|
| **Версии** | T1.1r |
| **Системы** | Windows |
| **Память** | 2 × 8 ГБ Crucial (2666 + 2400) |
| ✅ **Работает** | перезагрузки · все USB · сеть · оба DisplayPort и VGA · звук и микрофон спереди и сзади · M.2 NVMe (Samsung 970 EVO) |
| ⚠️ **Особенности** | на T1.1r с ручной частотой памяти при старте бывает лишняя перезагрузка (в T2.0 исправлено, на этом процессоре не проверяли) |

**Опыты**
- Память на **3000** и **3200** с задержками «Авто»: на 3200 вышло CL 24-23-23-52, 1T, Gear Down; память, Infinity Fabric
  и контроллер памяти 1:1:1 (1600 МГц), напряжение SoC 0,99 В — без повышения.
- Разные планки в разных каналах (двухранговая 2666 и одноранговая 2400): каждый канал получил свои задержки из своей
  планки — CL 24-23-23 и CL 22-22-22 при общей частоте 3200.
  AIDA64 (FPU, кэш, память) 15 минут и TestMem5 3 цикла — без ошибок.

## Ryzen 3 PRO 4350G

> Renoir · 4 ядра / 8 потоков · встроенная Vega 6

| | |
|---|---|
| **Версии** | T1.2, T2.0, T2.2 |
| **Системы** | Windows 10, Windows 11 |
| **Память** | 2 × 16 ГБ с XMP 3200 · четыре планки на 3200 вручную · 4 × 4 ГБ разные: две Ramaxel и две Micron, все на 2400 |
| ✅ **Работает** | Resizable BAR с видеокартой Intel Arc A380 · встроенная графика вместе с видеокартой (Arc A380, RX 550, на T2.2 — CMP 30HX) · тест-флешка: память и нагрузка без ошибок · на T1.2: все USB, все слоты PCIe, M.2 (NVMe), звук сзади · на T2.0: включение и перезагрузки, сон, USB, сеть, звук, DisplayPort, VGA, частота памяти вручную, обновление BIOS из меню, сброс F6 · на T2.2: включение и перезагрузки, сон (тест-флешка: 5 из 5), включение после пропадания света, USB, DisplayPort, VGA, SATA, M.2, обновление BIOS из меню, вентиляторы FAN2 и FAN3, сброс F6, долгая проверка тест-флешкой без ошибок |
| ⚠️ **Особенности** | на T1.2 компьютер не просыпался из сна (исправлено в T2.0, подтверждено) · кружок загрузки Windows задевал логотип (в T2.0 новая заставка) · на T2.2 не работает PS/2 (питание на разъём идёт) |

## Ryzen 5 4600G

> Renoir · 6 ядер / 12 потоков · встроенная Vega 7

| | |
|---|---|
| **Версии** | T1.1, T1.2 |
| **Системы** | Windows 10 |
| **Память** | 1 × 8 ГБ Crucial 2400 · 4 × 8 ГБ: две Crucial 2400 и две TeamGroup 3200 — вместе на 3600 |
| ✅ **Работает** | на T1.2: запуск Windows, перезагрузки из Windows, USB, VGA, DisplayPort, четыре планки памяти на 3600 |
| ⚠️ **Особенности** | на T1.1 после «Перезагрузки» Windows тормозила (исправлено в T1.1r, подтверждено) · на T1.2 компьютер не просыпался из сна (исправлено в T2.0; подтверждено на других Ryzen 4000G и 5000G, на этом процессоре не проверяли) · через пассивный переходник DP→HDMI картинка то пропадала, то шла с красными полосами — помогло поправить переходник в разъёме |

## Ryzen 5 PRO 4650G

> Renoir · 6 ядер / 12 потоков · встроенная Vega 7

| | |
|---|---|
| **Версии** | T1.2, T2.0, T2.1, T2.2 |
| **Системы** | Debian 13, Windows |
| **Память** | 2 × 16 ГБ (Apacer + Crucial) на 3200 |
| ✅ **Работает** | двое суток без зависаний и отвалов USB · Linux и Windows · переключение загрузочных дисков · сон и гибернация с T2.0 (в журнале запусков — удачные выходы из сна) · на T2.1: вентилятор после сна сам возвращается к кривой, корпусные вентиляторы (FAN2, AUX1, AUX2) идут по кривой, «Тихо» и «Минимум» у каждого вентилятора · на T2.2: видеокарта RX 560 и встроенная графика работают одновременно, сон 5 из 5, нагрузка на память и процессор без ошибок (тест-флешка), включение после пропадания света, сеть, звук, DisplayPort, SATA, M.2 (NVMe WD SN740), частота памяти вручную, вентиляторы FAN2 и FAN3 |
| ⚠️ **Особенности** | на T1.2 с накопителем NVMe Western Digital в M.2 Windows зависала, с SATA — нет; в T2.0 тактовый сигнал слота M.2 сделан как в BIOS Lenovo, помогло ли — ещё не проверено · в Linux частотой процессора управляет старый драйвер (так и на T2.2), буст работает · иногда не сохранялись настройки (исправлено в T2.0) |

## Ryzen 5 5600G

> Cezanne · 6 ядер / 12 потоков · встроенная Vega 7

| | |
|---|---|
| **Версии** | T1.1, T1.1r, T1.2, T2.0, T2.1, T2.2 |
| **Системы** | Windows 10, Proxmox VE 9.2 |
| **Память** | 4 × 8 ГБ разные (две 2400, две 2666) — вместе на 2667 · 4 × 8 ГБ: две Crucial 2400 и две TeamGroup 3200 — вместе на 3600 · 2 × 16 + 8 + 4 ГБ, четыре разные планки от 2400 до 3200 — вместе на 2667 · 1 × 8 ГБ Crucial 2400 |
| ✅ **Работает** | запуск Windows · перезагрузки из Windows (с T1.1r) · четыре планки памяти · сон с T2.0: лампа мигает, будят кнопка питания и любая клавиша · на T2.1: вентилятор после сна сам возвращается к кривой (до обычных оборотов — плавно, за пару минут), GPU-Z показывает производителя Lenovo · на T2.2: Proxmox VE 9.2 четыре дня, включение и перезагрузки, включение после пропадания света, USB, сеть, DisplayPort, SATA, частота памяти вручную, окно «Состояние», F6 «Сбросить всё на заводские» · на T2.2 с видеокартой Radeon RX 6400: «Две видеокарты сразу» = «Авто» — работают обе, «Выкл» — только видеокарта · на T2.2 деление слота x16 на x8+x4+x4 через переходник: видеокарта Radeon RX 6400, NVMe Micron и Intel Optane работают одновременно, Windows видит оба накопителя |
| ⚠️ **Особенности** | на T1.1 перезагрузка из Windows зависала (исправлено в T1.1r, подтверждено) · на T1.1 на одной из плат при включении было три перезапуска подряд, а передние USB и два задних под сетевым разъёмом не работали: в памяти CMOS остались данные прежней прошивки (исправлено в T1.2, подтверждено) · до T2.0 выход из сна зависал (исправлено в T2.0, подтверждено) · на T2.0 после сна вентилятор не возвращался к кривой, GPU-Z показывал производителя Biostar, в меню бывал второй курсор мыши (исправлено в T2.1) · после обновления на T2.1 Windows один раз поставила стандартный видеодрайвер (у устройств новые коды), драйвер AMD переустановили · на T2.1 с видеокартой не было изображения, а потом компьютер перестал запускаться, пока прошивку не записали заново (исправлено в T2.2, подтверждено) · после включения деления слота у встроенной графики в Windows был код 43 ([известные проблемы](KNOWN_ISSUES.md)) |

---

# What has been tested

| Processor | Family | Versions | Result |
|---|---|---|---|
| [Ryzen 5 1500X](#ryzen-5-1500x-1) | Summit Ridge | T2.1, T2.2 | ✅ works with a GT 710 card on T2.2 |
| [Ryzen 3 2200G](#ryzen-3-2200g-1) | Raven Ridge | T1, T1.1, T1.2, T2.0, T2.1 | ✅ works; core overclock up to 3900 MHz |
| [Ryzen 5 2400G](#ryzen-5-2400g-1) | Raven Ridge | T1.1 | ✅ works, 2 × 16 GB up to 3200 |
| [Ryzen 5 2600](#ryzen-5-2600-1) | Pinnacle Ridge | T2.1, T2.2 | ✅ works, the x16 slot split into four x4 |
| [Ryzen 3 3200G](#ryzen-3-3200g-1) | Picasso | T1.1 | ✅ works, memory up to 2933 |
| [Ryzen 5 3400G](#ryzen-5-3400g-1) | Picasso | T1.1 | ✅ works, sleep and power-ons |
| [Athlon PRO 300GE](#athlon-pro-300ge-1) | Picasso | T2.1, T2.2 | ✅ works, on T2.2 together with an RX 6400 card |
| [Ryzen 3 3100](#ryzen-3-3100-1) | Matisse | T1.1, T1.2, T2.1, T2.2 | ✅ works with a GTX 470 card on T2.2 |
| [Ryzen 3 3300X](#ryzen-3-3300x-1) | Matisse | T2.1, T2.2 | ✅ works with an RX 6400 card on T2.2; ⚠️ the x16 slot is PCIe 3.0 only |
| [Ryzen 3 4300GE](#ryzen-3-4300ge-1) | Renoir | T1.1r | ✅ works, memory up to 3200 |
| [Ryzen 3 PRO 4350G](#ryzen-3-pro-4350g-1) | Renoir | T1.2, T2.0, T2.2 | ✅ works: sleep, four memory sticks, Resizable BAR, built-in graphics together with a card; ⚠️ PS/2 does not work |
| [Ryzen 5 4600G](#ryzen-5-4600g-1) | Renoir | T1.1, T1.2 | ✅ works: restarts, USB, four memory sticks at 3600 |
| [Ryzen 5 PRO 4650G](#ryzen-5-pro-4650g-1) | Renoir | T1.2, T2.0, T2.1, T2.2 | ✅ works: Windows and Linux, sleep, 2 × 16 GB at 3200, a card together with the built-in graphics; ⚠️ on Linux the older driver controls the processor clock |
| [Ryzen 5 5600G](#ryzen-5-5600g-1) | Cezanne | T1.1, T1.1r, T1.2, T2.0, T2.1, T2.2 | ✅ works: sleep, four memory sticks, a card together with the built-in graphics, x16 slot bifurcation |

## Ryzen 5 1500X

> Summit Ridge · 4 cores / 8 threads · no built-in graphics

| | |
|---|---|
| **Versions** | T2.1, T2.2 |
| **Systems** | Windows, Linux (test stick) |
| **Memory** | 1 × 4 GB Micron 2400 |
| ✅ **Works** | on T2.2 a GeForce GT 710 card in the x16 slot gives a picture · test stick on T2.1: 15 starts in a row reached the system or the menu, no faults · sound (Realtek codec) · USB, 16 ports out of 16 |
| ⚠️ **Notes** | on T2.1 the card dropped off before the system started and the splash froze (fixed in T2.2, confirmed) |

## Ryzen 3 2200G

> Raven Ridge · 4 cores / 4 threads · Vega 8 graphics

| | |
|---|---|
| **Versions** | T1, T1.1, T1.2, T2.0, T2.1 |
| **Systems** | Windows 11, Windows 11 Pro, Linux |
| **Memory** | 2 × 8 GB DDR4-2666 (Crucial + Kingston) · 2 × 4 GB of different kinds (2666 + 2400), together at 2400 |
| ✅ **Works** | restarts, sleep, power-on by timer, over the network and after a power cut · both DisplayPort sockets · USB 3.0 · 1 Gbit/s network · SATA · sound · TPM 2.0 · fans · BIOS update from the menu · DASH: console, web page, remote power, ISO over the network |
| ✅ **New in T2.0** | updating from the menu and going back to the previous version · the boot screen with Del/F9 hints · F6 "Reset all to factory" and cancelling it · F12 screenshots · the F-key line and the F1 window with QR codes · the Health window · the Other tab · service mode · sleep and wake on Windows and Linux · DASH: power-on after the cord was out, the BIOS menu in the console · core overclock at 3900 MHz and 1.375 V · the overclock rollback after three failed starts (tested before the protection's last rework) · "Memory for graphics" at 11 GB · the new computer name · no "irq 7: nobody cared" on Linux |
| ✅ **New in T2.1** | the fan after sleep: two sleeps in a row, back on the curve after each (about 900 rpm at idle), 2616 rpm at 69 °C under load · the timer guard after sleep · Quiet: Lenovo's stock cooler at 894 rpm at idle instead of 1298 · 4-pin fans on SYS_FAN, AUX1_FAN and AUX2_FAN, AUX2's speed · 3-pin fans on CPU_FAN, SYS_FAN and AUX2_FAN are not controlled (the board is built that way) · the stall guard: a kick at full speed and the output 10 % higher · Lenovo device IDs (17AA:36C7) on Linux |
| ⚠️ **Notes** | the COM port is sometimes not detected in Windows · at 4000 MHz the cores freeze at any voltage · a graphics overclock of 1200 MHz / 1.200 V froze under load · what has not been tested yet: see the [version history](../CHANGELOG.md) |

**Experiments**
- Restart series: 25, 10 and 100 in a row without a hang.
- Windows 11: after a restart the clocks of all cores agree (less than 1 µs apart).
- No interrupt storm from the GPIO controller in Windows (0 % interrupt time).

## Ryzen 5 2400G

> Raven Ridge · 4 cores / 8 threads · Vega 11 graphics

| | |
|---|---|
| **Versions** | T1.1 |
| **Systems** | Windows 10 |
| **Memory** | 2 × 16 GB Apacer NOX (a DDR4-3600 kit), tested at 2133 and 3200 |
| ✅ **Works** | power-on and restarts · dual-channel memory · DisplayPort · USB · network · sound · M.2 · manual memory speed · fan · a P106-100 compute card alongside the built-in graphics |
| ⚠️ **Notes** | on T1.1 processor overclocking was locked (open from T2.0, not tested on this processor) |

## Ryzen 5 2600

> Pinnacle Ridge · 6 cores / 12 threads · no built-in graphics

| | |
|---|---|
| **Versions** | T2.1, T2.2 |
| **Systems** | Windows |
| **Memory** | 1 × 8 GB Crucial 2400 |
| ✅ **Works** | the x16 slot split as x4+x4+x4+x4 through an adapter: the BIOS menu sees a Radeon RX 6400 card (x4), a Micron NVMe drive (x4) and an Intel Optane (x2) at the same time · starting with a GeForce GT 1030 card |
| ⚠️ **Notes** | on T2.1 the picture froze while Windows started: the card dropped off before the system started (fixed in T2.2; not yet retested on this processor after the fix) |

## Ryzen 3 3200G

> Picasso · 4 cores / 4 threads · Vega 8 graphics

| | |
|---|---|
| **Versions** | T1.1 |
| **Systems** | Windows 10 |
| **Memory** | 2 × 8 GB Crucial Ballistix DDR4-3200, running at 2933 |
| ✅ **Works** | power-on and restarts, a cold start at the first try · power-on after a power cut · USB · network · DisplayPort · SATA · M.2 · BIOS update from the menu · manual memory speed: **2933**, AMD's stated limit for this processor · three days without a hang |
| ⚠️ **Notes** | at 3200 and 1.2 V the memory does not work (this board cannot raise the memory voltage) · an AMD 16 GB stick on Nanya chips does not start ([known issues](KNOWN_ISSUES.md)) · no 144 Hz through a passive DP→HDMI adapter ([known issues](KNOWN_ISSUES.md)) |

## Ryzen 5 3400G

> Picasso · 4 cores / 8 threads · Vega 11 graphics

| | |
|---|---|
| **Versions** | T1.1 |
| **Systems** | Windows 11 |
| **Memory** | 2 × 8 GB Crucial DDR4-2400, overclocked to 2866 |
| ✅ **Works** | restarts · sleep · power-on after a power cut · USB · network · sound · DisplayPort · SATA · M.2 · manual memory speed; power-ons are steadier than with the Acer and AFOX firmware |
| ⚠️ **Notes** | on T1.1 with a manual memory speed there is one extra restart before Windows starts (fixed in T2.0, not tested on this processor) |

## Athlon PRO 300GE

> Picasso · 2 cores / 4 threads · Vega 3 graphics

| | |
|---|---|
| **Versions** | T2.1, T2.2 |
| **Systems** | Windows 10 |
| **Memory** | 1 × 8 GB Crucial 2400 |
| ✅ **Works** | built-in graphics · sound (Realtek codec and HDMI) · USB, 17 ports out of 17 · on T2.2 with a Radeon RX 6400 card: starts without restarts; with "Both graphics at once" = "Auto" both work, with "Off" the built-in graphics turns off cleanly |
| ⚠️ **Notes** | on T2.1 it restarted in a loop with a card (fixed in T2.2, confirmed) · after the card went in, the built-in graphics showed code 43; it went away after reinstalling AMD's chipset and graphics drivers |

## Ryzen 3 3100

> Matisse · 4 cores / 8 threads · no built-in graphics

| | |
|---|---|
| **Versions** | T1.1, T1.2, T2.1, T2.2 |
| **Systems** | Windows |
| **Memory** | 2 × 16 GB Apacer, 2133 |
| ✅ **Works** | on T2.2 Windows starts with a GeForce GTX 470 card |
| ⚠️ **Notes** | before T2.2 the splash froze while Windows started: the card dropped off before the system started (fixed in T2.2, confirmed) |

## Ryzen 3 3300X

> Matisse · 4 cores / 8 threads · no built-in graphics

| | |
|---|---|
| **Versions** | T2.1, T2.2 |
| **Systems** | Windows, Linux (test stick) |
| **Memory** | 2 × 16 GB Kingston: HyperX Fury KHX3200C16D4/16GX and FURY Beast KF3200C16D4/16GX, running at 2400 |
| ✅ **Works** | on T2.2 with a Radeon RX 6400 card: a picture from power-on (UEFI) and in the system · 15 starts in a row reached the system or the menu, no faults · sound: the system sees the Realtek codec and the card's HDMI sound · USB |
| ⚠️ **Notes** | on T2.1 the card dropped off before the system started and the splash froze (fixed in T2.2, confirmed) · the x16 slot runs at PCIe 3.0 (8 GT/s), not 4.0: that is how AMD limits processors on boards of this class (B350 chipset) · XMP cannot be chosen: the menu allows it only for identical sticks, and these two have different names, though both are Kingston DDR4-3200 CL16 16 GB |

## Ryzen 3 4300GE

> Renoir · 4 cores / 8 threads · Vega 5 graphics

| | |
|---|---|
| **Versions** | T1.1r |
| **Systems** | Windows |
| **Memory** | 2 × 8 GB Crucial (2666 + 2400) |
| ✅ **Works** | restarts · every USB socket · network · both DisplayPort sockets and VGA · sound and microphone front and back · M.2 NVMe (Samsung 970 EVO) |
| ⚠️ **Notes** | on T1.1r with a manual memory speed there can be an extra restart at power-on (fixed in T2.0, not tested on this processor) |

**Experiments**
- Memory at **3000** and **3200** with timings on Auto: at 3200 that gave CL 24-23-23-52, 1T, Gear Down; memory,
  Infinity Fabric and memory controller 1:1:1 (1600 MHz), SoC voltage 0.99 V, not raised.
- Different sticks in the two channels (dual-rank 2666 and single-rank 2400): each channel got its own timings from its
  stick, CL 24-23-23 and CL 22-22-22, at a common 3200.
  AIDA64 (FPU, cache, memory) for 15 minutes and TestMem5 for 3 cycles, no errors.

## Ryzen 3 PRO 4350G

> Renoir · 4 cores / 8 threads · Vega 6 graphics

| | |
|---|---|
| **Versions** | T1.2, T2.0, T2.2 |
| **Systems** | Windows 10, Windows 11 |
| **Memory** | 2 × 16 GB with XMP 3200 · four sticks at 3200 set by hand · 4 × 4 GB of different kinds: two Ramaxel and two Micron, all at 2400 |
| ✅ **Works** | Resizable BAR with an Intel Arc A380 card · built-in graphics together with a card (Arc A380, RX 550, on T2.2 a CMP 30HX) · test stick: memory and load without errors · on T1.2: all USB sockets, all PCIe slots, M.2 (NVMe), rear sound · on T2.0: power-on and restarts, sleep, USB, network, sound, DisplayPort, VGA, a manual memory speed, BIOS update from the menu, the F6 reset · on T2.2: power-on and restarts, sleep (test stick: 5 out of 5), power-on after a power cut, USB, DisplayPort, VGA, SATA, M.2, BIOS update from the menu, fans on FAN2 and FAN3, the F6 reset, the test stick's long test without errors |
| ⚠️ **Notes** | on T1.2 the computer did not wake from sleep (fixed in T2.0, confirmed) · the Windows loading circle touched the logo (T2.0 has a new boot screen) · on T2.2 PS/2 does not work (the socket does get power) |

## Ryzen 5 4600G

> Renoir · 6 cores / 12 threads · Vega 7 graphics

| | |
|---|---|
| **Versions** | T1.1, T1.2 |
| **Systems** | Windows 10 |
| **Memory** | 1 × 8 GB Crucial 2400 · 4 × 8 GB: two Crucial 2400 and two TeamGroup 3200, together at 3600 |
| ✅ **Works** | on T1.2: Windows starts, restarts from Windows, USB, VGA, DisplayPort, four memory sticks at 3600 |
| ⚠️ **Notes** | on T1.1 Windows slowed down after Restart (fixed in T1.1r, confirmed) · on T1.2 the computer did not wake from sleep (fixed in T2.0; confirmed on other Ryzen 4000G and 5000G, not tested on this processor) · through a passive DP→HDMI adapter the picture sometimes vanished or came with red stripes; reseating the adapter in the socket helped |

## Ryzen 5 PRO 4650G

> Renoir · 6 cores / 12 threads · Vega 7 graphics

| | |
|---|---|
| **Versions** | T1.2, T2.0, T2.1, T2.2 |
| **Systems** | Debian 13, Windows |
| **Memory** | 2 × 16 GB (Apacer + Crucial) at 3200 |
| ✅ **Works** | two days without hangs or USB drop-outs · Linux and Windows · switching boot disks · sleep and hibernation from T2.0 (the boot log shows successful wakes from sleep) · on T2.1: the fan goes back to its curve by itself after sleep, the case fans (FAN2, AUX1, AUX2) follow their curve, Quiet and a minimum for each fan · on T2.2: an RX 560 card and the built-in graphics work at the same time, sleep 5 out of 5, memory and processor load without errors (test stick), power-on after a power cut, network, sound, DisplayPort, SATA, M.2 (a WD SN740 NVMe drive), a manual memory speed, fans on FAN2 and FAN3 |
| ⚠️ **Notes** | on T1.2 Windows hung with a Western Digital NVMe drive in M.2, with SATA it did not; in T2.0 the M.2 slot clock works as in Lenovo's BIOS, whether that helps has not been tested yet · on Linux the older driver controls the processor clock (still so on T2.2), boost works · settings were sometimes not saved (fixed in T2.0) |

## Ryzen 5 5600G

> Cezanne · 6 cores / 12 threads · Vega 7 graphics

| | |
|---|---|
| **Versions** | T1.1, T1.1r, T1.2, T2.0, T2.1, T2.2 |
| **Systems** | Windows 10, Proxmox VE 9.2 |
| **Memory** | 4 × 8 GB, all different (two 2400, two 2666), together at 2667 · 4 × 8 GB: two Crucial 2400 and two TeamGroup 3200, together at 3600 · 2 × 16 + 8 + 4 GB, four different sticks from 2400 to 3200, together at 2667 · 1 × 8 GB Crucial 2400 |
| ✅ **Works** | Windows starts · restarts from Windows (from T1.1r) · four memory sticks · sleep from T2.0: the light blinks, the power button and any key wake it · on T2.1: the fan goes back to its curve by itself after sleep (down to its usual speed smoothly, within a couple of minutes), GPU-Z shows Lenovo as the maker · on T2.2: Proxmox VE 9.2 for four days, power-on and restarts, power-on after a power cut, USB, network, DisplayPort, SATA, a manual memory speed, the Health window, F6 "Reset everything to factory" · on T2.2 with a Radeon RX 6400 card: with "Both graphics at once" = "Auto" both work, with "Off" only the card · on T2.2 the x16 slot split as x8+x4+x4 through an adapter: a Radeon RX 6400 card, a Micron NVMe drive and an Intel Optane work at the same time, Windows sees both drives |
| ⚠️ **Notes** | on T1.1 a restart from Windows hung (fixed in T1.1r, confirmed) · on T1.1 one board restarted three times in a row at power-on, and the front USB sockets and the two rear ones under the network socket did not work: the CMOS memory held another firmware's leftovers (fixed in T1.2, confirmed) · before T2.0 waking from sleep hung (fixed in T2.0, confirmed) · on T2.0 the fan did not go back to its curve after sleep, GPU-Z showed Biostar as the maker, and a second mouse pointer sometimes showed in the menu (fixed in T2.1) · after the update to T2.1 Windows once put in its standard display driver (the devices have new IDs), AMD's driver was reinstalled · on T2.1 with a card there was no picture, and then the computer stopped starting until the firmware was written again (fixed in T2.2, confirmed) · after the slot was split, the built-in graphics showed code 43 in Windows ([known issues](KNOWN_ISSUES.md)) |
