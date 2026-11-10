# Что проверено / What has been tested

Дополняется по мере проверок, наших и тестеров (форма «Всё работает» в Issues).
Updated as checks and testers' reports (the "Everything works" form in Issues) come in.

| Процессор | Поколение | Версии | Итог |
|---|---|---|---|
| [Ryzen 3 2200G](#ryzen-3-2200g) | Raven Ridge | T1, T1.1 | ✅ работает |
| [Ryzen 3 4300GE](#ryzen-3-4300ge) | Renoir | T1.1r | ✅ работает, память до 3200 |
| [Ryzen 5 4600G](#ryzen-5-4600g) | Renoir | T1.1 | ⚠️ тормоза после перезагрузки, исправление проверяется |

[English version](#what-has-been-tested)

## Ryzen 3 2200G

> Raven Ridge · 4 ядра / 4 потока · встроенная Vega 8

| | |
|---|---|
| **Версии** | T1, T1.1 |
| **Системы** | Windows 11, Windows 11 Pro, Linux |
| **Память** | 2 × 8 ГБ DDR4-2666 (Crucial + Kingston) · 2 × 4 ГБ разные (2666 + 2400) — вместе работают на 2400 |
| ✅ **Работает** | перезагрузки, сон, включение по таймеру, по сети и после пропадания света · оба DisplayPort · USB 3.0 · сеть 1 Гбит/с · SATA · звук · TPM 2.0 · вентилятор · обновление BIOS из меню · DASH: консоль, веб-страница, удалённое питание, ISO по сети |
| ⚠️ **Особенности** | COM-порт в Windows иногда не определяется |

**Опыты**
- Серии перезагрузок: 25, 10 и 100 подряд без зависаний.
- Windows 11: после перезагрузки часы всех ядер совпадают (расхождение меньше 1 мкс).
- Шторма прерываний от контроллера GPIO в Windows нет (0 % времени на прерывания).

## Ryzen 3 4300GE

> Renoir · 4 ядра / 8 потоков · встроенная Vega 5

| | |
|---|---|
| **Версии** | T1.1r (тестовая сборка) |
| **Системы** | Windows |
| **Память** | 2 × 8 ГБ Crucial (2666 + 2400) |
| ✅ **Работает** | перезагрузки · все USB · сеть · оба DisplayPort и VGA · звук и микрофон спереди и сзади · M.2 NVMe (Samsung 970 EVO) |
| ⚠️ **Особенности** | с ручной частотой памяти при старте бывает лишняя перезагрузка |

**Опыты**
- Память на **3000** и **3200** с задержками «Авто»: на 3200 вышло CL 24-23-23-52, 1T, контроллер памяти 1:1.
  AIDA64 (FPU, кэш, память) 15 минут и TestMem5 3 цикла — без ошибок.

## Ryzen 5 4600G

> Renoir · 6 ядер / 12 потоков · встроенная Vega 7

| | |
|---|---|
| **Версии** | T1.1 |
| **Системы** | Windows |
| ⚠️ **Особенности** | после «Перезагрузки» Windows тормозит ([известные проблемы](KNOWN_ISSUES.md)); исправление (T1.1r) проверяется |

---

# What has been tested

| Processor | Family | Versions | Result |
|---|---|---|---|
| [Ryzen 3 2200G](#ryzen-3-2200g-1) | Raven Ridge | T1, T1.1 | ✅ works |
| [Ryzen 3 4300GE](#ryzen-3-4300ge-1) | Renoir | T1.1r | ✅ works, memory up to 3200 |
| [Ryzen 5 4600G](#ryzen-5-4600g-1) | Renoir | T1.1 | ⚠️ slowdowns after a restart, a fix is being tested |

## Ryzen 3 2200G

> Raven Ridge · 4 cores / 4 threads · Vega 8 graphics

| | |
|---|---|
| **Versions** | T1, T1.1 |
| **Systems** | Windows 11, Windows 11 Pro, Linux |
| **Memory** | 2 × 8 GB DDR4-2666 (Crucial + Kingston) · 2 × 4 GB of different kinds (2666 + 2400), together at 2400 |
| ✅ **Works** | restarts, sleep, power-on by timer, over the network and after a power cut · both DisplayPort sockets · USB 3.0 · 1 Gbit/s network · SATA · sound · TPM 2.0 · fan · BIOS update from the menu · DASH: console, web page, remote power, ISO over the network |
| ⚠️ **Notes** | the COM port is sometimes not detected in Windows |

**Experiments**
- Restart series: 25, 10 and 100 in a row without a hang.
- Windows 11: after a restart the clocks of all cores agree (less than 1 µs apart).
- No interrupt storm from the GPIO controller in Windows (0 % interrupt time).

## Ryzen 3 4300GE

> Renoir · 4 cores / 8 threads · Vega 5 graphics

| | |
|---|---|
| **Versions** | T1.1r (test build) |
| **Systems** | Windows |
| **Memory** | 2 × 8 GB Crucial (2666 + 2400) |
| ✅ **Works** | restarts · every USB socket · network · both DisplayPort sockets and VGA · sound and microphone front and back · M.2 NVMe (Samsung 970 EVO) |
| ⚠️ **Notes** | with a manual memory speed there can be an extra restart at power-on |

**Experiments**
- Memory at **3000** and **3200** with timings on Auto: at 3200 that gave CL 24-23-23-52, 1T, memory controller 1:1.
  AIDA64 (FPU, cache, memory) for 15 minutes and TestMem5 for 3 cycles, no errors.

## Ryzen 5 4600G

> Renoir · 6 cores / 12 threads · Vega 7 graphics

| | |
|---|---|
| **Versions** | T1.1 |
| **Systems** | Windows |
| ⚠️ **Notes** | after Restart, Windows slows down ([known issues](KNOWN_ISSUES.md)); a fix (T1.1r) is being tested |
