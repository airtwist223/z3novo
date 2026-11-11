# Что проверено / What has been tested

Дополняется по мере проверок, наших и тестеров (форма «Всё работает» в Issues).
Updated as checks and testers' reports (the "Everything works" form in Issues) come in.

| Процессор | Поколение | Версии | Итог |
|---|---|---|---|
| [Ryzen 3 2200G](#ryzen-3-2200g) | Raven Ridge | T1, T1.1, T1.2 | ✅ работает |
| [Ryzen 5 2400G](#ryzen-5-2400g) | Raven Ridge | T1.1 | ✅ работает, 2 × 16 ГБ до 3200 |
| [Ryzen 3 3200G](#ryzen-3-3200g) | Picasso | T1.x | ✅ работает, память 2933 |
| [Ryzen 5 3400G](#ryzen-5-3400g) | Picasso | T1.1 | ✅ работает, сон и включения |
| [Ryzen 3 4300GE](#ryzen-3-4300ge) | Renoir | T1.1r | ✅ работает, память до 3200 |
| [Ryzen 5 4600G](#ryzen-5-4600g) | Renoir | T1.1 | ⚠️ тормоза после перезагрузки, исправлено в T1.1r (ждём подтверждения) |
| [Ryzen 5 5600G](#ryzen-5-5600g) | Cezanne | T1.1, T1.1r | ⚠️ работает; выход из сна виснет, у одного тестера не работают USB чипсета |

[English version](#what-has-been-tested)

## Ryzen 3 2200G

> Raven Ridge · 4 ядра / 4 потока · встроенная Vega 8

| | |
|---|---|
| **Версии** | T1, T1.1, T1.2 |
| **Системы** | Windows 11, Windows 11 Pro, Linux |
| **Память** | 2 × 8 ГБ DDR4-2666 (Crucial + Kingston) · 2 × 4 ГБ разные (2666 + 2400) — вместе работают на 2400 |
| ✅ **Работает** | перезагрузки, сон, включение по таймеру, по сети и после пропадания света · оба DisplayPort · USB 3.0 · сеть 1 Гбит/с · SATA · звук · TPM 2.0 · вентилятор · обновление BIOS из меню · DASH: консоль, веб-страница, удалённое питание, ISO по сети |
| ⚠️ **Особенности** | COM-порт в Windows иногда не определяется |

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
| ⚠️ **Особенности** | частоты и напряжения процессора в T1.1 закрыты (разгон процессора — в T2) |

## Ryzen 3 3200G

> Picasso · 4 ядра / 4 потока · встроенная Vega 8

| | |
|---|---|
| **Версии** | T1.x |
| **Системы** | Windows |
| ✅ **Работает** | разгон памяти до **2933** — штатного предела этого процессора по AMD |
| ⚠️ **Особенности** | 3200 на 1,2 В не держит (контроллеру памяти этого процессора нужно больше, а напряжение памяти на этой плате не поднять) · через пассивный переходник DP→HDMI нет 144 Гц в 1440p ([известные проблемы](KNOWN_ISSUES.md)) |

## Ryzen 5 3400G

> Picasso · 4 ядра / 8 потоков · встроенная Vega 11

| | |
|---|---|
| **Версии** | T1.1 |
| **Системы** | Windows 11 |
| **Память** | 2 × 8 ГБ Crucial DDR4-2400, разгон до 2866 |
| ✅ **Работает** | перезагрузки · сон · включение после пропадания света · USB · сеть · звук · DisplayPort · SATA · M.2 · частота памяти вручную; включения стабильнее, чем на прошивках Acer и AFOX |
| ⚠️ **Особенности** | с ручной частотой памяти перед запуском Windows бывает одна лишняя перезагрузка (исправление — в T2) |

## Ryzen 3 4300GE

> Renoir · 4 ядра / 8 потоков · встроенная Vega 5

| | |
|---|---|
| **Версии** | T1.1r |
| **Системы** | Windows |
| **Память** | 2 × 8 ГБ Crucial (2666 + 2400) |
| ✅ **Работает** | перезагрузки · все USB · сеть · оба DisplayPort и VGA · звук и микрофон спереди и сзади · M.2 NVMe (Samsung 970 EVO) |
| ⚠️ **Особенности** | с ручной частотой памяти при старте бывает лишняя перезагрузка |

**Опыты**
- Память на **3000** и **3200** с задержками «Авто»: на 3200 вышло CL 24-23-23-52, 1T, Gear Down; память, Infinity Fabric
  и контроллер памяти 1:1:1 (1600 МГц), напряжение SoC 0,99 В — без повышения.
- Разные планки в разных каналах (двухранговая 2666 и одноранговая 2400): каждый канал получил свои задержки из своей
  планки — CL 24-23-23 и CL 22-22-22 при общей частоте 3200.
  AIDA64 (FPU, кэш, память) 15 минут и TestMem5 3 цикла — без ошибок.

## Ryzen 5 4600G

> Renoir · 6 ядер / 12 потоков · встроенная Vega 7

| | |
|---|---|
| **Версии** | T1.1 |
| **Системы** | Windows |
| ⚠️ **Особенности** | после «Перезагрузки» Windows тормозит ([известные проблемы](KNOWN_ISSUES.md)); исправлено в T1.1r, ждём подтверждения |

## Ryzen 5 5600G

> Cezanne · 6 ядер / 12 потоков · встроенная Vega 7

| | |
|---|---|
| **Версии** | T1.1, T1.1r |
| **Системы** | Windows 10 |
| **Память** | 4 × 8 ГБ разные (две 2400, две 2666) · 1 × 8 ГБ Crucial 2400 |
| ✅ **Работает** | запуск Windows · перезагрузки из Windows (на T1.1r) · четыре планки памяти |
| ⚠️ **Особенности** | на T1.1 перезагрузка из Windows зависает (исправлено в T1.1r) · выход из сна зависает (с четырьмя разными планками, проверяем) · у одного тестера на T1.1 не работают передние USB и два задних под сетевым разъёмом ([известные проблемы](KNOWN_ISSUES.md)) |

---

# What has been tested

| Processor | Family | Versions | Result |
|---|---|---|---|
| [Ryzen 3 2200G](#ryzen-3-2200g-1) | Raven Ridge | T1, T1.1, T1.2 | ✅ works |
| [Ryzen 5 2400G](#ryzen-5-2400g-1) | Raven Ridge | T1.1 | ✅ works, 2 × 16 GB up to 3200 |
| [Ryzen 3 3200G](#ryzen-3-3200g-1) | Picasso | T1.x | ✅ works, memory at 2933 |
| [Ryzen 5 3400G](#ryzen-5-3400g-1) | Picasso | T1.1 | ✅ works, sleep and power-ons |
| [Ryzen 3 4300GE](#ryzen-3-4300ge-1) | Renoir | T1.1r | ✅ works, memory up to 3200 |
| [Ryzen 5 4600G](#ryzen-5-4600g-1) | Renoir | T1.1 | ⚠️ slowdowns after a restart, fixed in T1.1r (awaiting confirmation) |
| [Ryzen 5 5600G](#ryzen-5-5600g-1) | Cezanne | T1.1, T1.1r | ⚠️ works; waking from sleep hangs, one tester's chipset USB sockets do not work |

## Ryzen 3 2200G

> Raven Ridge · 4 cores / 4 threads · Vega 8 graphics

| | |
|---|---|
| **Versions** | T1, T1.1, T1.2 |
| **Systems** | Windows 11, Windows 11 Pro, Linux |
| **Memory** | 2 × 8 GB DDR4-2666 (Crucial + Kingston) · 2 × 4 GB of different kinds (2666 + 2400), together at 2400 |
| ✅ **Works** | restarts, sleep, power-on by timer, over the network and after a power cut · both DisplayPort sockets · USB 3.0 · 1 Gbit/s network · SATA · sound · TPM 2.0 · fan · BIOS update from the menu · DASH: console, web page, remote power, ISO over the network |
| ⚠️ **Notes** | the COM port is sometimes not detected in Windows |

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
| ⚠️ **Notes** | the processor's clocks and voltages are locked in T1.1 (processor overclocking comes in T2) |

## Ryzen 3 3200G

> Picasso · 4 cores / 4 threads · Vega 8 graphics

| | |
|---|---|
| **Versions** | T1.x |
| **Systems** | Windows |
| ✅ **Works** | memory overclocked to **2933**, AMD's stated limit for this processor |
| ⚠️ **Notes** | does not hold 3200 at 1.2 V (this processor's memory controller needs more, and this board cannot raise the memory voltage) · no 144 Hz at 1440p through a passive DP→HDMI adapter ([known issues](KNOWN_ISSUES.md)) |

## Ryzen 5 3400G

> Picasso · 4 cores / 8 threads · Vega 11 graphics

| | |
|---|---|
| **Versions** | T1.1 |
| **Systems** | Windows 11 |
| **Memory** | 2 × 8 GB Crucial DDR4-2400, overclocked to 2866 |
| ✅ **Works** | restarts · sleep · power-on after a power cut · USB · network · sound · DisplayPort · SATA · M.2 · manual memory speed; power-ons are steadier than with the Acer and AFOX firmware |
| ⚠️ **Notes** | with a manual memory speed there is one extra restart before Windows starts (the fix comes in T2) |

## Ryzen 3 4300GE

> Renoir · 4 cores / 8 threads · Vega 5 graphics

| | |
|---|---|
| **Versions** | T1.1r |
| **Systems** | Windows |
| **Memory** | 2 × 8 GB Crucial (2666 + 2400) |
| ✅ **Works** | restarts · every USB socket · network · both DisplayPort sockets and VGA · sound and microphone front and back · M.2 NVMe (Samsung 970 EVO) |
| ⚠️ **Notes** | with a manual memory speed there can be an extra restart at power-on |

**Experiments**
- Memory at **3000** and **3200** with timings on Auto: at 3200 that gave CL 24-23-23-52, 1T, Gear Down; memory,
  Infinity Fabric and memory controller 1:1:1 (1600 MHz), SoC voltage 0.99 V, not raised.
- Different sticks in the two channels (dual-rank 2666 and single-rank 2400): each channel got its own timings from its
  stick, CL 24-23-23 and CL 22-22-22, at a common 3200.
  AIDA64 (FPU, cache, memory) for 15 minutes and TestMem5 for 3 cycles, no errors.

## Ryzen 5 4600G

> Renoir · 6 cores / 12 threads · Vega 7 graphics

| | |
|---|---|
| **Versions** | T1.1 |
| **Systems** | Windows |
| ⚠️ **Notes** | after Restart, Windows slows down ([known issues](KNOWN_ISSUES.md)); fixed in T1.1r, awaiting confirmation |

## Ryzen 5 5600G

> Cezanne · 6 cores / 12 threads · Vega 7 graphics

| | |
|---|---|
| **Versions** | T1.1, T1.1r |
| **Systems** | Windows 10 |
| **Memory** | 4 × 8 GB, all different (two 2400, two 2666) · 1 × 8 GB Crucial 2400 |
| ✅ **Works** | Windows starts · restarts from Windows (on T1.1r) · four memory sticks |
| ⚠️ **Notes** | on T1.1 a restart from Windows hangs (fixed in T1.1r) · waking from sleep hangs (with four different sticks, being checked) · on one tester's board on T1.1 the front USB sockets and the two rear ones under the network socket do not work ([known issues](KNOWN_ISSUES.md)) |
