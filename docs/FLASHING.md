# Установка, обновление и возврат / Installing, updating and going back

> Устанавливая прошивку, вы принимаете [отказ от ответственности](../README.md#отказ-от-ответственности): всё делаете сами и на свой риск.

## Первая установка

**Сначала посмотрите ревизию платы.** Она напечатана на плате рядом с названием AM4P2MS (надпись вида «Ver 1.1»).
Прошивка проверена только на ревизии 1.1. На других ревизиях устанавливайте только на свой страх и риск и будьте готовы
вернуть родной BIOS программатором.

Родной BIOS Lenovo не даст поставить чужую прошивку обычным способом. Поэтому в первый раз её записывают
**программатором**: это небольшое USB-устройство, которое прищепкой цепляют прямо к микросхеме BIOS на плате.
Если вы никогда этого не делали, попросите помочь знакомого, который умеет.

### Что понадобится

- **Программатор CH341A** (или CH347) — продаётся в радиомагазинах и на маркетплейсах.
- **Переходник на 1,8 В — обязательно.** Микросхема BIOS на этой плате работает от 1,8 В, а программатор без переходника
  подаёт 3,3 В и может её сжечь.
- **Прищепка SOIC-8** — обычно продаётся в наборе с программатором.
- **Программа для записи.** Мы пользуемся flashrom (Linux); на Windows есть похожие программы, например AsProgrammer,
  но их мы не проверяли.

Микросхема: Winbond W25Q128FW, 16 МБ. На плате она подписана U53. В flashrom она называется `W25Q128.W`.

### Шаги

1. **Выключите компьютер и выньте шнур из розетки.** Пока прищепка подключена, питание на плату не подавайте.
   Читать и записывать микросхему можно на выключенной плате.
2. **Подключите прищепку к микросхеме U53.** Первая ножка микросхемы отмечена точкой на корпусе; к ней — первый
   провод прищепки (обычно красный).
3. **Сохраните свой родной BIOS.** Прочитайте микросхему два-три раза и сравните файлы, они должны совпасть:
   ```
   flashrom -p ch341a_spi -c W25Q128.W -r backup1.bin
   flashrom -p ch341a_spi -c W25Q128.W -r backup2.bin
   cmp backup1.bin backup2.bin
   ```
   Берегите эту копию: это ваш путь назад к родному BIOS. **В ней ваш серийный номер и ключ Windows — никому её
   не отправляйте.**
4. **Запишите Z3NOVO** (flashrom сам проверит запись):
   ```
   flashrom -p ch341a_spi -c W25Q128.W -w Z3NOVO_T1.bin
   ```
5. **Снимите прищепку, вставьте шнур, включите.** Первый раз компьютер может сам перезагрузиться 2–4 раза, пока
   прошивка готовит настройки и проверяет память. Это нормально, подождите.

Если программатор не видит микросхему, поправьте прищепку. Если две копии не совпадают — переподключите программатор к USB
и прочитайте ещё раз.

## Обновление

С версии T1 — прямо из меню: «Обновить прошивку» и файл с USB-флешки. Ваши настройки, ключ Windows и данные платы при
этом сохранятся. Подробная инструкция появится здесь, когда эту функцию проверят на плате.

## Возврат к родному BIOS

Тем же программатором запишите свою сохранённую копию (шаг 3):
```
flashrom -p ch341a_spi -c W25Q128.W -w backup1.bin
```

---

# Installing, updating and going back

> By installing the firmware you accept the [disclaimer](../README.md#disclaimer): you do everything yourself and at your own risk.

## First install

**Check the board revision first.** It is printed on the board next to the name AM4P2MS (something like "Ver 1.1").
The firmware has been tested only on revision 1.1. On other revisions install it only at your own risk, and be ready to
put Lenovo's BIOS back with the programmer.

Lenovo's BIOS will not let you install other firmware the usual way. So the first time it is written with a
**programmer**: a small USB device that clips straight onto the BIOS chip on the board. If you have never done this,
ask a friend who has.

### What you need

- **A CH341A programmer** (or CH347), sold in electronics shops and online.
- **A 1.8 V adapter — required.** The BIOS chip on this board runs at 1.8 V, and the programmer without the adapter puts
  out 3.3 V, which can burn it.
- **A SOIC-8 clip**, usually sold together with the programmer.
- **A program to write the chip.** We use flashrom (Linux); Windows has similar programs such as AsProgrammer, but we
  have not tested them.

The chip: Winbond W25Q128FW, 16 MB. It is marked U53 on the board. flashrom calls it `W25Q128.W`.

### Steps

1. **Shut the computer down and unplug the power cord.** Never power the board while the clip is attached. The chip can
   be read and written with the board unpowered.
2. **Clip onto the chip U53.** Pin 1 of the chip is marked with a dot on its body; the clip's first wire (usually red)
   goes there.
3. **Save your Lenovo BIOS.** Read the chip two or three times and compare the files; they must match:
   ```
   flashrom -p ch341a_spi -c W25Q128.W -r backup1.bin
   flashrom -p ch341a_spi -c W25Q128.W -r backup2.bin
   cmp backup1.bin backup2.bin
   ```
   Keep this copy: it is your way back to Lenovo's BIOS. **It holds your serial number and Windows key, so never send it
   to anyone.**
4. **Write Z3NOVO** (flashrom checks the write itself):
   ```
   flashrom -p ch341a_spi -c W25Q128.W -w Z3NOVO_T1.bin
   ```
5. **Remove the clip, plug the cord back in, power on.** The first time, the computer may restart by itself 2–4 times
   while the firmware prepares its settings and checks the memory. That is normal; wait.

If the programmer does not see the chip, reseat the clip. If the two copies differ, replug the programmer's USB and read
again.

## Updating

From T1 on, right from the menu: "Update firmware" with the file on a USB stick. Your settings, Windows key and board
data are kept. Detailed instructions will be here once the feature has been tested on a board.

## Going back to Lenovo's BIOS

Write your saved copy (step 3) with the same programmer:
```
flashrom -p ch341a_spi -c W25Q128.W -w backup1.bin
```
